# MEGA-BIOS V1.0 Reconstruction Project

### Display Telecommunications Corporation (DTC) MEGA-BIOS V1.0

Copyright &copy; 1983 Display Telecommunications Corporation (DTC)

Copyright &copy; 1985-1986 International Business Machines Corporation (IBM)

Author:	Don K. Harrison

### The Project

This project is the work of @FinnJorgensen, @sergioag and @640-KB to reconstruct MEGA-BIOS V1.0 from the [printed source code listing](https://theretroweb.com/motherboard/manual/dtc-mega-bios-listing-65a16bd9ed44e544310124.pdf) originally sold by DTC.

More information about DTC, MEGA-BIOS and it's legacy can be found [here](https://forum.vcfed.org/index.php?threads/display-telecommunications-corporation-megaboard.63853/) and [here](https://forum.vcfed.org/index.php?threads/anonymous-has-been-found.1246341/).

#### Goals

1. Preserve the original source code exactly as it was printed.
2. Document the source build process.
3. Provide fixes and updates to known bugs.

### Build instructions

**Prerequisites:**

1. PC running [MASM32 toolkit](https://masm32.com/)

**Steps:**

1. Make sure MASM32 directory is in your `PATH` environment variable (ex: `PATH=C:\MASM32\BIN` or wherever it is located).
2. Run `BUILD.BAT` in a DOS environment, which will produce `MEGABIOS.ROM`, a binary ROM file 8192 bytes long.

### Known Issues

#### V1.0
1. INITIAL.ASM: POST DMA Refresh test checks for a counter reading between `270H-290H` after a busy Loop of `0A00H` iterations. This will likely fail on anything other than a 4.77MHz 8088.
2. VIDEO.ASM: Light pen incorrectly checks for trigger as active high, but is actually active low.
3. VIDEO.ASM: During CGA snow/blanking wait, incorrectly jumps to outer loop instead of inner loop.
4. VIDEO.ASM: `Mov Bl,OffsetTable[Bx]` ASM 2.x requires `Mov Bl,Byte Ptr OffsetTable[Bx]`. TODO: confirm this is a change in behavior to ASM 1.x.
5. VIDEO.ASM: POST Memory test display occurs prior to video option ROM scan, so is not shown on EGA/VGA. Error messages are also displayed if an EGA/VGA card is installed.
