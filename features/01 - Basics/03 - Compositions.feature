Feature: Compositions
    @disable-bundler
    @no-clobber
    Scenario: Installing the necessary packages
        Given I cd to "dev"
        And I modify the file "autoproj/manifest" with:
        """
           - rock.gazebo
        +   - control/orogen/cart_ctrl_wdls
        """

        And within the workspace, I successfully run the following script for up to 3600 seconds:
        """
        aup --checkout-only --all
        amake --all
        """

    @disable-bundler
    @no-clobber
    Scenario: Using the installed component
        Given I cd to "dev/bundles/syskit_basics"
        And within the workspace, I successfully run the following script:
        """
        syskit gen cmp arm_cartesian_control_wdls
        """
        And I modify the file "models/compositions/arm_cartesian_control_wdls.rb" with:
        """
        +using_task_library "cart_ctrl_wdls"
        """
        Then the file "models/compositions/arm_cartesian_control_wdls.rb" is valid for Syskit

        When I overwrite "models/compositions/arm_cartesian_control_wdls.rb" with:
        """
        # This is in bundles/common_models
        require 'models/devices/gazebo/model'
        # Load the oroGen project
        using_task_library 'cart_ctrl_wdls'

        module SyskitBasics
          module Compositions
            class ArmCartesianControlWdls < Syskit::Composition
              add OroGen.cart_ctrl_wdls.WDLSSolver, as: 'twist2joint_velocity'
              add OroGen.cart_ctrl_wdls.CartCtrl, as: 'position2twist'
              add CommonModels::Devices::Gazebo::Model, as: 'arm'
            end
          end
        end
        """
        Then the file "models/compositions/arm_cartesian_control_wdls.rb" is valid for Syskit

        When I modify the file "models/compositions/arm_cartesian_control_wdls.rb" with:
        """
              add CommonModels::Devices::Gazebo::Model, as: 'arm'
        +
        +      position2twist_child.ctrl_out_port.
        +        connect_to twist2joint_velocity_child.desired_twist_port
        +      twist2joint_velocity_child.solver_output_port.
        +        connect_to arm_child.joints_cmd_port
        """
        Then the file "models/compositions/arm_cartesian_control_wdls.rb" is valid for Syskit

        When I modify the file "models/compositions/arm_cartesian_control_wdls.rb" with:
        """
              add CommonModels::Devices::Gazebo::Model, as: 'arm'

              position2twist_child.ctrl_out_port.
                connect_to twist2joint_velocity_child.desired_twist_port
              twist2joint_velocity_child.solver_output_port.
                connect_to arm_child.joints_cmd_port
        +      arm_child.joints_status_port.
        +        connect_to twist2joint_velocity_child.joint_status_port
        """
        Then the file "models/compositions/arm_cartesian_control_wdls.rb" is valid for Syskit

        When I modify the file "../../autoproj/manifest" with:
        """
           - rock.gazebo
           - control/orogen/cart_ctrl_wdls
        +   - control/orogen/robot_frames
        """
        And within the workspace, I successfully run the following script for up to 3600 seconds:
        """
        aup --checkout-only --all
        amake --all
        """
        And I overwrite "models/compositions/arm_cartesian_control_wdls.rb" with:
        """
        # This is in bundles/common_models
        require 'models/devices/gazebo/model'
        # Load the oroGen projects
        using_task_library 'cart_ctrl_wdls'
        using_task_library 'robot_frames'

        module SyskitBasics
          module Compositions
            class ArmCartesianControlWdls < Syskit::Composition
              add OroGen.cart_ctrl_wdls.WDLSSolver, as: 'twist2joint_velocity'
              add OroGen.cart_ctrl_wdls.CartCtrl, as: 'position2twist'
              add CommonModels::Devices::Gazebo::Model, as: 'arm'
              add OroGen.robot_frames.SingleChainPublisher, as: 'joint2pose'

              position2twist_child.ctrl_out_port.
                connect_to twist2joint_velocity_child.desired_twist_port
              twist2joint_velocity_child.solver_output_port.
                connect_to arm_child.joints_cmd_port
              arm_child.joints_status_port.
                connect_to twist2joint_velocity_child.joint_status_port
              arm_child.joints_status_port.
                connect_to joint2pose_child.joints_samples_port
              joint2pose_child.tip_pose_port.
                connect_to position2twist_child.cartesian_status_port
            end
          end
        end
        """
        Then the file "models/compositions/arm_cartesian_control_wdls.rb" is valid for Syskit

        When I modify the file "models/compositions/arm_cartesian_control_wdls.rb" with:
        """
              joint2pose_child.tip_pose_port.
                connect_to position2twist_child.cartesian_status_port
        +      export position2twist_child.command_port
        """
        Then the file "models/compositions/arm_cartesian_control_wdls.rb" is valid for Syskit

