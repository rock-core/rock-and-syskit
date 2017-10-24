---
layout: documentation
title: Introduction
sort_info: 0
directory_title: Runtime Overview
directory_sort_info: 20
---

# Syskit Runtime Behavior

This part of the documentation deals with the Syskit "runtime model", that is
how Syskit manages a system at runtime, the underlying mechanisms of execution
and how a user can interact with a Syskit system.

Later on this page, I will give a high-level explanation of [the video we've
seen at the end of the Basics
section](../basics/deployment.html#final_video). We will then get deeper
into each part of Syskit that handle Syskit's runtime behavior: an overview of
the [Syskit execution](event_loop.html) and of [error
representation and common type of errors](exceptions.html)

This is the first part that will deal with runtime aspects. For more advanced
related topics, one may want to also read all about
[coordination](../coordination/index.html).

## Actions and Jobs

In the [Basics](../basics) part, we've seen how to define network of
components on a [profile](../basics/devices.html), and that this profile could be then exposed on an
action interface, which allowed us [in the last
part](../basics/deployment.html) to control the system.
An **action** is an abstract concept that represents one thing the system can do.
In order to actually have it executed, one starts a **job**.
Once a job has been started it can be dropped, that is tell Syskit that this
particular job is not part of current system's goal.

All job-related commands are processed in batches: they are queued, and sent
to the Syskit app and processed by it all at once. We will see the
reason for this later in this section.

## Scheduling and Garbage Collection

Starting the first two jobs from the IDE seemed to be a very transparent
process. However, behind the scenes, even this seemingly simple actions require
a bunch of things, such as (in no particular order):

- connecting to the Gazebo task that handle our arm model
- creating the joint constant generator task
- connecting the two
- configuring and starting the components

The sequencing of these different actions is controlled by Syskit's
**scheduler**. While the overall scheduler could be in principle arbitrary,
Syskit internally relies on services that are currently provided by
the temporal scheduler (that you had to set [in the initial bundle
setup](../basics/getting_started.html#initial_setup)). Startup of
the `arm_safe_position_def` job looks like this:

<div id="job_start_step_by_step" class="carousel slide" data-ride="carousel" markdown="0">
  <!-- Indicators -->
  <ol class="carousel-indicators">
    <li data-target="#job_start_step_by_step" data-slide-to="0" class="active"></li>
    <li data-target="#job_start_step_by_step" data-slide-to="1"></li>
    <li data-target="#job_start_step_by_step" data-slide-to="2"></li>
    <li data-target="#job_start_step_by_step" data-slide-to="3"></li>
    <li data-target="#job_start_step_by_step" data-slide-to="4"></li>
    <li data-target="#job_start_step_by_step" data-slide-to="5"></li>
    <li data-target="#job_start_step_by_step" data-slide-to="6"></li>
    <li data-target="#job_start_step_by_step" data-slide-to="7"></li>
    <li data-target="#job_start_step_by_step" data-slide-to="8"></li>
    <li data-target="#job_start_step_by_step" data-slide-to="9"></li>
  </ol>

  <!-- Wrapper for slides -->
  <div class="carousel-inner" role="listbox">
    <div class="item active"><img src="media/scheduling_1.png" alt="start of the execution agents"></div>
    <div class="item"><img src="media/scheduling_2.png" alt="RubyTask ready"></div>
    <div class="item"><img src="media/scheduling_3.png" alt="Gazebo ready"></div>
    <div class="item"><img src="media/scheduling_4.png" alt="start JointPositionGenerator"></div>
    <div class="item"><img src="media/scheduling_5.png" alt="Wait"></div>
    <div class="item"><img src="media/scheduling_6.png" alt="JointPositionGenerator started"></div>
    <div class="item"><img src="media/scheduling_7.png" alt="Wait"></div>
    <div class="item"><img src="media/scheduling_8.png" alt="start ModelTask"></div>
    <div class="item"><img src="media/scheduling_9.png" alt="ModelTask running"></div>
  </div>

  <!-- Controls -->
  <a class="left carousel-control" href="#job_start_step_by_step" role="button" data-slide="prev">
    <span class="glyphicon glyphicon-chevron-left" aria-hidden="true"></span>
    <span class="sr-only">Previous</span>
  </a>
  <a class="right carousel-control" href="#job_start_step_by_step" role="button" data-slide="next">
    <span class="glyphicon glyphicon-chevron-right" aria-hidden="true"></span>
    <span class="sr-only">Next</span>
  </a>
</div>

Now, let's look at stopping things.

If we have the two initial jobs running (`ur10_fixed_dev` and
`arm_safe_position_def`) and stop the latter first and then the former. Focus
on the right panel, that shows the state of the "real" components (i.e. not the
compositions).

<div class="fluid-video" id="start_stop_video">
<iframe width="853" height="480" src="https://www.youtube.com/embed/OHFCvVYZSO8?rel=0&amp;showinfo=0" frameborder="0" allowfullscreen></iframe>
</div>

When `arm_safe_position_def` was stopped, only the setpoint generator
`joint_position_setpoint` has been stopped. The `ModelTask`
`gazebo:empty_world:ur10_fixed` is still running. This is because we still have
the `ur10_fixed_dev` action running and that this action "depends on" the
component. When we stop `ur10_fixed_dev`, this one is stopped as well.  At the
end, starting the `arm_safe_position_def` by itself starts both components, and
stopping it stops both.

Syskit maintains a set of components and compositions that are currently in use
by its goals. Everything else is "not useful" and stopped. This relies on two
things: the internal relationships between compositions and components which
tracks the "usefulness" of a task, and a garbage collection mechanism that
stops and removes not-useful tasks.

In a nutshell, so far:

- "starting" or "killing" a job is actually either adding a new goal
  or removing an existing goal from Syskit's goal set
- the scheduler is what actually starts things based on this goal set
- the garbage collector is what actually stops things based on this goal set

## Transitions

One of Syskit's most important features is its ability to transparently
_transform_ the component network to build one or a combination of behaviors.
We have seen this interactively in the video we saw [at the end of the Basics
section](../basics/deployment.html#final_video): the system was maintaining the
`arm_safe_position_def` and we transitioned it into a parametrized
`arm_cartesian_constant_control_def` to move its tip into a given cartesian
position. This entailed changing the network from a simple joint command to a
network that can do cartesian arm control. What we saw was that the transition
happened smoothly: the arm was controlled during the change of system
configuration.

The same mechanisms are key to autonomously transitioning between behaviours.
This is how one can build [coordination](../coordination/index.html) models.

When we transitioned from the joint control to the cartesian control, we first
**queued** the action start and the action drop and then processed them at
once.  When we clicked `Process`, the two changes were processed _together_.
That is, Syskit could understand that the intent was to stop an action and
start a new one _at the same time_, which it handled as a transition.
Generally speaking, Syskit's execution engine acts as an **event loop**, in which all events that
are received at the same time are processed _as if_ they happened at the
same time.

What if we dropped the action first, and only then
started `arm_cartesian_constant_control_def` ? Syskit would have applied the
kill _first_ and then the start. We would have basically had the same effect
than in [the video we just saw](#start_stop_video), with the arm falling
uncontrolled.

What if we started
`arm_cartesian_constant_control_def` and only then dropped the existing job ?

<div class="fluid-video">
<iframe width="853" height="480" src="https://www.youtube.com/embed/0N3ux-1pj4s?rel=0&amp;showinfo=0" frameborder="0" allowfullscreen></iframe>
</div>

Ouch … The start command failed. This is because we've tried to run two
different control chains that controlled the same device. This is an
impossibility, and the request is therefore rejected by Syskit's network
generation.
{: #deployment_failure}

**Next**: We'll now get to understand all of this step-by-step, starting with [Syskit's
task structure](task_structure.html), how Syskit tracks a system's state.
{: .next-page}

