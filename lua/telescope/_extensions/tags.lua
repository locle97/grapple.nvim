local Grapple = require("grapple")

local function create_finder()
    local tags, err = Grapple.tags()
    if not tags then
        ---@diagnostic disable-next-line: param-type-mismatch
        return vim.notify(err, vim.log.levels.ERROR)
    end

    local results = {}
    for i, tag in ipairs(tags) do
        ---@class grapple.telescope.result
        local result = {
            i,
            tag.path,
            (tag.cursor or { 1, 0 })[1],
            (tag.cursor or { 1, 0 })[2],
        }

        table.insert(results, result)
    end

    return require("telescope.finders").new_table({
        results = results,

        ---@param result grapple.telescope.result
        entry_maker = function(result)
            local utils = require("telescope.utils")

            local index = result[1]
            local filename = result[2]
            local lnum = result[3]

            local entry = {
                value = result,
                ordinal = filename,
                filename = filename,
                lnum = lnum,
                index = index,
                path = filename,
                display = function(entry)
                    local hl = {}
                    local relative_path = utils.transform_path({ path_display = { "truncate" } }, entry.filename)
                    local filename_only = vim.fn.fnamemodify(entry.filename, ":t")
                    local display_str = string.format("[%d] %s %s", entry.index, filename_only, relative_path)
                    local filename_start = string.len(string.format("[%d] ", entry.index))
                    local filename_end = filename_start + string.len(filename_only)

                    -- Highlight filename in bold
                    table.insert(hl, { { filename_start, filename_end }, "TelescopeResultsIdentifier" })
                    -- Highlight path in comment color
                    table.insert(hl, { { filename_end + 1, string.len(display_str) }, "Comment" })

                    return display_str, hl
                end,
            }

            return entry
        end,
    })
end

local function delete_tag(prompt_bufnr)
    local action_state = require("telescope.actions.state")
    local selection = action_state.get_selected_entry()

    Grapple.untag({ path = selection.filename })

    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:refresh(create_finder(), { reset_prompt = true })
end

return function(opts)
    local conf = require("telescope.config").values

    require("telescope.pickers")
        .new(opts or {}, {
            finder = create_finder(),
            sorter = conf.file_sorter({}),
            previewer = conf.grep_previewer({}),
            results_title = "Grapple Tags",
            prompt_title = "Find Grappling Tags",
            layout_strategy = "flex",
            attach_mappings = function(_, map)
                map("i", "<C-X>", delete_tag)
                map("n", "<C-X>", delete_tag)
                return true
            end,
        })
        :find()
end
