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
            local print_reg = function()
                local name = (ctx.periph.prepend_to_name or "") .. ctx.reg.name
                local addr = tonumber(ctx.periph.base_address) + tonumber(ctx.reg.address_offset)
                local descr = (ctx.reg.description and "| "..ctx.reg.description) or ""
                if ctx.reg.dim then
                    -- Print multiple registers
                    local offset = 0
                    for i in ctx.reg.dim_index:gmatch "%w+" do
                        io.write(fmt("%s equ    %-28s %s\n", muhex(addr + offset), fmt(name, i), unparen(descr)))
                        offset = offset + ctx.reg.dim_increment
                    end
                else
                    io.write(fmt("%s equ    %-28s %s\n", muhex(addr), name, unparen(descr)))
                end
                ctx.reg.printed = true
            end

            path = path.."/"..k
            if path == "/peripherals" then
                -- print chip info
                io.write "( Automagically generated! DO NOT EDIT!\n\n"
                io.write(fmt("  %s %s %s equates, version %s\n\n",
                    ctx.chip.vendor_id, ctx.chip.series, ctx.chip.name, ctx.chip.version))
                io.write(fmt("  Generated from https://github.com/nimblemachines/kinetis-chip-equates/blob/master/%s)\n\nhex\n",
                    ctx.chip.source_file))
            elseif path == "/peripherals/peripheral" then
                -- reset context
                ctx.periph = {}
            elseif path == "/peripherals/peripheral/interrupt" then
                -- reset context
                ctx.interrupt = {}
            elseif path == "/peripherals/peripheral/registers" then
                -- print heading for this peripheral
                io.write(fmt("\n( %s: %s)\n", ctx.periph.name, unparen(ctx.periph.description)))
            elseif path == "/peripherals/peripheral/registers/register" then
                -- reset context
                ctx.reg = {}
            elseif path == "/peripherals/peripheral/registers/register/fields" then
                -- Generally fields follow the register def, so print the reg now
                print_reg()
            elseif path == "/peripherals/peripheral/registers/register/fields/field" then
                -- reset context
                ctx.field = {}
            end

            -- Recurse into subtable
            as_equates(v, path, ctx)

            if path == "/peripherals/peripheral/registers/register/fields/field" then
                -- Registers defined with "dim" also have fields... but
                -- printing the fields for each version of the register
                -- would be stupid. Let's instead just remove the "%s" from
                -- the name.
                if ctx.field.bit_width < ctx.reg.size then
                    local name = (ctx.periph.prepend_to_name or "") ..
                                  ctx.reg.name:gsub("%%s", "")  .. "_" .. ctx.field.name
                    local descr = (ctx.field.description and "| "..ctx.field.description) or ""
                    io.write(fmt("  #%02d #%02d field  %-28s %s\n", ctx.field.bit_offset, ctx.field.bit_width,
                                                                    name, descr))
                end
            elseif path == "/peripherals/peripheral/registers/register" then
                -- If register has no fields, we won't have printed it above. Do it now.
                if not ctx.reg.printed then
                    print_reg()
                end
            elseif path == "/peripherals/peripheral/interrupt" then
                local vector = tonumber(ctx.interrupt.value)
                ctx.interrupts[vector] = ctx.interrupt.name
                ctx.interrupts.max = math.max(ctx.interrupts.max, vector)
            elseif path == "/peripherals" then
                -- We've processed all the peripherals; print the interrupt vectors.
                io.write "\n( IRQ vectors)\ndecimal\n"
                --io.stderr:write(fmt("max interrupt: %d\n", ctx.interrupts.max))
                for i = 0, ctx.interrupts.max do
                    local name = ctx.interrupts[i]
                    if name then
                        -- Fix LLW mistake
                        name = (name == "LLW") and "LLWU" or name
                        io.write(fmt("  %3d equ  %s_IRQ\n", i, name))
                    else
                        io.write(fmt("( %3d      Reserved)\n", i))
                    end
                end
                io.write "hex\n"
            end
        end,

        function(k, v, path, ctx)
            if path == "" then
                ctx.chip[k] = v
            elseif path == "/peripherals/peripheral" then
                ctx.periph[k] = v
            elseif path == "/peripherals/peripheral/interrupt" then
                ctx.interrupt[k] = v
            elseif path == "/peripherals/peripheral/registers/register" then
                ctx.reg[k] = v
            elseif path == "/peripherals/peripheral/registers/register/fields/field" then
                ctx.field[k] = v
            end
        end)

    as_equates(chip, "", { chip = {}, interrupts = { max = 0 } })
end

-- arg 1 is lua file to process
function doit()
    local chip = dofile(arg[1])
    print_regs(chip)
end

doit()
