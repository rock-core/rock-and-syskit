---
layout: documentation
title: Runtime
sort_info: 55
---

# Running Components
{:.no_toc}

- TOC
{:toc}

When new components are created, they can be used as-is within a Syskit app.
The only thing one has to do is declare them as [a new
deployment](../basics/deployment.html#use_deployment) in the `Robot.requires`
block of your app's configuration.

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

When multiple deployment exists for a given task model, the "right" deployment
needs to be explicitly selected, either in the composition or in the profile. Otherwise,
one gets the following error:

~~~
cannot deploy the following tasks,
  <description of the tasks>
  <task>: multiple possible deployments, choose one with #prefer_deployed_tasks(deployed_task_name):
     task left:task from deployment <deployment>,
     task right:task from deployment <deployment>
~~~

Where and how to use the `prefer_deployed_tasks` statement is a topic that is
covered in the [Reusable
Networks](../component_networks/reusable_networks.html#deployments) section of the
[Designing Component Networks](../component_networks) chapter.

## Component Model

Component models are made loaded using the `using_task_library` statement, that is, at toplevel:

~~~ ruby
using_task_library 'imu_advanced_navigation_anpp'
~~~

The components are then available using the `OroGen.` syntax, e.g. `OroGen.imu_advanced_navigation_anpp.Task`.

## Configuration Files {#config_files}

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
specified. The YAML content is a map with one entry per property, and a
representation of the property value mapped to YAML:

- structures are represented by maps, with one entry per field, e.g. a
  `timeout` property of type `/base/Time` is

  ~~~ yaml
  timeout:
    microseconds: 1000
  ~~~

  All fields of a struct do not need to be set. If some fields are left unset,
  the default value for this field will be used (default value being the value
  written at initialization by the component)
- arrays and containers are represented by arrays
- `/std/string` is represented by strings
- enums are represented by strings

Moreover, to facilitate writing configuration files, Syskit knows how to
interpret some unit specifiers. These specifiers work by converting the
value of the specified unit into the equivalent standard SI unit. When scale
specifiers apply, the following only shows the most useful ones.

- `.deg` converts a value in degrees into radians (e.g. `20.deg`)
- `.g` converts a gram into kilograms. Standard scale modifiers apply (kilogram
  `.kg`, milligram `.mg`)
- `.N` specifies the Newton (which is its own unit). Standard scale modifiers
  apply (kiloNewton `.kN`, milliNewton `.mN`)
- `.P` specifies the Pascal (which is its own unit). Standard scale modifiers
  apply (hectoPascal `.hP`, kiloPascal `.kP`, milliPascal `.mP`)
- `.bar` converts a bar into pascals. Standard scale modifiers apply (`.mbar`)

**Note** that the toolchain does not validate yet that the field is compatible with
the value's unit (i.e. you can assign a `.deg` to a pressure), but probably will in
the future.
{: .important}

Whenever an oroGen component, that is either in a
[composition](../basics/composition.html) or [in a Syskit
profile](../basics/devices.html), a non-default configuration can be selected
with the `with_conf` call, e.g.

~~~ ruby
OroGen.imu_advanced_navigation_anpp.Task
      .with_conf('default', 'high_dynamics')
~~~

The configurations are overlaid one on top of each other, from left to right.
In the example above, the values in the `high_dynamics` section will override
those in the `default` section.

## Quickly Running New Components

One usually wants to quickly run a new component "just to check". Having to
integrate it all the way in the app, through the profile, action and robot
configuration is a hassle at this stage. You may run a single-file "app"
instead of a whole robot configuration for this purpose. For instance, to run
Rock's `imu_advanced_navigation_anpp::Task` driver one would create a `test.rb`
file with:

~~~ ruby
using_task_library 'imu_advanced_navigation_anpp'
Syskit.conf.use_deployment OroGen.imu_advanced_navigation_anpp.Task => 'imu'
Robot.controller do
  plan.add_mission_task(OroGen.imu_advanced_navigation_anpp.Task)
end
~~~

which you can then run with

~~~
syskit run test.rb
~~~

You can put anything in the `add_mission_task` that you would put in a
profile's `define` statement. I.e. you may define a composition in the file and
run it, reuse definition from your app's profiles, … If you provide a robot
configuration with `-r`, the app's `requires` block is executed first, so all
models loaded by the configuration can also be used as-is in the file.

If you have an IDE opened, it will connect to this app and give you its status.

## Component Extension File {#extension_file}

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

## Runtime Environment

Syskit starts all the components under a common log directory, within the app's
`logs` directory. The log directory of the last started Syskit instance is
available as `logs/current`. If your component saves files in relative paths,
they will be saved there (which is a good thing). The output of each component
process is redirected into a file in this folder, with the name
`${deployment_name}-${PID}.txt`. Assuming that the process ID of following deployment
is `2345`, the log file name would be `imu-2345.txt`.

~~~
Syskit.conf.use_deployment OroGen.imu_advanced_navigation_anpp.Task => 'imu'
~~~

For debugging purposes, Syskit natively supports starting deployments under a
`gdbserver` instance.  IDEs commonly support connecting to these `gdbserver`
and debug it.

To enable this, just add the `gdb: true` option to the `use_deployment` statement:

~~~
Syskit.conf.use_deployment OroGen.imu_advanced_navigation_anpp.Task => 'imu', gdb: true
~~~

The first job that use this deployment will stay in `READY` state in the IDE
until you connect a debugger to the process. The port at which one must connect
is contained in the component's log file. Look for a message of the form
`Listening to port XXXXX`

This is all on the subject of adding new functionality in a Rock system. Go
back to the [documentation's overview](../index.html#how_to_read) if you're
looking for more.
{: .next-page}

