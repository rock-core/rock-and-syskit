Feature: 04. Profiles and Devices
    @disable-bundler
    @no-clobber
    Scenario: 01. Defining Devices for the Gazebo System
        Given I cd to "dev/bundles/syskit_basics"
        When within the workspace, I successfully run the following script:
        """bash
        syskit gen profile gazebo/base
        """
        And I overwrite "models/profiles/gazebo/base.rb" with:
        """
        module SyskitBasics
            module Profiles
                module Gazebo
                profile 'Base' do
                    use_gazebo_model 'model://ur10',
                        prefix_device_with_name: true
                    use_sdf_world
                end
                end
            end
        end
        """
        Then the file "models/profiles/gazebo/base.rb" is valid for Syskit in configuration "gazebo"
    
        When within the workspace, I successfully run the following script:
        """
        syskit gen profile gazebo/arm_control
        """
        And I overwrite "models/profiles/gazebo/arm_control.rb" with:
        """
        require 'syskit_basics/models/profiles/gazebo/base'
        require 'syskit_basics/models/compositions/arm_cartesian_constant_control_wdls'
        require 'syskit_basics/models/compositions/joint_position_constant_control'
    
        module SyskitBasics
            module Profiles
                module Gazebo
                    profile 'ArmControl' do
                        define 'arm_cartesian_constant_control',
                            Compositions::ArmCartesianConstantControlWdls.
                                use(Base.ur10_dev)
                        define 'arm_joint_position_constant_control',
                            Compositions::JointPositionConstantControl.
                                use(Base.ur10_dev)
                    end
                end
            end
        end
        """
        Then the file "models/profiles/gazebo/base.rb" is valid for Syskit in configuration "gazebo"
    
        When I modify the file "models/profiles/gazebo/arm_control.rb" with:
        """
                module Gazebo
        +            UR10_SAFE_POSITION = Hash[
        +                'ur10::shoulder_pan'  => 0,
        +                'ur10::shoulder_lift' => -Math::PI/2,
        +                'ur10::elbow'         => Math::PI/2,
        +                'ur10::wrist_1'       => 0,
        +                'ur10::wrist_2'       => 0,
        +                'ur10::wrist_3'       => 0]
        +
        """
        And I modify the file "models/profiles/gazebo/arm_control.rb" with:
        """
                        define 'arm_joint_position_constant_control',
                            Compositions::JointPositionConstantControl.
                                use(Base.ur10_dev)
        +                define 'arm_safe_position',
        +                    arm_joint_position_constant_control_def.
        +                        with_arguments(setpoint: UR10_SAFE_POSITION)
        """
        Then the file "models/profiles/gazebo/base.rb" is valid for Syskit in configuration "gazebo"
    
    