-- A re-interpretation of Roberto's XML parser
-- Parse an ARM SVD chip description file

-- shortcuts
fmt  = string.format
push = table.insert
pop  = table.remove

-- for debugging, turn printing of parsing process on or off
--debug = function(s) io.stderr:write(s .. "\n") end
debug = function (s) end

function parseattrs(s)
    local attrs = {}
    string.gsub(s, "([%w:-]+)=([\"'])(.-)%2", function (name, _, value)
        attrs[name] = value
    end)
    return (#attrs > 0) and attrs or nil
end

function nicer(id)
    return (id:gsub("(%l)(%u)", function(last, first)
        return last.."_"..first:lower()
    end)):lower()
end

function parsexml(s)
    local first = 1
    local stack = {}    -- nesting of elements
    local cur = { id = "document" }     -- current element in stack
    push(stack, cur)

    -- Skip any xml directives
    while true do
        local xmlstart, xmlend = s:find("<%?xml.->", first)
        if xmlstart then
            debug("skipping " .. s:sub(xmlstart, xmlend))
            first = xmlend + 1
        else
            break
        end
    end

    -- Now parse everything else
    while true do
        local tagstart, tagend, closing, id, attrs =
            s:find("<(/?)([%w:-]+)(.-)>", first)

        if not tagstart then break end

        debug(fmt("<%s%s%s>", closing, id, attrs))

        if closing == "/" then
            if id ~= cur.id then
                error(fmt("closing %s with %s", cur.id, id))
            end
            -- If there is text between start and end tags, capture it
            -- as the text field of this element.
            local text = s:sub(first, tagstart-1)
                          :gsub("%s*(.*)%s*", "%1")    -- strip leading and trailing ws
            if text ~= "" then
                cur.text = text
            end

            -- Rewrite id to something nicer
            cur.id = nicer(id)

            -- pop closing elem, and make enclosing elem new cur
            pop(stack)
            cur = stack[#stack]
        else
            -- start of element
            local elem = { id = id
                         , attrs = parseattrs(attrs) }

            -- append elem to contents of cur
            cur.contents = cur.contents or {}
            push(cur.contents, elem)
            -- descend into elem and make it new cur
            push(stack, elem)
            cur = elem
        end
        first = tagend + 1
    end

    if #stack > 1 then
        error("unclosed "..cur.id)
    end
    return cur.contents
end

-- Function to visit each branch and leaf of a tree.
--
-- Gets passed two functions: a function for branches and a function for
-- leaves. Returns a function that takes a tree and any number of
-- arguments, which are passed along as accumulators or whatever. visit()
-- doesn't know or care about them.
--
-- Also note that visit() does *not* recurse into branches! That's
-- fn_branch's job, if that's what it wants to do. visit() will, by
-- default, only visit the "top-level" items of tree.

function visit(fn_branch, fn_leaf)
    return function(tree, ...)
        for _, i in ipairs(tree) do
            if i.contents then
                -- process branch node
                fn_branch(i, ...)
            else
                -- process leaf node
                fn_leaf(i, ...)
            end
        end
        return ...
    end
end

function indent(n) return (" "):rep(n) end

function print_as_lua(chip)
    local as_lua

    as_lua = visit(
        function(branch, n)
            io.write(fmt("%s{ id = %q, contents = {\n", indent(n), branch.id))
            as_lua(branch.contents, n + 4)
            io.write(fmt("%s} },\n", indent(n)))
        end,

        function(leaf, n)
            io.write(fmt("%s{ id = %q, text = %q },\n", indent(n), leaf.id, leaf.text))
        end)

    io.write "return {\n"
    as_lua(chip, 4)
    io.write "}\n"
end

-- arg 1 is file to process
function doit()
    local f = io.open(arg[1], "r")
    local s = f:read("a")   -- read entire file as a string
    f:close()
    print_as_lua(parsexml(s))
end

doit()
