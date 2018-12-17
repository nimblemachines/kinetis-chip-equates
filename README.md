# Why?

One of the issues with rolling your own language - especially if, like [muforth](https://muforth.nimblemachines.com/), it is a cross-compiler that targets microcontrollers - is that you need to find or create, for every chip you care about, "equates" files that describe the i/o registers, their memory addresses, and their bit definitions.

It's a lot of work - and error-prone - to type these in by hand. For the Freescale S08 and the Atmel AVR I was able to get pretty good results by "scraping" the PDF files by hand (yes, by hand, with a mouse), pasting the results into a file, and then running code that processed the text into a useful form.

For the STM32 ARM microcontrollers I wrote code that shoddily "parses" the .h files (which I found in their "Std Periph Lib" and STM32Cube zip files - I tried both) and prints out muforth code.

When I went looking for something similar for Freescale's Kinetis microcontrollers, I found the "Kinetis SDK", but was unable to find a recent (2.0) version that had definitions for all their chips. It doesn't seem to exist for 2.0. All I could find is the 1.3 version, which seems pretty old (it's from 2015). If corrections or additions have been made since then, where do I find them?

In the 100+ MB zip file (!!) that I downloaded, I found the gold mine. In

    KSDK_1.3.0/platform/devices/

there is a directory for each chip, and in that directory is an [SVD file - a gawdawful XML file that describes all the registers and register fields](http://www.keil.com/pack/doc/CMSIS/SVD/html/). I've included all of the SVD files here, in the directory `SVD/`.

# How do I use this?

I wrote two Lua scripts: one - `parse-svd.lua` - to parse the XML into a big Lua table and print it out, and one - `print-regs.lua` - to slurp in that big Lua table and print out register (and register field) definitions in a form that muforth can understand.

    make

will process the SVD files for the chips on the Freescale FRDM boards, first by generating a Lua representation of the SVD file, and then reading that in and generating a muforth (.mu4) file. Unfortunately, only 14 of the 25 FRDM boards that are shown on the [MCUExpresso site](https://mcuxpresso.nxp.com/) are represented in the Kinetis SDK version 1.3.

    make kl

will process the Kinetis L SVD files into `.mu4` files;

    make everything

will process *all* the SVD files into 'mu4' files, but it's also *much* slower.

If there was an easy way to keep the SVD/ directory updated with the latest goodies from Freescale/NXP I would happily do it.

# What else can I do?

The infrastructure is there to generate *any* kind of output from the Lua-fied SVD files. If you have a favorite language that needs "equates" files for a Kinetis microcontroller, go forth and modify!

# BSD-licensed!

See the `LICENSE` file for details.
