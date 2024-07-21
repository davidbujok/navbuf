local M = {}

local utils = require("navbuf.utils")
local bufwindow = require("navbuf.bufwindow")
local bufferList = {}
local popupBufferStrings = {}
local popupWinId
local loadList = true
local listwindow = require('navbuf.listwindow')
local reopen = false
local _config = {}

function M.setup(config)
    _config = config
end

function M.createBufferMappings(popupBufnr, bufnrInvokedFile)
    local startOfBufMarks
    popupBufnr = tonumber(popupBufnr)
    if type(popupBufnr) ~= "number" then
        return
    end

    for index, line in ipairs(popupBufferStrings) do
        local stripSpaceLine = line:gsub("^%s*", "")
        local letter = string.sub(stripSpaceLine, 1, 1)
        if not letter:match("[ a-z ]") then
            print(stripSpaceLine)
            startOfBufMarks = index + 1
            break
        end
    end

    for i = startOfBufMarks, #popupBufferStrings do
        local stripSpaceLine = popupBufferStrings[i]:gsub("^%s*", "")
        local mark = string.sub(stripSpaceLine, 1, 1)
        local cmd = string.format(":lua require('navbuf').goToMarkInBuffer('%s', %d)<CR>", mark, bufnrInvokedFile)
        local lhs = mark
        vim.api.nvim_buf_set_keymap(popupBufnr, 'n', lhs, cmd, { noremap = true, silent = true })
    end
end

function M.switchBuffer(mark, lastBuf, winnr)
    local function edit()
        vim.api.nvim_command("normal! '" .. mark)
        vim.api.nvim_exec2("normal! `\"", {})
    end

    vim.api.nvim_win_close(0, true)
    vim.api.nvim_set_current_win(winnr)

    edit()

    if reopen == true then
        M.show()
        M.switchToBufMarks(0, lastBuf)
        reopen = false
    end
end

-- Close popup menu
function CloseMenu(bool, winnr, row, col)
    if bool == false then
        local bufnr = vim.api.nvim_get_current_buf()
        local lineCount = vim.api.nvim_buf_line_count(bufnr)
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, lineCount, false)

        local function bufferStringsToMarks()
            local marksLeft = {}
            for _, line in ipairs(lines) do
                local stripSpaceLine = line:gsub("^%s*", "")
                local mark = string.sub(stripSpaceLine, 1, 1)
                if not mark:match("[ a-z ]") then
                    marksLeft[mark] = true
                end
            end
            return marksLeft
        end

        local marksLeft = bufferStringsToMarks()
        for mark in pairs(bufferList) do
            if not marksLeft[mark] then
                bufferList[mark] = nil
                local upperMark = string.upper(mark)
                vim.api.nvim_del_mark(upperMark)
            end
        end
        vim.api.nvim_win_close(0, true)
        vim.api.nvim_set_current_win(winnr)
        vim.api.nvim_win_set_cursor(winnr, {row, col})
    else
        vim.api.nvim_win_close(0, true)
        local bufnr = vim.api.nvim_get_current_buf()
        local markAsteriks = vim.api.nvim_buf_get_mark(bufnr, "'")
        local win_id = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_cursor(win_id, { markAsteriks[1], markAsteriks[2] })
    end
end

function M.goToMarkInBuffer(mark, last_buf)
    local markLine = vim.api.nvim_buf_get_mark(last_buf, mark)
    vim.api.nvim_win_close(popupWinId, true)
    local win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_cursor(win_id, { markLine[1], markLine[2] })
end

-- Show popup menu
function M.show()
    local currentPosition = vim.api.nvim_win_get_cursor(0)
    bufferList = {}
    local bufnrInvokedFile = vim.api.nvim_get_current_buf()
    local winnrInvokedFile = vim.api.nvim_get_current_win()
    local tableFileNamesCapitalMarks = utils.capitalMarksFileNames(_config.marks)
    popupBufferStrings = utils.fileNamesToStrings(tableFileNamesCapitalMarks, bufnrInvokedFile)

    local listWindowId
    if loadList then
        listWindowId = listwindow.createWindowPopup(_config.marks)
        vim.api.nvim_win_set_cursor(winnrInvokedFile, { 1, 1 })
        loadList = false
    end

    local ids = bufwindow.createWindowPopup(popupBufferStrings, bufnrInvokedFile, _config)
    local popupBufnr = ids[1]
    popupWinId = ids[2]
    popupBufferStrings = ids[3]

    utils.generateCapitalMappings(popupBufnr, winnrInvokedFile)

    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "D", "<CMD>lua require('navbuf.utils').deleteMark()<CR>",
        { silent = false })
    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "<C-N>", "<C-Y>", { silent = false })
    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "<C-P>", "<C-E>", { silent = false })
    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "j", "<CMD>+1<CR>", { silent = false })
    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "k", "<CMD>-1<CR>", { silent = false })
    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "X", ":lua require('navbuf').deleteCapitalMarks()<CR>",
        { silent = false })
    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "Z", ":lua require('navbuf').deleteBufferMarks()<CR>",
        { silent = false })

    local cmd = string.format("<CMD>lua CloseMenu(%s, %d, %d, %d)<CR>",
        "false", winnrInvokedFile, currentPosition[1], currentPosition[2])
    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "<ESC>", cmd, { silent = false, desc = "Quit" })
    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "<C-C>", cmd, { silent = false, desc = "Quit" })
    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "q", cmd, { silent = false })

    local cmdSwitchToBufMarks = string.format(":lua require('navbuf').switchToBufMarks(%d, %d)<CR>", popupBufnr,
        bufnrInvokedFile)
    vim.api.nvim_buf_set_keymap(popupBufnr, "n", ",", cmdSwitchToBufMarks, { silent = false })

    local cmdAsteriks = string.format("<CMD>lua CloseMenu(%s)<CR>", "true")
    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "'", cmdAsteriks, { silent = false })
end

function M.deleteCapitalMarks()
    vim.api.nvim_win_close(0, true)
    if _config.marks then
        for _, mark in ipairs(_config.marks) do
            local markToDelete = string.format("delmarks %s", mark)
            vim.api.nvim_command(markToDelete)
        end
    else
        vim.api.nvim_command("delmarks [A-Z]")
    end
end

function M.deleteBufferMarks()
    vim.api.nvim_win_close(0, true)
    vim.api.nvim_command("delmarks a-z")
end

function M.switchToBufMarks(popupBufnr, bufnrInvokedFile)
    M.createBufferMappings(popupBufnr, bufnrInvokedFile)
end

function M.twoStep()
    reopen = true
    M.show()
end

vim.api.nvim_set_keymap("n", "'", "<cmd>lua require('navbuf').show()<CR>", { silent = false })
vim.api.nvim_set_keymap("n", "cm", "<cmd>lua require('navbuf').twoStep()<CR>", { silent = false })

return M
