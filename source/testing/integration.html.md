---
layout: documentation
title: Integration Tests
sort_info: 100
---

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
