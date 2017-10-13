---
layout: documentation
title: Syskit Integration
sort_info: 55
---

# Syskit Integration
{:.no_toc}

- TOC
{:toc}

When new components are created, they can be used as-is within a Syskit app.
The only thing one has to do is declare them as [a new
deployment](../basics/deployment.html#use_deployment) in the Syskit
configuration.

To use a task's default deployment, one adds

~~~ ruby
Syskit.conf.use_deployment OroGen.model.Task => 'task_name'
~~~

Which deploys a task called `task_name` using the component's [default
deployment](deployment.html#default). Explicit deployments can be used as-is

~~~ ruby
Syskit.conf.use_deployment 'test'
~~~

However, this way, only one of the `test` deployment can be started at a given
time. To start multiple ones, one must prefix the task's names:

~~~ ruby
Syskit.conf.use_deployment 'test' => 'left:'
Syskit.conf.use_deployment 'test' => 'right:'
~~~

This prefixes the task names with resp. `left:` and `right:`. For instance, if
`test` had a task called `task`, the deployed tasks would be called `left:task`
and `right:task`.

## Component Model

Component models are made loaded using the `using_task_library` statement, that is, at toplevel:

~~~ ruby
using_task_library 'imu_advanced_navigation_anpp'
~~~

The components are then available using the `OroGen.` syntax, e.g. `OroGen.imu_advanced_navigation_anpp.Task`.

## Configuration Files

Configuration files are YAML files that contain values for a component's
properties. A component's available configurations is to be saved in
`config/orogen/` with a file name of `project::Task.yml`. For instance,
`config/orogen/imu_advanced_navigation_anpp::Task.yml`.

A configuration file, which contains property documentation and default values,
can be generated with

~~~
syskit gen orogenconf imu_advanced_navigation_anpp::Task
~~~

The YAML file is split into named sections. The section separator is `---
name:SECTION_NAME`. If no section name is given, then `default` is assumed. The
default configuration is what is being applied if no other configurations is
specified.

Whenever an oroGen component, that is either in a
[composition](../basics/composition.thml) or [in a Syskit
profile](../basics/devices.html), a non-default configuration can be selected
with the `with_conf` call, e.g.

~~~ ruby
OroGen.imu_advanced_navigation_anpp.Task.
  with_conf('default', 'high_dynamics')
~~~

The configurations are overlaid one on top of each other, from left to right.
In the example above, the values in the `high_dynamics` section will override
those in the `default` section.

## Component Extension File

To handle a Syskit app's configuration needs, one often has to create a
component extension file. This file is part of the app, and allows to extend
the component model, built from the oroGen file, with Syskit-specific things, such
as task arguments and auto-configuration based on the SDF world or 

The component extension files are in the `models/orogen/` folder, named as the
oroGen project, for instance `models/orogen/imu_advanced_navigation_anpp.rb`. They are generated
using `syskit gen orogen`:

~~~
syskit gen orogen myproject
~~~

In this file, each task model may be extended by a block of the form

~~~ ruby
Syskit.extend_model OroGen.imu_advanced_navigation_anpp.Task do
end
~~~

The most common extension point is the `configure` method, in which the task model
can extract information out of the Syskit app to validate and/or auto-configure
the component. Properties within Syskit are accessed with the `properties` accessor, e.g.

~~~ ruby
Syskit.extend_model OroGen.imu_advanced_navigation_anpp.Task do
  def configure
    super # fill configuration from the configuration files
    properties.timeout = 100
  end
end
~~~

[The next page](plugins.html) describes how it is possible to extend the oroGen
specification. You may want to simply remember that it exists on first read and
come back to it later. And instead go to the [documentation's
overview](../index.html#how_to_read).
{: .next-page}

