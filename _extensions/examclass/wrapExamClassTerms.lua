-- This file combines three operations:
-- 1. Convert LaTeX environments to fenced Divs (original functionality)
-- 2. Flatten cell-output-display divs within solution divs
-- 3. Convert exam-prefixed Div environments back to raw LaTeX
-- DEBUG: This is the CURRENT VERSION with Div conversion logic

io.stderr:write("=== LOADING CURRENT VERSION OF wrapExamClassTerms.lua ===\n")
local environments = {"questions", "parts", "subparts", "subsubparts", "solution", "coverpages", "EnvFullwidth", "choices", "checkboxes", "multicolcheckboxes"}

-- Helper function to convert exam-prefixed Div environments back to raw LaTeX
local function convert_exam_div_to_latex(el)
    -- Check if this is an exam-prefixed environment
    for _, env in ipairs(environments) do
        if el.classes:includes("exam-" .. env) then
            -- Debug: print what we're converting
            io.stderr:write("Converting exam-" .. env .. " to LaTeX\n")
            
            -- Extract optional arguments from data-opts attribute
            local opts = ""
            if el.attr and el.attr.attributes and el.attr.attributes["data-opts"] then
                opts = "[" .. el.attr.attributes["data-opts"] .. "]"
            end
            
            -- Insert \begin{env}[opts] at the beginning
            table.insert(el.content, 1, pandoc.RawBlock("latex", "\\begin{" .. env .. "}" .. opts))
            
            -- Insert \end{env} at the end
            table.insert(el.content, pandoc.RawBlock("latex", "\\end{" .. env .. "}"))
            
            -- Return the modified div
            return el
        end
    end
    
    -- Return unchanged if not an exam environment
    return el
end

local function processRawBlocks(el)
    if el.format == "tex" then
        -- Check if it's the start of a "questions" environment
        local begin_pattern = "\\begin{questions}"
        local end_pattern = "\\end{questions}"
        if el.text:match("^" .. begin_pattern) then
            -- Find the end of the environment
            local content_start = #begin_pattern + 1
            local content_end = el.text:find(end_pattern, content_start)
            if content_end then
                local content = el.text:sub(content_start, content_end - 1)

                -- Surround \part commands with backticks and {=latex}
                -- Use word boundary to ensure we only match \part as a complete command
                content = content:gsub("(\\part%b[])", "`%1`{=latex}")
                content = content:gsub("(\\part)([%s{}])", "`%1`{=latex}%2")  -- Only match when followed by space or brace

                -- Surround \titledquestion commands with backticks and {=latex}
                content = content:gsub("(\\titledquestion%b{}%b[])", "`%1`{=latex}")
                content = content:gsub("(\\titledquestion%b{})([^[])", "`%1`{=latex}%2")

                -- Loop through environments and surround \begin and \end with backticks
                for _, env in ipairs(environments) do
                    -- Handle \begin{env} with optional square bracket argument -> markdown fenced Div with attributes
                    content = content:gsub("\\begin{" .. env .. "}%b[]", function(matched)
                        local opt = matched:match("%[(.*)%]") or ""
                        local attr = opt ~= "" and (" data-opts=\"" .. opt .. "\"") or ""
                        return "\n::: {.exam-" .. env .. attr .. "}\n"
                    end)
                    -- Handle \begin{env} without square brackets -> markdown fenced Div
                    content = content:gsub("(\\begin{" .. env .. "})([^[])", function(_, following)
                        return "\n::: {.exam-" .. env .. "}\n" .. following
                    end)
                    -- Handle \end{env} -> closing markdown fence
                    content = content:gsub("\\end{" .. env .. "}", "\n:::\n")

                end

  
                -- Process the content inside the environment
                local processed_content = pandoc.read(content, "markdown").blocks
                -- Wrap the processed content with the environment tags
                table.insert(processed_content, 1, pandoc.RawBlock("tex", begin_pattern))
                table.insert(processed_content, pandoc.RawBlock("tex", end_pattern))
                return processed_content
            end
        end
    end
    -- If it's not a "questions" environment, return the original element
    return el
end

-- Function to flatten cell-output-display divs within solution divs
local function flatten_cell_output_divs(div, is_within_solution)
    local within_solution = is_within_solution or div.classes:includes("solution")
    
    if div.t == "Div" then
        local processed_content = {}
        
        for _, block in ipairs(div.content) do
            if block.t == "Div" then
                if block.classes:includes("cell-output-display") and within_solution then
                    -- Flatten the cell-output-display div by adding its content directly
                    for _, inner_block in ipairs(block.content) do
                        table.insert(processed_content, inner_block)
                    end
                else
                    -- Recursively process other divs
                    local processed_block = flatten_cell_output_divs(block, within_solution)
                    table.insert(processed_content, processed_block)
                end
            else
                -- Keep non-div blocks as-is
                table.insert(processed_content, block)
            end
        end
        
        return pandoc.Div(processed_content, div.attr)
    end
    
    return div
end

-- Document-level processing to flatten cell-output-display divs and convert exam Divs to LaTeX
local function process_document(doc)
    io.stderr:write("process_document called\n")
    local processed_blocks = {}
    
    for _, block in ipairs(doc.blocks) do
        if block.t == "Div" then
            io.stderr:write("Processing Div with classes: " .. table.concat(block.classes, ", ") .. "\n")
            -- First flatten cell-output-display divs
            local flattened_block = flatten_cell_output_divs(block)
            -- Then convert exam-prefixed divs to LaTeX
            local final_block = convert_exam_div_to_latex(flattened_block)
            table.insert(processed_blocks, final_block)
        else
            table.insert(processed_blocks, block)
        end
    end
    
    return pandoc.Pandoc(processed_blocks, doc.meta)
end

-- Apply all functions
return {
    {Pandoc = process_document, RawBlock = processRawBlocks}
}
