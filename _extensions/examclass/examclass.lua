-- This script is used to process LaTeX commands corresponding to the LaTex exam class in a Pandoc filter. It is needed because Pandoc interprets content inside unknown LaTeX environments as verbatim Tex, which means it will miss code chunks and other RMarkdown features. It also misinterprets the "part" command, since this has other uses in LaTex.
-- The script works by finding the specific environments used by the Exam class and manually processing the content of these environments using the usual Markdown reader.
-- It also processes the "part" command and marks it as raw inline (as well as "question", "subpart" and "titledquestion").

local environments = {"questions", "parts", "subparts", "solution"}
local commands = { "part","question", "subpart","titledquestion"}
local MAX_DEPTH = 5

function RawBlock(el)
    if el.format == "tex" then
        return process_element(el, 0)
    end
    return el
end

function Para(el)
    return pandoc.Div(split_latex_lines(el.content))
end

function Plain(el)
    return pandoc.Div(split_latex_lines(el.content))
end

function process_inline_container(el, depth)
    if depth >= MAX_DEPTH then
        return el
    end

    local result = {}
    local i = 1
    while i <= #el.content do
        local inline = el.content[i]
        if (inline.t == "RawInline" or inline.t == "Str")  then
            local command_found = false
            for _, cmd in ipairs(commands) do
                local cmd_pattern = '\\' .. cmd
                if starts_with(cmd_pattern, inline.text) then
                    local command_text = inline.text
                    local j = i + 1
                    while j <= #el.content do
                        local next_inline = el.content[j]
                        if next_inline.t == "Str" and (next_inline.text:match("^%[") or next_inline.text:match("^{")) then
                            command_text = command_text .. next_inline.text
                            j = j + 1
                        else
                            break
                        end
                    end
                    local processed = process_element({text = command_text, format = "tex"}, depth + 1)
                    if type(processed) == "table" then
                        for _, p in ipairs(processed) do
                            table.insert(result, p)
                        end
                    else
                        table.insert(result, processed)
                    end
                    i = j - 1
                    command_found = true
                    break
                end
            end
            if not command_found then
                table.insert(result, inline)
            end
        else
            table.insert(result, inline)
        end
        i = i + 1
    end
    return el.t == "Para" and pandoc.Para(result) or pandoc.Plain(result)
end

function process_element(el, depth)
    if depth >= MAX_DEPTH then
        return el
    end
    -- Check for environments

    for _, env in ipairs(environments) do
        local begin_pattern = '\\begin{' .. env .. '}'
        local end_pattern = '\\end{' .. env .. '}'
        if starts_with(begin_pattern, el.text) then
            local content_start = #begin_pattern + 1
            local optional_arg = ''
            
            -- Check for optional argument
            if el.text:sub(content_start, content_start) == '[' then
                local close_bracket = el.text:find(']', content_start)
                if close_bracket then
                    optional_arg = el.text:sub(content_start, close_bracket)
                    content_start = close_bracket + 1
                end
            end
            
            if ends_with(end_pattern, el.text) then
                local content = el.text:sub(content_start, -#end_pattern - 1)
                return process_content(begin_pattern .. optional_arg, content, end_pattern, depth + 1)
            end
        end
    end

    
    -- Check for commands
    for _, cmd in ipairs(commands) do
        local cmd_pattern = '\\' .. cmd
        if starts_with(cmd_pattern, el.text) then
            local cmd_end, content_start = find_command_end(el.text, #cmd_pattern + 1)
            local command_with_args = el.text:sub(1, cmd_end)
            local content = el.text:sub(content_start)
            return process_content(command_with_args, content, nil, depth + 1)
        end
    end
    
    return el
end

function find_command_end(text, start_pos)
    local pos = start_pos
    local bracket_stack = {}
    local in_curly = false
    local in_square = false

    while pos <= #text do
        local char = text:sub(pos, pos)
        if char == '{' then
            table.insert(bracket_stack, '}')
            in_curly = true
        elseif char == '['  then
            table.insert(bracket_stack, ']')
            in_square = true
        elseif char == '}' or char == ']' then
            if #bracket_stack > 0 and bracket_stack[#bracket_stack] == char then
                table.remove(bracket_stack)
                if #bracket_stack == 0 then
                    in_curly = false
                    in_square = false
                end
            else
                break
            end
        elseif #bracket_stack == 0 and not (in_curly or in_square) and char:match('%s') then
                break
        end
        pos = pos + 1
    end

    return pos - 1, pos
end

function process_content(begin_text, content, end_text, depth)
    local parsed = pandoc.read(content, "markdown").blocks
    local result = {pandoc.RawInline("tex", begin_text)}
    for _, block in ipairs(parsed) do
        if block.t == "RawBlock" and block.format == "tex" then
            local processed = process_element(block, depth)
            if type(processed) == "table" then
                for _, p in ipairs(processed) do
                    table.insert(result, p)
                end
            else
                table.insert(result, processed)
            end
        elseif block.t == "Para" or block.t == "Plain" then
            local processed = process_inline_container(block, depth)
            if type(processed) == "table" then
                for _, p in ipairs(processed.content) do
                    table.insert(result, p)
                end
            else
                table.insert(result, processed)
            end
        else
            table.insert(result, block)
        end
    end
    if end_text then
        table.insert(result, pandoc.RawInline("tex", end_text))
    end
    return result
end

function starts_with(start, str)
    return str:sub(1, #start) == start
end

function ends_with(ending, str)
    return ending == "" or str:sub(-#ending) == ending
end

function process_latex_comments(el)
    local result = {}
    local current_latex_comment = nil

    for _, inline in ipairs(el.content) do
        if inline.t == "Str" and inline.text:match("^%%") then
            -- Start or continue a LaTeX comment
            if current_latex_comment then
                current_latex_comment.text = current_latex_comment.text .. " " .. inline.text
            else
                current_latex_comment = pandoc.RawInline("tex", inline.text)
            end
        else
            -- End the current LaTeX comment if exists
            if current_latex_comment then
                table.insert(result, current_latex_comment)
                current_latex_comment = nil
            end
            table.insert(result, inline)
        end
    end

    -- Add any remaining LaTeX comment
    if current_latex_comment then
        table.insert(result, current_latex_comment)
    end

    return el.t == "Para" and pandoc.Para(result) or pandoc.Plain(result)
end

function Block(el)
    if el.t == "Para" or el.t == "Plain" then
        local new_content = {}
        for i, inline in ipairs(el.content) do
            if inline.t == "Str" and inline.text:match("^%%") then
                -- This is a % at the start of a line, treat it as raw LaTeX
                table.insert(new_content, pandoc.RawInline("tex", inline.text))
            else
                table.insert(new_content, inline)
            end
        end
        return el.t == "Para" and pandoc.Para(new_content) or pandoc.Plain(new_content)
    end
    return el
end

function Str(el)
    if el.text:match("^%%") then
        return pandoc.RawInline("tex", el.text)
    end
    return el
end

function split_latex_lines(content)
    local result = {}
    local current_line = {}
    local in_latex = false

    for _, inline in ipairs(content) do
        if inline.t == "SoftBreak" or inline.t == "LineBreak" then
            -- End the current line
            if in_latex then
                table.insert(result, pandoc.RawBlock("tex", table.concat(current_line, "")))
            elseif #current_line > 0 then
                table.insert(result, pandoc.Plain(current_line))
            end
            current_line = {}
            in_latex = false
            table.insert(result, inline)
        elseif #current_line == 0 and inline.t == "Str" and (inline.text:match("^%%") or inline.text:match("^\\")) then
            -- Start a new latex line
            in_latex = true
            table.insert(current_line, inline)
        else
            -- Continue the current line
            table.insert(current_line, inline)
        end
    end

    -- Add any remaining content
    if #current_line > 0 then
        if in_latex then
            table.insert(result, pandoc.RawBlock("tex", table.concat(current_line, "")))
        else
            table.insert(result, pandoc.Plain(current_line))
        end
    end

    return result
end

function is_latex_line(inlines)
    local first = inlines[1]
    return first and first.t == "Str" and (first.text:match("^%%") or first.text:match("^\\"))
end

function convert_to_raw_tex(inlines)
    local tex = {}
    for _, inline in ipairs(inlines) do
        table.insert(tex, pandoc.utils.stringify(inline))
    end
    return pandoc.RawBlock("tex", table.concat(tex, ""))
end

function Pandoc(doc)
    local new_blocks = {}
    for _, block in ipairs(doc.blocks) do
        if block.t == "Para" or block.t == "Plain" then
            if is_latex_line(block.content) then
                table.insert(new_blocks, convert_to_raw_tex(block.content))
            else
                table.insert(new_blocks, block)
            end
        else
            table.insert(new_blocks, block)
        end
    end
    return pandoc.Pandoc(new_blocks, doc.meta)
end
