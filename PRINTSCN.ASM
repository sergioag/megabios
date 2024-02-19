$Title ('DTC/PC BIOS Print Screen Driver V1.0')
$Pagelength (80) Pagewidth (132) Debug Nogen
Name Printer


;	Author:	Don K. Harrison

;	Start date:	December 7,1983	 Last edit:	December 28,1983


;		************************
;		*  Module Description  *
;		************************
;
;	 This module contains the print screen interrupt routine
;    (Int 5)





;	(c) Display Telecommunications Corporation,1983
;			All Rights Reserved

$Eject

;		**********************
;		*  Revision History  *
;		**********************







$Eject

;		********************
;		*  Public Symbols  *
;		********************

		Public	PrintScreenInt


;		*************
;		*  Equates  *
;		*************

AsciiLineFeed		Equ	0AH		;Ascii line feed
AsciiCarriageReturn	Equ	0DH		;Ascii carriage return


$Include (Ibminc)
;		*************************
;		*  Global Include File  *
;		*************************
;$Nolist
$Eject

;		*******************
;		*  Data Segments  *
;		*******************

BiosDataArea	Segment Public
		Extrn PrintScnStatus:Byte
BiosDataArea	Ends
$Eject

;		******************
;		*  Code Segment  *
;		******************

Bios		Segment Common

		Org	0FF54H			;Align with Pc and Xt

		Assume	Cs:Bios,Ds:BiosDataArea

 PrintScreenInt	Proc	Far
		Sti				;Restore interrupts
		Push	Ds			;................
		Push	Ax			;.  Save	.
		Push	Bx			;.		.
		Push	Cx			;.    Registers .
		Push	Dx			;................
		Mov	Ax,BiosDataArea		;Load our segnent
		Mov	Ds,Ax			;...into Ds
		Cmp	PrintScnStatus,1	;In progress already?
		Je	InProgressEnd		;...jumP if so and return

		;	Set status = 1 = in progress

		Mov	PrintScnStatus,1	;set status

		;	Initialize printer

		Call	PCrlf			;Only needs a line feed

		;	Get cursor position

		Mov	Ah,VidCmdInfo		;Get page number and info
		Int	TrapVideo		;...for use later
		Push	Ax			;Save colunns
		Mov	Ah,VidCmdRdCurPos	;Read cursor position
		Int	TrapVideo		;...for restoration purposes
		Pop	Ax			;Get back coluams
		Push	Dx			;...and Save Cursor pos
		Mov	Ch,25			;Always do 25 rows
		Mov	Cl,Ah			;...and (Columns) columns
		Xor	Dx,Dx			;Start of screen = 0,0

		;	Print the screen

PrintScreenLoop:
		Mov	Ah,VidCmdCurPos		;Set cursor to next (first)
		Int	TrapVideo		;...line
		Mov	Ah,VidCmdRdCurChAt	;Read the
		Int	TrapVideo		;...Character
		Or	Al,Al			;If zero,
		Jnz	CharOk			;...then convert
		Mov	Al,' '			;...to a Space
CharOk:

		;	Print the character

		Push	Dx			;Save cursor position
		Xor	Dx,Dx			;Select printer 1
		Mov	Ah,Dl			;...print command
		Int	TrapPrintDrive		;Print it
		Pop	Dx			;Restore cursor

		;	Test for error

		Test	Ah,00100101B		;Error if any bit set
		Jz	NoError			;...jump if no error
		Mov	PrintScnStatus,0FFH	;Error status
		Jmp	Short PrintScnEnd
		
		;	Increment to next character position
NoError:
		Inc	Dl			;Bump column
		Cmp	Cl,Dl			;...is it right limit?
		Jnz	PrintScreenLoop		;...if not,loop
		Xor	Dl,Dl			;Do carriage return on screen
		Call	PCrlf			;Do carriage return on printer
		Inc	Dh			;Increment row
		Cmp	Dh,Ch			;...over Limit?
		Jnz	PrintScreenLoop		;...jump if not
		Mov	PrintScnStatus,0	;Indicate all done

		;	Restore cursor and return

PrintScnEnd:
		Pop	Dx			;Restore original
		Mov	Ah,VidCmdCurPos		;...cursor
		Int	TrapVideo		;...to screen
InProgressEnd:
		Pop	Dx			;................
		Pop	Cx			;. Restore	.
		Pop	Bx			;.  Registers	.
		Pop	Ax			;.	and	.
		Pop	Ds			;.	 Return	.
		Iret				;................


;		*****************************
;		*  Printer Carriage Return  *
;		*****************************

PCrlf		Proc	Near
		Push	Dx			;Save Dx
		Xor	Dx,Dx			;Select printer 1
		Mov	Ah,Dl			;...and command = print
		Mov	Al,AsciiLineFeed	;Send LF first
		Int	TrapPrintDrive		;...like IBM does
		Xor	Ah,Ah			;Ignore status
		Mov	Al,AsciiCarriageReturn	;Send Cr
		Int	TrapPrintDrive		;...next
		Pop	Dx			;Restore Dx
		Ret				;...and return
PCrlf		Endp

PrintScreenInt	Endp

Bios		Ends

End