---
layout: documentation
title: Recap
sort_info: 60
---

# Recap

Let's recap what we've seen in this Basics section.

### Workspace

Autoproj is Rock's tool to manage (install and update) packages. "Packages" are the unit
of integration of the Rock software. The role of a workspace build
configuration is to ensure repeatability in the installation of a system's
software

- [the initial bootstrap](installation.html) installs a predefined set of
  packages as defined by a given build configuration
- packages are also [added during development](composition.html#add_package),
  when the functionality is required

### Bundles

[Bundles](getting_started.html) are the package within which we create Syskit models and code. It is the _place of integration_.

From Syskit's point of view, a bundle has a toplevel namespace under which the rest of the app is defined. It is by default the CamelCased version of the bundle's folder name (`syskit_basics` becomes `SyskitBasics`).

A given bundle may contain multiple Syskit app configurations. The entry point
for each configuration is a file in `config/orogen/`. One usually creates one
bundle per class of system, and creates at least one configuration for
simulation and one for the live system. Syskit tools take a `-rROBOT_NAME`
argument to specify which configuration should be loaded.

It is possible to reuse models from another bundle by updating `Roby.app.search_path`
either globally in `config/init.rb` or per-robot in the `Robot.init` block of the robot
configuration file.

Within bundles:

- separate SDF models are saved within `models/sdf/`
- SDF scenes are saved within `scenes/#{scene_name}/#{scene_name}.world`
- [compositions](#compositions) are in `models/compositions/`
- [ruby tasks](#ruby_tasks) are in `models/compositions/`
- [orogen extension files](#orogen) are in `models/orogen/`
- [profiles](#profiles) are in `models/profiles/`
- [orogen configuration files](#orogen_config) are in `config/orogen/`.
  Configuration-specific files (e.g. in `config/orogen/gazebo/`) take precedence.
- within the Syskit model folders (`compositions/` and `profiles/`), the convention
  is to have subfolders for models that are specific to a given robot configuration
  (e.g. `profiles/gazebo/` for models that are specific to the `gazebo` configuration).
  The generators enforce this when given the `-rROBOT_NAME` option.
- the folder structure in `models/` maps one-to-one to the folder structure in `test/`

### Components and Compositions {#compositions}

Components are the basic construction block in a Syskit system.
[Compositions](composition.html) are used to turn single components into
more complex functional units, by binding the components together.

- a composition template is created using

  ~~~
  syskit gen NameOfComposition
  ~~~
- an element within a composition is declared with `add`, a component model
  (which can be another composition) and a name:

  ~~~ruby
  class MyComposition < Syskit::Composition
    add AnotherComponentModel, as: 'generator'
  end
  ~~~
- within the composition model, a composition child is accessed using the
  child's name and the `_child` suffix. Ports are accessed with the port name and
  the `_port` suffix. This is how connections are made:

  ~~~ruby
  source_child.out_port.connect_to sink_child.in_port
  ~~~
- a composition can have ports, which are exports of its children ports. This works
  for both input and output ports. The exported port name is the same as the child's
  port name, but this can be overriden

  ~~~ruby
  export source_child.out_port
  export another_source_child.out_port, as: 'another'
  ~~~

### oroGen components {#orogen}

oroGen is Rock's way to package C++ functionality into ready-to-use components with
a standardized interface. These components are imported in Syskit's with

~~~ruby
using_task_library "name_of_orogen_project"
~~~

The other role of oroGen is to define types whose instances can be transferred
between components. If one only wants to use a type defined by an oroGen
project, but without using the associated components, one does

~~~ruby
import_types_from "name_of_orogen_project"
~~~

The corresponding types are accessible under the `Types` object, e.g.

~~~ruby
Types.base.samples.RigidBodyState
~~~

On import, Syskit builds a component model that represents the oroGen
component. This model is accessible [within the `OroGen`
namespace](composition.html#orogen). It can also be extended to reflect needs
in the Syskit app, for instance configuration, using [extension
files](deployment.html#orogen_extension_files).

oroGen components provide a configuration interface as a set of properties.
These properties are filled using YAML configuration files stored in
`config/orogen/`, and may also be written in the `configure` method of the
component's class, in the extension file.
{: #orogen_config}

A configuration file for a component class is generated with

~~~
syskit gen orogenconf name_of_orogen_project::NameOfModelClass
~~~

### Ruby Tasks {#ruby_tasks}

In a system, one often needs to do some small tasks that are either too small
to warrant a full-fledged C++ component, or are so tied with the system integration
that having a C++/Ruby boundary makes understanding hard. For these, Syskit
allows to implement tasks in Ruby that are integrated within the Syskit
execution but provide input and output ports to integrate with the rest of the
components.

Because of the single-threaded nature of Syskit's execution engine, one must
**not** use ruby tasks to perform a lot of work. This would freeze Syskit.
Stick to simple tasks, and implement oroGen components for more complex ones.
{: .callout .callout-warning}

A canonical example for such a task is [the `common_models` bundle's `ConstantGenerator`](constant_generator.html).

Whenever runtime code is present in tasks, as it often is in ruby tasks,
**write tests**.
{: .callout .callout-warning}

A new Ruby task and associated test scaffold is generated with

~~~
syskit gen ruby_task class_name
~~~

### Profiles

Profiles are the models that contain functional networks. It is common to have
compositions made of _abstract_ models, that is components that are not really
components - such as [device models](devices.html). These abstract components
can be replaced by actual components within the profiles with the `use` call.
Moreover, profiles allow to specify arguments to compositions in the process
of definition.

The model name given to `define` in a profile is made out of a [demeter
chain](https://martinfowler.com/bliki/FluentInterface.html). In Ruby, one can
easily break the chain with a newline after each method call. Don't forget the
dots !
{: .callout .callout-warning}

- arguments are set with `with_arguments`

  ~~~ruby
  CompositionModel.with_arguments(arg_name: arg_value)
  ~~~

- `CompositionModel.use('child_name' => model)` replaces `CompositionModel`'s
  `child_name` child with the given model. `model` can itself be refined by `use`
  and `with_arguments`.
- `CompositionModel.use(model)` replaces any `CompositionModel`
  child whose model is compatible with `model` by `model`. 
- a definition or device can itself be used as `model` or `CompositionModel` in
  all these calls, possibly from another profile:

  ~~~ruby
  define 'first', CompositionModel.use(first_test_dev)
  define 'second', first_dev.use(AnotherProfile.second_test_dev)
  define 'third', AnotherProfile.first_dev.use(second_test_dev)
  ~~~

### Configuration

Apart from the [orogen configuration files](#orogen_config), components can have arguments.
The choice between a configuration file or a component argument is a matter of system design,
but there are some guidelines.

**Use task arguments when**

- consistency between different components is necessary, as for instance the robot model
- a value is to be provided at runtime, as for instance a target pose

**Use configuration files when**

- the values are static (set once and seldom changed)

Arguments can be forwarded from a composition to its children using the following pattern:

~~~ruby
class C < Syskit::Composition
  argument :robot
  add(ChildModel, as: 'generator').
    with_arguments(robot: from(:parent_task).robot)
end
~~~

### Deployments, Actions

Before they are used, components need to be deployed, that is associated with a
process and a name. This is done in the `requires` block of the robot
configuration file with

~~~ruby
Syskit.conf.use_deployment ComponentModel => 'component_name'
~~~

Actions are the basic block of interaction between a Syskit app and the outside
world.  Moreover, the Main action interface, defined by the `actions` block in
the robot configuration file is the interface that is being exposed through the
standard channels (IDE, shell).

Definitions from a profile [are exported on the Main interface](deployment.html#main).

### Runtime

We've only had a glimpse on the Syskit runtime workflow. [Let's dig deeper](../runtime_overview/index.html){: .btn-next-page}
