---
layout: documentation
title: Compositions
sort_info: 10
---

# Compositions
{:.no_toc}

- TOC
{:toc}

In the system modelling, compositions are what bind components together: they
define, for a specific task, behaviour or subsystem (depending from which side
of robotics you come from), what components are needed and how these components
should be connected together to perform the required function.

## Definition

Compositions are classed, defined with

~~~ ruby
class ModelName < Syskit::Composition
  ...
end
~~~

__Naming Convention__ compositions are by convention defined in the
`AppName::Compositions` module, and are saved in
`models/compositions/name_of_composition.rb`. For instance, a
`Localization::GlobalPoseEstimator` composition in the `CommonModels` bundle would be saved
in `models/compositions/localization/global_pose_estimator.rb` and the full class
name would be `CommonModels::Compositions::Localization::GlobalPoseEstimator`.


__Generation__ A template for a new composition as well as its related unit
tests, following Syskit's naming conventions and file system structure, can be
generated with

~~~
syskit gen cmp namespace/name_of_composition
~~~

for instance

~~~
syskit gen cmp localization/global_pose_estimator
~~~

## Building the Compositions' Network

The main statements in a composition are `add` and `connect`. From the
[basics](../basics/composition.html) chapter:

~~~ ruby
module SyskitBasics
  module Compositions
    class ArmCartesianControlWdls < Syskit::Composition
      add OroGen.cart_ctrl_wdls.WDLSSolver, as: 'twist2joint_velocity'
      add OroGen.cart_ctrl_wdls.CartCtrl, as: 'position2twist'
      add CommonModels::Devices::Gazebo::Model, as: 'arm'
    end
  end
end
~~~

The `add` statement adds a child to the composition's network. Once defined,
children are referred to with the `${child_name}_child` syntax, as e.g.
`position2twist_child`. A child's port is by calling `${port_name}_port` on the
child.  Children need to be given a name (which should reflect the child's
role).  Obviously, these children need to be connected together.  This is done
with `connect_to`:

~~~ ruby
module SyskitBasics
  module Compositions
    class ArmCartesianControlWdls < Syskit::Composition
      add OroGen.cart_ctrl_wdls.WDLSSolver, as: 'twist2joint_velocity'
      add OroGen.cart_ctrl_wdls.CartCtrl, as: 'position2twist'
      add CommonModels::Devices::Gazebo::Model, as: 'arm'

      position2twist_child.ctrl_out_port.
        connect_to twist2joint_velocity_child.desired_twist_port
      twist2joint_velocity_child.solver_output_port.
        connect_to arm_child.joints_cmd_port
    end
  end
end
~~~

**Note** models used within the composition need to be loaded at the toplevel
of the composition file, before the composition definition. orogen models with
the `using_task_library` statement, other models by `require`'ing the file that
defines it.
{: .important}

Modifiers on the children have to be added to the return value of the `add`
statement. The
[`with_conf`](../components/runtime.html) statement
for components for instance would be added like this:

~~~ ruby
add(OroGen.cart_ctrl_wdls.WDLSSolver, as: 'twist2joint_velocity').
  with_conf('default', 'high_velocity')
~~~

The result of this composition definition can be checked graphically using the `syskit ide`:

~~~
syskit ide models/compositions/arm_cartesian_control_wdls.rb
~~~

## Exporting ports on Compositions

Within the networks of a Syskit system, compositions can be used whenever a
Rock component is. This is made possible by the ability to give ports to
compositions.

However, since compositions are not "active components", but only combination
of other components, these ports are actually ports that come from the
composition's children. This is done by _exporting_ a child's port
onto the composition interface. The following snippet creates a port named
`command` onto the composition, that is in fact the `position2twist`'s port of
the same name:

~~~
export position2twist_child.command_port
~~~

If desired, the composition port may have a different name than the component port using the `as:` argument:

~~~
export position2twist_child.command_port,
  as: 'position_command`
~~~

In the IDE, an exported port is shown on the composition interface, and linked
to the composition's child port that defines it.

TODO: add figure

**Note** since compositions can be used as composition children, a
composition's exported port can be itself exported in a parent compositions,
and so on and so forth.
{: .note}

## Configuration {#configurations}

In the same way than compositions do not really have ports, but only "export"
the ports of its children, compositions do not have configurations by
themselves. Instead, configurations are defined as a list of configurations for
the children.

For instance:

~~~ ruby
module SyskitBasics
  module Compositions
    class ArmCartesianControlWdls < Syskit::Composition
      add OroGen.cart_ctrl_wdls.WDLSSolver, as: 'twist2joint_velocity'
      ...
      conf 'high_speed',
        twist2joint_velocity_child => ['default', 'high_sampling_rate']
    end
  end
end
~~~

Unlike what is possible with task contexts, one cannot "merge" configurations on
top of each other (i.e. only one configuration can be selected at a time).
Moreover, the configuration names are not verified at declaration time.
{: .important}

## Subclassing Compositions

Compositions can subclass each other, in which case they of course inherit
their children, exported ports and connections. This is done by subclassing
the composition model class instead of `Syskit::Composition`, e.g.

~~~ ruby
class Root < Syskit::Composition
end
class Submodel < Root
end
~~~

At this stage of the chapter, this would be only useful to create a "core"
network that is refined in subclasses. We will see momentarily that it has also
its usefulness in the [reusable networks](reusable_networks.html) and later in
building [coordination code](../coordination/index.html)

We will also talk more about compositions when we get into the
[reusable networks](reusable_networks.html) section. The rest of this section will
deal with common implementation patterns related to compositions. You may want
to skim through it quickly at first read, and come back to it later. The next
subject is [Profiles](profiles.html)
{: .next-page}

## Common Patterns

### Forwarding Arguments from Composition to Children {#argument_from_parent_task}

This is the pattern we have seen and used in the
[basics section](../basics/constant_generator.html#composition_forward_argument).  The
goal is to allow for arguments on the composition to be passed to its children.
The general mechanism is to pass `from(:parent_task).name_of_argument` in place
of the actual argument. This can only be used for a **whole** argument. It cannot be
used as e.g. a value in a hash or array.

For instance (from the Basics chapter):

~~~ ruby
module SyskitBasics
  module Compositions
    class ArmCartesianConstantControlWdls < Syskit::Composition
      argument :setpoint

      add(ArmCartesianConstantCommandGenerator, as: 'command').
        with_arguments(setpoint: from(:parent_task).setpoint)
      ...
    end
  end
end
~~~

A component's configuration, specified with the `with_conf` specifier, is really only
syntactic sugar on top of the `with_arguments` call. One can therefore pass configuration
from parent to child: `add(...).with_arguments(conf: from(:parent_task).conf)`.
{: .note}

### Handling Single-short Ports {#single-shot-ports}

Rock's defaults are tuned for components that continuously generate and
process data. Some components, for instance task or motion planning
components, are sometimes implemented as one short. That is, the component
will rarely generate a sample.

The problem with the integration of such components is that one would need
to ensure that port-to-port connections are established, and that receiving
components are ready to read the data [^1], before letting the source generate
the data. It would be a lot of synchronization burden.

Instead, one tells the framework to remember the last written sample, and
push this sample through new connections once they are established. To use
this method, one must declare that the last written value on a port should
be kept. Change the output port definition to read

~~~ ruby
output_port('trajectory', '/base/Trajectory')
    .keep_last_written_value(true)
~~~

Then, in the composition's `connect_to` statements, add `init: true`. An
`init: true` connection without the `keep_last_written_value` will have no
effect, and will currently do so silently.

~~~ ruby
planner_child.trajectory_port
    .connect_to controller_child.trajectory_port, init: true
~~~

This is all the basics about compositions. We will come back to it once we talk
about [reusing networks](reusable_networks.html). But first, the next subject is
[Profiles](profiles.html)
{: .next-page}

[^1]: This is because components clear their connections on start
      [More...](../components/writing_the_hooks.html#port-clear-on-start)