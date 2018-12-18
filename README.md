# Why?

One of the issues with rolling your own language - especially if, like [muforth](https://muforth.nimblemachines.com/), it is a cross-compiler that targets microcontrollers - is that you need to find or create, for every chip you care about, "equates" files that describe the i/o registers, their memory addresses, and their bit definitions.

It's a lot of work - and error-prone - to type these in by hand. For the Freescale S08 and the Atmel AVR I was able to get pretty good results by "scraping" the PDF files by hand (yes, by hand, with a mouse), pasting the results into a file, and then running code that processed the text into a useful form.

For the STM32 ARM microcontrollers I wrote code that shoddily "parses" the .h files (which I found in their "Std Periph Lib" and STM32Cube zip files - I tried both) and prints out muforth code.

When I went looking for something similar for Freescale's Kinetis microcontrollers, I found the "Kinetis SDK", but was unable to find a recent (2.0) version that had definitions for all their chips. It doesn't seem to exist for 2.0. All I could find is the 1.3 version, which seems pretty old (it's from 2015). If corrections or additions have been made since then, where do I find them?

In the 100+ MB zip file (!!) that I downloaded, I found the gold mine. In

    KSDK_1.3.0/platform/devices/

there is a directory for each chip, and in that directory is a [CMSIS-SVD file - a gawdawful XML file that describes all the registers and register fields](http://www.keil.com/pack/doc/CMSIS/SVD/html/). I've included all of the CMSIS-SVD files here, in the directory `SVD/`.

# How do I use this?

I wrote two Lua scripts: one - `parse-svd.lua` - to parse the XML into a big Lua table and print it out, and one - `print-regs.lua` - to slurp in that big Lua table and print out register (and register field) definitions in a form that muforth can understand.

    make

will process the SVD files for the chips on the Freescale FRDM boards, first by generating a Lua representation of the SVD file, and then reading that in and generating a muforth (.mu4) file. Unfortunately, only the chips on 14 of the 25 FRDM boards that are shown on the [MCUXpresso SDK Builder](https://mcuxpresso.nxp.com/) are represented in the Kinetis SDK version 1.3.

    make kl

will process all the Kinetis L SVD files into `.mu4` files;

    make everything

will process *all* the SVD files into `mu4` files, but it's also *much* slower.

# What if my chip is missing from the list?

If there was an easy way to keep the SVD/ directory updated with the latest goodies from Freescale/NXP I would happily do it. Unfortunately, it seems that the only way to get updated versions of these files is to do it by hand, for each chip, on the [MCUXpresso SDK Builder](https://mcuxpresso.nxp.com/). (For the brave and curious, after downloading your "custom" SDK you'll find the SVD file for your chip in the ./devices/<chip>/<chip>.xml file.)

I'm not the only one with this problem. Even the [Zephyr project](https://github.com/zephyrproject-rtos/zephyr/tree/master/ext/hal/nxp/mcux) is struggling with getting up-to-date header files for NXP/Freescale chips.

[Getting Started with MCUXpresso SDK CMSIS Packs](https://www.nxp.com/docs/en/user-guide/MCUXSDKPACKSGSUG.pdf) - a document from November 2017 - talks about "CMSIS packs downloaded from MCUXpresso packs repository", including "Device Family Packs", which contain the following:

* Device header files and system initialization modules
* Startup files
* Linker files
* SVD files
* Flash drivers (for some of the development tools)
* SDK drivers and utilities
* SDK project templates

Sounds perfect, right? Sadly, there is no way to download these "CMSIS packs". I can't seem to find the "MCUXpresso packs repository", just the SDK Builder.

# What else can I do?

The infrastructure is there to generate *any* kind of output from the Lua-fied SVD files. If you have a favorite language that needs "equates" files for a Kinetis microcontroller, go forth and modify!

# BSD-licensed!

See the `LICENSE` file for details.
