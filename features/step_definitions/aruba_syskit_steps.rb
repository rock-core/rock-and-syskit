Then(/^the file "([^"]+)" is valid for Syskit$/) do |path|
    step("within the workspace, I successfully run the following script:", "syskit check . '#{path}'")
end

Then(/^the file "([^"]+)" is valid for Syskit in configuration "([^"]+)"$/) do |path, conf_name|
    step("within the workspace, I successfully run the following script:", "syskit check -r #{conf_name} . '#{path}'")
end

Then(/^the "([^"]+)" configuration is valid for Syskit$/) do |conf_name|
    step("within the workspace, I successfully run the following script:", "syskit check -r '#{conf_name}'")
end

Then(/^the syskit test file "([^"]+)" passes$/) do |path|
    step("within the workspace, I successfully run the following script:", "syskit test '#{path}'")
end

