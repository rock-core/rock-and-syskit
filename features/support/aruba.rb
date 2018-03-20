require 'aruba/cucumber'
Aruba.configure do |config|
    checkout_name = File.basename(config.root_directory)
    config.exit_timeout = 60
    config.io_wait_timeout = 60
    config.root_directory = File.expand_path("../", config.root_directory)
    config.working_directory = "#{checkout_name}-dev"
end

After do |scenario|
    if scenario.passed?
        bundle_path = File.join(aruba.config.root_directory, aruba.config.working_directory, "dev", "bundles", "syskit_basics")
        git_dir = File.join(bundle_path, ".git")
        if File.directory?(bundle_path) && !File.directory?(git_dir)
            if !system("git init", chdir: bundle_path, out: :close)
                raise "Failed to create the git repository in #{bundle_path}"
            end
        end

        tag_name = "#{scenario.feature.name} - #{scenario.name}".gsub(/\s/, '_')
        if !system("git add .", chdir: bundle_path, out: :close) || !system("git commit --allow-empty -m '#{tag_name}'", chdir: bundle_path, out: :close)
            raise "Failed to commit the current state"
        end
        if !system("git tag -f '#{tag_name}'", chdir: bundle_path, out: :close)
            raise "Failed to create the git repository in #{git_dir}"
        end
    end
end
