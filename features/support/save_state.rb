SAVED_REPOS = %w[.autoproj autoproj bundles/syskit_basics] unless defined? SAVED_REPOS

def tag_name_from_feature_and_scenario(feature, scenario)
    cleaned = [feature, scenario].
        map { |name| name.gsub(/[^\w]+/, '_') }
    cleaned.join('-')
end

def save_repo_state_as_git_tag(tag_name, path)
    git_dir = File.join(path, ".git")
    if !File.directory?(git_dir)
        if !system("git init", chdir: path, out: :close)
            raise "Failed to create the git repository in #{path}"
        end
    end
    commit_successful = system("git", "add", ".", chdir: path, out: :close) &&
        system("git", "commit", "--allow-empty", "-m", tag_name, chdir: path, out: :close)
    unless commit_successful
        raise "Failed to commit the current state"
    end
    if !system("git", "tag", "-f", tag_name, chdir: path, out: :close)
        raise "Failed to create the git repository in #{git_dir}"
    end
end

def find_expected_scenario(feature_file, scenario: ARGV[1])
    features = []
    File.readlines(feature_file).each do |line|
        line = line.strip
        if (feature_match = /^Feature:\s+(.*)$/.match(line))
            features << [feature_match[1], []]
        elsif (scenario_match = /^Scenario:\s+(.*)$/.match(line))
            features.last[1] << scenario_match[1]
        end
    end

    unless scenario
        feature, scenarios = features.first
        return [feature, scenarios.first]
    end

    rx = Regexp.new(scenario)

    all_matches = []
    features.each do |feature_names, scenarios|
        matches = scenarios.grep(rx)
        all_matches.concat(matches.map { |n| [feature_name, n] })
    end

    if all_matches.size == 1
        return all_matches.first
    else
        raise Ambiguous, "#{scenario} matches more than one scenario "\
            "in #{feature_file}: #{all_matches.map { |f, s| "#{f} - #{s}" }.join(", ")}"
    end
end

def save_state_after_scenario(feature, scenario)
    tag_name = tag_name_from_feature_and_scenario(feature, scenario)
    SAVED_REPOS.each do |name|
        full_path = File.join(
            aruba.config.root_directory,
            aruba.config.working_directory,
            "dev", name)
        if File.directory?(full_path)
            save_repo_state_as_git_tag(tag_name, full_path)
        end
    end
end

def restore_state_before_scenario(feature, scenario, base_path)
    scenario_tag_name = tag_name_from_feature_and_scenario(feature, scenario)
    SAVED_REPOS.each do |name|
        full_path = File.join(base_path, "dev", name)
        if File.directory?(full_path)
            repo_tags = IO.popen(["git", "--git-dir", "#{full_path}/.git", "tag"]) do |io|
                io.readlines.map(&:chomp).sort
            end
            unless $?.success?
                raise "failed to get tags from #{full_path}" 
            end
            _, tag_index = repo_tags.each_with_index.
                find { |a, i| a == scenario_tag_name } ||
                [nil, repo_tags.size]
            before_tag = repo_tags[tag_index - 1] if tag_index > 0
            if before_tag
                puts "resetting #{full_path} to #{before_tag}"
                puts "press ENTER to confirm"
                STDIN.readline
                reset_successful =
                    system("git", "reset", "--hard", before_tag,
                        chdir: full_path, out: :close) &&
                    system("git", "clean", "-fdx", before_tag,
                        chdir: full_path, out: :close)
                puts "FAILED" unless reset_successful
            else
                puts "no tag found before #{scenario_tag_name} in #{full_path}, deleting"
                puts "press ENTER to confirm"
                STDIN.readline
                FileUtils.rm_rf full_path
            end
        end
    end
end

