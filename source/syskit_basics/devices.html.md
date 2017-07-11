---
layout: documentation
title: Devices
sort_info: 40
---

# Devices

So far, we have a control composition. But as we noticed when we created [the
arm control network](composition.html), it is not using a real component as the
arm, only a device model. This page will be talking about devices, and telling
how one replaces the device model by something that can be run.

One can partition a component network into three categories:

- source of data
- sinks of data
- transformation of data

Within a robotic system, the source and sinks of data are the sensors and
actuators of the robot itself. What makes them unique when building the system's
component network is that they are indeed _unique_.

While the data processing components can easily be duplicated - an image
preprocessing component can be instantiated multiple times to process multiple
streams of data - one cannot duplicate devices.  They are bound to hardware,
and we still don't know how to grow new devices on the robot on-demand.

This difference shows up in the Syskit modelling system. Devices
are defined separately within a _robot interface_. We will now see how this is done, and
how we can use these devices within our arm control network, binding the
simulated arm with the control network.

## Defining devices for the Gazebo system

The robot definition is done within a Syskit _profile_. Profiles are the models
that bind network definitions (compositions) with devices and other
compositions. It's also where the robot definition happens.

As a matter of convention, one usually creates a per-robot `Base` profile that
contains the robot definition.  Let's do that now.

~~~
$ syskit gen profile -rgazebo base
      create  models/profiles/gazebo
      create  models/profiles/gazebo/base.rb
      create  test/profiles/gazebo
      create  test/profiles/gazebo/test_base.rb
~~~

Note how the addition of `-rgazebo` to the command line ensured that the model
is generated within the `gazebo/` subdirectory of the `profiles/` folder and
within the `Gazebo` namespace of `Profiles`. This is a general convention (e.g.
compositions specific to our `gazebo` robot would be in `compositions/gazebo/` and
within the `Compositions::Gazebo` namespace.
{: .callout .callout-warning}

Now, here's the catch: we will actually not really learn to define devices, since
the mapping from the simulation model to devices is done automatically from the
robot model. One only has to declare the robot model in the `Base` profile:

~~~ruby
module SyskitBasics
  module Profiles
    module Gazebo
      profile 'Base' do
        use_gazebo_model 'model://ur10_fixed/model.sdf'
        use_sdf_world
      end
    end
  end
end
~~~

And have a look at the generated devices with `syskit ide -rgazebo models/profiles/gazebo/base.rb`:

![Devices from the UR10 model](media/devices.png){: .fullwidth}

One can see that there is one device definition per link in the model, and one
for the model itself. Let's click on the model and have a look at the dataflow.
Enable both "Show all ports" and "Show task info" to get port information .

![ModelTask interface](media/device_dataflow.png){: .fullwidth}

## Injecting the device into the arm control network {#profile_define}

As said, profiles is where this kind of injection is done. But let's keep `Base`
for really low-level stuff like devices. Let's create an `ArmControl` profile to
integrate the arm control stuff.

~~~
syskit gen profile -rgazebo ArmControl
~~~

We need to require the `Base` profile and `ArmCartesianControlWdls` composition
definition.  Then, `define` the cartesian and joint position controls _for our
UR10 robot in gazebo_ by injecting the UR10 device as the 'arm' child of the
composition.

The model name given to `define` in a profile is made out of a [demeter
chain](https://martinfowler.com/bliki/FluentInterface.html). In Ruby, one can
easily break the chain with a newline after each method call. Don't forget the
dots !
{: .callout .callout-warning}

~~~ruby
require 'models/profiles/gazebo/base'
require 'models/compositions/arm_cartesian_constant_control_wdls'
require 'models/compositions/joint_position_constant_control'

module SyskitBasics
  module Profiles
    module Gazebo
      profile 'ArmControl' do
        define 'arm_cartesian_constant_control',
          Compositions::ArmCartesianConstantControlWdls.
            use(Base.ur10_fixed_dev)
        define 'arm_joint_position_constant_control',
          Compositions::JointPositionConstantControl.
            use(Base.ur10_fixed_dev)
        define 'arm_safe_position',
          arm_joint_position_constant_control_def.
            with_arguments(setpoint: UR10_SAFE_POSITION)
      end
    end
  end
end
~~~

As we mentioned [when we defined it](constant_generator.html#joint_position_constant_generator),
the joint position constant control has been defined with the goal of providing a sane default
position. Let's make sure this is available easily by creating a definition with a default
setpoint. This will reuse the `arm_joint_position_constant_control` definition, which is accessed
with the `_def` suffix. Usable joint positions can be found using the `rock-transformer` tool:

~~~
$ rock-transformer models/sdf/ur10_fixed/model.sdf
~~~

~~~ruby
require 'models/profiles/gazebo/base'
require 'models/compositions/arm_cartesian_constant_control_wdls'
require 'models/compositions/joint_position_constant_control'

module SyskitBasics
  module Profiles
    module Gazebo
      UR10_SAFE_POSITION = Hash[
        'ur10_fixed::ur10::shoulder_pan'  => 0,
        'ur10_fixed::ur10::shoulder_lift' => -Math::PI/2,
        'ur10_fixed::ur10::elbow'         => Math::PI/2,
        'ur10_fixed::ur10::wrist_1'       => 0,
        'ur10_fixed::ur10::wrist_2'       => 0,
        'ur10_fixed::ur10::wrist_3'       => 0]

      profile 'ArmControl' do
        define 'arm_cartesian_constant_control',
          Compositions::ArmCartesianConstantControlWdls.
            use(Base.ur10_fixed_dev)
        define 'arm_joint_position_constant_control',
          Compositions::JointPositionConstantControl.
            use(Base.ur10_fixed_dev)
        define 'arm_safe_position',
          arm_joint_position_constant_control_def.
            with_arguments(setpoint: UR10_SAFE_POSITION)
      end
    end
  end
end
~~~

A device model is accessed using the device's name with a `_dev` suffix on the
profile it is defined. Here `Base.ur10_fixed_dev` is the `ur10_fixed` device
defined on the robot definition in `Base`.
{: .callout .callout-info}

**Note** when building profiles, the require lines as well as the names of
models and roles that can be used in the `use` statement can easily be browsed
using the IDE
{: .callout .callout-info}

Let's have a look at the final definition.

![Final injected arm control network](media/injected_arm_control_network.png){: .fullwidth}

We're almost there, just need now to map the components to actual processes, [a.k.a. deploy the network](deployment.html){: .btn .btn-primary}
