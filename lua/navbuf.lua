local M = {}

local popup = require("plenary.popup")
local utils = require("navbuf.utils")
local bufwindow = require("navbuf.bufwindow")
local buffer_list = {}
local bufferStrings = {}
local Win_id
local reopen = false

function M.FindBufferMarks(last_buf, bufferStrings)
    local bufferMarks = utils.getAllBufferMarks()

    for _, mark in ipairs(bufferMarks) do
        local bufferMark = vim.api.nvim_buf_get_mark(last_buf, mark)
        if bufferMark[1] ~= 0 then
            local marktext = vim.api.nvim_buf_get_lines(last_buf, bufferMark[1] - 1, bufferMark[1], false)
            local stripSpace = marktext[1]:gsub("^%s*", "")
            local bufferMarkString = mark .. " ➜ " .. stripSpace
            table.insert(bufferStrings, bufferMarkString)
        end
    end
end

function M.bufferListToStrings(buffer_list, last_buf)
    local bufferStrings = {}
    for mark, fileName in pairs(buffer_list) do
        local str = mark .. " ➜ " .. fileName
        table.insert(bufferStrings, str)
        table.sort(bufferStrings, function(a, b) return a:sub(1, 1) < b:sub(1, 1) end)
    end

    table.insert(bufferStrings, "-")
    M.FindBufferMarks(last_buf, bufferStrings)

    return bufferStrings
end

function M.bufferMarksToKeymaps(bufnr, last_buf)
    local startOfBufMarks
    bufnr = tonumber(bufnr)
    if type(bufnr) ~= "number" then
        return
    end

    for index, line in ipairs(bufferStrings) do
        local stripSpaceLine = line:gsub("^%s*", "")
        if string.sub(stripSpaceLine, 1, 1) == "-" then
            startOfBufMarks = index + 1
            break
        end
    end

    for i = startOfBufMarks, #bufferStrings do
        local stripSpaceLine = bufferStrings[i]:gsub("^%s*", "")
        local mark = string.sub(stripSpaceLine, 1, 1)
        local cmd = string.format(":lua GoToMarkInBuffer('%s', %d)<CR>", mark, last_buf)
        local lhs = mark
        vim.api.nvim_buf_set_keymap(bufnr, 'n', lhs, cmd, { noremap = true, silent = true })
    end
end

function SwitchToBufMarks(bufnr, last_buf)
    M.bufferMarksToKeymaps(bufnr, last_buf)
end

-- Close popup menu
function CloseMenu(bool)
    if bool == false then
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
    else
        vim.api.nvim_win_close(Win_id, true)
        local bufnr = vim.api.nvim_get_current_buf()
        local markAsteriks = vim.api.nvim_buf_get_mark(bufnr, "'")
        local win_id = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_cursor(win_id, { markAsteriks[1], markAsteriks[2] })
    end
end

-- Switch Buffers
function SwitchBuffer(mark, last_buf)
    local mark_path = vim.api.nvim_get_mark(mark, {})[4]
    local function edit()
        vim.api.nvim_command('edit ' .. mark_path)
    end
    if reopen == false then
        vim.api.nvim_win_close(Win_id, true)
        edit()
    else
        vim.api.nvim_win_close(Win_id, true)
        edit()
        last_buf = vim.api.nvim_get_current_buf()
        MyMenu()
        SwitchToBufMarks(0, last_buf)
        reopen = false
    end
end

function GoToMarkInBuffer(mark, last_buf)
    local markLine = vim.api.nvim_buf_get_mark(last_buf, mark)
    vim.api.nvim_win_close(Win_id, true)
    local win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_cursor(win_id, { markLine[1], markLine[2] })
end

-- Show popup menu
function ShowMenu(buffer_list, lastBuf)
    bufferStrings = M.bufferListToStrings(buffer_list, lastBuf)

    local ids = bufwindow.createWindowPopup(bufferStrings, lastBuf)
    Win_id = ids[1]
    local bufnr = ids[2]
    bufferStrings = ids[3]

    utils.generateCapitalMappings(bufferStrings, bufnr)

    vim.api.nvim_buf_set_keymap(bufnr, "n", "D", "<CMD>delete<CR>", { silent = false })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-N>", "<CMD>+1<CR>", { silent = false })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-P>", "<CMD>-1<CR>", { silent = false })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "X", "<CMD>delmarks [A-Z]<CR>", { silent = false })

    local cmd = string.format("<CMD>lua CloseMenu(%s)<CR>", "false")
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<ESC>", cmd, { silent = false, desc = "Quit" })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", cmd, { silent = false })

    local cmdSwitchToBufMarks = string.format(":lua SwitchToBufMarks(%d, %d)<CR>", bufnr, lastBuf)
    vim.api.nvim_buf_set_keymap(bufnr, "n", ",", cmdSwitchToBufMarks, { silent = false })

    local cmdAsteriks = string.format("<CMD>lua CloseMenu(%s)<CR>", "true")
    vim.api.nvim_buf_set_keymap(bufnr, "n", "'", cmdAsteriks, { silent = false })
end

function ReopenNavbuf()
    reopen = true
    MyMenu()
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
vim.api.nvim_set_keymap("n", "cm", "<cmd>lua ReopenNavbuf()<CR>", { silent = false })

return M
