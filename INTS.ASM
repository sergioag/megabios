$Title ('DTC/PC BIOS Interrupts V1.0')
;$Pagelength (80) Pagewidth (132) Debug Nogen
Name Ints


;	Author:	Don K. Harrison

;	Start date:	October 25, 1983	Last edit:	December 26, 1983


;		************************
;		*  Module Description  *
;		************************

;	This module contains the interrupt vector addresses.




;		(c) Display Telecommunications Corporation, 1983
;			All Rights Reserved

$Eject


;		**********************
;		*  Revision History  *
;		**********************





$Eject


;		********************
;		*  Public Symbols  *
;		********************

		Public	RamVectors, ROMVectors, VideoTrapAddr, BasicTrapAddr
		Public	VidParamsTrapAddr, FloppyParamsTrapAddr
		Public	VideoGraphicsTrapAddr, IllegalInt, NMIInt
		Public	PrintScreenTrapAddr, NMITrapAddr

;		*************
;		*  Equates  *
;		*************

		;	All Equates in include file: IbmInc

$Include (IbmInc.Asm)
;		*************************
;		*  Global Include File  *
;		*************************
;$Nolist
$Eject



;		*********************************
;		*  Ram Based Interrupt Vectors  *
;		*********************************

;IntSegment	Segment Public
IntSegment	Segment At 0

RamVectors		Label	DWord
ZeroDivisionTrapAddr	Dd	1 Dup (?)	;Divide by zero vector
SingleStepTrapAddr	Dd	1 Dup (?)	;Single step vector
NMITrapAddr		Dd	1 Dup (?)	;Non maskable interrupt vector
BreakpointTrapAddr	Dd	1 Dup (?)	;Breakpoint interrupt vector
OverflowTrapAddr	Dd	1 Dup (?)	;Overflow interrupt vector
PrintScreenTrapAddr	Dd	1 Dup (?)	;Print screen vector
Undef1TrapAddr		Dd	1 Dup (?)	;Undefined vector #1
Undef2TrapAddr		Dd	1 Dup (?)	;Undefined vector #2


			;	Hardware interrupts

TimerHdwrTrapAddr	Dd	1 Dup (?)	;Timer interrupt
KeyboardHdwrTrapAddr	Dd	1 Dup (?)	;Keyboard interrupt
IRQ2HdwrTrapAddr	Dd	1 Dup (?)	;Interrupt 2 interrupt
Sio2HdwrTrapAddr	Dd	1 Dup (?)	;Serial channel 2 interrupt
Sio1HdwrTrapAddr	Dd	1 Dup (?)	;Serial channel 1 interrupt
HarDiskHdwrTrapAddr	Dd	1 Dup (?)	;Hard disk interrupt
FloppyHdwrTrapAddr	Dd	1 Dup (?)	;Floppy disk interrupt
PrinterHdwrTrapAddr	Dd	1 Dup (?)	;Printer interrupt



			;	Driver entry points

VideoTrapAddr		Dd	1 Dup (?)	;Video trap vector
EquipTrapAddr		Dd	1 Dup (?)	;Equipsent query vector
MemorySizeTrapAddr	Dd	1 Dup (?)	;Memory size query vector
FloppyTrapAddr		Dd	1 Dup (?)	;Diskette vector
CommsTrapAddr		Dd	1 Dup (?)	;Serial interface vector
CassetteTrapAddr	Dd	1 Dup (?)	;Cassette (dummy routine)
KeyboarTrapAddr		Dd	1 Dup (?)	;Keyboard driver vector
PrinterTrapAddr		Dd	1 Dup (?)	;Printer driver vector
BasicTrapAddr		Dd	1 Dup (?)	;Cassette basic vector
BootTrapAddr		Dd	1 Dup (?)	;Bootstrap loader trap vector
TODTrapAddr		Dd	1 Dup (?)	;Time of day vector
KeyBreakTrapAddr	Dd	1 Dup (?)	;Keyboard break address
TickTrapAddr		Dd	1 Dup (?)	;Timer break address


			;	Data Pointers

VidParamsTrapAddr	Dd	1 Dup (?)	;Video parameters
FloppyParamsTrapAddr	Dd	1 Dup (?)	;Disk parameters
VideoGraphicsTrapAddr	Dd	1 Dup (?)	;Video graphics characters


IntSegment	Ends

$Eject

;		**********************
;		*  Public Variables  *
;		**********************

;BiosDataArea	Segment Public
BiosDataArea	Segment At 40h
		Extrn MemorySize:Word, IntrFlag:Byte
BiosDataArea	Ends

		;Public	_ResetEntry
_Bios		Segment At 0F000H
		Org	0E05BH
_POREntry	Label Far
		Org	0E066H
_ResetEntry	Label Far
_Bios		Ends

;		***********************
;		*  ROM Based Segment  *
;		***********************

Bios		Segment Common
		Extrn	WordOut:Near, CharOut:Near, NibbleOut:Near, KeyIn:Near
		Extrn	PrintMessage:Near, Beep:Near, TimerHdwrInt:Far
		Extrn	KeyboardHdwrInt:Far, FloppyHdwrInt :Far
		Extrn	VideoDriver:Far, EquipDriver:Far
		Extrn	MemorySizeDriver:Far, FloppyDriver:Far, CommsDriver:Far
		Extrn	CassetteDriver:Far, KeyboardDriver:Far, PrinterDriver:Far
		Extrn	BootDriver:Far, TODDriver:Far, VidParamsPointer:Byte
		Extrn	FloppyParamsPointer:Byte, ResetEntry:Far, PorEntry:Far
		Extrn	VideoInit:Near, ClearScreen:Near, PositionCursor:Near

;		**************************
;		*  Parity Error Service  *
;		**************************

		Org	0F85FH			;Align with PC / Xt

		Assume	Cs:Bios, Ds:BiosDataArea

NMIInt		Proc	Far
		Push	Ax			;........................
		Push	Bx			;.			.
		Push	Cx			;.			.
		Push	Dx			;.	Save		.
		Push	Si			;.			.
		Push	Di			;.	  Registers	.
		Push	Bp			;.			.
		Push	Ds			;.			.
		Push	Es			;........................
		In	Al,PortPPIPortC		;Get NMI status port
		Test	Al,11000000B		;...any interrupts pending?
		Jnz	NMIOccurred		;...jump if yes
		Jmp	NMIReturn		;...else, ignore and return
NMIOccurred:
		Mov	Ax,BiosDataArea	 	;Point at our data area
		Mov	Ds,Ax			;...with Ds
		Call	VideoInit		;Initialize the video
		Push	Ds			;Save our seg
		Push	Cs			;Load code pointer
		Pop	Ds			;...into data pointer
		Mov	Si,Offset ParityMsg	;Print error message: 
		Call	PrintMessage		;Parity error at: ????? Cont?
		Pop	Ds			;Restore our seg
		Mov	Ax,0011H		;Re-position cursor
		Call	PositionCursor		;...for writing address

		;	Find error location

		Mov	Dx,PortNMIMask		;Point at parity controls
		Mov	Al,NMIMask		;Disable NMI's
		Out	PortNMIMask,Al		;...from causing further err’s
		Mov	Dx,PortPPIPortB		;Point at port
		In	Al,Dx			;Get pra controls
		Or	Al,00110000B		;Set them Hi
		Out	Dx,Al			;...clearing F/Fs
		And	Al,11001111B		;Set them Lo
		Out	Dx,Al			;...enabling them
		Mov	Cl,6			;Convert memory size from
		Mov	Bx,MemorySize		;...1k blocks to
		Shl	Bx,Cl			;...16 byte paragraphs
		Inc	Dx			;Bump to port C

		;	Setup Pointers

		Xor	Ax,Ax			;Start aragraph pointer at @
		Mov	Ds,Ax			;feeeto tes
ParagraphLoop:	
		Mov	Cx,16			;Number of bytes in a paragraph
		Xor	Si,Si			;First byte in paragraph
ByteLoop:
		Mov	Ah,[Si]			;Get a byte
		In	Al,Dx			;Get interrupt status bits
		Test	Al,11000000B		;...either set?
		Jnz	FoundError		;Jump if error found
		Inc	Si			;Increment byte pointer
		Loop	ByteLoop		;...else loop through paragraph
		Mov	Ax,Ds			;Get paragraph value
		Inc	Ax			;...ineremen it
		Mov	Ds,Ax			;...and
		Cmp	Ax,Bx			;...compare it to end
		Jne	ParagraphLoop		;...and loop till all done
		Jmp	NoErrorFound		;...no error detected, return
FoundError:
		Mov	[Si],Ah			;Set parity in memory
		Mov	Ax,Ds			;Get paragraph value
		Call	WordOut			;...and output it to screen
		Mov	Ax,Si			;Get byte value
		Call	NibbleOut		;...and output it
NoErrorFound:
		Mov	Ax,001DH		;Position cursor to end
		Call	PositionCursor		;...for retreiving answer
		Push	Ds			;Save our seg
		Push	Cs			;Load code pointer
		Pop	DS			;...into data pointer
		Mov	Si,Offset ContMsg	;Print error message: 
		Call	PrintMessage		; Cont?
		Pop	Ds			;Restore our seg
		In 	Al,PortPicOCW1		;Get interrupt mask
		Push	Ax			;...and save it
		Mov	Al,11111100B		;...unmask only clock and kbrd
		Out	PortPicOCW1,Al		;...output it
		Sti				;Turn ints back on
		Call	KeyIn			;Get keyboard data
		Push	Ax			;Save Ax
		Call	CharOut			;Echo keyboard response
		Pop	Ax			;Restore Ax
		Cmp	Al,'Y'			;...Y?
		Je	NMIReturn		;...jump and return if yes
		Cmp	Al,'y'			;...y?
		Je	NMIReturn		;...jump and return if yes
		Jmp	_POREntry		;Re-boot from cold start
NMIReturn:
		Call	ClearScreen		;Clear the screen
		Pop	Ax			;Restore mask
		Out	PortPicOCW1,Al		;...like before
		Mov	Dx,PortPPIPortB		;Point at port B
		In	Al,Dx			;Get parity controls
		Or	Al,00110000B		;Set them Hi
		Out	Dx,Al			;...clearing F/Fs
		And	Al,11001111B		;Set them Lo
		Out	Dx,Al			;...parity error ints again
		Mov	Al,NMIUnmask		;Clear NMI mask
		Out	PortNMIMask,Al		;...enabling
		Pop	Es			;........................
		Pop	Ds			;.			.
		Pop	Bp			;.			.
		Pop	Di			;.	Restore		.
		Pop	Si			;.			.
		Pop	Dx			;.	  Registers	.
		Pop	Cx			;.			.
		Pop	Bx			;.			.
		Pop	Ax			;........................
		Iret				;...and return, restore ints
ParityMsg	Db	'Parity error at: ?????',0

ContMsg		Db	' Cont?',0

NMIInt		Endp
$Eject

;		******************************************
;		*  Rom Based Vector Initialization Data  *
;		******************************************

		Org	0FEF3H			;Align with PC/Xt

RomVectors	Label	DWord

		;	Hardware interrupts

		Dw	TimerHdwrInt		;Timer interrupt
		Dw	KeyboardHdwrInt		;Keyboard interrupt
		Dw	IllegalInt		;Interrupt 2 interrupt
		Dw	IllegalInt		;Serial channel 2 interrupt
		Dw	IllegalInt		;Serial channel 1 interrupt
		Dw	IllegalInt		;Hard disk interrupt
		Dw	FloppyHdwrInt		;Floppy disk interrupt
		Dw	IllegalInt		;Printer interrupt

		;	Driver entry points

		Dw	VideoDriver		;Video driver trap vector
		Dw	EquipDriver		;Equipment query vector
		Dw	MemorySizeDriver	;Memory size query vector
		Dw	FloppyDriver		;Diskette driver vector
		Dw	CommsDriver		;Serial interface vector
		Dw	CassetteDriver		;Cassette (dummy routine)
		Dw	KeyboardDriver		;Keyboard driver vector
		Dw	PrinterDriver		;Printer driver vector
		Dw	IllegalInt		;Cassette basic vector
		Dw	BootDriver		;Bootstrap loader trap vector
		Dw	TODDriver		;Time of day vector
		Dw	DummyReturn		;Keyboard break address
		Dw	DummyReturn		;Timer break address

		;	Data Pointers

		Dw	VidParamsPointer	;Video parameters
		Dw	FloppyParamsPointer	;Disk parameters
		Dw	0			;Video graphics characters

$Eject

;		*******************************
;		*  Illegal Interrupt Handler  *
;		*******************************

IllegalInt	Proc	Near
		Push	Ds			;..................
		Push	Dx			;. Save Registers .
		Push	Ax			;..................
		Mov	Ax,BiosDataArea		;Load our data
		Mov	Ds,Ax			;...segment
		Mov	Al,00001011B		;Command to point at
		Out	PortPICOCW2,Al		;...in service register
		Nop
		In	Al,PortPICOCW2		;Get in-service register
		Mov	Ah,Al			;Save it for masking
		Or	Al,Al			;Zero?
		Jnz	NonZeroLevel		;...jump in not
		Mov	Al,0FFH			;Flag for non-hardware
		Jmp	Short IllegalReturn	;...jump and return
NonZeroLevel:
		In	Al,PortPICOCW1		;Get Mask Register
		Or	Al,Ah			;...mask off service level
		Out	PortPICOCW1,Al		;...in progress
		Mov	Al,PICEOI		;Interrupt ack
		Out	PortPICOCW2,Al		;...to 8259A
IllegalReturn:
		Mov	IntrFlag,Ah		;Set global variable
		Pop	Ax			;Restore
		Pop	Dx			;   Registers
		Pop	Ds			;      and
		Iret				;	 Return
IllegalInt	Endp

;		**************************
;		*  Compatibility Return  *
;		**************************

		Org	0FF53H			;Align with Xt and Pc
DummyReturn:
		Iret				;Return found in Pe and Xt

Bios		Ends

End