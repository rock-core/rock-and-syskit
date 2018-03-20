require 'aruba/cucumber'
Aruba.configure do |config|
    checkout_name = File.basename(config.root_directory)
    config.exit_timeout = 60
    config.io_wait_timeout = 60
    config.root_directory = File.expand_path("../", config.root_directory)
    config.working_directory = "#{checkout_name}-dev"
end
