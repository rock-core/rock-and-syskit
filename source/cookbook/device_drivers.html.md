---
layout: documentation
title: Device Drivers with iodrivers_base
sort_info: 10
---

# Device Drivers
{:.no_toc}

- TOC
{:toc}

From the perspective of this howto, a device driver really is a piece of
software that interacts with another piece of software through OS-provided
I/O, that could be low-level protocols (serial) or higher-level ones
(network). This _howto_ will explain what Rock provides you to integrate this
type of I/O at the library and component level. See the [network design page on
devices and busses for the Syskit integration of these devices](../component_networks/devices_and_busses.html)

We also will provide design guidelines on how to interact with the special
case of interacting with actual devices, that is the sensors and actuators
that form your system.

## Roles of library, component and Syskit

As with all Rock software, the library must be the place where most of the work
is being done. See the introduction to [the library section](../libraries/index.html)
for the rationale behind this.

In the more particular context of a device driver, the roles of library and
component are:

- _library_: provide an API to the device's functionality. Ideally, when it makes
  sense, the API should be using Rock conventions and data types. But the goal
  really is to expose the **device functionality**, without presuming too much
  on how this functionality might be used in your particular robotic system
- _component_: provide the interface(s) that the robotic system needs. What you
  have to realize is that if the library is well-designed, it will be easy to
  build system-specific tasks if needed (most of the time they're not, but bear
  with me).

## Design Guidelines {#guidelines}

### Reading and writing threads

It is an (unfortunately) common reflex to spawn reading threads, to read the
data from the device as it arrives. In the context of Rock, this threading is
**much more safely** taken care of by the component implementation. Libraries
should be "passive", that is should do something only when called, and do it
in the thread of the caller.

Of course, if you need to, it is also fine to write a higher-level layer that
would do the threading **on top of** the driver API. Just don't embed it the driver
API.

### Saved Configuration

Do not use _saved configuration_, that is configuration stored on the device.
And do not assume that the device has a configuration that you already know,
unless you explicitely reset it to default configuration each time the device
connects to it (a valid practice in some cases).

### Retrying

Use retries only as a very last resort (i.e. to workaround very broken devices).
The system should be the one dealing with errors. Fail early.

## Implementation using `iodrivers_base`

### Library

Let's start with the first level of implementation, _the library_. Rock has
a very neat library meant to deal with I/O, `drivers/iodrivers_base`. Unless
you really know what you are doing, we very strongly suggest you start by
basing your device driver on `iodrivers_base`.

Check out [its README](https://github.com/rock-core/drivers-iodrivers_base)
for documentation.

### Component

As is usual within Rock, the `drivers/iodrivers_base` library has an equivalent
oroGen integration. `drivers/orogen/iodrivers_base`. See
[its README](https://github.com/rock-core/drivers-orogen-iodrivers_base)
for documentation.

## Syskit Integration

Two steps are needed to integrate a device driver in your Syskit environment:

1. define the supported device's model (if needed)
2. declare that your component is a driver for the device

Then, to use a device, one declares it in a profile's `robot` context, as we
have seen [in the Syskit basics tutorial](../basics/devices.html). Between this
declaration and the loading of a compatible device driver component (with
`using_task_library`), Syskit will be able to inject the device in your component
network.

### Device model

We have seen device models [in the Syskit basics tutorial](../basics/devices.html).
The role of a device model is to represent an actual device in a network, without
necessarily picking _how_ this device will be interfaced with the Syskit system
just yet.

Because device models represent actual devices, the guideline for device naming
is to categorize them by manufacturer and model. This makes creating the
robot block declaration in the system's base profile much easier, as it leaves
little to guessing.

In practice, the device model hierarchy should follow the
`App::Devices::Type::Manufacturer::Model` pattern, for instance
`CommonModels::Devices::Sonar::Tritech::Micron`. As an example, let's declare
the M8-class chip from Ublox.

To create the new device model, one would run

~~~shell
syskit gen dev GPS::Ublox::M8
~~~

Within the device model, one declares the services that all drivers for this
device **must** provide (they *may* provide more). Let's edit the newly
created `models/devices/gps/ublox/m8.rb' file and modify the device declaration

~~~ruby
require 'common_models/services/pose'

module MyApp
    module Devices
        module GPS
            module Ublox
                device_type 'M8' do
                    provides CommonModels::Services::GlobalPosition
                    provides CommonModels::Services::GPS
                end
            end
        end
    end
end
~~~

### Device Driver Component

A device driver component is an oroGen component that has been declared as
being able to drive a device. This is done in the
[oroGen extension file](../basics/deployment.html).

Let's expand on our hypothetical Ublox M8. If we assume that we have written a
`gps_ublox::M8Task` component to drive it, we can generate the orogen extension
file with:

~~~shell
syskit gen orogen gps_ublox
~~~

And edit the created `models/orogen/gps_ublox.rb` file to add:

~~~ruby
require 'models/devices/gps/ublox/m8'

Syskit.extend_task OroGen.gps_ublox.M8Task do
    driver_for MyApp::Devices::GPS::Ublox::M8, as: 'ublox_m8'
end
~~~

This way, when you load the component model using `using_task_library 'gps_ublox'`,
Syskit will be aware that the `M8Task` component can be used to drive a M8 device.

### Usage

On the usage side, one needs to declare the devices that are available on the
device. Edit your robot's `Base` profile, and declare the device. This
declaration a `gps_dev` entry in the profile, that can be used directly in
the Syskit IDE and/or used in dependency injection in the other profiles.

~~~ruby
profile 'Base' do
    robot do
        device Devices::GPS::Ublox::M8, as: 'gps'
    end
end
~~~

At runtime, the device configuration is done through the standard orogen
configuration file(s). The device URI
(as [supported by `iodrivers_base`](https://github.com/rock-core/drivers-iodrivers_base))
is given in the `io_port` property. Drivers should be designed so that only setting
this property should be enough to have a functional component.

Syskit will automatically pick a configuration with the device's name if one
is available, e.g. with a configuration file containing two sections

~~~
--- name:default
--- name:gps
~~~

Syskit will use the `['default', 'gps']` configuration by default (since the
device declared in the `robot` block is called `gps`) for the driver. If the
`gps` configuration does not exist, it will simply use `default`.

In addition to the URI mechanism, the oroGen integration also allows you to
communicate with the driver through the `io_raw_in` and `io_raw_out`
component ports. To use this, connect the component that will handle the byte
streams to these two ports and leave `io_port` empty.

### Logging

`iodrivers_base`-based components "replicate" the data they
exchange on their `io_read_listener` and `io_write_listener` ports. This can
generate a *lot* of log data. We recommend that you configure Syskit to not
log this by default using Syskit's log groups:

In the `Robot.config` block of your robot configuration file,

~~~ruby
Syskit.conf.logs.create_group 'RawIO', enabled: false do |g|
    g.add /iodrivers_base.RawIO/
end
~~~

You may then re-enable logging using the Syskit IDE for better debugging

### Monitoring

`iodrivers_base`-based components output a [`iodrivers_base/Status`](https://github.com/rock-core/drivers-iodrivers_base/blob/master/src/Status.hpp)
status structure on the `io_status` port. When things misbehave, this
structure allows you to determine whether
- the problem is that a device stopped sending data (`good_rx`/`bad_rx` stops
  increasing)
- the communication channel is bad or the packet extraction logic has a bug
  (`bad_rx` is high)
- the component stopped sending data even though it should not have (`tx` stops
  increasing)
