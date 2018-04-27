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

Before('@clobber-git') do |scenario|
    FileUtils.rm_rf File.join(
        aruba.config.root_directory, aruba.config.working_directory, "git")
    FileUtils.rm_rf File.join(
        aruba.config.root_directory, aruba.config.working_directory, "dev",
            '.autoproj', 'remotes',
            "git__home_doudou_dev_rock_and_syskit_dev_dev____"\
            "git_rock_rock_and_syskit_package_set_git")
end

Before('@clobber-new_package_set') do |scenario|
    FileUtils.rm_rf File.join(
        aruba.config.root_directory, aruba.config.working_directory, "new_package_set")
end

After do |scenario|
    autoproj_config_dir = File.join(
        aruba.config.root_directory, aruba.config.working_directory, "dev", '.autoproj')
    if File.directory?(autoproj_config_dir)
        File.open(File.join(autoproj_config_dir, '.gitignore'), 'w') do |io|
            io.puts "remotes/"
        end
    end

    if scenario.passed?
        save_state_after_scenario(scenario.feature.name, scenario.name)
    end
end
