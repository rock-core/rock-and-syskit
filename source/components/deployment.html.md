---
layout: documentation
title: Deployments
sort_info: 50
---

# Deployments
{:.no_toc}

- TOC
{:toc}

So far, we have declared and written a C++ component _class_. That is, we
implemented the component's computation. We have however not yet breached the
subject of describing when the component's methods
([Hooks](writing_the_hooks.html)) are called. This is what the **deployment**
is all about.

In Rock, each deployment is a separate binary (UNIX process) in which a certain
number of tasks have been _instanciated_. The role of the deployment is to:
 - group threads in processes
 - group tasks into threads (and specify the thread parameters)
 - assign each task to a triggering mechanism, that defines in which conditions
   the task's `updateHook` will be called.

The combination of thread information and triggering mechanism is called an
**activity**.

All the deployment definitions that are covered in this section are defined
within an oroGen project. They can either be done in the same project that
defines the tasks, or use tasks from other projects by loading them beforehand
with `using_task_library 'project_name'`.
{: .important}

## Default Deployments {#default}

orogen creates a default deployment for each declared
[non-abstract](interface.html#inheritance) task. This default deployment puts each
component in a single thread, in its own process. It uses a default triggering
mechanism that is defined on the task context. This default activity should be
considered a "sane default", but components should in general not rely on this
activity being the only way it could be deployed.

In some cases, it is beneficial to deploy components differently than the
default. This is done by defining explicit deployments.

## Explicit Deployments

Deployment blocks declare one binary, that is a set of components along with
their activities that are grouped into a single process.

~~~ ruby
deployment "test" do
  <deployment statements>
  add_default_logger
end
~~~

This statement generates a "test" binary which will be installed by CMake. If
that is not desired, for instance if it is for testing purposes only, add the
<tt>do_not_install</tt> statement in the block:

~~~ ruby
deployment "test" do
  do_not_install
  <other deployment statements>
end
~~~

The most basic thing that can be done in a deployment is listing the tasks that
should be instantiated. It is done by using the 'task' statement:

~~~ ruby
task 'TaskName', 'orogen_project::TaskClass'
~~~

It will create a task with the given name and class. By default, that task will
have its own thread. Use `using_task_library` to import tasks from another project.

## Triggers

Trigger statements can be placed either in the component's `task_context`
block, or as a refinement of an explicit deployment's `task` statement.

The first case looks like

~~~ ruby
task_context "Task" do
  periodic 0.1
end
~~~

The second case looks like

~~~ ruby
deployment 'test' do
  task('task', 'Task').
    periodic(0.1)
end
~~~

When a task is added in the explicit deployment, the component's default
activity will be used (as defined in its `task_context` block).  However, the
`periodic` and `fd_driven` activity statements that are available within the
`task_context` statement can also be used in a deployment's definition to
change. `port_driven` cannot. This overrides the default.

**Note** the dot at the end of the `task` statement. This is a fluid
interface, don't forget that each modifier for the task definition is actually
a chain of method calls, and require the dots.
{: .important}

### Periodic Triggering (`periodic`)

This is the most simple triggering method. When a task is declared periodic, its
`updateHook` will be called with a fixed time period. The task is within its own
thread.

To use this triggering mechanism, simply add the `periodic(period)` statement
to the task context:

~~~ ruby
task_context 'Task' do
  ...
  periodic 0.01
end
~~~

The period is given in seconds. The periodic activity cannot be combined with
other triggering mechanisms.

### Port-Driven Triggering (`port_driven`)

A port-driven task is a task that wants to perform computations whenever new
data is available on its input ports. In general, data-processing tasks (as for
instance image processing tasks) fall into that category: their goal is to take
data from their input, process it, and push it to their outputs.

A port-driven task is declared by using the `port_driven` statement.

~~~ ruby
task_context "Task" do
    input_port  'image', '/Camera/Frame'
    input_port  'parameters', '/SIFT/Parameters'
    output_port 'features' '/SIFT/FeatureSet'

    port_driven 'image'
end
~~~

During runtime, the `updateHook` method will be called when new data arrives on
the listed ports (in this case `image`).  Other input ports are ignored by the
triggering mechanism. Obviously, the listed ports must be input ports. In
addition, they must be declared _before_ the call to `port_driven`.

Finally, if called without arguments, `port_driven` will activate the port
triggering on all input ports declared before it is called. This means that, in

~~~ ruby
task_context "Task" do
    input_port  'image', '/Camera/Frame'
    input_port  'parameters', '/SIFT/Parameters'
    output_port 'features' '/SIFT/FeatureSet'

    port_driven
end
~~~

both `parameters` and `image` are triggering. Now, in the following declaration, only `image` will be:

~~~ ruby
task_context "Task" do
    input_port  'image', '/Camera/Frame'
    port_driven
    input_port  'parameters', '/SIFT/Parameters'
    output_port 'features' '/SIFT/FeatureSet'
end
~~~

### FD-Driven Triggering (`fd_driven`)

In the IO triggering scheme, `updateHook` is called whenever new data is made
available on a file descriptor. It allows to very easily implement drivers,
that are waiting for new data on the driver communication line(s). The task
has its own thread.

**Note** if you're writing a task that has to interact with I/O, consider using
Rock's [iodrivers_base](https://github.com/rock-core/drivers-iodrivers_base)
library and the corresponding [orogen
integration](https://github.com/rock-core/drivers-orogen-iodrivers_base)

To use the IO-driven mechanism, use the `fd_driven` statement. fd-driven and
port-driven triggering can be combined.


~~~ ruby
task_context 'Task' do
  ...
  fd_driven
end
~~~

To access more detailed information on the trigger reason, and to set up the
trigger mechanism, one must access the underlying activity. Two parts are
needed, one in `configureHook` to tell the activity which file descriptors to watch
for, and one in `cleanupHook` to remove all the watches (**that last part is
mandatory**)

First of all, include the header in the task's cpp file:

~~~ cpp
#include <rtt/extras/FileDescriptorActivity.hpp>
~~~

Second, set up the watches in `configureHook`

~~~ cpp
bool MyTask::configureHook()
{
    // Here, "fd" is the file descriptor of the underlying device
    // it is usually created in configureHook()
    RTT::extras::FileDescriptorActivity* activity =
        getActivity<RTT::extras::FileDescriptorActivity>();
    // This is mandatory so that the task can be deployed
    // with e.g. a port-driven or periodic activity
    if (activity)
        activity->watch(fd);
    return true;
}
~~~

It is possible to list multiple file descriptors by having multiple calls to
`watch()`.

One can set a timeout in milliseconds, in which case `updateHook` with be
called after that many milliseconds after the last successful trigger.

~~~ cpp
activity->setTimeout(100);
~~~

Finally, you **must** clear all watches in stopHook():

~~~ cpp
void MyTask::cleanupHook()
{
    RTT::extras::FileDescriptorActivity* activity =
        getActivity<RTT::extras::FileDescriptorActivity>();
    if (activity)
        activity->clearAllWatches();
}
~~~

The FileDescriptorActivity class offers a few ways to get more information
related to the trigger reason (data availability, timeout, error on a file
descriptor). These different conditions can be tested with:

~~~ cpp
RTT::extras::FileDescriptorActivity* fd_activity =
    getActivity<RTT::extras::FileDescriptorActivity>();
if (fd_activity)
{
  if (fd_activity->hasError())
  {
  }
  else if (fd_activity->hasTimeout())
  {
  }
  else
  {
    // If there is more than one FD, discriminate. Otherwise,
    // we don't need to use isUpdated
    if (fd_activity->isUpdated(device_fd))
    {
    }
    else if (fd_activity->isUpdated(another_fd))
    {
    }
  }
}
~~~

### Threading

When in an explicit deployment, one has the option to fine-tune the assignment
of tasks to threads.

The first option is to associate a task with a thread. When there is a trigger,
the thread is woken up and the task will be asynchronously executed when the OS
scheduler decides to do so. It is the safest option (and the default) as the
different tasks are made independent from each other.

The second option is to *not* associate the task with its own thread. Instead,
the thread that triggers it will be used to run the task. This is really only
useful for port-driven tasks: the task that wrote on the triggering port
will also execute the triggered task's `updateHook`. The main advantage is that
the OS scheduler is removed from the equation, which can reduce latency.  The
periodic and IO triggering mechanisms _require_ the task to be in its own
thread.

When using a separate thread, the underlying thread can be parametrized with a
scheduling class (realtime/non-realtime) and a priority. By default, a task is
non-realtime and with the lowest priority possible. Changing it is done with
the following statements:

~~~ ruby
  task('TaskName', 'orogen_project::TaskClass').
    realtime.
    priority(<priority value>)
~~~

Where the priority value is a number between 1 (lowest) and 99 (highest).

**Note** the dot at the end of the `task` statement. This is a fluid
interface, don't forget that each modifier for the task definition is actually
a chain of method calls, and require the dots.
{: .important}

The second case is called a sequential activity and is declared with:

~~~ ruby
  task('TaskName', 'orogen_project::TaskClass').
    sequential
~~~

**Next** this is mostly all. [The next page](runtime.html) describes
how components are integrated in Syskit.
{: .next-page}
