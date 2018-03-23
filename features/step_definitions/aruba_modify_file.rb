class LineNotFound < RuntimeError; end
def patch_find_line(content, current, line)
    while current < content.size
        return current if content[current] == line
        current += 1
    end
    raise LineNotFound, "cannot find #{line.inspect}"
end

def patched_line_content(line)
    content = line[1..-1]
    if content.start_with?(" ")
        " #{content}"
    else
        content
    end
end

def patch_file(file_content, patch_content)
    output_file = []
    current_index = 0
    ellipsis = false
    last_op = nil
    file_content = file_content.split("\n")
    patch_content.split("\n").each do |line|
        if line.start_with?("+")
            raise "ellipsis can only be used between to - lines" if ellipsis
            output_file << patched_line_content(line)
        elsif line.start_with?("-")
            new_index = patch_find_line(file_content, current_index,
                patched_line_content(line))
            unless ellipsis
                output_file.concat(file_content[current_index...new_index])
            end
            current_index = new_index + 1
            ellipsis = false
            last_op = "-"
        elsif line.strip == "..."
            raise "ellipsis can only be used between to - lines (#{last_op})" if last_op != "-"
            ellipsis = true
        else
            raise "ellipsis can only be used between to - lines (#{last_op})" if ellipsis
            new_index = patch_find_line(file_content, current_index, line)
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
