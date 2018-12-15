# Makefile to generate Lua tables from SVD files, and then muforth equates
# files from the Lua tables.

# Everything
SVD_FILES=	$(wildcard SVD/*.svd)
LUA_FILES=	$(notdir $(SVD_FILES:.svd=.lua))
MU4_FILES=	$(LUA_FILES:.lua=.mu4)

# Kinetis_L subset - much faster to make, enough for many FRDM boards
SVD_L_FILES=	$(wildcard SVD/MKL*.svd)
LUA_L_FILES=	$(notdir $(SVD_L_FILES:.svd=.lua))
MU4_L_FILES=	$(LUA_L_FILES:.lua=.mu4)

all : fast

fast : $(MU4_L_FILES)

slow : $(MU4_FILES)

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
