require_relative './save_state'
require 'aruba/cucumber'
Aruba.configure do |config|
    checkout_name = File.basename(config.root_directory)
    config.exit_timeout = 60
    config.io_wait_timeout = 60
    config.root_directory = File.expand_path("../", config.root_directory)
    config.working_directory = "#{checkout_name}-dev"
    if ENV['ARUBA_LOG_LEVEL']
        config.log_level = ENV['ARUBA_LOG_LEVEL'].to_sym
    end
end

After do |scenario|
    if scenario.passed?
        save_state_after_scenario(scenario.feature.name, scenario.name)
    end
end

