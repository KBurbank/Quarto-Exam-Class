-- This script is used to process LaTeX commands corresponding to the LaTex exam class in a Pandoc filter. It is needed because Pandoc interprets content inside unknown LaTeX environments as verbatim Tex, which means it will miss code chunks and other RMarkdown features. It also misinterprets the "part" command, since this has other uses in LaTex.
-- The script works by finding the specific environments used by the Exam class and manually processing the content of these environments using the usual Markdown reader.
-- It also processes the "part" command and marks it as raw inline (as well as "question", "subpart" and "titledquestion").

local environments = {"questions", "parts", "subparts", "subsubparts", "solution", "coverpages", "EnvFullwidth", "solution", "choices","checkboxes"}
local commands = { "part","question", "subpart","titledquestion", "subsubpart", "choice","CorrectChoice"}
local MAX_DEPTH = 5

function RawBlock(el)
    if el.format == "tex" then
        return identifyAndHandleLatexElement(el, 0)
    end
    return el
end


function Para(el)
    return pandoc.Para(findLatexComments(el))
end

function Plain(el)
    return pandoc.Plain(findLatexComments(el))
end


-- New unified function for processing commands
-- This function is used to find the command and its arguments in the text and to process the content of the command as Markdown.
function markdownifyCommandAndText(text, cmd_pattern, depth)
    if startsWithPattern(cmd_pattern, text) then
        local cmd_end, content_start = findCommandEnd(text, #cmd_pattern + 1)
        local command_with_args = text:sub(1, cmd_end)
        local textAfterCommand = text:sub(content_start)
        return reinterpretLatexContentAsMarkdown(command_with_args, textAfterCommand, nil, depth + 1)
    end
    return nil
end

-- Updated process_inline_container function
function traverseAndTransformInlineLatex(el, depth)
    -- Check if we've reached the maximum recursion depth
    if depth >= MAX_DEPTH then
        return el
    end

    local result = {}
    local i = 1
    while i <= #el.content do
        local inline = el.content[i]
        if inline.t == "Str" then
            -- Combine consecutive string elements to handle commands that might be split across them
            local command_text = inline.text
            local j = i + 1
            while j <= #el.content and el.content[j].t == "Str" do
                command_text = command_text .. el.content[j].text
                j = j + 1
            end
            
            -- Use the new helper function
            local parsedCommandAndFollowingText = findMatchingLatexCommand(command_text, depth)
            
            if parsedCommandAndFollowingText then
                -- If a command was found and processed, add the result to our output
                if type(parsedCommandAndFollowingText) == "table" then
                    for _, p in ipairs(parsedCommandAndFollowingText) do
                        table.insert(result, p)
                    end
                else
                    table.insert(result, parsedCommandAndFollowingText)
                end
                -- Skip over the strings we've just processed
                i = j - 1
            else
                -- If no command was found, just add the original string to the output
                table.insert(result, inline)
            end
        else
            -- For non-string elements, add them to the output unchanged
            table.insert(result, inline)
        end
        i = i + 1
    end
    
    -- Return a new Para or Plain element with our processed content
    return el.t == "Para" and pandoc.Para(result) or pandoc.Plain(result)
end

-- Updated process_element function
function identifyAndHandleLatexElement(el, depth)
    if depth >= MAX_DEPTH then
        return el
    end
    
    -- Check for environments
    local begin_pattern, optional_arg, content, end_pattern = findMatchingLatexEnvironment(el)
    if begin_pattern then
        return reinterpretLatexContentAsMarkdown(begin_pattern .. optional_arg, content, end_pattern, depth + 1)
    end

    -- Check for commands
    local processed = findMatchingLatexCommand(el.text, depth)
    if processed then return processed end
    
    return el
end



function reinterpretLatexContentAsMarkdown(begin_text, content, end_text, depth)
    local parsed = pandoc.read(content, "markdown").blocks
    local result = {pandoc.RawInline("tex", begin_text)}
    for _, block in ipairs(parsed) do
        if block.t == "RawBlock" and block.format == "tex" then
            local processed = identifyAndHandleLatexElement(block, depth)
            if type(processed) == "table" then
                for _, p in ipairs(processed) do
                    table.insert(result, p)
                end
            else
                table.insert(result, processed)
            end
        elseif block.t == "Para" or block.t == "Plain" then
            local processed = traverseAndTransformInlineLatex(block, depth)
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


-- Check whether a block contains a Latex comment, i.e. a line starting with %. If it does, return a RawBlock with the content of the block, otherwise return the block.
-- This is needed because Pandoc doesn't automatically Latex comments in Markdown code, and it escapes the % automatically..

function findLatexComments(block)
    contains_comment = false
    for i, el in ipairs(block.content) do
        if el.t == "Str" and el.text:match("^%%") then
            if i == 1 or (i > 1 and block.content[i-1].t == "SoftBreak") then
                contains_comment = true
            end
        end
    end
    if contains_comment then
        local result = {}
        
        for _, item in ipairs(block.content) do
            if item.t == "Str" then
                table.insert(result, pandoc.RawInline("tex", item.text))
            elseif item.t == "Space" then
                table.insert(result, pandoc.RawInline("tex", " "))
            else
                table.insert(result, item)
            end
        end
        return result
    else
        return block.content
    end
end

-- New helper function
function findMatchingLatexCommand(text, depth)
    for _, cmd in ipairs(commands) do
        local processed = markdownifyCommandAndText(text, '\\' .. cmd, depth)
        if processed then
            return processed
        end
    end
    return nil
end

-- New function to check for LaTeX environments
function findMatchingLatexEnvironment(el, depth)
    for _, env in ipairs(environments) do
        local begin_pattern = '\\begin{' .. env .. '}'
        local end_pattern = '\\end{' .. env .. '}'
        if startsWithPattern(begin_pattern, el.text) then
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
            
            if endsWithPattern(end_pattern, el.text) then
                local content = el.text:sub(content_start, -#end_pattern - 1)
                return begin_pattern, optional_arg, content, end_pattern
            end
        end
    end
    return nil
end


-- Utility

function findCommandEnd(text, start_pos)
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


function startsWithPattern(start, str)
    return str:sub(1, #start) == start
end

function endsWithPattern(ending, str)
    return ending == "" or str:sub(-#ending) == ending
end
