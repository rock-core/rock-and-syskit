def make_workspace_script(script)
"#! /bin/bash -e
source #{File.join(Aruba.config.root_directory, Aruba.config.working_directory, "dev", "env.sh")}
#{script}"
end

Then(/^within the workspace, I run the following script in background:$/) do |script|
    step "I run the following script in background:", make_workspace_script(script)
end

Then(/^within the workspace, I run the following script interactively:$/) do |script|
    step "I run the following script interactively:", make_workspace_script(script)
end

Then(/^within the workspace, I successfully run the following script for up to (\d+) seconds:$/) do |timeout, script|
    step "I successfully run the following script for up to #{timeout} seconds:", make_workspace_script(script)
end

Then(/^within the workspace, I successfully run the following script:$/) do |script|
    step "I successfully run the following script:", make_workspace_script(script)
end

