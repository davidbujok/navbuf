local bufwindow = {}
local popup = require("plenary.popup")

function bufwindow.createWindowPopup(bufferStrings)
    local height = 10

    -- Get the dimensions of the current Neovim window
    local win_width = vim.api.nvim_get_option_value('columns', {})
    local win_height = vim.api.nvim_get_option_value('lines', {})
    local curr_width = vim.api.nvim_win_get_width(0)

    -- Calculate the center position
    local col = math.floor((win_width - curr_width) / 2)
    local line = win_height - height
    local Win_id = popup.create(bufferStrings, {
        pos = "center",
        minwidth = curr_width,
        minheight = height,
        col = col + 1,
        line = line,
    })
    return Win_id
end

return bufwindow
