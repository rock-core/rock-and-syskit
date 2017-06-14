---
layout: documentation
---

# Profiles, Actions and Deployments:

## Running the arm control network

A few things are missing before we can actually run [the network we just
created](arm_cartesian_control_generator.html):

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
