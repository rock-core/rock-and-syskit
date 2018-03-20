class LineNotFound < RuntimeError; end
def patch_find_line(content, current, line)
  while current < content.size
    return current if content[current].strip == line
    current += 1
  end
  raise LineNotFound, "cannot find #{line}"
end

def patch_file(file_content, patch_content)
  output_file = []
  current_index = 0
  file_content = file_content.split("\n")
  patch_content.split("\n").each do |line|
    if line.start_with?("+")
      new_content = line[1..-1]
      if file_content[current_index].strip != new_content.strip
        output_file << new_content
      end
    elsif line.start_with?("-")
      new_index = patch_find_line(file_content, current_index, line[1..-1].strip)
      output_file.concat(file_content[current_index...new_index])
      current_index = new_index + 1
    else
      new_index = patch_find_line(file_content, current_index, line.strip)
      output_file.concat(file_content[current_index..new_index])
      current_index = new_index + 1
    end
  end
  output_file.concat(file_content[current_index..-1])
  output_file.join("\n")
end

Given(/^(?:that )?I modify (?:a|the) file(?: named)? "([^"]*)" with:$/) do |file_name, patch_content|
  with_file_content expand_path(file_name) do |file_content|
    overwrite_file(file_name, patch_file(file_content, patch_content))
  end
end
