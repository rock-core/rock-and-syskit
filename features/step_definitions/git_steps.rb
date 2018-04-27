
def aruba_git_path(name)
    File.join(aruba.config.root_directory,
        aruba.config.working_directory, "git", "#{name}.git")
end

Given("a git repository {string}") do |repo_name|
    git_path = aruba_git_path(repo_name)
    FileUtils.mkdir_p File.dirname(git_path)
    step("I run `git --git-dir '#{git_path}' init`")
end

When("I push {string} to {string}") do |branch, repo_name|
    git_path = aruba_git_path(repo_name)
    step("I run `git push --tags '#{git_path}' '#{branch}'`")
end