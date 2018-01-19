Feature: Getting Started
    @disable-bundler
    @no-clobber
    Scenario: Creating the bundle
        Given I cd to "dev"
        And I successfully run the following script:
        """bash
        set -e
        source env.sh
        acd
        cd bundles
        syskit init syskit_basics
        cd syskit_basics
        """

        When I cd to "bundles/syskit_basics"
        And I run the following script in background:
        """bash
        set -e
        source ../../env.sh
        syskit run
        """
        Then stdout gets "ready" within 5 seconds

        When I successfully run the following script:
        """bash
        set -e
        source ../../env.sh
        syskit quit
        """
        Then the output should contain "closed communication"

        When I stop the command started last
        Then the exit status should be 0

