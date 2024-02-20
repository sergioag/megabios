# MEGA-BIOS V1.0 Reconstruction Project

### Display Telecommunications Corporation (DTC) MEGA-BIOS V1.0

Copyright &copy; 1983 Display Telecommunications Corporation (DTC)

Copyright &copy; 1985-1986 International Business Machines Corporation (IBM)

### The Project

This project is the work of @FinnJorgensen, @sergioag and @640-KB to reconstruct MEGA-BIOS V1.0 from the printed source code originally sold by DTC.

More information about DTC, MEGA-BIOS and it's legacy can be found [here](https://forum.vcfed.org/index.php?threads/display-telecommunications-corporation-megaboard.63853/) and [here](https://forum.vcfed.org/index.php?threads/anonymous-has-been-found.1246341/).

#### Goals

1. Preserve the original source code exactly as it was printed.
2. Document the source build process.
3. Provide fixes and updates to known bugs.

### Build instructions

**Prerequisites:**

1. A PC running real mode DOS, or emulator: [MartyPC](https://github.com/dbalsom/martypc), [VirtualXT](https://virtualxt.org/) or [86Box](https://86box.net/) are suggested. Note: since the `LINK86`/`LOC86` command line requires STDIN redirection, DOSBox will not work.
2. Intel ASM86 Macro Assembler complete tools: `ASM86.EXE`, `LINK86.EXE`, `LOC86.EXE` and `OH86.EXE` ([here](https://www.os2museum.com/wp/the-ibm-pc-bios-and-intel-isis-ii/) or [here](https://winworldpc.com/product/intel-asm86-macro-assembler/31)).
3. (Optional) Tool to convert [Intel HEX](https://en.wikipedia.org/wiki/Intel_HEX) output to binary. Example: [`objcopy`](https://www.linux.org/docs/man1/objcopy.html) or similar.
4. Tool to compute and add valid checksum to file offset `0x1fef`.

**Steps:**

1. Make sure ASM86 directory is in your `PATH` environment variable (ex: `PATH=C:\ASM86` or whever it is located).
2. Run `BUILD.BAT` in a DOS environment, which will produce `MB.HEX` in Intel Hex format.
3. (Optional) Convert to binary file format using one of the following methods:
   - objcopy: `objcopy --input-target=ihex --output-target=binary --gap-fill=255 mb.hex mb.bin`\
   - TODO: instructions for other programs.
4. Compute 8 bit file checksum in `mb.bin` and replace byte at `0x1fef` so that sum is `0`. TODO: include program to do this.

### Known Issues

#### V1.0
1. INITIAL.ASM: POST DMA Refresh test checks for a counter reading between `270H-290H` after a busy Loop of `0A00H` iterations. This will likely fail on anything other than a 4.77MHz 8088.
2. VIDEO.ASM: Light pen incorrectly checks for trigger as active high, but is actually active low.
3. VIDEO.ASM: During CGA snow/blanking wait, incorrectly jumps to outer loop instead of inner loop.
4. VIDEO.ASM: `Mov Bl,OffsetTable[Bx]` ASM 2.x requires `Mov Bl,Byte Ptr OffsetTable[Bx]`. TODO: confirm this is a change in behavior to ASM 1.x.
5. VIDEO.ASM: POST Memory test display occurs prior to video option ROM scan, so is not shown on EGA/VGA. Error messages are also displayed if an EGA/VGA card is installed.
