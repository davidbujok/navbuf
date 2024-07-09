local bufwindow = {}

local popup = require("plenary.popup")
local utils = require("navbuf.utils")

function bufwindow.createWindowPopup(bufferStrings, lastBuf)
    local lastFileMark = utils.getAllPathsCapitalMarks(lastBuf)

    local height = 10

    -- Get the dimensions of the current Neovim window
    local win_width = vim.api.nvim_get_option_value('columns', {})
    local win_height = vim.api.nvim_get_option_value('lines', {})
    local curr_width = vim.api.nvim_win_get_width(0)

    -- Calculate the center position
    local col = math.floor((win_width - curr_width) / 2)
    local line = win_height - height

    local lastBufTemp
    for index, buffer in ipairs(bufferStrings) do
        local mark = string.sub(buffer, 1, 1)
        if mark == lastFileMark then
            lastBufTemp = table.remove(bufferStrings, index)
            break
        end
    end
    table.insert(bufferStrings, 1, lastBufTemp)


    Win_id = popup.create(bufferStrings, {
        pos = "center",
        padding = { 0, 0, 0, 10 },
        minwidth = curr_width,
        minheight = height,
        col = col + 1,
        line = line,
    })

    local bufnr = vim.api.nvim_win_get_buf(Win_id)
    -- vim.api.nvim_command("set cursorline")
    for linenr, str in ipairs(bufferStrings) do
        local mark = string.sub(str, 11, 11)
        if mark == lastFileMark then
            vim.api.nvim_buf_add_highlight(bufnr, -1, 'SpecialKey', linenr - 1, 10, 11)
            vim.api.nvim_buf_add_highlight(bufnr, -1, 'Question', linenr - 1, 1, -1)
        else
            vim.api.nvim_buf_add_highlight(bufnr, -1, 'Conditional', linenr - 1, 10, 11)
            vim.api.nvim_buf_add_highlight(bufnr, -1, 'CursorLineNumber', linenr - 1, 12, 13)
            vim.api.nvim_buf_add_highlight(bufnr, -1, 'SpecialKey', linenr - 1, 14, -1)
        end
    end

    return { Win_id, bufnr, bufferStrings }
end

return bufwindow
