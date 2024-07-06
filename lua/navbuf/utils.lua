local utils = {}

-- Create a table with capital lettters
function utils.getAllCapitalMarks()
    local capitalLetters = {}
    for i = 65, 90 do
        table.insert(capitalLetters, string.char(i))
    end
    return capitalLetters
end

function utils.getAllBufferMarks()
    local letters = {}
    for i = 97, 122 do
        table.insert(letters, string.char(i))
    end
    return letters
end

function utils.getFileNameFromMark(mark)
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

function utils.loadFileNamesForCapitalMarks()
    local capitalMarks = utils.getAllCapitalMarks()

    local fileNames = {}
    for _, mark in ipairs(capitalMarks) do
        local fileName = utils.getFileNameFromMark(mark)

        if fileName then
            fileNames[string.lower(mark)] = fileName
        else
        end
    end

    return fileNames
end

function utils.generateCapitalMappings(bufferStrings, bufnr)
    for _, value in ipairs(bufferStrings) do
        local mark = string.sub(value, 1, 1)
        local capitalMark = string.upper(mark)
        local cmd = string.format(":lua SwitchBuffer('%s', '%d')<CR>", capitalMark, bufnr)
        local lhs = mark
        vim.api.nvim_buf_set_keymap(bufnr, 'n', lhs, cmd, { noremap = true, silent = true })
    end
end

return utils
