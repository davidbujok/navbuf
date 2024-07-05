local M = {}

local popup = require("plenary.popup")
local buffer_list = {}
local Win_id

-- Extract file names from a given mark
function GetFileNameFromMark(mark)
    local path = vim.api.nvim_get_mark(mark, {})[4]

    if not path then
        return
    end

    local filename = path:match("([^/]+)$")
    if filename then
        return filename
    else
        return
    end
end

-- Create a table with capital lettters
function M.getAllCapitalMarks()
    local capitalLetters = {}

    for i = 65, 90 do
        table.insert(capitalLetters, string.char(i))
    end

    return capitalLetters
end

-- Insert the filename into bufferlist
function InsertModifiedFilenameIntoBuffer(mark, fileName)

    local modifiedString = mark .. "   " .. fileName
    table.insert(buffer_list, modifiedString)
end

function M.loadFileNamesForCapitalMarks()
    local capitalMarks = M.getAllCapitalMarks()

    local fileNames = {}
    for _, mark in ipairs(capitalMarks) do
        local fileName = GetFileNameFromMark(mark)

        if fileName then
            fileNames[string.lower(mark)] = fileName
        else
        end
    end

    return fileNames
end

function M.PopulateBufferList()
    local fileNames = M.loadFileNamesForCapitalMarks()

    for mark, fileName in pairs(fileNames) do
        InsertModifiedFilenameIntoBuffer(mark, fileName)
    end
end


-- Show popup menu
function ShowMenu(buffer_list, last_buf)
    local height = 10

    -- Get the dimensions of the current Neovim window
    local win_width = vim.api.nvim_get_option_value('columns', {})
    local win_height = vim.api.nvim_get_option_value('lines', {})
    local curr_width = vim.api.nvim_win_get_width(0)

    -- Calculate the center position
    local col = math.floor((win_width - curr_width) / 2)
    local line = win_height - height

    Win_id = popup.create(buffer_list, {
        pos = "center",
        minwidth = curr_width,
        minheight = height,
        col = col + 1,
        line = line,
    })
    local bufnr = vim.api.nvim_win_get_buf(Win_id)

    for _, value in ipairs(buffer_list) do
        local mark = string.sub(value, 1, 1)
        local capitalMark = string.upper(mark)
        local cmd = string.format(":lua SwitchBuffer('%s', '%d')<CR>", capitalMark, bufnr)
        local lhs = mark
        vim.api.nvim_buf_set_keymap(bufnr, 'n', lhs, cmd, { noremap = true, silent = true })
    end

    local cmd = string.format("<CMD>lua CloseMenu()<CR>")
    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", cmd, { silent = false, desc = "Quit"} )
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<ESC>", cmd, { silent = false, desc = "Quit"} )
end

-- Close popup menu
function CloseMenu()
    vim.api.nvim_win_close(Win_id, true)
    P(buffer_list)
end

-- Switch Buffers
function SwitchBuffer(mark, last_buf)
    local mark_path = vim.api.nvim_get_mark(mark, {})[4]
    local function edit()
        vim.api.nvim_command('edit ' .. mark_path)
    end
    vim.api.nvim_win_close(Win_id, true)
    edit()
end

-- Start Plugin
function MyMenu()
    buffer_list = {}
    M.PopulateBufferList()
    local last_buf = vim.api.nvim_get_current_buf()
    ShowMenu(buffer_list, last_buf)
end

vim.api.nvim_set_keymap("n", "'", "<cmd>lua MyMenu()<CR>", { silent = false })
vim.api.nvim_set_keymap("n", "cm", "<cmd>lua MyMenu()<CR>", { silent = false })


return M
