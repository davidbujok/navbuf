local utils = {}

-- Create a table with capital lettters
function utils.tableCapitalLetters()
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

function utils.getFileNameFromCapitalMark(mark)
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

function utils.deleteMark(winnr, row, col)
    local line = vim.api.nvim_get_current_line()
    local stripSpaceLine = line:gsub("^%s*", "")
    local mark = string.sub(stripSpaceLine, 1, 1)
    local markToDelete = string.format("delmarks %s", string.upper(mark))
    vim.api.nvim_command(markToDelete)
    CloseMenu(false, winnr, row, col)
end

function utils.findBufferMarks(lastBuf, bufferStrings)
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

function utils.findMarksLeft(lines)
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

function utils.fileNamesToStrings(tableFileNamesCapitalMarks, bufnrInvokedFile)
    local popupBufferStrings = {}
    for capitalMark, fileName in pairs(tableFileNamesCapitalMarks) do
        local str = capitalMark .. " ➜ " .. fileName
        table.insert(popupBufferStrings, str)
        table.sort(popupBufferStrings, function(a, b) return a:sub(1, 1) < b:sub(1, 1) end)
    end

    local winWidth = vim.api.nvim_win_get_width(0)
    local spaceNumber = winWidth / 2 - 20
    local spaceToReplace = string.rep(" ", spaceNumber)
    local breakString = string.format("%s  buffer marks ", spaceToReplace)
    table.insert(popupBufferStrings, breakString)
    utils.findBufferMarks(bufnrInvokedFile, popupBufferStrings)

    return popupBufferStrings
end

function utils.capitalMarksFileNames(marks)
    local fileNames = utils.tableFileNamesCapitalMarks(marks)
    local fileNamesCapitalMarks = {}
    for capitalMark, fileName in pairs(fileNames) do
        fileNamesCapitalMarks[capitalMark] = fileName
    end
    return fileNamesCapitalMarks
end

function utils.tableFileNamesCapitalMarks(marks)
    local fileNames = {}
    for _, mark in ipairs(marks) do
        local fileName = utils.getFileNameFromCapitalMark(mark)

        if fileName then
            fileNames[string.lower(mark)] = fileName
        else
        end
    end
    return fileNames
end

function utils.generateCapitalMappings(bufnr, winnr)
    local capitalLetters = utils.tableCapitalLetters()
    local lines = utils.capitalMarksFileNames(capitalLetters)
    for mark, _ in pairs(lines) do
        local capitalMark = string.upper(mark)
        local cmd = string.format(":lua require('navbuf').switchBuffer('%s', '%d', %d)<CR>", capitalMark, bufnr, winnr)
        local lhs = mark
        vim.api.nvim_buf_set_keymap(bufnr, 'n', lhs, cmd, { silent = true })
    end
end

function utils.getAllPathsCapitalMarks(lastBuf)
    local lastBufPath = vim.api.nvim_buf_get_name(lastBuf)
    local capitalMarks = utils.tableCapitalLetters()
    local paths = {}
    for _, mark in ipairs(capitalMarks) do
        local path = vim.api.nvim_get_mark(mark, {})[4]
        local expanded_rel_path = vim.fn.expand(path)
        if expanded_rel_path then
            paths[expanded_rel_path] = mark
        end
    end

    local lastFile
    if paths[lastBufPath] then
        lastFile = string.lower(paths[lastBufPath])
    end
    return lastFile
end

function utils.nextMark(bufferStrings, lastBuf)
    vim.api.nvim_command("+1")
    local lineMark = vim.api.nvim_get_current_line()
    local stripSpace = lineMark:gsub("^%s*", "")
    local mark = stripSpace:sub(1, 1)
    local markTable = vim.api.nvim_get_mark(string.upper(mark), {})
    local bufferMarks = utils.getAllBufferMarks()

    local removeFromHere = false
    local indexStart
    for index, line in ipairs(bufferStrings) do
        local stripSpaceLine = line:gsub("^%s*", "")
        if removeFromHere then
            table.remove(bufferStrings, index)
        end
        if string.sub(stripSpaceLine, 1, 1) == "-" then
            removeFromHere = true
            indexStart = index
        end
    end
    removeFromHere = false

    local localToFileMark = {}
    for _, markB in ipairs(bufferMarks) do
        local bufferMark = vim.api.nvim_buf_get_mark(markTable[3], markB)
        if bufferMark[1] ~= 0 then
            local marktext = vim.api.nvim_buf_get_lines(lastBuf, bufferMark[1] - 1, bufferMark[1], false)
            local stripSpace2 = marktext[1]:gsub("^%s*", "")
            local bufferMarkString = markB .. " " .. stripSpace2
            table.insert(localToFileMark, bufferMarkString)
        end
    end
    vim.api.nvim_buf_set_lines(0, indexStart, -2, false, localToFileMark)
end

function utils.prevMark()
    vim.api.nvim_command("-1")
end

return utils
