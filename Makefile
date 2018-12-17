# Makefile to generate Lua tables from SVD files, and then muforth equates
# files from the Lua tables.

# Everything
SVD_FILES=	$(wildcard SVD/*.svd)
LUA_FILES=	$(notdir $(SVD_FILES:.svd=.lua))
MU4_FILES=	$(LUA_FILES:.lua=.mu4)

# FRDM boards subset
FRDM_CHIPS=	MK22F51212 MK28F15 MK28FA15 MK64F12 MK66F18 MK82F25615 \
		MKE02Z4 MKE04Z4 MKE06Z4 MKE15Z7 MKL02Z4 MKL03Z4 MKL25Z4 \
		MKL26Z4 MKL27Z644 MKL28Z7 MKL43Z4 MKL46Z4 MKL82Z7 MKV10Z7 \
		MKV11Z7 MKV31F51212 MKW24D5 MKW36Z4 MKW41Z4

# Some of the FRDM_CHIPS are missing from Kinetis SDK 1.3, or the SVD file is missing.
# Filter based on the .svd files in the SVD/ directory.
SVD_FRDM_FILES=	$(filter $(wildcard SVD/*.svd),$(patsubst %,SVD/%.svd,$(FRDM_CHIPS)))
LUA_FRDM_FILES=	$(notdir $(SVD_FRDM_FILES:.svd=.lua))
MU4_FRDM_FILES=	$(LUA_FRDM_FILES:.lua=.mu4)

# Kinetis_L subset
SVD_L_FILES=	$(wildcard SVD/MKL*.svd)
LUA_L_FILES=	$(notdir $(SVD_L_FILES:.svd=.lua))
MU4_L_FILES=	$(LUA_L_FILES:.lua=.mu4)

# By default, make just the FRDM boards subset
all : frdm

# FRDM boards subset
frdm : $(MU4_FRDM_FILES)

# Kinetis L subset
kl : $(MU4_L_FILES)

# Everything
everything : $(MU4_FILES)

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
