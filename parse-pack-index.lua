-- After downloading the Keil CMSIS Pack index, parse it

fmt = string.format

-- An entry looks like this:
-- <pdsc url="http://www.keil.com/pack/" vendor="Keil" name="LPC800_DFP" version="1.10.0" deprecated="2018-07-30" replacement="Keil.LPC8N04_DFP" />
-- deprecated and replacement are optional
function parse(s)
    local packs = {}
    local list = s:match "<pindex>(.*)</pindex>"
    for e in list:gmatch "<pdsc(..-)/>" do
        local url     = e:match [[url="(%S+)"]]
        local vendor  = e:match [[vendor="(%S+)"]]
        local name    = e:match [[name="(%S+)"]]
        local version = e:match [[version="(%S+)"]]
        local pack = { url = url, vendor = vendor, name = name, version = version }

        -- Check for optional attributes
        local deprecated  = e:match [[deprecated="(%S+)"]]
        local replacement = e:match [[replacement="(%S+)"]]
        if deprecated then
            pack.deprecated = deprecated
        end
        if replacement then
            pack.replacement = replacement
        end

        -- add pack to list
        packs[#packs+1] = pack
    end

    return packs
end

function print_as_lua(p)
    io.write "return {\n"
    for _, e in ipairs(p) do
        local deprecated = e.deprecated and
            fmt(", deprecated = %q", e.deprecated) or
            ""
        local replacement = e.replacement and
            fmt(", replacement = %q", e.replacement) or
            ""
        io.write(fmt("  { url = %q, vendor = %q, name = %q, version = %q%s%s },\n",
            e.url, e.vendor, e.name, e.version, deprecated, replacement))
    end
    io.write "}\n"
end

-- arg 1 is file to process
function doit()
    local f = io.open(arg[1], "r")
    local s = f:read("a")   -- read entire file as a string
    f:close()
    s = s:gsub("\r", "")    -- remove any CR characters
    print_as_lua(parse(s))
end

doit()
