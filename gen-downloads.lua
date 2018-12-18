-- Generate a list of curl commands based on a Keil CMSIS Pack index

fmt = string.format

-- A CMSIS-Pack is uniquely identified by <vendor>.<packname>.<version>

function print_commands(packs, vendor, pattern, cmd)
    for _, p in ipairs(packs) do
        -- Which pack(s) do we want?
        if p.vendor == vendor and p.name:match(pattern) then
            local packname = fmt("%s.%s.%s.pack", p.vendor, p.name, p.version)
            if cmd == "show" then
                print(fmt("%s%s", p.url, packname))
            elseif cmd == "get" then
                print(fmt("[ -f pack/%s ] || curl -L -o pack/%s %s%s", packname, packname, p.url, packname))
            end
        end
    end
end

-- arg 1 is Keil CMSIS pack in Lua form
-- arg 2 is vendor match string
-- arg 3 is packname match string
-- arg 4 is "show" or "get"
function doit()
    packs = dofile(arg[1])
    print_commands(packs, arg[2], arg[3], arg[4])
end

doit()
