Boot Process
------------
This document describes the boot process of the Mega-Bios. These are the steps:

1. Sets addressing to the BIOS data area and reset flag to 0.
2. (Here also starts the warm boot) CPU flags and registers are tested. Any error here results in a halt with no other indication.
3. Mask NMI
4. Disable MDA and CGA cards
5. Setup keyboard, speaker, and memory refresh.
6. Test if memory refresh is working (error 8). *This step is broken if ran on anything except for a 8088 at 4.77MHz.*
7. Start timer
8. Enable expansion box
9. Find top of memory and zero everything.
10. Test first 2K of memory
11. Verify checksum of BIOS ROM (error 1).
12. Initialize PIC.
13. Initialize interrupt vectors.
14. Initialize Cassette Interrupt Vector if Basic if found.
15. Initialize NMI, print screen, and user graphics vectors.
16. Enable NMI interrupts.
17. Initialize video (both MDA and CGA)
18. Read configuration switches
19. Initialize video
20. Initialize keyboard
21. Initialize serial and parallel ports
22. Initialize game card
23. Initialize expansion ROMs (error 10)
24. Enable floppy, keyboard, and RTC interrupts.
25. Beep once
26. Show error message, if any (`System error XXX. Continue?`).
27. Print banner.
28. Call bootstrap interrupt.

