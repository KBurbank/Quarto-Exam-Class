-- This filter handles cell outputs inside solution environments
-- It runs after wrapExamClassTermsOld.lua which processes the questions environment
--
-- For cells with layout attributes (panels), it splits the solution and wraps them with \ifprintanswers
-- For regular cells, it flattens cell-output-display divs

local function has_layout_attr(div)
    -- Check if this div has a layout attribute (indicates a panel)
    if div.attr and div.attr.attributes then
        return div.attr.attributes.layout ~= nil
    end
    return false
end

local function flatten_cell_content(content)
    -- Recursively flatten cell-output-display divs (for non-panel cells)
    local result = {}
    for _, block in ipairs(content) do
        if block.t == "Div" and block.classes[1] == "cell-output-display" then
            -- Flatten: add the contents of cell-output-display directly
            for _, inner in ipairs(block.content) do
                table.insert(result, inner)
            end
        elseif block.t == "Div" then
            -- Recursively process nested divs
            local flattened_content = flatten_cell_content(block.content)
            if #flattened_content > 0 then
                table.insert(result, pandoc.Div(flattened_content, block.attr))
            end
        else
            table.insert(result, block)
        end
    end
    return result
end

local function flatten_solutions(blocks)
    local result = {}
    local in_solution = false
    local solution_content = {}
    local solution_start_block = nil
    
    for i, block in ipairs(blocks) do
        -- Check if this Para contains a solution marker
        local is_begin_solution = false
        local is_end_solution = false
        
        if block.t == "Para" and #block.content > 0 then
            for _, inline in ipairs(block.content) do
                if inline.t == "RawInline" then
                    if inline.text:match("^\\begin{solution}") then
                        is_begin_solution = true
                    elseif inline.text:match("^\\end{solution}") then
                        is_end_solution = true
                    end
                end
            end
        end
        
        if is_begin_solution and is_end_solution then
            -- Both begin and end in same block - this is a complete solution in one paragraph
            -- Just pass it through unchanged
            io.stderr:write("Complete solution at block " .. i .. ", next block type: " .. (blocks[i+1] and blocks[i+1].t or "nil") .. "\n")
            table.insert(result, block)
        elseif is_begin_solution then
            in_solution = true
            solution_start_block = block
            solution_content = {}
        elseif is_end_solution then
            -- Process accumulated solution content
            local has_panel = false
            
            -- Check if any cell has a layout attribute
            for _, sol_block in ipairs(solution_content) do
                if sol_block.t == "Div" and sol_block.classes[1] == "cell" and has_layout_attr(sol_block) then
                    has_panel = true
                    break
                end
            end
            
            if has_panel then
                -- Split solution around panel cells
                table.insert(result, solution_start_block)  -- \begin{solution} with initial text
                
                for _, sol_block in ipairs(solution_content) do
                    if sol_block.t == "Div" and sol_block.classes[1] == "cell" and has_layout_attr(sol_block) then
                        -- Close solution, wrap panel in \ifprintanswers, reopen solution
                        table.insert(result, pandoc.Para({pandoc.RawInline("latex", "\\end{solution}")}))
                        table.insert(result, pandoc.RawBlock("latex", "\\ifprintanswers"))
                        table.insert(result, sol_block)
                        table.insert(result, pandoc.RawBlock("latex", "\\fi"))
                        table.insert(result, pandoc.Para({pandoc.RawInline("latex", "\\begin{solution}")}))
                    else
                        table.insert(result, sol_block)
                    end
                end
                
                table.insert(result, block)  -- Final \end{solution}
            else
                -- No panels, do regular flattening
                table.insert(result, solution_start_block)
                
                for _, sol_block in ipairs(solution_content) do
                    if sol_block.t == "Div" and sol_block.classes[1] == "cell" then
                        -- Flatten cell-output-display divs
                        local new_cell_content = flatten_cell_content(sol_block.content)
                        if #new_cell_content > 0 then
                            table.insert(result, pandoc.Div(new_cell_content, sol_block.attr))
                        end
                    else
                        table.insert(result, sol_block)
                    end
                end
                
                table.insert(result, block)  -- \end{solution}
            end
            
            in_solution = false
            solution_content = {}
            solution_start_block = nil
        elseif in_solution then
            table.insert(solution_content, block)
        else
            table.insert(result, block)
        end
    end
    
    return result
end

return {
    {Pandoc = function(doc)
        local processed_blocks = flatten_solutions(doc.blocks)
        return pandoc.Pandoc(processed_blocks, doc.meta)
    end}
}
