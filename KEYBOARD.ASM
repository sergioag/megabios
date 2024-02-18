$Title ('DTC/PC BIOS Keyboard Interface V1.0')
$Pagelength (80)
$Pagewidth (132)
$Debug
$Nogen
;$Pagelength (80) Pagewidth (132) Debug Nogen
Name Keyboard


;	Author:	Don K. Harrison

;	Start date:	November 3, 1983	Last edit:	December 17, 1983


;		************************
;		*  Module Description  *
;		************************

;	This module handles the keyboard interface through interrupt
;    16 (TrapKeyDrive).




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

		Public KeyboardDriver


$Eject


;		*******************
;		*  Data Segeents  *
;		*******************

BiosDataArea	Segment At 40H
		Extrn KeyboardFlag1:Byte
		Extrn KeyBufHead:Word, KeyBufTail:Word
		Extrn BufferStart:Word, BufferEnd:Word
BiosDataArea	Ends
$Eject

;		******************	
;		*  Code Segment  *
;		******************

Bios		Segment Common

		Assume 	Cs:Bios, Ds:BiosDataArea

		Org	0E82EH			;Align with PC and XT

KeyboardDriver 	Proc	Far
		Sti				;Restore interrupts
		Push	Ds			;Save Registers
		Push	Bx
		Mov	Bx,BiosDataArea		;Our data segment
		Mov	Ds,Bx			;...point to it

		;	Do Case Ah;

		Or	Ah,Ah			;Case = 0
		Jz	KeyRead			;...read ascii translation
		Dec	Ah			;Case = 1
		Jz	KeyStatus		;...read key status
		Dec	Ah			;Case = 2
		Jz	KeyShift		;...read shift status
KeyDrvReturn:
		Pop	Bx			;Case = ??? and general return
		Pop	Ds			;Restore registers
		Iret				;...and return

;		************************
;		*  Read the character  *
;		************************

KeyRead:
		Cli			;No ints while reading pointer
		Mov	Bx,KeyBufHead	;If heads = tails, buffer
		Cmp	Bx,KeyBufTail	;...is empty
		Jne	KeyBufRdy	;Jump if buffer has data
		Sti			;...else, restore ints and loop
		Jmp	Keyread		;...till something comes in
KeyBufRdy:
		Mov	Ax,[Bx]		;Get Ah=scan code Al=ascii
		Inc	Bx		;Remove char from buffer
		Inc	Bx		;...by adjusting pointers
		Mov	KeyBufHead,Bx	;...and
		Cmp	Bx,BufferEnd	;...circling
		Jne	KeyDrvReturn	;Jump and return if not at end
		Mov	Bx,BufferStart	;...else, sove the pointer
		Mov	KeyBufHead,Bx	;...to the start
		Jmp	KeyDrvReturn	;...and return
				
;		***********************
;		*  Return the Status  *
;		***********************

KeyStatus:
		Cli			;No ints while reading pointer
		Mov	Bx,KeyBufHead	;If heads = tails, buffer
		Cmp	Bx,KeyBufTail	;...is empty
		Mov	Ax,[Bx]		;Get the data (if any)
		Sti			;...restore interrupts
		Pop	Bx		;Restore registers, but
		Pop	Ds		;...keep the flags intact
		Ret	2		;(Like Iret, but flags not affected)
					;..Note: Interrupts leave enabled!!

;		**********************
;		*  Return the Shift  *
;		**********************

KeyShift:
		Mov	Al,KeyboardFlag1	;Get shift state flag
		Jmp	KeyDrvReturn		;...and return with it

KeyboardDriver 	Endp

Bios		Ends

End