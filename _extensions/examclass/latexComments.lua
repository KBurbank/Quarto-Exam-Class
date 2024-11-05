-- This file is used to find lines in a Markdown document which begin with a percent sign (%), and mark these lines as inline LaTeX so that Pandoc will process them as LaTeX comments.

function Para(el)
    return pandoc.Para(findLatexComments(el))
end

function Plain(el)
    return pandoc.Plain(findLatexComments(el))
end

function Math(el)
   -- Check if el is valid and has text property
   if el and el.text then
    if el.text:match("^%s%%") then
        io.stderr:write("We have a comment in math" .. el.text)
        return(pandoc.RawInline("tex", el.text))
    else
      return el
   end
end
end


function findLatexComments(block)
    local to_return = {}
    local in_comment = false
    for _, el in ipairs(block.content) do
        if el.t == "Str" and el.text:match("^%%") then
            in_comment = true
        end
        if in_comment then
            if el.text then
                table.insert(to_return, pandoc.RawInline("tex", el.text))
            elseif el.t == "Space" then
                table.insert(to_return, pandoc.RawInline("tex", " "))
            elseif el.t == "SoftBreak" then
                in_comment = false
                table.insert(to_return, pandoc.RawInline("tex", "\n"))
            end
        else
            table.insert(to_return, el)
        end
    end
    return to_return
end
