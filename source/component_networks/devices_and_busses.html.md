---
layout: documentation
title: Robot definition&colon; Devices and Busses
sort_info: 35
---

# Devices and Communication Busses
{:.no_toc}

- TOC
{:toc}

We have briefly seen _devices_ during [the Basics tutorial](../basics/devices.html).
This section will expand on the notion of device, and explore a related subject,
the notion of communication bus.

Briefly, the role of a device and a device model in a Syskit model is to
represent the system's hardware interfaces. From the perspective of the
component network, it is to represent which components are truly _unique_,
that is aren't "simply" processors of data.

The role of device model's is also to allow to describe a robot's hardware in
terms of _what_ is on it (the devices), not _how_ the software can talk to the
devices (the device drivers). Device models are indeed named after the type of
device, not the driver implementation/component, and will provide the
[data services](reusable_networks.html#data_services) that
_this particular device_ provides. The link between device and
its driver is declared in the driver model.

This section will _not_ explain how to write an actual device driver, only how
one is to be integrated in the system. For the actual implementation, Rock
provides `iodrivers_base`, a flexible C++ library and associated component.
See [the associated cookbook page](../cookbook/device_drivers.html).

## Devices

Three different entities are used to handle a device in Syskit:

1. the device model. This is what describes a class of device(s). A device
   type if you will
2. the device instance. This is a particular instance of a given device class,
   present on a robot.
3. the device driver. This is the actual component that will allow the Rock
   system to interface with devices of a certain class (or class_es_)

We will now detail how to create all three. The next section will deal with
communication busses, that is communication mediums that provide means of
communication between devices and the control computer(s).

### Device Models

Device models are generated with `syskit gen dev type/manufacturer/model`.
The `type/manufacturer/model` triplet should rather closely follow Rock's convention
for the naming of device drivers:

- `type` represents _what_ the device does
- `manufacturer` is the device manufacturer
- `model` is the device model. This is the least well-defined part of the whole naming
  scheme, as one would want to avoid listing every single device type in
  existence, using instead groups of devices that have the same capabilities but
  different performance. A set of different LIDARS from the same manufacturer that
  use the same protocol(s) could be defined this way in a group.

__Naming Convention__ device models are by convention defined in the
`AppName::Devices` module, and are saved in
`models/devices/name_of_service.rb`. For instance, the `GPS::Ublox::F9`
device models would be saved in `models/devices/gps/ublox/f9.rb` and its full
name would be `AwesomeRobot::Devices::GPS::Ublox::F9` (assuming that the
bundle is `awesome_robot`).

__Generation__ A template for a device, following Syskit's naming
conventions and file system structure, can be generated with

~~~
syskit gen dev type/manufacturer/model
~~~

For instance, Ublox's F9 model would be defined with

~~~
syskit gen dev gps/ublox/f9
~~~

Device models can have `provides` relationships, [just like data
services](reusable_networks.html#data_service_relationships). A device model
can provide data services and/or other device models (I don't have an example
of the latter in the wild, though)

### Device Declarations

We have just learned how to create a device _model_. We now need to create
a device _instance_ that will be controlled by a device _driver_.

The robot's actual devices are declared within the robot definition block,
within a profile (each profile may have a different robot block). It is
customary to declare a given system's robot in that system's `Base` profile.
For instance, the [basic tutorial's `gazebo` robot](../basics/devices.html) was
declared in `SyskitBasics::Profiles::Gazebo::Base`.

The robot definition block looks like

~~~ruby
require 'devices/gps/ublox/f9'

profile 'Base' do
  robot do
    device Devices::GPS::UBlox::F9, as: 'gps'
  end
end
~~~

Declaring a device creates a corresponding `_dev` action on the profile that
can be used in place of the device model for
[injection](reusable_networks.html#injection) or at runtime to start the
device driver.

That's it ...

### Device Drivers

Devices are obvisouly abstract, the way data services are. One needs to
associate them with a device _driver_ to be able to actually _use_ the device
at runtime. **One or more device driver must be available at the point of
definition of the device** - for instance by loading them first with `using_task_library`.

A device driver is a component which has a `driver_for` declaration in its
[extension file](../components/runtime.html). For instance, assuming a
`gps_ublox::F9Task` driver, able to handle our F9 model, we would generate
the extension file with:

~~~
syskit gen orogen gps_ublox
~~~

then edit `models/orogen/gps_ublox.rb` to modify the model extension block for `F9Task`:

~~~ ruby
require 'models/devices/gps/ublox/f9'

Syskit.extend_model OroGen.gps_ublox.F9Task do
    driver_for MyApp::Devices::GPS::Ublox::F9, as: 'f9'
end
~~~

After this, adding `using_task_library 'gps_ublox'` at the top of
`models/profiles/live/base.rb` would make Syskit associate the device with
this given driver. Remember that there **must** be at least one device driver
available at the point of definition of the device.

In some cases, one will have more than one driver component compatible with a
given device loaded in a Syskit app. When this happens, you have to explicitely
tell Syskit which component should be used. This is done with the `using` option.

~~~ ruby
using_task_library 'gps_ublox'

profile 'Base' do
  robot do
    device(Devices::GPS::UBlox::F9, as: 'gps', using: OroGen.gps_ublox.F9Task)
  end
end
~~~

Note that the driver component must of course [be deployed in the app's robot
config](../components/runtime.html)

## Communication Busses

In some (relatively) common cases, devices are attached to _communication
busses_ (combus). From Syskit's perspective, a communication bus is

- a _shared_ means of communication: multiple devices use the same communication
  bus
- a _shared_ component that multiplexes and demultiplexes each device drivers'
  I/O to and from the actual device

Syskit's communication bus support is useful when the handling of the bus
itself is done through Rock components. If the multiplexing and demultiplexing
on the bus is done transparently by the operating system, this support is not needed.

CAN is a good example of a shared communication link that can use Syskit's
combus support. Ethernet would be a good example of a shared communication
link that does **not** require to use Syskit's communication bus support.

Syskit's communication bus support provides the protocols needed to
auto-configure the bus-handling component to properly connect the devices
that are attached to the bus. It really is a _protocol_, that is a set of
conventions that bus and device drivers need to follow.

The remainer of this section will explain these conventions, and help you understand
how you can use existing bus support and/or integrate a new bus.

### Using an Existing Communication Bus

We will use Rock's CAN support as example here, as it is a relatively common
bus type on robots.

To use Syskit's combus support, one has to (1) declare the bus and (2) declare
the devices that are attached to it. This is done with the `com_bus` and
and `through` statements within the same `robot` block that defines the system's
devices:

~~~ ruby
using_task_library 'canbus' # canbus driver
using_task_library 'can_temperature_sensor' # does not exist, just an example

module MyApp
  module Profiles
    module Base
      robot do
        com_bus CommonModels::Devices::Bus::CAN, as: 'can0'
        through 'can0' do
          device(OroGen.can_temperature_sensor.Task, as: 'temperature_sensor')
            .can_id(0x1234, 0xffff) # CAN ID filter
        end
      end
    end
  end
end
~~~

If the `can_temperature_sensor::Task` has been integrated with Syskit's combus
handling in mind, this is all that is needed.

The combus device is first and foremost a _device_. So, as we just saw, it needs
to have a device driver component available at the point of declaration,
and an instance of that component needs to be deployed. The attached device(s)
as well.

In the case of the CAN bus, in the generated network, this bus-device pair will
be:
- configured to create a single output port named
  `temperature_sensor` on which CAN messages which match the `can_id` filter
  `(id & 0xffff == 0x1234)` are routed.
- connected that output port to the device's input port for CAN messages
- connected the device's output for CAN messages to the bus component's `can_in`
  port. This port is shared for all attached devices.
- ensures that the CAN component is started before the attached devices are
  **configured**

### Defining New Busses

As we just mentioned, a communication bus is also seen by Syskit as a device.
Just as for the device, one has to declare a com bus model to use it in the
robot definition. They usually simply named by their common name (e.g. CAN)
and lie in the `Devices::Bus` namespace.

__Naming Convention__ combus models are by convention defined in the
`AppName::Devices::Bus` module, and are saved in
`models/devices/bus/name_of_bus.rb`. For instance, the `CAN`
combus model would be saved in `models/devices/bus/can.rb` and its full
name would be `AwesomeRobot::Devices::Bus::CAN` (assuming that the
bundle is `awesome_robot`).

__Generation__ A template for a device, following Syskit's naming
conventions and file system structure, can be generated with

~~~
syskit gen bus bus/name
~~~

In addition to the template generation, one has to declare which datatype is
used by the bus to communicate with the devices. Syskit's combus support
currently assumes the same datatype is used in both directions (e.g.
`/canbus/Message` for CAN). This datatype is passed as second argument
to the `com_bus_type` declaration, as generated in the template:

~~~ruby
import_types_from 'canbus'
com_bus_type 'CAN', message_type: Types.canbus.Message do
  # any declaration valid for data services, for instance 'provides' other
  # services
end
~~~

### Bus and Device oroGen Drivers

To run over a communication bus, the device driver only needs to provide an
input and/or an output port of the bus' data type. Syskit's support won't
require anything more (but specific combus drivers might, see below).

The communication bus implementation may be a little more complex, depending
on the level of functionality required by the integration:

- one option is to keep the combus driver simple, with one input and one
  output, and let the device drivers filter the combus data. This is simpler
  to implement, and will have little performance impact if relatively few
  messages are exchanged on the bus. The downside to this method is that the
  components will have to do the filtering, which also means that it won't be
  simple to look at a particular device's I/O stream in the IDE or in the log
  files. Making things harder for monitoring as well.

- the other option is to demultiplex the data stream on the combus component side.
  This is more complicated to implement as the combus component needs to
  dynamically create ports (but must be implemented once). It is easier to monitor
  at runtime and will be more efficient if there is a lot of traffic on the bus.

### Integrating a Combus Driver that does not Demultiplex

As we just said, in this case the combus driver itself is fairly simple. The
only combus-specific code that will need to be added is to configure the device
driver (since the filtering will have to be done on the device driver).

On the combus driver side, we need to have an input and an output port of the combus's
data type, and its Syskit [orogen extension file](../components/runtime.html#extension_file)
must add a `provides` on the com bus `BusSrv` service. Assuming a `canbus.Task` driver
for our CAN bus:

~~~ ruby
Syskit.extend_model OroGen.canbus.Task do
  provides CommonModels::Devices::Bus::CAN::BusSrv, as: 'canbus'
end
~~~

On the device driver side, the
[component's Syskit's `configure` method](../components/runtime.html#extension_file)
would pass the bus information (the `can_id` attribute in the case of CAN) to
the component's own configuration, for instance, assuming it has two `can_id`
and `can_mask` properties defined by

~~~ruby
property 'can_id', 'int'
property 'can_mask', 'int'
~~~

one would pass the information with

~~~ruby
driver_for MyApp::Devices::Roboteq::CANOpen, as: 'roboteq'

def configure
  super
  # 'roboteq' in roboteq_dev matches the 'roboteq' name in `driver_for`
  id, mask = roboteq_dev.can_id
  properties.can_id = id
  properties.can_mask = mask
end
~~~

This configure method is tested with:

~~~ruby
# Create a bus, as if defined in a robot model
bus = syskit_stub_com_bus(Devices::Bus::CAN)
# Create a device attached to that bus
dev = syskit_stub_attached_device(bus)
      .can_id(10, 20)
dev_task = syskit_stub_deploy_and_configure(dev)

# Verify values on dev_task.properties
assert_equal 10, dev_task.properties.can_id
assert_equal 20, dev_task.properties.can_mask
~~~

For additional information about how this `can_id` attribute is defined,
see [Configuration in the robot declaration](#extend_attached_device_configuration)
below.

### Integrating a Combus Driver that Demultiplexes

By _demultiplexing_ here, we mean tha the combus driver separates per-device
data streams and puts them on separate output ports, and receives per-device
input streams on separate input ports.

This can be useful if the combus driver itself adds per-device information
on the data streams, instead of having it done by the driver (maybe because
the drivers don't know about the combus itself, think for instance an IP
multiplexing component that would take raw IO as input)

To handle demultiplexing, the combus driver will need to provide
- a property to define the devices that are attached, in terms of a name
  (to name the created ports) and the information needed to filter the
  bus messages
- code to create the necessary ports in `configureHook` and remove them in
  `cleanupHook`. The output ports (that is, the ports that send data from
  the bus to the device) are expected to be named the same way than the device
  name. The input ports are named `w${device_name}`. This is a convention that
  will be enforced by Syskit, but needs to be explicitely implemented by the
  orogen component implementation and its Syskit integration. Note that
  the input port is commonly shared, see following section.

When using dynamic ports, Syskit requires the component to declare that
it can create ports and of which type. In addition to the property described
in (1) above, one therefore has to add the dynamic ports declarations to the
orogen file, matching the dynamic port patterns we described above:

~~~ ruby
# Replace canbus/Message by the actual bus data type
dynamic_input_port(/^w\w+$/, '/canbus/Message')
    .needs_reliable_connection
dynamic_output_port /^\w+$/, '/canbus/Message'
~~~

Internally, the component will have to create the ports at configure time, like
so:

~~~cpp
for (auto const& dev : _devices.get()) {
  auto* output_port = new RTT::OutputPort<canbus::Message>(dev.name);
  auto* input_port = new RTT::InputPort<canbus::Message>("w" + dev.name);
  provides()->addPort(*output_port);
  provides()->addPort(*input_port);
  // Some attribute suitably setup to store the allocated ports
  m_allocated_ports.push_back({ name, output_port, input_port });
}
~~~

These ports must be removed and deallocated in cleanupHook:

~~~cpp
for (auto const& dev : m_allocated_ports) {
  provides()->removePort(dev.name);
  provides()->removePort("w" + dev.name);
  delete dev.output_port;
  delete dev.input_port;
}
m_allocated_ports.clear();
~~~

On the Syskit side, the hypothetical `devices` property we defined would be
filled in the combus' `configure` method:

~~~ruby
def configure
  super

  properties.devices = each_declared_attached_device.map do |dev|
    Types.my_bus.Device.new(dev.name, *dev.can_id)
  end
end
~~~

Before we can test the bus device, we need to stub the port creation
behavior. Tests that deal only with checking correctness of the configuration
blocks don't run the actual components. It is therefore needed to "stub" the
fact that filling certain properties cause ports to be created. The following
code does so, and is to be placed at the same context than the configure method:

~~~ruby
def configure
  super

  properties.devices = each_declared_attached_device.map do |dev|
    Types.my_bus.Device.new(dev.name, *dev.can_id)
  end
end

stub do
  devices.each do |dev|
    create_input_port "w#{dev.name}", Types.canbus.Message
    create_output_port dev.name, Types.canbus.Message
  end
end
~~~

Finally, the configure method is tested with:

~~~ruby
# Create a bus, as if defined in a robot model
bus = syskit_stub_com_bus(Devices::Bus::CAN)
# Create a device attached to that bus
dev = syskit_stub_attached_device(bus)
      .can_id(10, 20)
dev_task = syskit_stub_deploy_and_configure(dev)
bus_task, = task.each_child.first

# Verify bus_task.properties.devices
~~~

### Shared Input Port on the Combus Driver

It is usually not necessary to have one input port per device. To simplify,
it is possible to have a single input port instead. To make this work,
one needs to add the `multiplexes` attribute to the port - to make Syskit
accept connecting more than one output to it - and to provide the bus'
`BusInSrv` service as follows.

In the orogen file:

~~~ruby
input_port('msg_in', '/canbus/Message')
  .needs_reliable_connection # make sure buffers are big enough to avoid losing samples
  .multiplexes
~~~

In the task's extension file:

~~~ruby
provides CommonModels::Devices::Bus::CAN::BusInSrv, as: 'bus_in'
~~~

Obviously, everything related to input ports must be removed from both
the oroGen declaration, component implementation and Syskit integration.

### Declaring One Way Communications

Some devices are read-only or write-only. For instance, NMEA2000 sensors often
have no configuration to speak of, and only automatically put their sensor values
on the bus (so, the driver reads only). A CANOpen SYNC message generator would not
need to read the bus.

To integrate a read-only device driver, pass the `client_to_bus: false` option
to the `device` declaration:

~~~ ruby
module MyApp
  module Profiles
    module Base
      robot do
        com_bus CommonModels::Devices::Bus::CAN, as: 'can0'
        through 'can0' do
          device(OroGen.can_temperature_sensor.Task, as: 'temperature_sensor',
                                                     client_to_bus: false)
            .can_id(0x1234, 0xffff) # CAN ID filter
        end
      end
    end
  end
end
~~~

To integrate a write-only device driver, pass the `bus_to_client: false` option
to the `device` declaration:

~~~ ruby
module MyApp
  module Profiles
    module Base
      robot do
        com_bus CommonModels::Devices::Bus::CAN, as: 'can0'
        through 'can0' do
          device(OroGen.can_open.SyncTask, as: 'sync', bus_to_client: false)
            .can_id(0x1234, 0xffff) # CAN ID filter
        end
      end
    end
  end
end
~~~

The same parameters can be provided to `syskit_stub_attached_device` in the
tests.

## Advanced Topics

### Disambiguating Bus Ports on Device Drivers

The `device` declaration basically auto-add the `provides` on the relevant
data services (`bus_model::ClientInSrv` and `bus_model::ClientOutSrv`) before
attempting to setup the network. This works only if the device driver
components have single input or output ports of the com bus message type. If
it is not the case, one needs to disambiguate which ports should be used.

This is done by (1) declaring the data services explicitely and (2) passing
the bus names to the `bus_to_client` and `client_to_bus` options to `device`.
The data service definition will have to provide the disambiguation using
[port mappings](reusable_networks.html#multiple_data_services).

~~~ ruby
OroGen.extend_task OroGen.project.Task do
  provides MyApp::Devices::SomeBus::ClientSrv,
           as: 'client_in',
           'can_in' => 'bus_in',
           'can_out' => 'bus_out'
end
~~~

If the component is read-only resp. write-only, use `ClientInSrv` resp.
`ClientOutSrv` instead of `ClientSrv`

### Per-device configuration in the robot declaration {#extend_attached_device_configuration}

The `can_id` information attached to the device definition we have seen in
the section's example is defined by the com bus itself. The call appears
only on devices that are attached to a CAN bus.

One defines such bus-specific configurations with `extend_attached_device_configuration`
in the com bus model definition:

~~~ ruby
com_bus_type 'CAN', message_type: '/canbus/Message' do
  extend_attached_device_configuration do
    # This context will be added to any device 'attached' to the bus 'self' is
    # the device object
    def can_id(*args)
    end
end
~~~

Syskit provides the `dsl_attribute` helper which provides proper fluid interface:
- without arguments, returns the attribute value
- with arguments, set the attribute value
- always returns 'self' to allow for method chaining

~~~ ruby
dsl_attribute :can_id do |id, mask|
  # Validate 'id' and 'mask', and return the value
  # that will be set
  [id * 2, mask * 2]
end
~~~

~~~
device.can_id # => nil
device.can_id(1, 2) # => device
device.can_id # => [2, 4]
~~~

### Association Between Driver and Device

In practice, Syskit will refuse running a device driver component if no devices
are attached to it. The association between device driver and device is done
through task arguments. Calling `driver_for` also creates an argument named
after the driver data service's name. The device is passed to this argument.

For instance, `OroGen.gps_ublox.Task` components defined after

~~~ ruby
Syskit.extend_model OroGen.gps_ublox.Task do
  driver_for MyApp::Devices::GPS::Ublox::F9, as: 'f9p'
end
~~~

will have a `f9p_dev` argument, and the argument's value will be the device
object itself.

### Defining informations at the device model level

In some cases, the device model itself provides information relevant to the
device driver. For instance, the NMEA2000 specification defines the relationship
between PGNs (a numerical message ID) and the type of message/device that will
send this PGN. This is a static association that is specific to the device
model, not to a particular device instance of this model.

To simplify creating systems with busses that are constructed this way, it
is possible to attach the information to the device model itself. To do so,
one needs to create a device model class that is then used as root for
all the device models for the bus.

The new device model class is created by subclassing `Syskit::Models::DeviceModel`:

~~~ ruby
module Seabots
  module Devices
    module N2k
      class DeviceModel < Syskit::Models::DeviceModel
        # Define nmea2000-specific API for all device models of this class
        def pgn(pgn)
        end
      end

      # Make the device model available to define other models
      Device = DeviceModel.new
      Device.provides Syskit::Device
    end
  end
end
~~~

Then, devices for this class may be defined by passing the `parent: Device` option:

~~~ ruby
require 'seabots/models/devices/n2k/device'

module Seabots
  module Devices
    module N2k
      device_type 'FluidLevel', parent: Device do
        pgn 127_505
      end
    end
  end
end
~~~

The information is then available at configure time through the device's
`#model` attribute, for instance:

~~~ ruby
def configure
  super

  each_declared_attached_device.map do |dev|
    [dev.name, dev.model.pgn]
  end
end
~~~

When creating stub devices in tests, one passes the base model with
the `parent_model: ` option to `syskit_stub_attached_device`, e.g.

~~~ ruby
bus = syskit_stub_com_bus(Seabots::Devices::N2k::Bus,
                          driver: OroGen.nmea2000.CANTask)
@dev = syskit_stub_attached_device(
    bus, client_to_bus: false,
         base_model: Seabots::Devices::N2k::Device
)
~~~
