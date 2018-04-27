@disable-bundler
@no-clobber
Feature: 14. Integration Tests
    Background:
        Given I cd to "dev/bundles/syskit_basics"

    Scenario: 01.1 Installing Cucumber support
        Given I modify the file "manifest.xml" with:
        """
            <depend package="control/orogen/robot_frames" />
        +   <depend_optional name="bundles/cucumber" />
        """
        And within the workspace, I run the following script:
        """
        aup --checkout-only
        """
        Then within the workspace, I successfully run the following script:
        """
        cucumber --init
        """

    Scenario: 01.2 Setting up a Syskit app to use integration tests
        Given the file "features/support/env.rb" with:
        """
        require 'cucumber/rock_world'
        Cucumber::RockWorld.setup
        World(
            Roby::App::Cucumber::World,
            RockGazebo::Syskit::Cucumber::World,
            Cucumber::RockWorld)
        """
        And within the workspace, I successfully run the following script:
        """
        syskit gen action cucumber
        """
        And I overwrite the file "models/actions/cucumber.rb" with:
        """
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
        """
        And within the workspace, I successfully run the following script:
        """
        syskit gen robot cucumber
        """
        And I modify the file "config/robots/cucumber.rb" with:
        """
        +require_relative './gazebo'
        -Robot.requires do
        ...
        -end
        +Robot.requires do
        +   require 'syskit_basics/models/actions/cucumber'
        +end
        -Robot.actions do
        ...
        -end
        +Robot.actions do
        +   use_library SyskitBasics::Actions::Cucumber
        +end
        """
        And the file "features/Test Setup.feature" with:
        """
        Feature: Checking the Syskit/Cucumber Test Setup
            Scenario: Starting a simulation and a Syskit app under Cucumber
                Given the cucumber robot starting at origin in the empty world
                Then the pose reaches z=0m with a tolerance of 0.1m within 30s
        """
        Then within the workspace, I successfully run the following script:
        """
        cucumber "features/Test Setup.feature"
        """
