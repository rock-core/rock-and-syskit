---
layout: documentation
title: Profiles
sort_info: 20
---

# Profiles
{:.no_toc}

- TOC
{:toc}

[Compositions](compositions.html) allow to define self-contained networks.
These networks have to be exposed as _actions_ into the system, which is what
is accessible to the [coordination layer](../coordination) and externally to
the user. Moreover, these networks aim ultimately at being as system- and
application-independent as possible, allowing their reuse in different contexts
and/or with different configurations.

The place where they are exported as actions, and fine-tuned to an
application/system need is the **Profile**. We will go through the basics
about profiles in this section, to significantly expand in the next, where we
talk about [reusable models](reusable_models.html).

## Definition

Profiles are defined inside a module with the `profile` statement, which
creates and registers a profile object in the enclosing module. For instance,
the following code snippet creates a profile whose full name is
`AppName::Profiles::ProfileName`:

~~~ ruby
module AppName
  module Profiles
    profile "ProfileName" do
    end
  end
end
~~~

__Naming Convention__ Profiles are by convention defined under the `AppName::Profiles`
namespace (e.g. `CommonModels::Profiles` for the `common_models` bundle). 
They are saved in `models/profiles/`. The file
names should be the snake_case version of the profile name (e.g.
`models/profiles/profile_name.rb` for the profile defined above). 

__Generation__ Template for a profile, following Syskit's naming and filesystem
conventions, can be created with

~~~
syskit gen profile name/of_profile
~~~

for instance

~~~
syskit gen profile rovers/localization
~~~

## Registering Networks on Profiles

A component network when registered on a profile is called a __definition__ and is created with the `define` statement. From the [basics](../basics/devices.html):

~~~ ruby
module SyskitBasics
  module Profiles
    profile 'ArmControl' do
      define 'arm_cartesian_constant_control',
        Compositions::ArmCartesianConstantControlWdls
      define 'arm_joint_position_constant_control',
        Compositions::JointPositionConstantControl
    end
  end
end
~~~

**Note** models used within the composition need to be loaded at the toplevel
of the composition file, before the composition definition. orogen models with
the `using_task_library` statement, other models by `require`'ing the file that
defines it.
{: .important}

Once created, the definition is available as a method on the profile object,
using the pattern `${definition_name}_def`. This allows to create new
definitions based on other ones. Modifiers can directly be called on the model
object passed as argument to `define`.

An example that combines both can be found in the
[basics](../basics/devices.html) section:

~~~ ruby
define 'arm_joint_position_constant_control',
  Compositions::JointPositionConstantControl
define 'arm_safe_position', arm_joint_position_constant_control_def.
  with_arguments(setpoint: UR10_SAFE_POSITION)
~~~

We will also talk more about compositions in the [next
section](reusable_models.html). The rest of this section will deal with common
patterns related to profiles. You may want to skim through it quickly at first
read, and come back to it later.
{: .next-page}

## Common Patterns

### Specifying Configuration and Arguments

To set the configuration and/or arguments of a toplevel model before defining
it, pass the `with_conf` (resp. `with_arguments`) call to the model, as:

~~~ ruby
define 'arm_safe_position', arm_joint_position_constant_control_def.
  with_arguments(setpoint: UR10_SAFE_POSITION)
~~~

In addition, it is possible to change the configuration/arguments of a child of
a composition. This uses dependency injection mechanisms that will be detailed
[in the next section](reusable_models.html), but the pattern is easy enough to use:

~~~ ruby
define 'cartesian_control_wdls_slow', arm_cartesian_constant_control_def.
  use('control.twist2joint_velocity' =>
    OroGen.cart_ctrl_wdls.WDLSSolver.with_conf('default', 'slow'))
~~~
{: #dependency_injection}

The string in the `use` statement is the path to the child that is being
refined (in this case, the `twist2joint_velocity` child of the `control` child
in the `arm_cartesian_constant_control` definition).

__`use` vs composition configurations__ This mechanism
looks very much like the [composition configurations](composition.html#configurations).
Composition configurations are meant to be used when some configurations are
really __expected__ to be present on the composition, as for instance if these
configurations are used by a higher-level mechanism. The `use` statement is
better for the other cases, as it does not assume that all useful
configurations will be known at the composition's design time.
{: .note}

__`use` vs composition argument forwarding__ This mechanism
also looks very much like the argument forwarding. 
Use argument forwarding when the argument makes sense on the composition. In
the basics section, it *really makes sense* that a constant control composition
has a `setpoint` argument, and that is therefore how it has been implemented.
`use` is for the other cases.
{: .note}

This is all the basics about profiles. Let's now deepen our understanding of
how we can make [reusable models](reusable_models.html) using these basic tools
and one additional: the data service.
{: .next-page}

