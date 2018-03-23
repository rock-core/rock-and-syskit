Feature: 01. Getting Started
    @disable-bundler
    @no-clobber
    Scenario: 01. Creating the bundle
        Given I cd to "dev"
        And within the workspace, I successfully run the following script:
        """
        acd
        cd bundles
        syskit gen app syskit_basics
        cd syskit_basics
        """

        When I cd to "bundles/syskit_basics"
        And within the workspace, I run the following script in background:
        """
        syskit run
        """
        Then stdout gets "ready" within 5 seconds

        When within the workspace, I successfully run the following script:
        """
        syskit quit
        """
        Then the output should contain "closed communication"

        When I stop the command started last
        Then the exit status should be 0

    @disable-bundler
    @no-clobber
    Scenario: 02. Setting up the scene
        Given I cd to "dev/bundles/syskit_basics"
        And a file named "scenes/empty_world/empty_world.world" with:
        """
        <?xml version="1.0"?>
        <sdf version="1.6">
            <world name="empty_world">
                <model name="ur10_fixed">
                    <include>
                        <name>ur10</name>
                        <uri>model://ur10</uri>
                    </include>
                    <joint name="attached_to_ground" type="fixed">
                        <parent>world</parent>
                        <child>ur10::base</child>
                    </joint>
                </model>
                <include>
                    <uri>model://ground_plane</uri>
                </include>
            </world>
        </sdf>
        """

        Then within the workspace, I successfully run the following script:
        """bash
        rock-gazebo --download-only empty_world
        """

    @disable-bundler
    @no-clobber
    Scenario: 03. Preparing the gazebo Syskit configuration
        Given I cd to "dev/bundles/syskit_basics"
        Then I successfully run the following script:
        """bash
        set -e
        source ../../env.sh
        syskit gen robot gazebo
        """
	Given that I modify the file "config/robots/gazebo.rb" with:
        """
        Robot.init do
        +    # The rock-gazebo bridge requires models from the 'common_models' bundle.
        +    # It already depends on it, but we need to manually add the bundle to the
        +    # Roby search path
        +    Roby.app.search_path << File.expand_path('../../../common_models', __dir__)
        +    require 'rock_gazebo/syskit'
        +    Conf.syskit.transformer_enabled = true

        Robot.requires do
        +    Syskit.conf.use_gazebo_world('empty_world')
        """
        Then the "gazebo" configuration is valid for Syskit

