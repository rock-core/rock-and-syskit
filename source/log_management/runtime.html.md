---
layout: documentation
title: Log Generation at Runtime
sort_info: 10
---

# Log Generation at Runtime
{:.no_toc}

- TOC
{:toc}

Whenever a new Syskit instance is started, for instance by executing `syskit
run`, Syskit creates a new log directory. This log directory is named after the
date and time - for instance `20211011-1123` for 11:23 on the 11/10/2021 - and
optionally an index if more than one Syskit instance was started within the same
minute (e.g. `20211011-1123.1`). These folders are by default created within the
bundle itself, under `logs/`. The logs of the currently running Syskit instance
(or the last instance that was started) is pointed to by a `current` symlink
under the same folder.

Instead of the `logs` folder, one can choose a different base folder by setting
the `ROBY_BASE_LOG_DIR` environment variable. If it is set, the logs will be
created under `$ROBY_BASE_LOG_DIR/$APPNAME/$TIME_TAG` where `$APPNAME` is the
basename of the Syskit app folder (e.g. $APPNAME is `tutorials` in
`bundles/tutorials`)

All Syskit-deployed systems should strive to put all runtime-generated data within
the log folder. The remainder of this section will describe what type of data is
stored there by default, and how that can be controlled. The analysis of these log
files will be handled in followup sections.

## Component Output Ports

In a Rock system, all output ports may be logged by the system. By default, they
**are** all logged. Logging is the default.

Each deployment - i.e. each process that contains component - has a single log component
(the `logger::Logger` from the `tools/logger` package) that is configured by Syskit to
log the output ports of the components that run within that process.

When using a [default deployment](../components/deployment.html#default), the generated
log file has the same name than the component that is being deployed, suffixed with `.N.log`
where `N` is a sequential number starting at zero. This number is incremented each time
the process is restarted. For instance, the logs of

~~~ ruby
Syskit.use_task_context OroGen.motors_weg_cvw300.Task => "left_motor"
~~~

will be named `left_motor.0.log`, `left_motor.1.log` and so on.

When using [explicit deployments](../components/deployment.html#explicit), the generated
log file has the same name than the deployment, including [the specified prefix if there
is one](../components/runtime.html). For instance, the logs of a `motor_control`
deployment declared with

~~~ ruby
Syskit.use_deployment OroGen::Deployments.motor_control => "left_"
~~~

will be stored in `left_motor_control.0.log`, `left_motor_control.1.log`

## Controlling Which Outputs Ports are Logged

As we just saw, a Rock+Syskit system will log all output ports. This may become
a bit much in a production system - especially with sensors like cameras or
LIDARs.

Syskit of course has a way to enable and disable ports from being logged. The way
to do it is by defining _log groups_, that declare sets of output ports based on
port, component or type names. These log groups can then be enabled or disabled.
Ports are not logged if all groups that match them are disabled.

Group declarations are usually done within a robot configuration (in `config/robots/`):

~~~ ruby
Syskit.conf.logs.create_group "Images" do |g|
    g.add(/REGEXP/)
end
~~~

The regexp is matched against the port name, the task name and the type name.
For instance, to control logging of Rock's default image type:

~~~ ruby
Syskit.conf.logs.create_group "Images" do |g|
    g.add(/base.samples.frame.Frame/)
end
~~~

Groups are enabled on creation. To disable a group on creation instead, do

~~~ ruby
Syskit.conf.logs.create_group "Images", enabled: false do |g|
    g.add(/base.samples.frame.Frame/)
end
~~~

The easiest way to control a group is through the Syskit IDE. In the runtime
pane, open the Logs tab and enable/disable groups:

TODO: screencast

## Component Standard Output and Error

The component's standard output and error streams are streamed to text files. The
text files are named with $NAME.$PID.txt, where $NAME follows the same rules than
the data logs (above), and $PID is the process ID of the underlying process.

## Component Properties

Syskit creates a single `properties.0.log` file containing all property values
from the components. When a process is started, Syskit reads the initial
property values and save them. Afterwards, it will save any update it applies to
the properties.

## Syskit Events

In addition to the component data, text output and properties, Syskit has an
extensive system for its own internal events. The corresponding log is named
`$ROBOTNAME-events.log` (e.g. `gazebo-events.log` for a Syskit instance executed
with `syskit run -r gazebo`). This log can be analyzed to determine the task
structure (composition / tasks) as well as event information.

## Limitations

- Syskit currently does not log any data from the ruby tasks