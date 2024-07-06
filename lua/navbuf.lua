local M = {}

local popup = require("plenary.popup")
local utils = require("navbuf.utils")
local buffer_list = {}
local bufferStrings = {}
local Win_id

function M.FindBufferMarks(last_buf, bufferStrings)
    local bufferMarks = utils.getAllBufferMarks()

    for _, mark in ipairs(bufferMarks) do
        local bufferMark = vim.api.nvim_buf_get_mark(last_buf, mark)
        if bufferMark[1] ~= 0 then
            local marktext = vim.api.nvim_buf_get_lines(last_buf, bufferMark[1] - 1, bufferMark[1], false)
            local stripSpace = marktext[1]:gsub("^%s*", "")
            local bufferMarkString = mark .. " " .. stripSpace
            table.insert(bufferStrings, bufferMarkString)
        end
    end
end

function M.bufferListToStrings(buffer_list, last_buf)
    local bufferStrings = {}
    for mark, fileName in pairs(buffer_list) do
        local str = mark .. " " .. fileName
        table.insert(bufferStrings, str)
    end
    table.insert(bufferStrings, "------------------------------------------")

    M.FindBufferMarks(last_buf, bufferStrings)

    return bufferStrings
end

function M.bufferMarksToKeymaps(bufnr, last_buf)
    local startOfBufMarks
    bufnr = tonumber(bufnr)
    print(bufnr)

    if type(bufnr) ~= "number" then
        return
    end

    for index, line in ipairs(bufferStrings) do
        if string.sub(line, 1, 1) == "-" then
            startOfBufMarks = index + 1
            break
        end
    end

    for i = startOfBufMarks, #bufferStrings do
        local mark = string.sub(bufferStrings[i], 1, 1)
        local cmd = string.format(":lua GoToMarkInBuffer('%s', %d)<CR>", mark, last_buf)
        local lhs = mark
        print(lhs)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', lhs, cmd, { noremap = true, silent = true })
    end
end

function SwitchToBufMarks(bufnr, last_buf)
    M.bufferMarksToKeymaps(bufnr, last_buf)
end

-- Close popup menu
function CloseMenu()
    local bufnr = vim.api.nvim_get_current_buf()
    local lineCount = vim.api.nvim_buf_line_count(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, lineCount, false)

    local function bufferStringsToMarks()
        local marksLeft = {}
        for _, line in ipairs(lines) do
            local stripSpaceLine = line:gsub("^%s*", "")
            local mark = string.sub(stripSpaceLine, 1, 1)
            if mark ~= "-" then
                marksLeft[mark] = true
            end
        end
        P(marksLeft)
        return marksLeft
    end

    local marksLeft = bufferStringsToMarks()
    for mark in pairs(buffer_list) do
        if not marksLeft[mark] then
            buffer_list[mark] = nil
            local upperMark = string.upper(mark)
            vim.api.nvim_del_mark(upperMark)
        end
    end

    vim.api.nvim_win_close(Win_id, true)
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

function GoToMarkInBuffer(mark, last_buf)
    local markLine = vim.api.nvim_buf_get_mark(last_buf, mark)
    vim.api.nvim_win_close(Win_id, true)
    local win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_cursor(win_id, { markLine[1], markLine[2] })
    P(markLine)
end

-- Show popup menu
function ShowMenu(buffer_list, last_buf)
    bufferStrings = M.bufferListToStrings(buffer_list, last_buf)

    local height = 10

    -- Get the dimensions of the current Neovim window
    local win_width = vim.api.nvim_get_option_value('columns', {})
    local win_height = vim.api.nvim_get_option_value('lines', {})
    local curr_width = vim.api.nvim_win_get_width(0)

    -- Calculate the center position
    local col = math.floor((win_width - curr_width) / 2)
    local line = win_height - height



    Win_id = popup.create(bufferStrings, {
        pos = "center",
        padding = { 0, 0, 0, 10 },
        minwidth = curr_width,
        minheight = height,
        col = col + 1,
        line = line,
    })
    print("PRINT: ", Win_id)
    local bufnr = vim.api.nvim_win_get_buf(Win_id)

    utils.generateCapitalMappings(bufferStrings, bufnr)

    vim.api.nvim_buf_set_keymap(bufnr, "n", "D", "<CMD>delete<CR>", { silent = false })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "J", "<CMD>:+1<CR>", { silent = false })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "K", "<CMD>:-1<CR>", { silent = false })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-N>", "<CMD>:+1<CR>", { silent = false })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-P>", "<CMD>:-1<CR>", { silent = false })

    local cmd = string.format("<CMD>lua CloseMenu()<CR>")
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<ESC>", cmd, { silent = false, desc = "Quit" })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", cmd, { silent = false })
    local cmdSwitchToBufMarks = string.format(":lua SwitchToBufMarks(%d, %d)<CR>", bufnr, last_buf)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "'", cmdSwitchToBufMarks, { silent = false })
end

function utils.PopulateBufferList()
    local fileNames = utils.loadFileNamesForCapitalMarks()
    for mark, fileName in pairs(fileNames) do
        buffer_list[mark] = fileName
    end
end

-- Start Plugin
function MyMenu()
    local bufnr = vim.api.nvim_get_current_buf()
    buffer_list = {}
    utils.PopulateBufferList()
    ShowMenu(buffer_list, bufnr)
end

vim.api.nvim_set_keymap("n", "'", "<cmd>lua MyMenu()<CR>", { silent = false })
vim.api.nvim_set_keymap("n", "cm", "<cmd>lua MyMenu()<CR>", { silent = false })

return M
