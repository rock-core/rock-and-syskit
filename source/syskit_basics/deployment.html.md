---
layout: documentation
title: Deployment
sort_info: 50
---

# Profiles, Actions and Deployments:

## Running the arm control network

A few things are missing before we can actually run [the network we just
created](constant_generator.html):

1. Deploy the components
4. Configure the components
3. Bind the network to the actual arm in Gazebo
5. Export the network as a Syskit Action so that we can instruct Syskit to start it

## Component deployment

When declared in oroGen files, components are a functional encapsulation of a
function. At this stage, a "component" is really just a class which embeds code
in a specific, normalized way, and that has predefined inputs, outputs and
configuration parameters.

To actually run a component, one needs to declare how it will be supported by
the operating system's runtime ressources (how the components are mapped to
processes and threads), and when the component will be processing its data
(periodically, triggered by its inputs). Moreover, the component is given a name
so that it can be discovered by Rock's inspection tools, and so that its outputs
can be found in the data logged at runtime.

All oroGen components have a default deployment scheme of one component per
process. The triggering mechanism does not have a default, but the
`port_driven` scheme (where the component is triggered whenever data is
received on its inputs) is a very common scheme. If you look into the
`cart_ctrl_wdls` package, you would see that 

One usually starts with the defaults defined in the oroGen file. We therefore
only have left to give a name to the components Syskit is using. This is done
in the robot's config file with:

~~~ruby
Robot.requires do
  require 'models/compositions/arm_cartesian_control_wdls'
  Syskit.conf.use_deployment 'cart_ctrl_wdls::CartCtrl' => 'arm_pos2twist'
  Syskit.conf.use_deployment 'cart_ctrl_wdls::WDLSSolver' => 'arm_twist2joint'
  Syskit.conf.use_deployment 'robot_frames::SingleChainPublisher' => 'arm_chain_publisher'
end
~~~


Let's finally integrate the generator and the control network in a
`ArmCartesianConstantControl` composition. Generate it and link the command to
the control.

~~~ruby
require 'models/compositions/arm_cartesian_constant_generator'
require 'models/compositions/arm_cartesian_control_wdls'

module SyskitBasics
  module Compositions
    class ArmCartesianConstantControl < Syskit::Composition
      add ArmCartesianConstantGenerator, as: 'command'
      add ArmCartesianControlWdls, as: 'control'
      command_child.out_port.
        connect_to control_child.command_port
    end
  end
end
~~~

### Configuring the components

Configuration of components in a Syskit system is split into two parts:

- "dynamic" configuration: parameters that cannot be known at design
  time, will be changed each time an action is started, or are to be
  extracted from other information such as the world definition (SDF model).
  These are represented as **task arguments**. This is the mean [we just
  saw](constant_generator.html) to parametrize the setpoint of the
  cartesian controller.
- "static" configuration: parameters that are known at design time. Most
  of the algorithm parameters fit into this category. These are the subject
  of this section.

The static configuration is stored within YAML files in `config/orogen/`. Each
file is named after the component model that is configured, so for instance
`config/orogen/cart_ctrl_wdls::WDLSSolver` stores the configuration of all
components under that name. Each file can contain multiple configurations
within sections, but for now we'll only use the `default` configuration,
which is the one that is loaded by default unless specified otherwise.

Let's generate configuration file templates for the components we are using. The
files are generated with the default configuration exposed by the components.

~~~
$ syskit gen orogenconf cart_ctrl_wdls::WDLSSolver
      create  config/orogen/
      create  config/orogen/cart_ctrl_wdls::WDLSSolver.yml
$ syskit gen orogenconf cart_ctrl_wdls::CartCtrl
      exists  config/orogen/
      create  config/orogen/cart_ctrl_wdls::CartCtrl.yml
$ syskit gen orogenconf robot_frames::SingleChainProducer
      exists  config/orogen/
      create  config/orogen/robot_frames::SingleChainPublisher.yml
~~~

Each properties in the generated files have their corresponding configuration.
Let's look at them one by one, to see what needs to actually be configured.

- `cart_ctrl_wdls::WDLSSolver`. There are robot model parameters as well as tip
  and root, but as we described above, these are best handled within Syskit
  itself.  The only algorithm parameter that does not seem to have a sane
  default is the `lambda` parameter. The documentation mentions 0.1 has a
  known-good parameter for some arm, let's pick that and keep in mind that it
  might be wrong.
- `cart_ctrl_wdls::CartCtrl`. The one parameter that is probably best changed is
  the max output. The component's designer decided to pick `RigidBodyState` to
  represent a twist, which means that we only need to update the velocity
  and angular velocity fields. Let's set `0.1` in linear and `2.deg` in angular
  (the `.deg` suffix will convert a degree value in radians).
- `robot_frames::SingleChainPublisher` only has robot model and tip/root parameters.


