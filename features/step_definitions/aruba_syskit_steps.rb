Then(/^the file "([^"]+)" is valid for Syskit$/) do |path|
    step("within the workspace, I successfully run the following script:", "syskit check . '#{path}'")
end

Then(/^the file "([^"]+)" is valid for Syskit in configuration "([^"]+)"$/) do |path, conf_name|
    step("within the workspace, I successfully run the following script:", "syskit check -r #{conf_name} . '#{path}'")
end

Then(/^the "([^"]+)" configuration is valid for Syskit$/) do |conf_name|
    step("within the workspace, I successfully run the following script:", "syskit check -r '#{conf_name}'")
end

Then(/^the Syskit test file "([^"]+)" passes$/) do |path|
    step("within the workspace, I successfully run the following script:", "syskit test '#{path}'")
end

Then("the Syskit test file {string} fails") do |path|
    step("within the workspace, I run the following script:", "syskit test '#{path}'")
    step("the exit status should be 1")
end

Then("the Syskit test file {string} fails in configuration {string}") do |path, conf_name|
    step("within the workspace, I run the following script:", "syskit test -r #{conf_name} '#{path}'")
    step("the exit status should be 1")
end

Then("the tests matching {string} in the Syskit test file {string} pass") do |names, path|
    step("within the workspace, I successfully run the following script:", "syskit test '#{path}' -- '-n=#{names}'")
end

Then("the tests matching {string} in the Syskit test file {string} and configuration {string} pass") do |names, path, conf_name|
    step("within the workspace, I successfully run the following script:", "syskit test -r #{conf_name} '#{path}' -- '-n=#{names}'")
end

Then("the Syskit tests pass in configuration {string}") do |conf_name|
    step("within the workspace, I successfully run the following script:", "syskit test -r '#{conf_name}'")
end

Then("the Syskit tests fail in configuration {string}") do |conf_name|
    step("within the workspace, I run the following script:", "syskit test -r '#{conf_name}'")
    step("the exit status should be 1")
end

Then("the Syskit test file {string} passes in configuration {string}") do |path, conf_name|
    step("within the workspace, I successfully run the following script:", "syskit test -r '#{conf_name}' '#{path}'")
end

