---
layout: documentation
title: Integration Tests
sort_info: 100
---

# Integration Tests
{:.no_toc}

- TOC
{:toc}

The last level of tests that a Rock/Syskit system supports is the one of
integration or acceptance tests. In a nutshell, these tests see your system
as a blackbox, run actions and verify the result of these actions. They
actually act as outsiders: they run everything through Syskit's remote
interface, the way you would control it through the IDE or a GUI. These tests
are based on [Cucumber](https://cucumber.io/). This documentation assumes
that you've at least read the introductory Cucumber material, especially [the
description of the guerkin language](https://cucumber.io/docs/reference).

This page will instead focus on the Syskit-specific parts of using cucumber.

Generally speaking, each cucumber feature when interacting with a Syskit system
follows this pattern:

- start a Gazebo scene
- start the Syskit app
- start action(s)
- run a predicate that verifies the action's result
- start more action(s)
- run more predicates that verifies the action's result
- end

The _predicates_ described above are themselves actions, which are supposed to
finish successfully if the predicate passes, and fail otherwise.

Let's go through the items step-by-step. We will take use the Syskit basics
tutorial as a basis for our examples. 

## Setting up a Syskit app to use integration tests

In order to use Cucumber to run test features, one needs to depend on [the
cucumber bundle](https://github.com/rock-core/bundles-cucumber). Just add the
following in your bundle's `manifest.xml`, and then run `aup`.

~~~ xml
<depend_optional name="bundles/cucumber" />
~~~

Add this dependency as optional, as it will allow you to exclude it from the
build in production systems
{: .note}

You must have also followed the modifications to `config/init.rb` listed in
[the basics section](../basics/getting_started.html), 

Finally, create the initial scaffold.

1.  run `cucumber --init` in your bundle

2.  edit `features/support/env.rb` and add the Roby, RockGazebo and this
    bundle's own World modules to the Cucumber world.

    ~~~ ruby
    require 'cucumber/rock_world'
    Cucumber::RockWorld.setup
    World(
        Roby::App::Cucumber::World,
        RockGazebo::Syskit::Cucumber::World,
        Cucumber::RockWorld)
    ~~~

3.  create an action that refines the `Cucumber` action interface provided by
    `bundles/cucumber`. The refinement is meant to provide the robot-under test
    to the underlying compositions
    See `bundles/cucumber/models/actions/cucumber.rb` for the interface
    definition. The action interface is usually called `Actions::Cucumber` as
    well. In the `syskit_basics` bundle we created during the
    [Basics](../basics/index.html) tutorials, one would do

    ~~~
    syskit gen action cucumber
    ~~~

    and edit `models/actions/cucumber.rb`:

    ~~~ ruby
    require 'cucumber/models/actions/cucumber'
    require 'syskit_basics/models/profiles/gazebo/base'

    module SyskitBasics
        module Actions
            class Cucumber < Cucumber::Actions::Cucumber
                def cucumber_robot_model
                    # NOTE the device must be the root model, i.e. cannot use ur10_dev
                    Profiles::Gazebo::Base.ur10_fixed_dev
                end
            end
        end
    end
    ~~~
   
4.  create a robot configuration and load this new profile in it. This robot
    configuration will usually "derive" from the gazebo configuration by
    adding the following line at the top of the robot's configuration file.
    This robot is commonly called `cucumber`.

    Create the new configuration with

    ~~~
    syskit gen robot cucumber
    ~~~

    And add the following line at the top of `config/robots/cucumber.rb`:

    ~~~ ruby
    require_relative './gazebo'
    ~~~

    The robot should obviously add the `Cucumber` action interface to its main actions, with

    ~~~ ruby
    Robot.requires do
        require 'syskit_basics/models/actions/cucumber'
    end
    Robot.actions do
        use_library SyskitBasics::Actions::Cucumber
    end
    ~~~

## Starting the scene and the app

The app and the scene (Gazebo) are both started with a `Given` step of the
form

~~~cucumber
Given the _robot name_ robot starting at _pose_ in _scene name_
~~~

The _robot name_ is the name of the robot configuration in the Syskit app.
The _pose_ stanza defines where the robot-under-test should be placed in the
scene at the beginning of the test (see below for how poses are specified).
The _scene name_ is the name of the scene in `scenes/`. Underscores in the
robot or scene names can be replaced by spaces, and `the` can be added in
front of the scene name

For instance, in our `syskit_basics` bundle, with the `cucumber` robot we just started,
this could be:

~~~cucumber
Given the cucumber robot starting at origin in the empty world
~~~

If your Syskit app needs more arguments (as passed with the `--set` option on
the command line), these can be given with a **with key=value, key=value and
key=value** syntax. For instance

~~~cucumber
Given the cucumber robot starting at origin in the empty world with never_fail=true
~~~

Let's create now a file with the `.feature` extension within `features/`,
that contains this `Given` line. This file will allow us to test that the setup
is functioning as expected.

For instance, `features/01. Test Setup.feature` with:

~~~cucumber
Feature: Checking the Syskit/Cucumber Test Setup
    Scenario: Starting a simulation and a Syskit app under Cucumber
        Given the cucumber robot starting at origin in the empty world
        Then the pose reaches z=0m with a tolerance of 0.1m within 30s
~~~

Which you would run with

~~~
cucumber "features/01. Test Setup.feature"
~~~

## Given/When/Then with Syskit apps

The Given/When/Then loop, when testing a Syskit app is based on placing the robot
somewhere, and then using Syskit's _actions_ to (1) do something and (2) verify the
action result. The Syskit-specific Cucumber steps are only there to integrate this
within a Cucumber feature file.

The Cucumber bundle provide actions and steps that allow to check the
system's position. The underlying infrastructure can be used to create new
steps, more adapted to your application.

More specifically, in a Cucumber scenario, one will have:
- `When` steps that start one or more **application actions**, that is the actions
  of the application-under test.
- `Then` steps that start zero or more **monitoring actions**. These actions are started
  in the background, and should emit their _failed_ event when the predicate their
  represent fails.
- `Then` steps that runs a **predicate** action, which will emit _success_ if the
  test passes, and _failed_ if not.

The application, monitoring and predicate actions of consecutive `When` and
`Then` statements are batched together and started when the first predicate
action is encountered. Application actions are then kept until the next `When it runs ...`
step, while monitoring actions are dropped at the end of the predicate:

~~~
Given the cucumber robot ...
When it runs actionA # starts actionA
Then the pose is maintained at ... # starts a maintain_pose monitor
And after 10s # waits 10 seconds, starts the pending actions
# At this point, the maintain_pose monitor is stopped
# actionA is still active
Then it is failed within 20s
# actionA is still active
When it runs actionB
# actionA will be dropped in the next batch
# actionB will be used to replace it
Then after 20s # this transitions from actionA to actionB and waits 20s
~~~

In addition, a set of `Given` steps can be given before the app startup to initialize
it with a set of actions.

For instance, let's test the [`syskit_basics`](../syskit_basics/) cartesian movement:

~~~cucumber
Feature: cartesian movement
    Scenario: moving the tip of the arm to a given target
        # Start safe_robot_position_def on app startup
        Given the safe robot position definition running
        # Start the app and the simulation
        And the cucumber robot starting at origin in the empty world
        # When I start an application action with arguments
        When it runs the move arm to pose action with position={x=0.5, y=0 and z=0.5} and orientation={yaw=0, pitch=0 and roll=0}
        # Then I expect this step to match
        Then the link ur10::wrist_3 reaches x=0.5m, y=0m, z=0.5m with a tolerance of 0.01m within 20s
~~~

**Note**: the `When` step above do not match what is in our tutorial
application. The Cucumber interface only allows passing simple arguments to
the actions. We will therefore have to create a simple action in the Cucumber
interface that translates this simple representation into the underlying
action's real arguments.

Let's import the Gazebo `ArmControl` profile first

~~~ruby
require 'syskit_basics/models/profiles/gazebo/arm_control
~~~

and define this helper action

~~~ruby
describe('moves the tip of the arm to a given pose').
    required_arg(:position, 'the position as a Hash with x, y and z keys').
    required_arg(:orientation, 'the orientation as a Hash with yaw, pitch and roll keys')
def move_arm_to_pose(position: Hash.new, orientation: Hash.new)
    Profiles::Gazebo::ArmControl.arm_cartesian_constant_control_def(
        position: Eigen::Vector3.new(*position.values_at(0, 0, 0),
        orientation: Eigen::Quaternion.from_euler(
            Eigen::Vector3.new(*orientation.values_at(:yaw, :pitch, :roll))))
end
~~~

## Existing Steps

The steps are defined in the Cucumber bundle, under [`lib/cucumber/rock_steps.rb`](https://github.com/rock-core/bundles-cucumber/blob/master/lib/cucumber/rock_steps.rb). 
The rest of this page will try to explain how these work. It will then detail
how can create your own.

All names (scene, robot, actions, events, ...) can be written replacing the
underscore by a space, to make the steps more natural. For instance, the
`empty_world` scene can be referred to by `empty world`

~~~cucumber
Given the $action action running
Given the $action action running with arg0=$arg0, arg1=$arg1 and arg2=$arg2
Given the $definition definition running
Given the $definition definition running with $arguments
~~~

Specify a set of actions and definitions that will be started in the next
`Given` statement that starts an app. Best is to use the `And` keyword to
chain them, and also to use `And` to start the app afterwards. The `with`
versions can be used to pass arguments (see the [Specifying
Arguments](#specifying_arguments) section below)

~~~cucumber
Given the $robot_name starting at $pose in $scene
Given the $robot_name starting at $pose in $scene with $arguments
~~~

Starts the rock-gazebo and Syskit apps on the given scene and robot
configuration. How `$pose` can be specified is detailed later. Previous
`Given the $action action running` and `Given the $definition definition running`
steps are started immediately. The `with` version can be used to pass
arguments (see the [Specifying Arguments](#specifying_arguments) section
below)

~~~cucumber
When it runs the $action action
When it runs the $action action with $arguments
When it runs the $definition definition
When it runs the $definition definition with $arguments
~~~

Start an action or definition. The `with` version can be used to pass
arguments (see the [Specifying Arguments](#specifying_arguments) section
below). The `definition` version appends `_def` to the definition name,
for clarity of the step. I.e. instead of writing
`When it runs the arm safe joint position def action`, one writes
`When it runs the arm safe joint position definition`

Multiple actions can be started by chaining them with `And`.

~~~cucumber
Then the pose is maintained at $pose with a tolerance of $tolerance
Then the pose is maintained during $time at $pose with a tolerance of $tolerance
~~~

Verify that the pose is within a given tolerance of a target pose. In the
first form, without the time specification, it starts a monitor that runs in
the background until the next step finishes. In the seconf form, with the
time, it verifies that the constraint is met during the given time. See
[this section](#specifying_quantities) for details on how `$pose` and `$tolerance`
should be written.

~~~cucumber
Then after $time
~~~

Wait a given time before executing the next step. It executes the current
batch (start new application actions and drops obsolete ones, runs monitor
actions). See [this section](#specifying_quantities) for details on how
`$pose` and `$tolerance` should be written.

~~~cucumber
Then the pose reaches $pose with a tolerance of $tolerance within $time
~~~

Verifies that the robot reaches the given pose with tolerance in less than a given
time. See [this section](#specifying_quantities) for details on how `$pose`, `$tolerance`
and `$time` should be written.

~~~cucumber
Then it stays there for $time
~~~

Verifies that robot stays at the pose last specified by the
`Then the pose reaches ...` step for a given amount of time.

~~~cucumber
Then it has $event within $time
Then it is $event within $time
~~~

Verifies that the job last started with `When it runs ...` emits the given
event within a certain amount of time. The choice between the two versions is
meant to help having a clearer step (i.e. one would use `it has reached target`
but `it is aborted`).

## Specifying Arguments {#specifying_arguments}

Arguments are always specified using the form `arg0=val0, arg1=val1 and arg2=val2`.
The value can either be a plain string, a number, or a hash of
the form `{key0=val0, key1=val1 and key2=val2}`. [Units can also be specified](#specifying_quantities)

## Specifying Quantities {#specifying_quantities}

The default Cucumber steps will recognize units for certain type of quantities: length,
angles and time. Moreover, it provides a specific syntax to specify constraints
on positions, orientations or poses. Units are used within the built-in steps to verify
that the quantities are matching what the step expects (e.g. no angles for lengths).

**Lengths** have a `m` suffix (for "meter"), e.g. `10m` or `0.01m`

**Angles** have a `deg` suffix (for "degrees"). Angles are internally converted to
radians before being passed to the underlying action.

**Times** have either a `h`, `min` or `s` suffix (for "hours", "minutes" and
*"seconds"). Fraction of a time are specified for the chosen unit (e.g. `1.5h` is one
and a half hour, not one hour and five minutes). They can't be combined: the
system won't recognize `1h5min`. They are internally converted to seconds, as a `Float`.

**Positions** are specified by providing `x`, `y` and `z` as lengths (`m`) using the
argument syntax, e.g. `x=10m, y=20m and z=0.2m`.

**Orientations** are specified as Euler angles `yaw`, `pitch` and `roll` as angles (`deg`)
using the argument syntax, e.g. `yaw=10deg, pitch=-5deg and roll=0deg`.

**Poses** are simply a position and an orientation specified together, that is e.g.
`x=10m, y=20m, z=0.2m, yaw=10deg, pitch=-5deg and roll=0deg`.

**Position, Orientation and Pose Constraints** Constraints are specified as the target
quantity followed by `within a tolerance of $tolerance`, where `$tolerance` is specified
the same way. Constraints can be partial. For instance:
`x=10m and y=20m within a tolerance of x=0.1m and y=0.02m`

Variable names can be omitted in `$tolerance`, in which case they are assumed
to follow the same order than the target quantity:
`x=10m and y=20m within a tolerance of 0.1m and 0.02m`

Finally, one can give a single value if all the values in the target are of the same
dimension: `x=10m and y=20m within a tolerance of 0.1m`

## Defining your own Steps

The first step to create your own steps is to follow the standard Cucumber workflow:
create a `.rb` file in `features/step_definitions` and add `Given`, `When`, ...
definitions.

If you would like to use the argument or quantity parsing used by
the default steps, they are available on the [Roby::App::CucumberHelpers](http://www.rubydoc.info/github/rock-core/tools-roby/Roby/App/CucumberHelpers) module.

The job management API is defined on [Roby::App::Cucumber::Controller](http://www.rubydoc.info/github/rock-core/tools-roby/Roby/App/Cucumber/Controller). You
want in particular to have a look at the `#start_job` and `#start_monitoring_job` methods.
