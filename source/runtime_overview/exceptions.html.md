---
layout: documentation
title: Errors
sort_info: 30
---

# Error Representation
{:.no_toc}

- TOC
{:toc}

So far, we've touched execution in Syskit when everything is going fine. This
is hardly the case, both in development and in production systems. Robots have
a complex interaction with their (potentially harsh) environments. Hardware fails.
Software has bugs.

The first question is going to be _what is an error_. It is hardly a simple
question when seen in the context of a complex, adaptable system like a robot
under Rock and Syskit. We will then go into the more practical cases of the
common errors that you will encounter while working with Syskit. We will not
breach the subject of error handling on this page. This will be done later
[in a separate part](../syskit_error_handling)

## What are errors ?

One of the most important concept to understand within Syskit is that errors
are _contextual_. What may be an error in a given context might be nominal
execution in another. There's rarely something like an error in absolute.

Within Syskit, an error is usually _an unexpected event_. For instance, a
[dependency error](#dependency_error) would be caused by a component's _stop_
event, as the component's enclosing composition _needs_ the component (this
need being represented by a [dependency relation](task_structure.html#dependency).
However, the same _stop_ event might be expected by other parts of the system.
In the same way, the _failed_ event [of a planning task](task_structure.html#planning_task)
is the source of a `PlanningFailedError`. The same planning task could be used
in a different context for which this event is not an issue.

There are errors whose source is not an event. For instance, the failure to
establish a connection between two ports will have the composition which needs
this connection as an error context.

Because errors are contextual, every exception is associated with either a task
or an event in Syskit's internal structures - the exception source. In addition,
it may be associated with a particular relation. In the dependency example above,
the dependency error is associated with the dependency relation(s) for which the
failure event is a problem.

## Default Response to an Error {#default_response}

Whenever an error happens, Syskit's default response is to stop all jobs and
components that were enclosing the faulty relation if specific relation(s) are
associated with the error, or the faulty task if not. Tasks that were needed
only by said jobs are stopped by the garbage collection pass.

## The Dependency Error {#dependency_error}

Let's see what happens if we run the arm controller and manually stop the
`CartCtrl` component:

<div class="fluid-video">
<iframe width="853" height="480" src="https://www.youtube.com/embed/CXddqjif5CM?rel=0&amp;showinfo=0" frameborder="0" allowfullscreen></iframe>
</div>

The error looks like this (parts that you can't interpret yet removed)

~~~
OroGen::CartCtrlWdls::CartCtrl:0x1664c10<id:401>(conf: ["default"], orocos_name: arm_pos2twist) failed,
child position2twist of SyskitBasics::Compositions::ArmCartesianControlWdls:0x220fc68<id:408>(robot: profile:SyskitBasics::Profiles::Gazebo::Base),
  the following event has been emitted event 'stop' emitted at [17:58:58.634 @1750] from ,
    OroGen::CartCtrlWdls::CartCtrl:0x1664c10,
      owners: ,
      arguments: ,
        orocos_name: "arm_pos2twist",,
        conf: ["default"],
The failed relation is,
  SyskitBasics::Compositions::ArmCartesianControlWdls:0x220fc68,
    owners: ,
    arguments: ,
      robot: profile:SyskitBasics::Profiles::Gazebo::Base,
  depends_on OroGen::CartCtrlWdls::CartCtrl:0x1664c10,
    owners: ,
    arguments: ,
      orocos_name: "arm_pos2twist",,
      conf: ["default"]
~~~

Just below this one, a `MissionFailedError` is displayed as well. Missions are
another name for jobs. Whenever a unhandled error cause a mission to be
terminated by Syskit (as part of the [Syskit's default error
handling](#default_response) we've just discussed), a corresponding
MissionFailedError is generated as well to make it easier to track what happens
to the missions for e.g. UIs or higher-level goal management.

**Notice that** in Syskit two components that are connected to each other do
not have a dependency relationship. From Syskit's point of view, a component
does not depend on its sources to be functioning or faulty. The network that
binds them together is. This allows to isolate the role of each component in an
overall function, and to build either degraded or orthogonal functions on the
same set of components. What fails is the function, not the component.
Obviously, there are cases where the function and the component are one and the
same, but this is not often the case.
{: .callout .callout-warning}

## Failures in Component Configuration and Start

The failure to configure, or failure to start a component is a bit of a strange
beast. It relies on Syskit's ability to represent the negative of an event
emission: instead of representing that an event -- in this case the _start_
event -- has been emitted, Syskit represent those by representing that the
_start_ will never be emitted. This also causes a failure in the dependency
relation between a composition and its children.

Let's emulate an error by mis-configuring `cart_ctrl_wdl::WDLSSolver`. With the
[work we've done validating the tip and root
links](../basics/deployment.html#validate_tip_and_root_links), we'll
just edit the task's configuration file and trigger a reconfiguration:

<div class="fluid-video">
<iframe width="853" height="480" src="https://www.youtube.com/embed/n5qLjTuVhkA?rel=0&amp;showinfo=0" frameborder="0" allowfullscreen></iframe>
</div>

The error looks this time like this. The important part is that the dependency failure
is caused this time because the _start_ event is unreachable while it was before caused
because an event had been emitted.

~~~
OroGen::CartCtrlWdls::WDLSSolver:0x7f589155df20<id:889>(conf: ["default"], orocos_name: arm_twist2joint, robot: profile:SyskitBasics::Profiles::Gazebo::Base) failed,
child twist2joint_velocity of SyskitBasics::Compositions::ArmCartesianControlWdls:0x7f5890ffb280<id:767>(robot: profile:SyskitBasics::Profiles::Gazebo::Base),
triggered the failure predicate '(never(start?)) || (stop?)': the value of start? will not change anymore,
  the following event is unreachable start event of OroGen::CartCtrlWdls::WDLSSolver:0x7f589155df20,
  The unreachability was caused by:
    failed emission of the start event of OroGen::CartCtrlWdls::WDLSSolver:0x7f589155df20 (Roby::EmissionFailed),

The failed relation is,
  SyskitBasics::Compositions::ArmCartesianControlWdls:0x7f5890ffb280,
    owners: ,
    arguments: ,
      robot: profile:SyskitBasics::Profiles::Gazebo::Base,
  depends_on OroGen::CartCtrlWdls::WDLSSolver:0x7f589155df20,
    owners: ,
    arguments: ,
      orocos_name: "arm_twist2joint",,
      conf: ["default"],,
      robot: profile:SyskitBasics::Profiles::Gazebo::Base,
failed emission of the start event of OroGen::CartCtrlWdls::WDLSSolver:0x7f589155df20 (Roby::EmissionFailed),
link name 'does_not_exist' is not a link of the robot model. Existing links: ur10_…
~~~

**Do not forget to restore the configuration file to something valid**, and to run
a `syskit.reload_config` in the shell to apply the change.
{: .callout .callout-warning}

## The Planning Failed Error

We've already seen a planning failed error when we attempted to start both
`arm_safe_position_def` and `arm_cartesian_constant_control_def` jobs in the
introduction.  Let's have a look again:

<div class="fluid-video">
<iframe width="853" height="480" src="https://www.youtube.com/embed/LkmR9AFo5ek?rel=0&amp;showinfo=0" frameborder="0" allowfullscreen></iframe>
</div>

In this case, the error displayed would be:

~~~
failed to plan SyskitBasics::Compositions::ArmCartesianConstantControlWdls:0x679e428
  owners: 
  arguments: 
    setpoint: {:position=>Vector3(0.5, 0.0, 0.5),
     :orientation=>Quaternion(1.0, (0.0, 0.0, 0.0))},
    robot: profile:SyskitBasics::Profiles::Gazebo::Base
planned by Syskit::InstanceRequirementsTask:0x6757280
  owners: 
  arguments: 
    action_model: Action arm_cartesian_constant_control_def [snip]

  device ur10_fixed is assigned to two tasks that have mismatching inputs,
    [snip]
~~~

In this case, the only thing that can cause a `PlanningFailedError` is that the planning
task emitted the _failed_ event. Given that the failure was caused by a Ruby exception thrown
during the deployment, this exception is displayed as well (the `device ur10_fixed …` message).

## Aborted Tasks

Tasks emit _aborted_ when they were running but their execution agent stops.
Indeed, as we've mentioned in the
[description of the execution agent relation](task_structure.html#execution_agents),
an execution agent that stops really means that the executed tasks _are already dead_.

Let's see an example. This is what happens when the safe position job is running and I stop
the Gazebo simulation:

![Stopped execution agent causes a task abort](media/execution_agent_failed.svg){: .fullwidth}

Note that as the rest, whether the fact that tasks emit the aborted event would
be actually considered an error for the system mainly depends on the task
structure.  Usually, the abort would trigger a dependency relation -- this is
what happens here and the reason why the other tasks are stopped. For a
counter-example, a common bug in newly developed components is that they crash
when they are stopped. Given that they are usually stopped when they are not
needed by the system, this error would not affect the running jobs.
{: .callout .callout-info}

**Next**. This concludes this overview of the Syskit runtime aspects. We will make a detour
through [live data visualization](live_data.html) and then get to the [part
recap](recap.html) before we move on to more advanced
topics.
{: .next-page}
