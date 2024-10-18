function Para(el)
    return pandoc.Para(findLatexComments(el))
end

function Plain(el)
    return pandoc.Plain(findLatexComments(el))
end



function findLatexComments(block)
    local contains_comment = false
    for i, el in ipairs(block.content) do
        if el.t == "Str" and el.text:match("^%%") then
            if i == 1 or (i > 1 and block.content[i-1].t == "SoftBreak") then
                -- Debug: Print the element type and content instead of using pandoc.write

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
            elseif item.t == "SoftBreak" then
                table.insert(result, pandoc.RawInline("tex", "\n"))
            else
                table.insert(result, item)
            end
        end
        table.insert(result, pandoc.SoftBreak())
        return result
    else
        return block.content
    end
end
