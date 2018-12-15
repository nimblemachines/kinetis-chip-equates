-- Given a parsed .SVD file (in Lua table form), print out some registers

-- shortcuts
fmt  = string.format

-- for debugging, turn printing of parsing process on or off
--debug = function(s) io.stderr:write(s .. "\n") end
debug = function (s) end

-- Function to visit each branch and leaf of a tree.
--
-- Gets passed two functions: a function for branches and a function for
-- leaves. Returns a function that takes a tree and any number of
-- arguments, which are passed along as accumulators or whatever. visit()
-- doesn't know or care about them.
--
-- Also note that visit() does *not* recurse into branches! That's
-- fn_branch's job, if that's what it wants to do. visit() will, by
-- default, only visit the "top-level" nodes of tree.

function visit(fn_branch, fn_leaf)
    return function(tree, ...)
        for _, node in ipairs(tree) do
            local k, v = next(node)
            if type(v) == "table" then
                -- process branch node
                fn_branch(k, v, ...)
            else
                -- process leaf node
                fn_leaf(k, v, ...)
            end
        end
        return ...
    end
end

function hex(s)
    return tonumber(s, 16)
end

function muhex(num)
    return fmt("%04x_%04x", num >> 16, num % (2^16))
end

-- Convert parens to square brackets so muforth comments don't barf
function unparen(s)
    return (s:gsub("%(", "[")
             :gsub("%)", "]"))
end

function print_regs(chip)
    local as_equates

    as_equates = visit(
        function(k, v, path, ctx)
            path = path.."/"..k
            if path == "/peripherals" then
                -- print chip info
                io.write "( Automagically generated! DO NOT EDIT!)\n\n"
                io.write(fmt("( %s %s %s equates, SVD version %s)\n",
                    ctx.chip.vendor_id,
                    ctx.chip.series,
                    ctx.chip.name,
                    ctx.chip.version))
            elseif path == "/peripherals/peripheral" then
                -- reset context
                ctx.periph = {}
            elseif path == "/peripherals/peripheral/registers" then
                -- print heading for this peripheral
                io.write(fmt("\n( %s: %s)\n", ctx.periph.name, unparen(ctx.periph.description)))
            elseif path == "/peripherals/peripheral/registers/register" then
                -- reset context
                ctx.reg = {}
            end

            -- Recurse into subtable
            as_equates(v, path, ctx)

            if path == "/peripherals/peripheral/registers/register" then
                local name = (ctx.periph.prepend_to_name or "") .. ctx.reg.name
                local addr = tonumber(ctx.periph.base_address) + tonumber(ctx.reg.address_offset)
                local descr = (ctx.reg.description and "| "..ctx.reg.description) or ""
                if ctx.reg.dim then
                    -- Print multiple registers
                    local offset = 0
                    for i in ctx.reg.dim_index:gmatch "%w+" do
                        io.write(fmt("%s equ %-20s %s\n", muhex(addr + offset), fmt(name, i), unparen(descr)))
                        offset = offset + ctx.reg.dim_increment
                    end
                else
                    io.write(fmt("%s equ %-20s %s\n", muhex(addr), name, unparen(descr)))
                end
            end
        end,

        function(k, v, path, ctx)
            if path == "" then
                ctx.chip[k] = v
            elseif path == "/peripherals/peripheral" then
                --print(fmt("periph.%s = %s", k, v))
                ctx.periph[k] = v
            elseif path == "/peripherals/peripheral/registers/register" then
                --print(fmt("reg.%s = %s", k, v))
                ctx.reg[k] = v
            end
        end)

    as_equates(chip, "", { chip = {} })
end

-- arg 1 is lua file to process
function doit()
    local chip = dofile(arg[1])
    print_regs(chip)
end

doit()
