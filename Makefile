# Makefile to generate Lua tables from SVD files, and then muforth equates
# files from the Lua tables.

# They don't all work yet, so let's just use a few.
SVD_FILES=	$(wildcard SVD/*.svd)
#SVD_FILES=	SVD/MKL25Z4.svd SVD/MKL46Z4.svd SVD/MK66F18.svd

LUA_FILES=	$(notdir $(SVD_FILES:.svd=.lua))
MU4_FILES=	$(LUA_FILES:.lua=.mu4)

all : $(MU4_FILES)

$(LUA_FILES) $(MU4_FILES) : Makefile

$(LUA_FILES) : parse-svd.lua

$(MU4_FILES) : print-regs.lua

.PRECIOUS : $(LUA_FILES)

%.lua : SVD/%.svd
	lua parse-svd.lua $< > $@

%.mu4 : %.lua
	lua print-regs.lua $< > $@

clean :
	rm -f MK*.lua MK*.mu4
