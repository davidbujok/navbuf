local listwindow = {}
local id

local popup = require("plenary.popup")
local utils = require("navbuf.utils")

function listwindow.createWindowPopup(marks)
    local win_width = vim.api.nvim_get_option_value('columns', {})
    local col = math.floor(win_width)
    local stringWidth = 1

    local function createStrings()
        local capitalLetters = utils.tableCapitalLetters()
        local fileNames = utils.capitalMarksFileNames(capitalLetters)
        local strings = {}
        local longest = 1
        for _, mark in ipairs(marks) do
            if fileNames[string.lower(mark)] ~= nil then
                local stringLen = string.len(fileNames[string.lower(mark)])
                if longest < stringLen then
                    longest = string.len(fileNames[string.lower(mark)])
                end
            end
            local str = string.format("%s %s", mark, fileNames[string.lower(mark)])
            if fileNames[string.lower(mark)] then
                table.insert(strings, str)
            end
        end
        return { strings, longest }
    end

    local strAndLen = createStrings()
    local strings = strAndLen[1]

    if strAndLen[2] > stringWidth then
        stringWidth = strAndLen[2]
    end

    id = popup.create(strings, {
        pos = "center",
        padding = { 0, 0, 0, 0 },
        minwidth = 10,
        minheight = #strAndLen,
        focusable = false,
        -- borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
        col = win_width - stringWidth - 2,
        line = 2,
    })
    local bufnr = vim.api.nvim_win_get_buf(id)
    for linenr, str in ipairs(strings) do
        vim.api.nvim_buf_add_highlight(bufnr, -1, 'Number', linenr - 1, 0, 1)
        vim.api.nvim_buf_add_highlight(bufnr, -1, 'Normal', linenr - 1, 2, -1)
    end
    vim.api.nvim_exec2("set nobuflisted \
    setlocal buftype=nofile \
    setlocal bufhidden=hide \
    setlocal noswapfile \
    set nobuflisted \
    ", {})

    -- Set up autocommands for events that might involve setting marks
    function listwindow.on_m_pressed(mark)
        local execute = string.format("mark %s", mark)
        vim.api.nvim_command(execute)
        local stringsReplacement = createStrings()
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, stringsReplacement[1])
        for linenr, _ in ipairs(stringsReplacement) do
            vim.api.nvim_buf_add_highlight(bufnr, -1, 'Number', linenr - 1, 0, 1)
            vim.api.nvim_buf_add_highlight(bufnr, -1, 'Normal', linenr - 1, 2, -1)
        end
        local config = vim.api.nvim_win_get_config(id)
        stringWidth = stringsReplacement[2]
        config["relative"] = 'editor'
        config["col"] = win_width - stringWidth - 2
        config["row"] = 1
        config["width"] = stringWidth + 3
        vim.api.nvim_win_set_config(id, config)
    end

    -- Set up the key mapping for 'm' in normal mode
    for _, mark in ipairs(marks) do
        local mapper = string.format(":lua require('navbuf.listwindow').on_m_pressed('%s')<CR>", mark)
        local keys = 'm' .. string.lower(mark)
        vim.api.nvim_set_keymap('n', keys, mapper, { noremap = true, silent = true })
    end

    return id
end

function listwindow.CloseWindow()
    vim.api.nvim_win_close(id, true)
end

return listwindow
