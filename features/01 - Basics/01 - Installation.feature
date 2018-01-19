Feature: Installation
    @disable-bundler
    Scenario: Bootstrapping
        # High timeout, we're building and installing stuff
        Given the aruba exit timeout is 3600 seconds
        # High timeout because of variability due to network access
        Given the default answer timeout is 3600 seconds

        When I run the following script:
        """bash
        mkdir dev
        cd dev
        """
        When I cd to "dev"
        And I run the following script:
        """bash
        wget http://rock-robotics.org/autoproj_bootstrap
        """
        Then the following files should exist:
            | autoproj_bootstrap |

        When I run the following script interactively:
        """bash
        ruby autoproj_bootstrap git \
            https://github.com/rock-gazebo/buildconf
        """
        And I answer "" to "Which prepackaged software" 
        And I answer "" to "The current directory is not empty, continue bootstrapping anyway ?"
        When I stop the command started last
        Then the exit status should be 0
        Then the output should contain "successfully"

        When I run the following script interactively:
        """bash
        set -e
        echo $PWD
        source env.sh
        aup --all -k
        amake --all -k
        """
        And I answer "" to "How should I interact with gitorious.org"
        And I answer "" to "How should I interact with github.com"
        And I answer "" to "whether C++11 should be enabled"
        And I answer "" to "Do you need compatibility with OCL ?"
        And I answer "" to "the target operating system for Orocos/RTT"
        And I answer "" to "which CORBA implementation should the RTT use ?"
        When I stop the command started last
        Then the exit status should be 0
        Then the output should contain "Command finished successfully"

