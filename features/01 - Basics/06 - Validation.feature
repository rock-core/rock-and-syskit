Feature: 06. Validation
    Background:
        Given I cd to "dev/bundles/syskit_basics"

    @disable-bundler
    @no-clobber
    Scenario: 01. Validating Configuration Consistency
        When I modify the file "models/orogen/cart_ctrl_wdls.rb" with:
            """
            -Syskit.extend_model OroGen.cart_ctrl_wdls.WDLSSolver do
            ...
            -end
            +Syskit.extend_model OroGen.cart_ctrl_wdls.WDLSSolver do
            +   argument :robot
            +
            +   # @api private
            +   #
            +   # Validates that a link is part of the provided robot model
            +   #
            +   # @param [String] link_name the name of the link
            +   # @param [String] property_name the name of the property being
            +   #   verified
            +   # @raise [ArgumentError] if the link is not in the model
            +   def verify_link_in_model(model, link_name)
            +       if !model.each_link.any? { |link| link.full_name == link_name }
            +           raise ArgumentError, "link name '#{link_name}' is not a link of the robot model. Existing links: #{model.each_link.map(&:full_name).sort.join(", ")}"
            +       end
            +   end
            +
            +   def configure
            +       super
            +
            +       # Extract the model into its own SDF document
            +       as_root = robot.sdf_model.make_root
            +       # And get the new model
            +       model = as_root.each_model.first
            +       verify_link_in_model(model, properties.root)
            +       verify_link_in_model(model, properties.tip)
            +
            +       properties.robot_model = as_root.to_xml_string
            +       properties.robot_model_format = :ROBOT_MODEL_SDF
            +   end
            +end
            """
        
        And I modify the file "test/orogen/test_cart_ctrl_wdls.rb" with:
        """
        -   describe cart_ctrl_wdls.WDLSSolver do
        ...
        -   end
        +   describe cart_ctrl_wdls.WDLSSolver do
        +       attr_reader :profile
        +       
        +       before do
        +           # Create a mock that has a robot model
        +           xml = <<-EOSDF
        +           <model name='test'>
        +               <link name="root_test" />
        +               <link name="tip_test" />
        +           </model>
        +           EOSDF
        +           # We don't really need a full profile object, only an object
        +           # that provides a Model object from a '#sdf_model' attribute
        +           #
        +           # Let's fake one using flexmock. Flexmock is loaded as part
        +           # Of Syskit's test harness
        +           #
        +           # https://github.com/doudou/flexmock
        +           @profile = flexmock(sdf_model: SDF::Model.from_xml_string(xml))
        +       end
        +       
        +       it "sets the robot model from its 'robot' argument" do
        +           # Create a fake test configuration with valid root and tip
        +           syskit_stub_conf OroGen.cart_ctrl_wdls.WDLSSolver, 'default',
        +               data: { 'root' => 'test::root_test', 'tip' => 'test::tip_test' }
        +           task = syskit_stub_deploy_and_configure(
        +               OroGen.cart_ctrl_wdls.WDLSSolver.
        +                   with_arguments(robot: profile))
        +           assert_equal "<sdf>#{profile.sdf_model.to_xml_string}</sdf>",
        +               task.properties.robot_model
        +       end
        +       
        +       it "raises if the root link does not exist" do
        +           syskit_stub_conf OroGen.cart_ctrl_wdls.WDLSSolver, 'default',
        +               data: { 'root' => 'invalid', 'tip' => 'test::tip_test' }
        +           e = assert_raises(ArgumentError) do
        +               syskit_stub_deploy_and_configure(
        +                   OroGen.cart_ctrl_wdls.WDLSSolver.
        +                       with_arguments(robot: profile))
        +           end
        +           assert_equal "link name 'invalid' is not a link of the robot model. "\
        +               "Existing links: test::root_test, test::tip_test",
        +               e.message
        +       end
        +       
        +       it "raises if the tip link does not exist" do
        +           syskit_stub_conf OroGen.cart_ctrl_wdls.WDLSSolver, 'default',
        +               data: { 'root' => 'test::root_test', 'tip' => 'invalid' }
        +           e = assert_raises(ArgumentError) do
        +               syskit_stub_deploy_and_configure(
        +                   OroGen.cart_ctrl_wdls.WDLSSolver.
        +                       with_arguments(robot: profile))
        +           end
        +           assert_equal "link name 'invalid' is not a link of the robot model. "\
        +               "Existing links: test::root_test, test::tip_test",
        +               e.message
        +       end
        +   end
        """
        Then the tests matching "/cart_ctrl_wdls.WDLSSolver/" in the Syskit test file "test/orogen/test_cart_ctrl_wdls.rb" and configuration "gazebo" pass
        Then the Syskit test file "test/orogen/test_cart_ctrl_wdls.rb" fails in configuration "gazebo"

        When I modify the file "test/orogen/test_cart_ctrl_wdls.rb" with:
        """
            describe cart_ctrl_wdls.AdaptiveWDLSSolver do
        -       it { is_configurable }
            end
        """
        Then the Syskit test file "test/orogen/test_cart_ctrl_wdls.rb" passes in configuration "gazebo"
        Then the Syskit tests fail in configuration "gazebo"

        When I modify the file "test/compositions/test_arm_cartesian_control_wdls.rb" with:
        """
                describe ArmCartesianControlWdls do
        +           before do
        +               # Create a mock that has a robot model
        +               xml = <<-EOSDF
        +                   <model name='test'>
        +                   <link name="root_test" />
        +                   <link name="tip_test" />
        +                   </model>
        +               EOSDF
        +               @profile = flexmock(sdf_model: SDF::Model.from_xml_string(xml))
        +               syskit_stub_conf OroGen.cart_ctrl_wdls.WDLSSolver, 'default',
        +                   data: { 'root' => 'test::root_test', 'tip' => 'test::tip_test' }
        +               syskit_stub_conf OroGen.robot_frames.SingleChainPublisher, 'default',
        +                   data: { 'chain' => Hash['root_link' => 'test::root_test', 'tip_link' => 'test::tip_test'] }
        +           end
        -               cmp_task = syskit_stub_deploy_configure_and_start(ArmCartesianControlWdls)
        +               cmp_task = syskit_stub_deploy_configure_and_start(
        +                   ArmCartesianControlWdls.with_arguments(robot: @profile))
        """
        And I modify the file "test/compositions/test_arm_cartesian_constant_control_wdls.rb" with:
        """
                describe ArmCartesianConstantControlWdls do
        +           before do
        +               # Create a mock that has a robot model
        +               xml = <<-EOSDF
        +                   <model name='test'>
        +                   <link name="root_test" />
        +                   <link name="tip_test" />
        +                   </model>
        +               EOSDF
        +               @profile = flexmock(sdf_model: SDF::Model.from_xml_string(xml))
        +               syskit_stub_conf OroGen.cart_ctrl_wdls.WDLSSolver, 'default',
        +                   data: { 'root' => 'test::root_test', 'tip' => 'test::tip_test' }
        +               syskit_stub_conf OroGen.robot_frames.SingleChainPublisher, 'default',
        +                   data: { 'chain' => Hash['root_link' => 'test::root_test', 'tip_link' => 'test::tip_test'] }
        +           end
        -               cmp = syskit_stub_deploy_configure_and_start(
        -                   ArmCartesianConstantControlWdls.with_arguments(setpoint: setpoint))
        +               cmp_task = syskit_stub_deploy_configure_and_start(
        +                   ArmCartesianConstantControlWdls.with_arguments(
        +                       setpoint: setpoint, robot: @profile))
        """
        Then the "gazebo" configuration is valid for Syskit
