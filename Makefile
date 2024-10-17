# Makefile to generate Lua tables from SVD files, and then muforth equates
# files from the Lua tables.

#### Variables

FRDM_FILES=	$(wildcard svd/MK*.xml) KSDK-1.3.0/MKL25Z4.svd
FRDM_CHIPS=	$(basename $(notdir $(FRDM_FILES)))

# Let's do a very small subset right now. Things are pretty broken.
ALL_CHIPS=	MKL25Z4 MKL26Z4 MKL46Z4 rp2040

LUA_FILES=	$(patsubst %,%.lua,$(ALL_CHIPS))
MU4_FILES=	$(LUA_FILES:.lua=.mu4)

#### Targets

all :  $(MU4_FILES)

#### Rules

$(LUA_FILES) : parse-xml.lua

$(MU4_FILES) : print-regs.lua

.PRECIOUS : $(LUA_FILES)

# NOTE: When make finds two pattern rules that match, it uses the *first* one.

%.lua : svd/%.svd
	lua parse-xml.lua $< > $@

%.lua : svd/%.xml
	lua parse-xml.lua $< > $@

%.lua : KSDK-1.3.0/%.svd
	lua parse-xml.lua $< > $@

%.mu4 : %.lua
	lua print-regs.lua $< > $@

#### Raspberry Pi RP2040

# SVD source path
rp2040_path=	https://raw.githubusercontent.com/raspberrypi/pico-sdk/master/src/rp2040/hardware_regs/RP2040.svd

svd/rp2040.svd : svd
	curl -L -o $@ $(rp2040_path)

# Override the lua -> mu4 pattern for the rp2040.
rp2040.mu4 : rp2040.lua print-regs-generic.lua
	lua print-regs-generic.lua $< $(rp2040_path) > $@

#### Downloading and parsing Keil's CMSIS-Pack files

# Keil keeps a list of CMSIS "packs". We can grab the latest copy and use it
# as a source for SVD files.
# CMSIS-Pack files:       https://www.keil.com/pack/doc/CMSIS/Pack/html/
# CMSIS-Pack index files: https://www.keil.com/pack/doc/CMSIS/Pack/html/packIndexFile.html
# A pack's download URL is formed like this: <repo>/<vendor>.<packname>.<version>.pack

keil-pack-index.xml :
	curl -L -o $@ https://www.keil.com/pack/index.pidx

keil-pack-index.lua : keil-pack-index.xml parse-pack-index.lua
	lua parse-pack-index.lua $< > $@


# XXX Added some STM32 and GigaDevice GD32 rules. If I decide to use STM32 SVD
# files instead of .h files, I will need to download all th STM32 packs. I
# added the GD32 rules mostly to be able to make an equates file for the
# GD32VF103 RISC-V chip.
.PHONY : show-kinetis-packs get-kinetis-packs \
	show-stm32-packs get-stm32-packs \
	show-gd32-packs get-gd32-packs

pack :
	mkdir pack

show-kinetis-packs : keil-pack-index.lua
	@lua gen-downloads.lua $< NXP "^MKE.*_DFP$$" show
	@lua gen-downloads.lua $< NXP "^MKL.*_DFP$$" show

get-kinetis-packs : keil-pack-index.lua pack
	#lua gen-downloads.lua $< NXP "^MKE.*_DFP$$" get | sh
	lua gen-downloads.lua $< NXP "^MKL.*_DFP$$" get | sh

show-stm32-packs : keil-pack-index.lua
	@lua gen-downloads.lua $< Keil "^STM32F.*_DFP$$" show
	@lua gen-downloads.lua $< Keil "^STM32G.*_DFP$$" show

get-stm32-packs : keil-pack-index.lua pack
	lua gen-downloads.lua $< Keil "^STM32F.*_DFP$$" get | sh
	lua gen-downloads.lua $< Keil "^STM32G.*_DFP$$" get | sh

show-gd32-packs : keil-pack-index.lua
	@lua gen-downloads.lua $< GigaDevice "^GD32F10x.*_DFP$$" show

get-gd32-packs : keil-pack-index.lua pack
	lua gen-downloads.lua $< GigaDevice "^GD32F10x.*_DFP$$" get | sh

.PHONY : unzip-kinetis-packs unzip-stm32-packs unzip-gd32-packs \
	update

# NOTE: unzip -j will throw away paths, rather than recreating hierarchy
#
svd :
	mkdir svd

unzip-kinetis-packs : get-kinetis-packs svd
	for p in pack/NXP.MK*.pack; do unzip -aa -j -u $$p "MK*.xml" -d svd; done

unzip-stm32-packs : get-stm32-packs svd
	for p in pack/Keil.STM32*.pack; do unzip -aa -j -u $$p "*.svd" -d svd; done

unzip-gd32-packs : get-gd32-packs svd
	for p in pack/GigaDevice.GD32*.pack; do unzip -aa -j -u $$p "*.svd" -d svd; done

# XXX The stm32 packs are rather huge. Let's not grab them until/unless we
# decide to use SVD files rather than ST's .h files.
update : svd/rp2040.svd unzip-kinetis-packs #unzip-gd32-packs unzip-stm32-packs


#### Cleaning up the mess

.PHONY : clean clean-svd clean-packs clean-index spotless

clean :
	rm -f MK*.lua STM32*.lua GD32*.lua rp2040.lua *.mu4

clean-svd :
	rm -rf svd/

clean-packs :
	rm -rf pack/

clean-index :
	rm -f keil-pack-index.*

spotless : clean clean-index clean-packs clean-svd
