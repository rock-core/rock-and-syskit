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

def save_state_as_git_tag(tag_name, path)
    git_dir = File.join(path, ".git")
    if !File.directory?(git_dir)
        if !system("git init", chdir: path, out: :close)
            raise "Failed to create the git repository in #{path}"
        end
    end
    if !system("git add .", chdir: path, out: :close) || !system("git commit --allow-empty -m '#{tag_name}'", chdir: path, out: :close)
        raise "Failed to commit the current state"
    end
    if !system("git tag -f '#{tag_name}'", chdir: path, out: :close)
        raise "Failed to create the git repository in #{git_dir}"
    end
end

After do |scenario|
    if scenario.passed?
        tag_name = "#{scenario.feature.name} - #{scenario.name}".gsub(/[^\w]+/, '_')
        bundle_path = File.join(aruba.config.root_directory, aruba.config.working_directory, "dev", "bundles", "syskit_basics")
        if File.directory?(bundle_path)
            save_state_as_git_tag(tag_name, bundle_path)
        end
    end
end
