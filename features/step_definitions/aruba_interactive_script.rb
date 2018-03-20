default_answer_timeout = 5

When(/^I run the following (?:commands|script)(?: (?:with|in) `([^`]+)`)? in background:$/) do |shell, commands|
  prepend_environment_variable('PATH', expand_path('bin') + File::PATH_SEPARATOR)

  Aruba.platform.mkdir(expand_path('bin'))
  shell ||= Aruba.platform.default_shell

  Aruba::ScriptFile.new(:interpreter => shell, :content => commands,
                        :path => expand_path('bin/myscript')).call
  step 'I run `myscript` in background'
end

When(/^I run the following (?:commands|script)(?: (?:with|in) `([^`]+)`)? interactively:$/) do |shell, commands|
  prepend_environment_variable('PATH', expand_path('bin') + File::PATH_SEPARATOR)

  Aruba.platform.mkdir(expand_path('bin'))
  shell ||= Aruba.platform.default_shell

  Aruba::ScriptFile.new(:interpreter => shell, :content => commands,
                        :path => expand_path('bin/myscript')).call
  step 'I run `myscript` interactively'
end

When(/^I successfully run the following (?:commands|script)(?: for up to (\d+) seconds)?:$/) do |timeout, commands|
  prepend_environment_variable('PATH', expand_path('bin') + File::PATH_SEPARATOR)

  Aruba.platform.mkdir(expand_path('bin'))
  shell ||= Aruba.platform.default_shell

  Aruba::ScriptFile.new(:interpreter => shell, :content => commands,
                        :path => expand_path('bin/myscript')).call

  timeout = aruba.config.exit_timeout if timeout == 0
  step "I successfully run `myscript` for up to #{timeout} seconds"
end

When(/^I answer "([^"]*)" to "([^"]+)"(?: from (\w+))?$/) do |answer, question, channel|
    step "I wait for #{channel || 'stdout'} to have \"#{question}\""
    step "I type \"#{answer}\""
end

When(/^the default answer timeout is (\d+) seconds$/) do |timeout|
    default_answer_timeout = Integer(timeout)
end

When(/^I wait for (stdout|stderr) to have "([^"]+)"(?: within (\d+) seconds)?$/) do |channel, pattern_string, timeout|
    commands = all_commands
    if commands.empty?
        raise "no commands in the background"
    end
    if !timeout || timeout == 0
        timeout = default_answer_timeout
    end
    deadline = Time.now + Integer(timeout)
    pattern  = Regexp.new(Regexp.quote(pattern_string))
    while true
      combined_output = commands.map do |c|
        c.send(channel.to_sym, wait_for_io: 0).chomp
      end.join("\n")
      if combined_output =~ pattern
        break
      elsif commands.all? { |c| c.stopped? }
        step "stdout should contain \"#{pattern_string}\""
      elsif Time.now > deadline
          raise "timed out (#{timeout} seconds) while waiting for #{combined_output} to contain #{pattern_string}"
      end
      sleep 0.1
    end
end

When(/^(stdout|stderr) gets "([^"]+)"(?: within (\d+) seconds)?$/) do |channel, pattern_string, timeout|
    if !timeout || timeout == 0
        step "I wait for #{channel} to have \"#{pattern_string}\""
    else
        step "I wait for #{channel} to have \"#{pattern_string}\" within #{timeout} seconds"
    end
end
