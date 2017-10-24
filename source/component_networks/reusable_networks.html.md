---
layout: documentation
title: Reusable Networks
sort_info: 30
---

# Designing Reusable Networks
{:.no_toc}

- TOC
{:toc}

So far, in this chapter as well as in the [Basics](../basics), we have designed
fairly specific networks - all the components they use are fully specified. The
only thing that was not a proper component was the device in the [Basics
section](../basics/devices.html).

This is very constraining. The networks and profile we built in the Basics
chapter could for instance not been adapted to a system where the arm control
is not a single device, but a whole sub-network. Generally speaking, it is not enough.

The first tool we will introduce in this section, that allows for more general
networks, is the **data service**. Data services are placeholders for real
components, a type system of sorts, that can be replaced in profiles by actual
component implementations.

Other mechanisms are then built on top of the data services. Profiles can
inherit from each other, gradually replacing data services or sub-networks by
more specific ones. Compositions can also be subclassed to refine their
children in the same way.  The core mechanism that make this possible is
_dependency injection_, that is the ability to transform a network into another
by replacing sub-parts of the network.  This what the `use` statement we
[saw](profiles.html#dependency_injection) in
[passing](../basics/devices.html#profile_define)

## Data Services Definition

Defining a data service entails giving it a name, which represents what the
data service represents, and providing it with a dataflow interface (input and
output ports). 

Data services are defined using a `data_service_type` statement in a class or module
context. The data service name must be in `CamelCase`, and the new data service
is registered on the enclosing module, e.g.

~~~ ruby
module CommonModels
  module DataServices
    data_service_type 'Pose' do
      output_port 'pose_samples', '/base/samples/RigidBodyState'
    end
  end
end
~~~

The types used in the data service must be imported first by adding the
relevant [`import_types_from` statement at toplevel](../type_system/types_in_ruby.html#import_types_from)
{: .important}

__Naming Convention__ data services are by convention defined in the `AppName::Services`
module, and are saved in `models/services/name_of_service.rb`. For instance,
the `Pose` data service in the `CommonModels` bundle is saved in
`models/services/pose.rb` and the full service name would be
`CommonModels::Services::Pose`.

__Generation__ A template for a new data service, following Syskit's naming
conventions and file system structure, can be generated with

~~~
syskit gen srv namespace/name_of_service
~~~

for instance

~~~
syskit gen srv pose
~~~

Data services do not have tests.

## Data Service Providers

Components and compositions can **provide** data services. That is, they model
that they are providing a service. In its simplest form, this is done by using
the `provide` statement with the service model and a service name. The latter has
to be unique in the context of the component.

Let's assume a `gps::Task` component which has the following interface definition:

~~~ ruby
task_context 'Task' do
  output_port 'position_samples', '/base/samples/RigidBodyState'
end
~~~

One can declare that this component provides the position data service from `common_models` with:

~~~ ruby
Syskit.extend_model OroGen.gps.Task do
  provides CommonModels::Services::Position,
    as: 'position'
end
~~~

To be able to call `provide` like this, each of the data services ports must
have a **single port** on the component (exported port in the case of
compositions) that matches the port direction and type. If there case more
there is more than one match, the ports must be matched explicitly by passing a
mapping from the service's position name to the component's. If our gps
component had an interface like:

~~~ ruby
task_context 'Task' do
  # Position in the local frame
  output_port 'local_position_samples',
    '/base/samples/RigidBodyState'
  # Position in the UTM frame
  output_port 'utm_position_samples',
    '/base/samples/RigidBodyState'
end
~~~

Then attempting to provide the service without mapping information would cause the following error:

~~~
OroGen.gps.Task does not provide the 'CommonModels::Services::Position' service's interface
 there are multiple candidates to map position_samples[/base/samples/RigidBodyState]: local_position_samples, utm_position_samples
~~~

The mapping must be provided explicitly:
{: #multiple_data_services}

~~~ ruby
Syskit.extend_model OroGen.gps.Task do
  provides CommonModels::Services::Position, as: 'local_position',
    'position_samples' => 'local_position_samples'
  provides CommonModels::Services::Position, as: 'utm_position',
    'position_samples' => 'utm_position_samples'
end
~~~

**Data services and component subclassing** The data service system in effect
allows to exchange components that are unrelated code-wise but have a
relationship from a semantic point of view. This is the preferred way. Don't
subclass two orogen components if they don't share a significant amount of
code.
{: .important}

## Relationships between Data Services

Data types sometimes are semantically complex, that is combine more than one
data into a single sample. The canonical example is a pose, which provides both
a position and an orientation. However, there are other systems that may provide
only an orientation or only a pose. Within Rock, in order to allow a pose
output to be connected to an orientation input, one must use the same data
type. This means that the type (in our pose example,
`/base/samples/RigidBodyState`) can represent a complex data (the full pose) as
well as its parts (position and orientation).

These relationships can be represented within the data service system. The
relationships between the data services are modelled by declaring that
a service `provides` another. In this case, no name has to be provided
since there is no ambiguity - a service cannot provide the same other service
multiple times.

Unlike with components, `provides` in this case does not attempt to map the
provided service ports to the provider's. It will instead, by default, **add**
the provided service ports to the provider interface. Port mappings are instead
required to avoid the port creation.

For instance, if one would define the `Position`, `Orientation` and `Pose` services like this:

~~~ ruby
data_service_type 'Position' do
  output_port 'position_samples', '/base/samples/RigidBodyState'
end
data_service_type 'Orientation' do
  output_port 'orientation_samples', '/base/samples/RigidBodyState'
end
data_service_type 'Pose' do
  output_port 'pose_samples', '/base/samples/RigidBodyState'
  provides Position
  provides Orientation
end
~~~

The resulting data service would be this:

![Pose service without port mappings](media/pose_service_without_port_mappings.svg){: .fullwidth}

By explicitly mapping the provided service ports with:

~~~
data_service_type 'Pose' do
  output_port 'pose_samples', '/base/samples/RigidBodyState'
  provides Position, 'position_samples' => 'pose_samples'
  provides Orientation, 'orientation_samples' => 'pose_samples'
end
~~~

One gets the expected:

![Pose service with port mappings](media/pose_service_with_port_mappings.svg){: .fullwidth}

**Note** the Syskit IDE shows the list of provided services, along with the port mappings for them.
{: .note}

## Using Data Services as Children in Compositions

Data services can be used as-is in compositions. In fact, the device model [we
have used in the basics chapter](../basics/composition.html) is at its core a
data service.  The joint control composition
[from the Basics](../basics/composition.html) should be rewritten using a data service.
This requires to replace the device model by the data service, but also to change the
port names (obviously)

~~~ ruby
# This is in bundles/common_models. The _control_loop files define a set of
# data services related to controlling using the /base/samples/Joints data type
require 'models/services/joints_control_loop'
# Load the oroGen projects
using_task_library 'cart_ctrl_wdls'
using_task_library 'robot_frames'

module SyskitBasics
  module Compositions
    class ArmCartesianControlWdls < Syskit::Composition
      add OroGen.cart_ctrl_wdls.WDLSSolver, as: 'twist2joint_velocity'
      add OroGen.cart_ctrl_wdls.CartCtrl, as: 'position2twist'
      # This was a device
      add CommonModels::Services::JointsControlledSystem, as: 'arm'
      add OroGen.robot_frames.SingleChainPublisher, as: 'joint2pose'

      position2twist_child.ctrl_out_port.
        connect_to twist2joint_velocity_child.desired_twist_port
      # Needed to update the ports
      twist2joint_velocity_child.solver_output_port.
        connect_to arm_child.command_in_port
      arm_child.status_out_port.
        connect_to twist2joint_velocity_child.joint_status_port
      arm_child.status_out_port.
        connect_to joint2pose_child.joints_samples_port
      joint2pose_child.tip_pose_port.
        connect_to position2twist_child.cartesian_status_port

      export position2twist_child.command_port
    end
  end
end
~~~

**Devices vs. data services ?** Generally speaking, one seldom use a device in
a compositions. Do you really need a Garmin GPS in a particular network ? Can't
it work with any other receiver ? Or even a complete network that does pose
estimation instead of a GPS ? Using devices in compositions breaks generality
with zero advantage, since one still has to do things at the profile level to
use the composition.
{: .note}

A data service child within a composition can be refined in subclasses by using
the `overload` statement. A data service child can be overloaded by either
another data service that provides it, or a component that does. If one still
*really* wanted to use the device model in a joint control composition, he could with

~~~ ruby
class GazeboCartesianControlWdls < ArmCartesianControlWdls
  overload arm_child, CommonModels::Devices::Gazebo::Model
end
~~~

## Dependency Injection

Data services are obviously abstract in nature. One cannot run a network that
contains a data service, we therefore need a mechanism to transform composition
models to replace services by concrete components. While overloading
compositions would be a possibility, it would lead to having dense forest of
composition models, as one would need to define a single composition model for
each assignation of concrete components to the services.

Syskit has another mechanism for this, the `use` statement we already
discussed.  When `.use('child_name' => NewModel, …)` is called on a composition
model, the result is the composition model with the given child replaced by the
new model. If a child is itself a composition, a grandchild can be selected by
separating the names with dots (e.g. `.use('child.grandchild' => NewModel)`).

The composition overload we did just above could equivalent have been using a
`use` statement:

~~~ ruby
ArmCartesianControlWdls.use('arm' => CommonModels::Devices::Gazebo::Model)
~~~

Syskit validates type compatibility, of course, that is the replacement is
valid only if it is another service that provides the child's or a component
that does. If the types are incompatible, one gets the following message:

~~~ ruby
invalid selection for arm
got OroGen.cart_ctrl_wdls.CartCtrl
which provides
  OroGen.cart_ctrl_wdls.CartCtrl
  OroGen.RTT.TaskContext
  Syskit::TaskContext
  Syskit::Component
  Roby::Task
expected something that provides child arm of type CommonModels::Services::JointsControlledSystem
~~~

If multiple services match the requested service type, one can select one
explicitly by passing the service instead of the component. A component model
can be accessed with the `${service_name}_srv` accessor. In our [fake GPS
task](#multiple_data_services), one would access the UTM position service with
`OroGen.gps.Task.utm_position_srv` and the local position service with
`OroGen.gps.Task.local_position_srv`.

The result of the `use` statements can be used anywhere a component or service
can be used, as for instance as a composition child or profile definition. It
can be chained with other model modifiers such as `with_arguments` or
`with_conf`. This is how we injected [the robot device in out control
compositions](../basics/devices.html):

~~~ ruby
profile 'ArmControl' do
	define 'arm_cartesian_constant_control',
		Compositions::ArmCartesianConstantControlWdls.
			use(Base.ur10_dev)
	define 'arm_joint_position_constant_control',
		Compositions::JointPositionConstantControl.
			use(Base.ur10_dev)
	define 'arm_safe_position',
		arm_joint_position_constant_control_def.
			with_arguments(setpoint: UR10_SAFE_POSITION)
end
~~~

## Managing Reusability in Profiles

Profiles are the objects that expose the "final" networks, that is the networks
that are going to be used at runtime. As such, they usually are the place where
the replacement of services by actual concrete components happen.



## A Word of Warning

The Syskit type system is _rich_. It has a tendency to play with the software
engineer aspiration of making everything general and reusable.

So **be careful with this**. A Syskit model set that is all-general will be
also all-unmanageable. In most cases, make _resonably large_ compositions that
contain few data services. Don't reuse compositions just because the other
composition existed.

Syskit acts as a type and test system. Its aim is to make refactoring
painless. Don't over-think your designs, splitting common functionality when
necessary.

