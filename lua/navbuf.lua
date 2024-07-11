local M = {}

local popup = require("plenary.popup")
local utils = require("navbuf.utils")
local bufwindow = require("navbuf.bufwindow")
local bufferList = {}
local popupBufferStrings = {}
local popupWinId
local reopen = false
local _config = {}

function M.setup(config)
    _config = config
end

function M.findBufferMarks(lastBuf, bufferStrings)
    local bufferMarks = utils.getAllBufferMarks()
    for _, mark in ipairs(bufferMarks) do
        local bufferMark = vim.api.nvim_buf_get_mark(lastBuf, mark)
        if bufferMark[1] ~= 0 then
            local marktext = vim.api.nvim_buf_get_lines(lastBuf, bufferMark[1] - 1, bufferMark[1], false)
            local stripSpace = marktext[1]:gsub("^%s*", "")
            local bufferMarkString = mark .. " ➜ " .. stripSpace
            table.insert(bufferStrings, bufferMarkString)
        end
    end
end

function M.fileNamesToStrings(tableFileNamesCapitalMarks, bufnrInvokedFile)
    local popupBufferStrings = {}
    for capitalMark, fileName in pairs(tableFileNamesCapitalMarks) do
        local str = capitalMark .. " ➜ " .. fileName
        table.insert(popupBufferStrings, str)
        table.sort(popupBufferStrings, function(a, b) return a:sub(1, 1) < b:sub(1, 1) end)
    end

    table.insert(popupBufferStrings,
        "------------------------------ local to buffer marks ------------------------------")

    M.findBufferMarks(bufnrInvokedFile, popupBufferStrings)

    return popupBufferStrings
end

function M.createBufferMappings(popupBufnr, bufnrInvokedFile)
    local startOfBufMarks
    popupBufnr = tonumber(popupBufnr)
    if type(popupBufnr) ~= "number" then
        return
    end

    for index, line in ipairs(popupBufferStrings) do
        local stripSpaceLine = line:gsub("^%s*", "")
        if string.sub(stripSpaceLine, 1, 1) == "-" then
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

function M.switchBuffer(mark, lastBuf)
    local mark_path = vim.api.nvim_get_mark(mark, {})[4]
    local function edit()
        vim.api.nvim_command('edit ' .. mark_path)
    end
    if reopen == false then
        vim.api.nvim_win_close(0, true)
        edit()
    else
        vim.api.nvim_win_close(0, true)
        edit()
        lastBuf = vim.api.nvim_get_current_buf()
        MyMenu()
        M.switchToBufMarks(0, lastBuf)
        reopen = false
    end
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
        for mark in pairs(bufferList) do
            if not marksLeft[mark] then
                bufferList[mark] = nil
                local upperMark = string.upper(mark)
                vim.api.nvim_del_mark(upperMark)
            end
        end
        vim.api.nvim_win_close(popupWinId, true)
    else
        vim.api.nvim_win_close(popupWinId, true)
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
function ShowMenu(tableFileNamesCapitalMarks, bufnrInvokedFile)
    popupBufferStrings = M.fileNamesToStrings(tableFileNamesCapitalMarks, bufnrInvokedFile)

    local ids = bufwindow.createWindowPopup(popupBufferStrings, bufnrInvokedFile)
    local popupBufnr = ids[1]
    popupWinId = ids[2]
    popupBufferStrings = ids[3]

    utils.generateCapitalMappings(popupBufferStrings, popupBufnr)

    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "D", "<CMD>delete<CR>", { silent = false })
    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "<C-N>", "<CMD>+1<CR>", { silent = false })
    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "<C-P>", "<CMD>-1<CR>", { silent = false })
    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "j", "<C-E>", { silent = false })
    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "k", "<C-Y>", { silent = false })
    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "X", ":lua require('navbuf').deleteCapitalMarks()<CR>",
        { silent = false })
    vim.api.nvim_buf_set_keymap(popupBufnr, "n", "Z", ":lua require('navbuf').deleteBufferMarks()<CR>",
        { silent = false })

    local cmd = string.format("<CMD>lua CloseMenu(%s)<CR>", "false")
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
    vim.api.nvim_command("delmarks [A-Z]")
end

function M.deleteBufferMarks()
    vim.api.nvim_win_close(0, true)
    vim.api.nvim_command("delmarks a-z")
end

function M.switchToBufMarks(popupBufnr, bufnrInvokedFile)
    M.createBufferMappings(popupBufnr, bufnrInvokedFile)
end

function M.addCapitalMarksFileNames()
    local fileNames = utils.tableFileNamesCapitalMarks(_config.marks)
    local fileNamesCapitalMarks = {}
    for capitalMark, fileName in pairs(fileNames) do
        fileNamesCapitalMarks[capitalMark] = fileName
    end
    return fileNamesCapitalMarks
end

function ReopenNavbuf()
    reopen = true
    MyMenu()
end

-- Start Plugin
function MyMenu()
    bufferList = {}
    P(_config.marks)
    local bufnrInvokedFile = vim.api.nvim_get_current_buf()
    local tableFileNamesCapitalMarks = M.addCapitalMarksFileNames()
    ShowMenu(tableFileNamesCapitalMarks, bufnrInvokedFile)
end

vim.api.nvim_set_keymap("n", "'", "<cmd>lua MyMenu()<CR>", { silent = false })
vim.api.nvim_set_keymap("n", "cm", "<cmd>lua ReopenNavbuf()<CR>", { silent = false })

return M
