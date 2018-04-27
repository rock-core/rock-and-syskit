@disable-bundler
@no-clobber
Feature: 07. Publishing
    As a new Rock/Syskit user, I intend to learn how to integrate a new package.

    @clobber-git
    @clobber-new_package_set
    Scenario: 01. Push the bundle
        Given I cd to "dev/bundles/syskit_basics"
        And a file named "manifest.xml" with:
        """
        <package>
            <description brief="Syskit Tutorial Bundle from 'Rock and Syskit'">
            </description>

            <depend package="bundles/common_models" />
            <depend package="simulation/rock_gazebo" />
            <depend package="control/orogen/cart_ctrl_wdls" />
            <depend package="control/orogen/robot_frames" />
        </package>
        """

        And a git repository "bundles-syskit_basics"
        When within the workspace, I successfully run the following script:
        """
        git init
        git add .
        git commit -m "Initial commit - Finished the Basics tutorial"
        """
        Then I push "master" to "bundles-syskit_basics"

    Scenario: 02. Creating the new build configuration
        Given a git repository "rock.rock_and_syskit-buildconf"
        And I cd to "dev/autoproj"
        And within the workspace, I successfully run the following script:
        """
        git add .
        git commit --allow-empty -m "Publishing the Basics tutorial results"
        """
        And I push "master" to "rock.rock_and_syskit-buildconf"
        And I cd to ".."
        When within the workspace, I run the following script interactively:
        """
        autoproj switch-config git ../git/rock.rock_and_syskit-buildconf.git
        """
        And I answer "y" to "delete the current configuration ? (required to switch)" 
        And I stop the command started last
        Then the exit status should be 0

    Scenario: 03. Creating the new package set
        Given a git repository "rock.rock_and_syskit-package_set"
        And a directory named "new_package_set"
        When I cd to "new_package_set"
        Then I successfully run the following script:
        """
        git init
        echo "name: rock.rock_and_syskit" > source.yml
        echo "version_control:" >> source.yml
        echo "overrides:" >> source.yml
        touch packages.autobuild packages.osdeps init.rb overrides.rb
        git add .
        git commit -m "Initial commit"
        """
        And I push "master" to "rock.rock_and_syskit-package_set"

    Scenario: 04. Adding the package set to the build
        Given I cd to "dev"
        When I modify the file "autoproj/manifest" with:
        """
        package_sets:
        +  - type: git
        +    url: $AUTOPROJ_ROOT/../git/rock.rock_and_syskit-package_set.git
        layout:
           - rock.gazebo
        +  - rock.rock_and_syskit
        """
        Then within the workspace, I successfully run the following script:
        """
        aup --config
        """

    Scenario: 05. Defining the package
        Given I cd to "dev/autoproj/remotes/rock.rock_and_syskit"
        And I append to "packages.autobuild" with:
        """
        bundle_package "bundles/syskit_basics"
        """
        And I modify the file "source.yml" with:
        """
        version_control:
        +- bundles/syskit_basics:
        + type: git
        + url: $AUTOPROJ_ROOT/../git/bundles-syskit_basics.git
        """
        Then within the workspace, I successfully run the following script:
        """
        autoproj show syskit_basics
        aup -n syskit_basics
        """

    Scenario: 06. Removing the control packages
        Given I cd to "dev"
        When I modify the file "autoproj/manifest" with:
        """
        -  - control/orogen/cart_ctrl_wdls
        -  - control/orogen/robot_frames
        """
        Then within the workspace, I successfully run the following script:
        """
        aup --config
        """
