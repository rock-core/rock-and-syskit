Feature: 04. Constant Generator
    @disable-bundler
    @no-clobber
    Scenario: 01. The Cartesian Command Generator
        Given I cd to "dev/bundles/syskit_basics"
        And within the workspace, I successfully run the following script:
        """
        syskit gen ruby_task arm_cartesian_constant_command_generator
        """
        Then the file "models/compositions/arm_cartesian_constant_command_generator.rb" is valid for Syskit

        When I overwrite "models/compositions/arm_cartesian_constant_command_generator.rb" with:
        """
        import_types_from 'base'
        require 'common_models/models/compositions/constant_generator'

        module SyskitBasics
            module Compositions
                class ArmCartesianConstantCommandGenerator < CommonModels::Compositions::ConstantGenerator.
                    for('/base/samples/RigidBodyState')
                end
            end
        end
        """
        Then the file "models/compositions/arm_cartesian_constant_command_generator.rb" is valid for Syskit

        When I modify the file "models/compositions/arm_cartesian_constant_command_generator.rb" with:
        """
                class ArmCartesianConstantCommandGenerator < CommonModels::Compositions::ConstantGenerator.
                    for('/base/samples/RigidBodyState')
        +           # The setpoint as a { position: p, orientation: q } hash
        +           argument :setpoint
        +
        +           def setpoint=(setpoint)
        +               rbs = Types.base.samples.RigidBodyState.Invalid
        +               # Use 'fetch' to generate an error if the key is not present
        +               # in the hash
        +               rbs.position = setpoint.fetch(:position)
        +               rbs.orientation = setpoint.fetch(:orientation)
        +               self.values = Hash['out' => rbs]
        +           end
        """
        Then the file "models/compositions/arm_cartesian_constant_command_generator.rb" is valid for Syskit

        When I modify the file "models/compositions/arm_cartesian_constant_command_generator.rb" with:
        """
                        self.values = Hash['out' => rbs]
                    end
        +
        +           def values
        +               if v = super
        +                   # Do not change the argument "under the hood"
        +                   sample = v['out'].dup
        +                   sample.time = Time.now
        +                   Hash['out' => sample]
        +               end
        +           end
        """
        Then the file "models/compositions/arm_cartesian_constant_command_generator.rb" is valid for Syskit

    @disable-bundler
    @no-clobber
    Scenario: 02. Testing
        Given I cd to "dev/bundles/syskit_basics"

        When I overwrite "test/compositions/test_arm_cartesian_constant_command_generator.rb" with:
        """
        require 'models/compositions/arm_cartesian_constant_command_generator'

        module SyskitBasics
            module Compositions
                describe ArmCartesianConstantCommandGenerator do
                end
            end
        end
        """
        Then the syskit test file "test/compositions/test_arm_cartesian_constant_command_generator.rb" passes

        When I modify the file "test/compositions/test_arm_cartesian_constant_command_generator.rb" with:
        """
                describe ArmCartesianConstantCommandGenerator do
        +           it "propagates its position and orientation arguments to #values" do
        +               p = Eigen::Vector3.new(1, 2, 3)
        +               q = Eigen::Quaternion.from_angle_axis(0.2, Eigen::Vector3.UnitX)
        +               task = syskit_stub_deploy_configure_and_start(
        +                 ArmCartesianConstantCommandGenerator.
        +                   with_arguments(setpoint: Hash[position: p, orientation: q]))
        +               assert_equal p, task.values['out'].position
        +               assert_equal q, task.values['out'].orientation
        +           end
                end
        """
        Then within the workspace, I successfully run the following script:
        """
        syskit test -rgazebo test/compositions/test_arm_cartesian_constant_command_generator.rb
        """
        Then within the workspace, I successfully run the following script:
        """
        syskit test -rgazebo
        """

        When I modify the file "test/compositions/test_arm_cartesian_constant_command_generator.rb" with:
        """
                        assert_equal p, task.values['out'].position
                        assert_equal q, task.values['out'].orientation
                    end
        +           it "returns the value with an updated timestamp" do
        +               p = Eigen::Vector3.new(1, 2, 3)
        +               q = Eigen::Quaternion.from_angle_axis(0.2, Eigen::Vector3.UnitX)
        +               task = syskit_stub_deploy_configure_and_start(
        +                 ArmCartesianConstantCommandGenerator.
        +                   with_arguments(setpoint: Hash[position: p, orientation: q]))
        +               Timecop.freeze(expected_time = Time.now)
        +               sample = expect_execution.to do
        +                 have_one_new_sample task.out_port
        +               end
        +               assert_in_delta expected_time, sample.time, 1e-6
        +           end
                end
        """
        Then within the workspace, I successfully run the following script:
        """
        syskit test -rgazebo test/compositions/test_arm_cartesian_constant_command_generator.rb
        """

        When I overwrite "test/compositions/test_arm_cartesian_constant_command_generator.rb" with:
        """
        require 'models/compositions/arm_cartesian_constant_command_generator'

        module SyskitBasics
            module Compositions
                describe ArmCartesianConstantCommandGenerator do
                    attr_reader :task, :p, :q
                    before do
                        @p = Eigen::Vector3.new(1, 2, 3)
                        @q = Eigen::Quaternion.from_angle_axis(0.2, Eigen::Vector3.UnitX)
                        @task = syskit_stub_deploy_configure_and_start(
                            ArmCartesianConstantCommandGenerator.
                                with_arguments(setpoint: Hash[position: p, orientation: q]))
                    end

                    it "propagates its position and orientation arguments to #values" do
                        assert_equal p, task.values['out'].position
                        assert_equal q, task.values['out'].orientation
                    end

                    it "returns the value with an updated timestamp" do
                        Timecop.freeze(expected_time = Time.now)
                        sample = expect_execution.to do
                        have_one_new_sample task.out_port
                        end
                        assert_in_delta expected_time, sample.time, 1e-6
                    end
                end
            end
        end
        """
        Then within the workspace, I successfully run the following script:
        """
        syskit test -rgazebo test/compositions/test_arm_cartesian_constant_command_generator.rb
        """

    @disable-bundler
    @no-clobber
    Scenario: 03. Creating the ArmCartesianConstantControlWdls Composition
        Given I cd to "dev/bundles/syskit_basics"
        And within the workspace, I successfully run the following script:
        """
        syskit gen cmp arm_cartesian_constant_control_wdls
        """
        And I overwrite "models/compositions/arm_cartesian_constant_control_wdls.rb" with:
        """
        require 'syskit_basics/models/compositions/arm_cartesian_constant_command_generator'
        require 'syskit_basics/models/compositions/arm_cartesian_control_wdls'

        module SyskitBasics
            module Compositions
                class ArmCartesianConstantControlWdls < Syskit::Composition
                    add ArmCartesianConstantCommandGenerator, as: 'command'
                    add ArmCartesianControlWdls, as: 'control'

                    command_child.out_port.
                        connect_to control_child.command_port
                end
            end
        end
        """
        And within the workspace, I run the following script:
        """
        syskit test -r gazebo test/compositions/test_arm_cartesian_constant_control_wdls.rb
        """
        Then the exit status should be 1

        When I modify the file "models/compositions/arm_cartesian_constant_control_wdls.rb" with:
        """
        -           add ArmCartesianConstantCommandGenerator, as: 'command'
        +           argument :setpoint
        +
        +           add(ArmCartesianConstantCommandGenerator, as: 'command').
        +               with_arguments(setpoint: from(:parent_task).setpoint)
        """
        And I modify the file "test/compositions/test_arm_cartesian_constant_control_wdls.rb" with:
        """
        -           it "starts" do
        ...
        -           end
        +           it "forwards its setpoint argument to the generator child" do
        +               setpoint = Hash[
        +                   position: Eigen::Vector3.new(1, 2, 3),
        +                   orientation: Eigen::Quaternion.from_angle_axis(0.4, Eigen::Vector3.UnitZ)]
        +               cmp = syskit_stub_deploy_configure_and_start(
        +                   ArmCartesianConstantControlWdls.with_arguments(setpoint: setpoint))
        +               assert_equal setpoint, cmp.command_child.setpoint
        +           end
        """
        Then within the workspace, I successfully run the following script:
        """
        syskit test -r gazebo test/compositions/test_arm_cartesian_constant_control_wdls.rb
        """

    @disable-bundler
    @no-clobber
    Scenario: 04. The Joint Position Constant Generator
        Given I cd to "dev/bundles/syskit_basics"
        And within the workspace, I successfully run the following script:
        """
        syskit gen ruby_task joint_position_constant_generator
        """
        And I overwrite "models/compositions/joint_position_constant_generator.rb" with:
        """
        require 'common_models/models/compositions/constant_generator'
        import_types_from 'base'
        
        module SyskitBasics
            module Compositions
                class JointPositionConstantGenerator < CommonModels::Compositions::ConstantGenerator.
                    for('/base/commands/Joints')
            
                    # The setpoint as a hash of joint names to joint positions
                    argument :setpoint
                
                    def setpoint=(setpoint)
                        joint_names    = setpoint.keys
                        joint_commands = setpoint.each_value.map do |position|
                            Types.base.JointState.new(
                                position: position,
                                speed: Float::NAN,
                                effort: Float::NAN,
                                raw: Float::NAN,
                                acceleration: Float::NAN)
                        end
                        self.values = Hash['out' =>
                            Types.base.commands.Joints.new(
                                time: Time.at(0),
                                names: joint_names,
                                elements: joint_commands)]
                    end
                
                    def values
                        if v = super
                            # Do not change the argument "under the hood"
                            sample = v['out'].dup
                            sample.time = Time.now
                            Hash['out' => sample]
                        end
                    end
                end
            end
        end
        """
        And I overwrite "test/compositions/test_joint_position_constant_generator.rb" with:
        """
        require 'syskit_basics/models/compositions/joint_position_constant_generator'

        module SyskitBasics
            module Compositions
                describe JointPositionConstantGenerator do
                    it "sets the names and positions based on the given hash" do
                        task = syskit_stub_deploy_configure_and_start(
                            JointPositionConstantGenerator.
                                with_arguments(setpoint: Hash['j0' => 10, 'j1' => 20]))
                        assert_equal ['j0', 'j1'], task.values['out'].names
                        assert_equal [10, 20], task.values['out'].elements.map(&:position)
                    end
                
                    it "returns the value with an updated timestamp" do
                        task = syskit_stub_deploy_configure_and_start(
                            JointPositionConstantGenerator.
                                with_arguments(setpoint: Hash['j0' => 10, 'j1' => 20]))
                        Timecop.freeze(expected_time = Time.now)
                        sample = expect_execution.
                            to { have_one_new_sample task.out_port }
                        assert_in_delta expected_time, sample.time, 1e-6
                    end
                end
            end
        end
        """
        Then within the workspace, I successfully run the following script:
        """
        syskit test -r gazebo test/compositions/test_joint_position_constant_generator.rb
        """

        When within the workspace, I successfully run the following script:
        """
        syskit gen cmp joint_position_constant_control
        """
        And I overwrite "models/compositions/joint_position_constant_control.rb" with:
        """
        require 'common_models/models/devices/gazebo/model'
        require 'syskit_basics/models/compositions/joint_position_constant_generator'
        
        module SyskitBasics
            module Compositions
                class JointPositionConstantControl < Syskit::Composition
                    # The setpoint as a 'joint_name' => position_in_radians hash
                    argument :setpoint
            
                    add CommonModels::Devices::Gazebo::Model, as: 'arm'
                    add(JointPositionConstantGenerator, as: 'command').
                        with_arguments(setpoint: from(:parent_task).setpoint)
                
                    command_child.out_port.connect_to \
                        arm_child.joints_cmd_port
                end
            end
        end
        """
        And I overwrite "test/compositions/test_joint_position_constant_control.rb" with:
        """
        require 'syskit_basics/models/compositions/joint_position_constant_control'

        module SyskitBasics
            module Compositions
                describe JointPositionConstantControl do
                    it "forwards its setpoint argument to the constant generator" do
                        cmp_task = syskit_stub_deploy_configure_and_start(
                        JointPositionConstantControl.with_arguments(setpoint: Hash['j0' => 10]))
                        assert_equal Hash['j0' => 10], cmp_task.command_child.setpoint
                    end
                end
            end
        end
        """
        Then within the workspace, I successfully run the following script:
        """
        syskit test -rgazebo test/compositions/test_joint_position_constant_control.rb
        """

