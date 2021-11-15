-- Generate a list of curl commands based on a Keil CMSIS Pack index

fmt = string.format

-- A CMSIS-Pack is uniquely identified by <vendor>.<packname>.<version>

function print_commands(pack_index, vendor, pack_pattern, cmd, want_deprecated)
    for _, p in ipairs(pack_index) do
        -- Which pack(s) do we want?
        if p.vendor == vendor and p.name:match(pack_pattern) and
            ((not p.deprecated) or want_deprecated) then
            local packname = fmt("%s.%s.%s.pack", p.vendor, p.name, p.version)
            if cmd == "show" then
                print(fmt("%s%s", p.url, packname))
            elseif cmd == "get" then
                print(fmt("[ -f pack/%s ] || curl -L -o pack/%s %s%s", packname, packname, p.url, packname))
            end
        end
    end
end

-- arg 1 is Keil CMSIS pack index in Lua form
-- arg 2 is vendor name
-- arg 3 is packname match string
-- arg 4 is "show" or "get"
-- arg 5 is optional: "deprecated" will show or get deprecated packs
function doit()
    print_commands(dofile(arg[1]), arg[2], arg[3], arg[4], arg[5] and ("deprecated"):match(arg[5]))
end

doit()
