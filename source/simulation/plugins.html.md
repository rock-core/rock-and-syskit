---
layout: documentation
title: Plugins
sort_info: 20
---

# Plugins
{:.no_toc}

- TOC
{:toc}

## Using Model Plugins

The Syskit integration for Gazebo offers extension points to allow integrating plugins
within the Syskit system. Plugins that are meant to be gazebo-only - i.e. that don't
have the need to interface with Rock are transparent. This guide is for model plugins
that are getting exposed through a Rock interface.

As good Rock citizens, these plugins should come in two packages:

- a `simulation/$NAME` package that contains the gazebo plugin itself
- a `simulation/orogen/$NAME` package that contains the orogen components that will
  interface with the plugin

The plugin's documentation, apart from information on how to set itself up,
should say what task and device model to use for the interface. Then, if you
with to use the plugins' Rock interface, you must add a `<task ...>` element
to the `plugin` element like this:

~~~ xml
<plugin name="direct_force" filename="libgazebo_usv.so">
  <task model="gazebo_usv::DirectForceApplicationTask" />
  <!-- other elements that configure the plugin and/or the task -->
</plugin>
~~~

In your Syskit app, you also have to map the task model to the device model that
should be used to expose it on profiles. Do so in the orogen package's
[extension file](../components/runtime.html#extension_file) Note that this
device model does not necessarily have to be provided by the plugin developer.
It is usually designed and added for your application specifically.

The `gazebo_usv` example above would be declared in `models/orogen/gazebo_usv.rb` with:

~~~ ruby
RockGazebo::Syskit::RobotDefinitionExtension.register_device_by_plugin_task_model(
    OroGen.gazebo_usv.DirectForceApplicationTask,
    Seabots::Devices::Gazebo::DirectForceApplication
)
~~~

## Implementing an oroGen Plugin Interface

To ensure that the gazebo plugin and the orogen component can use a common
configuration, the orogen component must implement the
[`ModelTaskI`](https://github.com/rock-gazebo/simulation-orogen-rock_gazebo/blob/master/tasks/ModelPluginTaskI.hpp).
interface. In most cases, just subclass the `rock_gazebo::ModelPluginTask` task context.

Doing so will ensure that the interface's `setGazeboModel` method gets called at
component creation. This method must be overloaded. In particular, it sets the
task name, which to allow syskit to pick up the plugin must be

~~~ cxx
string worldName = model->GetWorld()->Name();
string taskName = "gazebo::" + worldName + "::" + model->GetName() + "::" + pluginName;
provides()->setName(taskName);
~~~

At runtime, the preferred mechanism to allow communication between the gazebo
plugin itself and its associated orogen component is to use Gazebo's own
publish/subscribe system.  One essentially has to choose a topic name that is
unique, and that only depend on the plugin configuration in the SDF. This way,
both the plugin and the orogen component can infer the same topic name(s) and
successfully manage to communicate. Note that the orogen component runs within
the Gazebo event loop itself.

The [gazebo_usv](https://github.com/tidewise/simulation-gazebo_usv) and
[associated components](https://github.com/tidewise/simulation-orogen-gazebo_usv) are a
good example of these mechanisms
