--[[
    Modules - Работа с модулями
]]

--  Fields

modules = {
    file = nil,
    module = nil,
}

--  Functions

--  Load module
function modules:load(path)
    self.file = fs.open(path, "r")
    local section = ""
    local pattern = nil

    --  Preparing
    self.module = {
        info = {
            name = "nil",
            author = "nil",
            copyright = "nil",
            comment = "nil",
        },
        settings = {
            speed = nil,
            tempo = nil,
            rows = nil,
            channels = nil,
        },
        order = {},
        patterns = {},
    }

    --  Reading
    while true do
        local line = self:readline()

        --  EOF
        if line == nil then
            break
        end

        --  Section matching
        do
            local mo = table.pack( line:match("%[(%a+)%]") )
            if mo[1] ~= nil then
                section = self:spacestrip(mo[1]):lower()
            end
        end

        --  Field matching
        do
            local mo = table.pack( line:match("(.+):(.*)") )
            if mo[1] ~= nil then
                if section == "info" then
                    self.module.info[self:spacestrip(mo[1])] = self:spacestrip(mo[2])
                elseif section == "settings" then
                    self.module.settings[self:spacestrip(mo[1])] = tonumber(self:spacestrip(mo[2]))
                end
            end
        end

        --  Order matching
        if section == "order" then
            local row = {}
            for index in line:gmatch("(%d%d)") do
                table.insert(row, index)
            end

            if #row > 0 then
                table.insert(self.module.order, row)
            end
        end

        --  Pattern matching
        if section == "patterns" then
            local mo = table.pack( line:match("pattern (%d%d)") )
            if mo[1] ~= nil then
                pattern = tonumber(mo[1])
                self.module.patterns[pattern] = {}
            end
        end

        --  Row matching
        if section == "patterns" then
            local mo = table.pack( line:match("(...) (..) (..)") )
            if mo[1] ~= nil then
                local note = { nil, nil, nil }

                --  Note name
                local mo_0 = table.pack( mo[1]:match("%.%.%.") )
                if mo_0[1] ~= nil then
                    note[1] = mo_0[1]
                end

                local mo_1 = table.pack( mo[1]:match("%-%-%-") )
                if mo_1[1] ~= nil then
                    note[1] = mo_1[1]
                end

                local mo_2 = table.pack( mo[1]:match("[A-G][#%-][1-7]") )
                if mo_2[1] ~= nil then
                    note[1] = mo_2[1]
                end

                --  Note instrument
                local mo_3 = table.pack( mo[2]:match("%.%.") )
                if mo_3[1] ~= nil then
                    note[2] = mo_3[1]
                end

                local mo_4 = table.pack( mo[2]:match("%d%d") )
                if mo_4[1] ~= nil then
                    note[2] = mo_4[1]
                end

                --  Note volume
                local mo_5 = table.pack( mo[3]:match("%.%.") )
                if mo_5[1] ~= nil then
                    note[3] = mo_5[1]
                end

                local mo_6 = table.pack( mo[3]:match("%d%d") )
                if mo_6[1] ~= nil then
                    note[3] = mo_6[1]
                end

                --  Apply
                if note[1] ~= nil and note[2] ~= nil and note[3] ~= nil then 
                    table.insert(self.module.patterns[pattern], note)
                end
                -- print("Row ~>", self:spacestrip(mo[1]))
                -- os.sleep(3)
            end
        end
    end

    --  Null Pattern
    self.module.patterns[0] = {}
    for i = 1, self.module.settings.rows do
        table.insert(self.module.patterns[0], {"...", "..", ".."})
    end

    return self.module
end

--  Reads line from module. Skips empty lines
function modules:readline()
    local line = ""
    
    -- Skip empty lines
    while line == "" do
        line = self.file.readLine()

        --  Remove comments
        if line ~= nil then
            local pos = line:find("//")
            if pos ~= nil then
                line = line:sub(1, pos - 1)
            end
        end

        --  Strip spaces
        if line ~= nil then
            line = self:spacestrip(line)
        end
    end

    return line
end

--  Removes space character at string edges
function modules:spacestrip(str)
    return str:match("%s*(.*)%s*")
end

--  Export

return modules


