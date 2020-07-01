---
layout: documentation
title: Action Methods
sort_info: 30
---

# Action Methods
{:.no_toc}

- TOC
{:toc}

So far, we know of one way to create actions, by importing a whole profile in
an action interface using the `use_profile` statement. This is rather static:
the only parametrization is by passing arguments to the toplevel composition
of the network, which may trickle down to lower levels through

This section will present a second way, which allows to actually run code to
"implement" the action. It essentially runs a method on the action interface,
whose job is to create a small "plan" later executed by Syskit.

This section will go through the general syntax for such actions, and will
list a few use-cases for such actions.

## Definition

Action methods are methods that are defined on an action interface. To "export"
them as actions, one must do a declaration before the method definition using
the `describe` statement:

~~~ ruby
describe("a simple action")
    .returns(Tasks::ASimpleAction)
def a_simple_action
    Tasks::ASimpleAction.new
end
~~~

The name of the method becomes the name of the action. The string given to
`describe` is documentation only.

If the action requires arguments, you must both declare them and allow them
to be passed to the method as a keyword argument:

~~~ ruby
describe("a simple action")
    .required_arg("arg0", "some documentation")
    .returns(Tasks::ASimpleAction)
def a_simple_action(arg0:)
    Tasks::ASimpleAction.new(arg0: arg0)
end
~~~

Optional arguments may be defined the same way, and require a default value.

~~~ ruby
describe("a simple action")
    .optional_arg("arg1", "some documentation", 42)
    .returns(Tasks::ASimpleAction)
def a_simple_action(arg1: 42)
    Tasks::ASimpleAction.new(arg1: arg1)
end
~~~

## Return Value

As with all actions, action methods are represented by a single "root" task. The
action's return value is this very task.

You **MUST** specify the type of the task that is being returned, the way
we've done it in the examples above. It can be either its exact type, or a
parent class. For instance, all actions could have a `returns(Roby::Task)`, but
this would lead to a very confusing system (a.k.a. don't do that).

Specifying task return types becomes even more important when creating [action
state machines](action_state_machines.html), as the return type is used to
determine which events are available for the state machine to transition on.

For historical reasons, if there is no return type specified, Syskit
auto-generates a task model whose name is based on the action name (e.g.
`ASimpleAction` for our action above). Do not rely on this behavior, which ended
up being a lot more confusing than useful.
{: .note}

## Exception Handling

The failure of an action method does *not* change the currently executed
system. The changes are being made in a _transaction_ that is rolled back if
the action method raises an exception. In addition, the action's planning
taks will fail in this case, which should allow your reporting subsystem or
[higher-level control](higher_level_control.html) to react.

## Tests

You can run an action through the action instanciation codepath using the
`roby_run_planner` statement, e.g.

~~~ ruby
task = roby_run_planner MyInterface.my_action
# Look for properties on `task`
~~~

arguments are naturally passed to the action:

~~~ ruby
task = roby_run_planner MyInterface.my_action(arg1: 10)
# Look for properties on `task`
~~~

## Use Cases

### Generation of complex parameters from simpler action arguments

Let's consider a drone. The drone will usually have a trajectory following
definition, which allows it to move along a curve, following some parameters
such as for instance speed. Let's assume that the definition that implements
this trajectory follower is called `trajectory_follower` in a `Navigation`
profile. This definition's toplevel composition is `Compositions::TrajectoryFollowing`.

Now, there are a lot of use-cases where generating a full trajectory is a
rather complicated endeavour. We might want to design the system to provide
higher-level behaviors such as `survey`, that would do a sweep of an area, or
`straight_line` which does a line.

One way to implement these would be to create separate compositions (possibly
subclasses of the same base composition) that generate a trajectory based
on their parameters, and write them to the trajectory follower.

Another way is to keep the single trajectory following definition, but create
one action per behavior, which generates the trajectory and returns the
properly parametrized trajectory following definition:

~~~ ruby
class Navigation < Roby::Actions::Interface
    use_profile Profiles::Navigation

    describe("goes on a straight line")
        .required_arg("start_p", "starting point, as an Eigen::Vector3")
        .required_arg("end_p", "end point, as an Eigen::Vector3")
        .required_arg("speed", "speed at which to execute the trajectory")
        .returns(Compositions::TrajectoryFollowing)
    def straight_line(start_p:, end_p:, speed:)
        self.model.trajectory_follower_def(
            trajectory: straight_line_trajectory(start_p, end_p, speed)
        )
    end

    # @api private
    #
    # Helper that converts two points into a straight line trajectory
    def straight_line_trajectory(start_p, end_p, speed)
        ...
    end
end
~~~

### Dynamic Dependency Injection

Thanks to action methods, it is possible to dynamically [inject dependencies](../component_networks/reusable_networks.html#injection)
Until now, the only mean we have seen was to pre-define the injections in the
profiles and export them as action. Actions methods will allow to make the
injection dependent on e.g. an action argument.

For instance, in a 4-camera teleoperated system, we could choose a main and
auxiliary camera using a `ui_camera_streamer` action:

~~~ ruby
class UI < Roby::Actions::Interface
    use_profile Profiles::UI

    describe("runs the UI while selecting the current camera")
        .required_arg("main_camera", "the camera to use as main")
        .returns(Compositions::CameraStreamer)
    def ui_camera_streamer(main_camera:)
        # `resolve_cameras` is a helper that verifies the parameters,
        # and returns the camera devices from Profiles::Base in the right
        # order for injection
        main_camera, left_thumb, center_thumb, right_thumb =
            resolve_cameras(main_camera)
        self.model.camera_streamer_def
            .use('main_camera' => main_camera,
                 'left_thumb' => left_thumb,
                 'center_thumb' => center_thumb,
                 'right_thumb' => right_thumb)
    end
end
~~~

## And many other things

_In fine_, the action methods give direct access to Syskit's execution data
structures. We will see how this can be leveraged for other uses in further
sections of this chapter, as for instance the [creation of higher level controllers](higher_level_control.html)
or with the [event scheduling](event_scheduling.html).
