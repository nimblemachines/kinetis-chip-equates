# Makefile to generate Lua tables from SVD files, and then muforth equates
# files from the Lua tables.

#### Variables

# Everything
CUSTOM_FILES:=	$(wildcard SVD/custom/*.xml)
DFP_FILES:=	$(wildcard SVD/NXP_DFP/*.xml)
KSDK_FILES:=	$(wildcard SVD/KSDK-1.3.0/*.svd)

CUSTOM_CHIPS=	$(basename $(notdir $(CUSTOM_FILES)))
DFP_CHIPS=	$(basename $(notdir $(DFP_FILES)))
KSDK_CHIPS=	$(basename $(notdir $(KSDK_FILES)))

BROKEN=		MKE14Z4 MKE16Z4 MKE04Z4 MKE15Z4

ALL_CHIPS=	$(filter-out $(BROKEN),$(CUSTOM_CHIPS) $(DFP_CHIPS) $(KSDK_CHIPS))

LUA_FILES=	$(patsubst %,%.lua,$(ALL_CHIPS))
MU4_FILES=	$(LUA_FILES:.lua=.mu4)

# FRDM boards subset
FRDM_CHIPS=	MK22F51212 MK28F15 MK28FA15 MK64F12 MK66F18 MK82F25615 \
		MKE02Z4 MKE04Z4 MKE06Z4 MKE15Z7 MKL02Z4 MKL03Z4 MKL25Z4 \
		MKL26Z4 MKL27Z644 MKL28Z7 MKL43Z4 MKL46Z4 MKL82Z7 MKV10Z7 \
		MKV11Z7 MKV31F51212 MKW24D5 MKW36Z4 MKW41Z4

LUA_FRDM_FILES=	$(patsubst %,%.lua,$(filter $(FRDM_CHIPS),$(ALL_CHIPS)))
MU4_FRDM_FILES=	$(LUA_FRDM_FILES:.lua=.mu4)

# Kinetis_L subset
LUA_KL_FILES=	$(patsubst %,%.lua,$(filter MKL%,$(ALL_CHIPS)))
MU4_KL_FILES=	$(LUA_KL_FILES:.lua=.mu4)


#### Targets

.PHONY : frdm kl everything

# By default, make just the FRDM boards subset
all : frdm

# FRDM boards subset
frdm : $(MU4_FRDM_FILES)

# Kinetis L subset
kl : $(MU4_KL_FILES)

# Everything
everything : $(MU4_FILES)


#### Rules

$(LUA_FILES) : parse-xml.lua

$(MU4_FILES) : print-regs.lua

.PRECIOUS : $(LUA_FILES)

# NOTE: When make finds two pattern rules that match, it uses the *first* one.
# We want custom/ to override NXP_DFP/, and NXP_DFP/ to override KSDK-1.3.0/.
# Let's see if this actually works!

%.lua : SVD/custom/%.xml
	lua parse-svd.lua $< > $@

%.lua : SVD/NXP_DFP/%.xml
	lua parse-svd.lua $< > $@

%.lua : SVD/KSDK-1.3.0/%.svd
	lua parse-svd.lua $< > $@

%.mu4 : %.lua
	lua print-regs.lua $< > $@

.PHONY : clean

clean :
	rm -f MK*.lua MK*.mu4


#### Downloading and parsing Keil's CMSIS-Pack files

# Keil keeps a list of CMSIS "packs". We can grab the latest copy and use it
# as a source for SVD files.
# CMSIS-Pack files:       http://www.keil.com/pack/doc/CMSIS/Pack/html/
# CMSIS-Pack index files: http://www.keil.com/pack/doc/CMSIS/Pack/html/packIndexFile.html
# A pack's download URL is formed like this: <repo>/<vendor>.<packname>.<version>.pack

keil-pack-index.xml :
	curl -L -o $@ http://www.keil.com/pack/index.pidx

keil-pack-index.lua : keil-pack-index.xml parse-pack-index.lua
	lua parse-pack-index.lua $< > $@

.PHONY : get-packs show-packs unzip-packs update clean-dfp clean-packs spotless

show-packs : keil-pack-index.lua
	@lua gen-downloads.lua $< NXP "^MK.*_DFP$$" show

get-packs : keil-pack-index.lua
	mkdir -p pack
	lua gen-downloads.lua $< NXP "^MK.*_DFP$$" get | sh

unzip-packs : get-packs
	mkdir -p SVD/NXP_DFP
	for p in pack/*.pack; do unzip -u $$p "MK*.xml" -d SVD/NXP_DFP; done

update : unzip-packs

clean-dfp :
	rm -f keil-pack-index.*
	rm -rf SVD/NXP_DFP/

clean-packs : clean-dfp
	rm -rf pack/

spotless : clean clean-packs
