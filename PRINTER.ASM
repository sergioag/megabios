$Title ('DTC/PC BIOS Parallel Printer Driver V1.0')
$Pagelength (80) Pagewidth (132) Debug Nogen
Name Printer


;	Author:	Don K. Harrison

;	Start date:	November 25, 1983	Last edit:	December 20, 1983


;		************************
;		*  Module Description  *
;		************************
;
;	This module handles the parallel printer driver, accessed via
;	interrupt 17H,





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

		Public PrinterDriver


;		*************
;		*  Equates  *
;		*************

		;	All Equates in include file: IbmInc

$Include (Ibminc.Asm)	
;		*************************
;		*  Global Include File  *
;		*************************
;$Nolist
$Eject

;		*******************
;		*  Data Segments  *
;		*******************

BiosDataArea	Segment Public
		Extrn PrintTimeOut:Byte, PrinterBase:Word
BiosDataArea	Ends
$Eject

;		******************
;		*  Code Segment  *
;		******************

Bios		Segment Common

		Assume	Cs:Bios, Ds:BiosDataArea

		Org	0EFD2H

PrinterDriver	Proc	Far
		Sti				;Restore interrupts
		Push	Ds			;Save registers
		Push	Bx			;...that
		Push	Cx			;...we
		Push	Dx			;...Will use
		Mov	Bx,BiosDataArea		;Point at our
		Mov	Ds,Bx			;...data sequent
		Mov	Bx,Dx			;Use Bx as index of ports
		Shl	Bx,1			;...(ports are words)
		Mov	Dx,PrinterBase[Bx]	;...and get our port
		Or	Dx,Dx			;if none, return
		Jz	PrinterReturn		;...no particular status

		;	Do case on command

		Or	Ah,Ah			;Case = 0?
		Jz	PrintChar		;...if so, Jump and print char
		Dec	Ah			;Case = 1?
		Jz	PrintInitialize		;...if so, init printer
		Dec	Ah			;Case = Fa)
		Jz	PrintStatus		;...if so, jump and return status

		;	If illegal command, just return

PrinterReturn:
		Pop	Dx			;Restore registers we
		Pop	Cx			;...used
		Pop	Bx			;...and
		Pop	Ds			;...return
		Iret				;...to caller

;		***************************
;		*  Print Character in Al  *
;		***************************

PrintChar	Proc	Near
		Out	Dx,Al			;Send char to printer
		Inc	Dx			;...then point at status
		Mov	Bh,PrintTimeOut[Bx]	;Get # of loops in Bh
		Mov	Ah,Al			;...save print character
PrintOuterLoop:
		Xor	Cx,Cx			;Maximum loop count
PrintInnerLoop:
		In	Al,Dx			;Get the status
		Or	Al,Al			;...and affect flags
		Js	StrobeChar		;...jump if not busy
		Loop	PrintInnerLoop		;...else loop till not busy
		Dec	Bh			;Decrement outer loop
		Jnz	PrintOuterLoop		;...and loop

		;	Timeout

		Or	Al,1			;...set timeout error
		And	Al,11111001B		;...mask unused bits
		Jmp	StatusReturn2		;...and return status
StrobeChar:
		Inc	Dx			;Point at command port
		Mov	Al,00001101B		;Strobe = high
		Out	Dx,Al			;...to printer

		;	This is an entry point from PrinterInitialize

StatusReturn3:

		Mov	Al,00001100B		;Strobe = low
		Out	Dx,Al			;...to printer
		Dec	Dx			;Point back at status
		Jmp	Short StatusReturn1	;...and return with it
PrintChar	Endp

;		***************************
;		*  Return Printer Status  *
;		***************************

PrintStatus	Proc	Near
		Mov	Ah,Al			;Preserve Al
		Inc	Dx			;Increment to status port
StatusReturn1:
		In	Al,Dx			;...and get status
		And	AL,011111000B		;...turn off unused bits
StatusReturn2:
		Xor	Al,01001000B		;...and flip sense of some
		Xchg	Al,Ah			;...Al=char, Ah=status
		Jmp	PrinterReturn		;...jump and return status
PrintStatus	Endp

;		************************
;		*  Initialize Printer  *
;		************************

PrintInitialize Proc	Near
		Mov	Ah,Al			;Preserve Al
		Inc	Dx			;Point at command
		Inc	Dx			;...port
		Mov	Al,00001000B		;Init bit
		Out	Dx,Al			;...to printer
		Mov	Cx,1500		;Delay
InitDelay:
		Loop	InitDelay		;...for reset pulse
		Jmp	StatusReturn3		;...then pus and turn off
						;...init bit and return status

PrintInitialize Endp

PrinterDriver	Endp

Bios		Ends

End