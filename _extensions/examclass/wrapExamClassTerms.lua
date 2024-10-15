local environments = {"questions", "parts", "subparts", "subsubparts", "solution", "coverpages", "EnvFullwidth", "choices", "checkboxes", "multicolcheckboxes"}

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
                content = content:gsub("(\\part%b[])", "`%1`{=latex}")
                content = content:gsub("(\\part)([^[])", "`%1`{=latex}%2")

                -- Surround \titledquestion commands with backticks and {=latex}
                content = content:gsub("(\\titledquestion%b{}%b[])", "`%1`{=latex}")
                content = content:gsub("(\\titledquestion%b{})([^[])", "`%1`{=latex}")

                -- Loop through environments and surround \begin and \end with backticks
                for _, env in ipairs(environments) do
                    -- Handle \begin{env} with optional square bracket argument
                    content = content:gsub("(\\begin{" .. env .. "}%b[])", "`%1`{=latex}")
                    -- Handle \begin{env} without square brackets
                    content = content:gsub("(\\begin{" .. env .. "})([^[])", "`%1`{=latex}%2")
                    -- Handle \end{env}
                    content = content:gsub("(\\end{" .. env .. "})", "`%1`{=latex}")

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

-- Apply the function to all RawBlocks
return {
    {RawBlock = processRawBlocks}
}
