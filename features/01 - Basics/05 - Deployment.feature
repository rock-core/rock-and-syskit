@disable-bundler
@no-clobber
Feature: 05. Deployment
    Background:
        Given I cd to "dev/bundles/syskit_basics"

    Scenario: 01. Component Deployment
        When I modify the file "config/robots/gazebo.rb" with:
        """
        -Robot.requires do
        ...
        -end
        +Robot.requires do
        +   Syskit.conf.use_gazebo_world('empty_world')
        +
        +   require 'syskit_basics/models/profiles/gazebo/arm_control'
        +   Syskit.conf.use_deployment OroGen.cart_ctrl_wdls.CartCtrl => 'arm_pos2twist'
        +   Syskit.conf.use_deployment OroGen.cart_ctrl_wdls.WDLSSolver => 'arm_twist2joint'
        +   Syskit.conf.use_deployment OroGen.robot_frames.SingleChainPublisher => 'arm_chain_publisher'
        +   Syskit.conf.use_ruby_tasks SyskitBasics::Compositions::ArmCartesianConstantCommandGenerator => 'arm_constant_setpoint'
        +   Syskit.conf.use_ruby_tasks SyskitBasics::Compositions::JointPositionConstantGenerator => 'joint_position_setpoint'
        +end
        """
        Then the "gazebo" configuration is valid for Syskit

    Scenario: 02. Static configuration of oroGen components
        When within the workspace, I successfully run the following script:
        """
        syskit gen orogenconf cart_ctrl_wdls::WDLSSolver
        syskit gen orogenconf cart_ctrl_wdls::CartCtrl
        syskit gen orogenconf robot_frames::SingleChainPublisher
        """
        Then the output should contain "create  config/orogen/cart_ctrl_wdls::WDLSSolver.yml"
        And the output should contain "create  config/orogen/cart_ctrl_wdls::CartCtrl.yml"
        And the output should contain "create  config/orogen/robot_frames::SingleChainPublisher.yml"
        Then the "gazebo" configuration is valid for Syskit

        When I modify the file "config/orogen/cart_ctrl_wdls::WDLSSolver.yml" with:
        """
        -root: ''
        +root: "ur10::base"
        -tip: ''
        +tip: "ur10::wrist_3"
        """
        And I modify the file "config/orogen/cart_ctrl_wdls::CartCtrl.yml" with:
        """
          velocity:
            data:
        -   - .nan
        -   - .nan
        -   - .nan
        +   - 0.1
        +   - 0.1
        +   - 0.1
          angular_velocity:
            data:
        -   - .nan
        -   - .nan
        -   - .nan
        +   - 3.deg
        +   - 3.deg
        +   - 3.deg
        """
        And I modify the file "config/orogen/robot_frames::SingleChainPublisher.yml" with:
        """
        chain:
        - root_link: ''
        - tip_link: ''
        + root_link: 'ur10::base'
        + tip_link: 'ur10::wrist_3'
        """
        Then the "gazebo" configuration is valid for Syskit

    Scenario: 03. Dynamic and system-wide configuration
        When I modify the file "models/compositions/arm_cartesian_constant_control_wdls.rb" with:
        """
                class ArmCartesianConstantControlWdls < Syskit::Composition
        +           # The robot model that is to be used
        +           #
        +           # This must be the enclosing profile object that has the use_sdf_model call
        +           #
        +           # @return [Profile]
        +           argument :robot

        -           add ArmCartesianControlWdls, as: 'control'
        +           add(ArmCartesianControlWdls, as: 'control').
        +               with_arguments(robot: from(:parent_task).robot)

        """

        And I modify the file "models/compositions/arm_cartesian_control_wdls.rb" with:
        """
                class ArmCartesianControlWdls < Syskit::Composition
        +           # The robot model that is to be used
        +           #
        +           # This must be the enclosing profile object that has the use_sdf_model call
        +           #
        +           # @return [Profile]
        +           argument :robot
        +
        -           add OroGen.cart_ctrl_wdls.WDLSSolver, as: 'twist2joint_velocity'
        +           add(OroGen.cart_ctrl_wdls.WDLSSolver, as: 'twist2joint_velocity').
        +               with_arguments(robot: from(:parent_task).robot)
        -           add OroGen.robot_frames.SingleChainPublisher, as: 'joint2pose'
        +           add(OroGen.robot_frames.SingleChainPublisher, as: 'joint2pose').
        +               with_arguments(robot: from(:parent_task).robot)
        """

        And I modify the file "models/profiles/gazebo/arm_control.rb" with:
        """
                        define 'arm_cartesian_constant_control',
                            Compositions::ArmCartesianConstantControlWdls.
        -                       use(Base.ur10_dev)
        +                       use(Base.ur10_dev).
        +                       with_arguments(robot: Base)
        """
        Then the "gazebo" configuration is valid for Syskit

        When within the workspace, I successfully run the following script:
        """
        syskit gen orogen cart_ctrl_wdls
        syskit gen orogen robot_frames
        """
        And I modify the file "models/orogen/cart_ctrl_wdls.rb" with:
        """
        -Syskit.extend_model OroGen.cart_ctrl_wdls.WDLSSolver do
        ...
        -end
        +Syskit.extend_model OroGen.cart_ctrl_wdls.WDLSSolver do
        +   argument :robot
        +   def configure
        +       super # call super as described in the template
        +
        +       properties.robot_model = robot.sdf_model.make_root.to_xml_string
        +       properties.robot_model_format = :ROBOT_MODEL_SDF
        +   end
        +end
        """
        And I modify the file "models/orogen/robot_frames.rb" with:
        """
        -Syskit.extend_model OroGen.robot_frames.SingleChainPublisher do
        -end
        +Syskit.extend_model OroGen.robot_frames.SingleChainPublisher do
        +   argument :robot
        +   def configure
        +       super # call super as described in the template
        +
        +       properties.robot_model = robot.sdf_model.make_root.to_xml_string
        +       properties.robot_model_format = :ROBOT_MODEL_SDF
        +   end
        +end
        """
        Then the "gazebo" configuration is valid for Syskit

    Scenario: 04. Building the system's action interface
        When I modify the file "config/robots/gazebo.rb" with:
        """
        -Robot.actions do
        ...
        -end
        +Robot.actions do
        +   use_profile SyskitBasics::Profiles::Gazebo::Base
        +   use_profile SyskitBasics::Profiles::Gazebo::ArmControl
        +end
        """
        Then the "gazebo" configuration is valid for Syskit


