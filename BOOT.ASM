$Title ('DTC/PC BIOS Bootstrap Loader V1.0')
$Pagelength (80) Pagewidth (132) Debug Nogen
Name Boot


;	Author:	Don K. Harrison

;	Start date:	October 25, 1983	Last edit:	December 27, 1983


;		************************
;		*  Module Description  *
;		************************

;	  This module is called by interrupt 19 (TrapBoot).
;    It's function is to read in the boot image from the diskette
;    and transfer control to it.


;	     (c) Display Telecommunications Corporation, 1983
;			All Rights Reserved

$Eject


;		**********************
;		*  Revision History  *
;		**********************





$Eject


;		********************
;		*  Public Symbols  *
;		********************

		Public BootDriver

;		*************
;		*  Equates  *
;		*************

BootOffset	Equ	7C00H		;Location of loaded boot code
AsciiCarriage	Equ	0DH		;Carriage return code
AsciiLineFeed	Equ	0AH		;Line feed code

$Nolist
$Include (IbmInc.Asm)
;		*************************
;		*  Global Include File  *
;		*************************
;$Nolist
$List
$Eject
	
;		*******************
;		*  Data Segments  *
;		*******************

IntSegment	Segment Public
		Extrn FloppyParamsTrapAddr:DWord, BasicTrapAddr:DWord

IntSegment	Ends

BootSegment	Segment at 0
BootSegment	Ends

BasicSeg	Segment Common
		Assume Cs:BasicSeg
		Org	0
Basic	 	Label Far
BasicSeg	Ends
$Eject

;		******************
;		*  Code Segment  *
;		******************

Bios		Segment Common
		Extrn FloppyParamsPointer:DWord, ClearScreen:Near
		Extrn PrintMessage:Near, KeyIn:Near

		Assume Cs:Bios, Ds:IntSegment

		Org	0E6F2H			;Align with Xt and Pc

BootDriver:
		Jmp	BootContinue		;Jump to code

		Org	0E600H			;Place code above init
BootContinue:
		Sti				;Enable Interrupts
		Mov	Ax,IntSegment		;Point at vector segment
		Mov	Ds,Ax			;...make it data segment

		;	Initialize pointer to disk tables

		Mov	Word ptr FloppyParamsTrapAddr, Offset FloppyParamsPointer
		Mov	Word ptr FloppyParamsTrapAddr + 2, Cs

		;	Load from diskette

		Mov	Ax,4			;Reset try = 4 times
RetryLoop:
		Push	Ax			;Save count
		Mov	Ah,0			;Reset the diskette
		Int	TrapFDDriver		;...system
		Jc	BootFailed		;Carry set on error, try again
		Mov	Al,1			;Read in 1 sector
		Mov	Ah,DiskCmdRead		;Command in Ah
		Mov	Dx,BootSegment	  	;Point Es to bootstrap segment
		Mov	Es,Dx			;...(which is at zero)
		Mov	Bx,BootOffset		;Load Bx with address of
		Mov	Cl,1			;...first byte in boot area
		Mov	Ch,0			;Cl = sector 1, Ch = track 0
		Int	TrapFDDriver		;Execute disk I/O software
		Jc	BootFailed		;Jump and retry if error
		Assume	Cs:BootSegment		;Assume causes Jmp instr. to
		Jmp	Far ptr BootOffset	;...reference BootSegment
		Assume	Cs:Bios			;Back to Bios
BootFailed:
		Pop	Ax			;Restore count
		Dec	Al			;...and reduce it by 1
		Jnz	RetryLoop		;...keep trying till 0

		;	Ask user  . . What gives?
WhatGives:
		Or	Ah,Ah			;Second time around?
		Jnz	TryBasic		;...try to load basic
		Call	ClearScreen		;Clear the screen
		Push	Cs			;Print
		Pop	Ds			;...message
		Mov	Si,Offset LoadDiskMsg	;...telling him
		Call	PrintMessage		;...to insert diskette
		Call	KeyIn			;Get his response
		Call	ClearScreen		;Clear the screen
		Mov	Ax,0FF04H		;Try 4 more times, set flag
		Jmp	RetryLoop		;...try again

		;	Try to load basic

TryBasic:
		Xor	Ax,Ax			;Point at interrupt segment
		Mov	Ds,Ax			;...check
		Les	Ax,BasicTrapAddr	;...if basic available
		Mov	Bx,Es			;...for booting
		Cmp	Ax,Offset Basic		;Check offset
		Mov	Ax,0			;Clear flag incase failure
		Jne	WhatGives		;...jump if not basic
		Cmp	Bx,BasicSeg		;Check segment
		Jne	WhatGives		;...jump if not basic
		Jmp	Basic			;...else startup basic

LoadDiskMsg	Db	'Insert diskette in DRIVE A.',AsciiCarriage
		Db	AsciiLineFeed,'    Press any key.',0

Bios		Ends

End