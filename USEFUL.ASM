$Title ('DTC/PC BIOS Useful Procedures V1.0')
$Pagelength (80) Pagewidth (132) Debug Nogen
Name Useful


;    Author:	Don K. Harrison

;    Start date:	December 14,1983	Last edit:	December 27,1983


;		************************
;		*  Module Description  *
;		************************

;	This module contains some useful subroutines,including:

;		Beep			Beeps the bell
;		PrintMessage		Prints a message ending in 0
;		WordOut			Outputs a word value from Ax
;		ByteOut			Outputs a byte value from Al
;		CharDut			Outputs a character in Al
;		NibbleOut		Outputs a single nibble from Al
;		CrtCrlf			Outputs a carriage return line feed
;		KeyIn			Gets character from keyboard
;		VideoInit		Initialize video from switches
;		ROMCheckBK		Rom checksum procedure
;		MemoryTest		Ram memory test
;		ClearScreen		Clear screen
;		PositionCursor		Position cursor from Ax


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

		Public	ByteOut, WordOut, CharOut, NibbleOut, KeyIn
		Public	PrintMessage, Beep, VideoInit, CrtCrLf
		Public	ROMCheck8K, MemoryTest, ROMCheckCx
		Public	ClearScreen, PositionCursor

;		*************
;		*  Equates  *
;		*************

AsciiCarriage	Equ	0DH			;Carriage return
AsciiLineFeed	Equ	0AH			;Line feed

$Include (IbmInc)
;		*************************
;		*  Global Include File  *
;		*************************
;$Nolist
$Eject

;		*******************
;		*  Data Segments  *
;		*******************


BiosDataArea	Segment Public
		Extrn EquipFlag:Word
BiosDataArea	Ends

$Eject
;		******************
;		*  Code Segment  *
;		******************

Bios		Segment Common

		Extrn	NMIInt:Near
		Assume	Cs:Bios, Ds:BiosDataArea

		Org	0F950H			;Available spot in ROM

;		*************************
;		*  Output a Byte Value  *
;		*************************

ByteOut		Proc	Near
		Push	Ax			;Save low nibble
		Mov	Cl,4			;...Shift it to lower nibble
		Shr	Al,Cl			;...and
		Call	NibbleOut		;...output it
		Pop	Ax			;Restore lower nibble
		Call	NibbleOut		;...and output it
		Ret				;...then return
ByteOut		Endp

;		*************************
;		*  Output a Word Value  *
;		*************************

WordOut		Proc	Near
		Push	Ax			;Save Lo byte
		Mov	Al,Ah			;Get Hi byte first
		Call	ByteOut			;...and output it
		Pop	Ax			;Get lo byte
		Call	ByteOut			;...and output it
		Ret				;...then return
WordOut		Endp

;		************************
;		*  Output a Character  *
;		************************

CharOut		Proc	Near
		Push	Bx			;Save Bx
		Push	Ax			;...and Ax
		Mov	Ah,VidCmdWrTTY		;Command = Write TTY
		Mov	Bl,7			;Foreground color if in graph.
		Int	TrapVideo		;Send char TTY style
		Pop	Ax			;Restore
		Pop	Bx			;...registers
		Ret				;...and return
CharOut		Endp

;		*********************
;		*  Output a Nibble  *
;		*********************

NibbleOut	Proc	Near
		Push	Ax			;Save Ax
		And	Al,0FH			;Strip upper, just in case
		Cmp	Al,9			;Is it greater than 9?
		Jbe	LessEqu9		;...jump if it isn't
		Add	Al,7			;...else add diff from 9 to A
LessEqu9:
		Add	Al,'0'			;Add ascii offset
		Call	CharOut			;....output it
		Pop	Ax			;Restore Ax
		Ret				;...and return
NibbleOut	Endp

;		*******************************
;		*  Carriage Return Line Feed  *
;		*******************************

CrtCrlf		Proc	Near
		Mov	Al,AsciiCarriage
		Call	CharOut
		Mov	Al,AsciiLineFeed
		Call	CharOut
		Ret
CrtCrlf		Endp

;		****************************
;		*  Get Keyboard Character  *
;		****************************

KeyIn		Proc	Near
		Mov	Ah,0			;Character command
		Int	TrapkeyDrive		;...do procedure
		Ret				;...and return
KeyIn		Endp

;		*********************
;		*  Print a Message  *
;		*********************

PrintMessage	Proc	Near
		Lodsb				;Get a character
		Or	Al,Al			;...is it 0?
		Jnz	PrintMsgCont		;...jump if not
		Ret				;...else return
PrintMsgCont:
		Call	CharOut			;...output it
		Jmp	PrintMessage		;...and loop till 0 found
PrintMessage	Endp

;		**********
;		*  Beep	 *
;		**********

Beep		Proc	Near
		Push	Ax			;Save Ax
		Push	Cx			;...and Cx
		Mov	Al,10110110B		;Setup timer
		Out	PortCTCMode,Al		;...2
		Mov	Ax,1320			;Save freq as IBM
		Out	PortCTCLoadCh2,Al	;...Lo byte
		Mov	Al,Ah			;...Hi
		Out	PortCTCLoadCh2,Al	;...byte
		In	Al,PortPPIPortB		;Get current value of ctl port
		Push	Ax			;...Save it
		Or	Al,00000011B		;Turn on the speaker
		Out	PortPPIPortB,Al		;...during the beep
		Xor	Cx,Cx			;Long count in Cx
BeepLoop:
		Loop	BeepLoop		;Wait
		Dec	Bl			;...decrement user supplied
		Jnz	BeepLoop		;...variable and loop till done
		Pop	Ax			;Restore port value prior to
		Out	PortPPIPortB,Al		;...beep and restore it
		Pop	Cx			;Restore used registers
		Pop	Ax			;...and
		Ret				;...return
Beep		Endp

;		********************************************
;		*  Video Default Initialization Procedure  *
;		********************************************

VideoInit	Proc	Near
		Mov	Ah,Byte Ptr EquipFlag	;Which card to init?
		And	Ah,30H			;Isolate display bits
		Mov	Al,0			;Mode = Monochrome
		Cmp	Ah,30H			;Is monochrome selected?
		Je	InitVidJmp		;...jump if so
		Mov	Al,1			;Mode = 40x25
		Cmp	Ah,10H			;Is color 40x25?
		Je	InitVidJmp		;...jump if so
		Mov	Al,3			;Mode = 80x25

InitVidJmp:
		Mov	Ah,VidCmdinit		;Command = initialize
		Int	TrapVideo		;...Al = target mode
		Ret
VideoInit	Endp

;		******************
;		*  Clear Screen  *
;		******************

ClearScreen	Proc	Near
		Mov	Dx,184FH		;Clear screen
		Xor	Cx,Cx			;...
		Mov	Ax,0600H		;...
		Mov	Bh,7			;...
		Int	TrapVideo		;...
		Mov	Ah,VidCmdCurPos		;Home the cursor
		Mov	Dx,0			;...
		Mov	Bh,0			;...
		Int	TrapVideo		;...
		Ret				;Return
ClearScreen	Endp

;		*********************
;		*  Position Cursor  *
;		*********************

PositionCursor	Proc	Near
		Push	Dx			;Save Dx
		Push	Bx			;...and Bx
		Mov	Dx,Ax			;Position from Ax
		Mov	Ah,VidCmdCurPos		;Load the command
		Mov	Bh,0			;...page 0
		Int	TrapVideo		;...Do-it
		Pop	Bx			;Restore
		Pop	Dx			;...registers
		Ret				;Return
PositionCursor 	endp

;		**********************************************************
;		*  ROM Checksum Procedure: Entry 1 = 8K,Entry 2 = (Cx)K  *
;		**********************************************************

ROMCheck8K	Proc	Near
		Mov	Cx,8192			;Length of ROM = 8k
ROMCHeckCx:
		Mov	Al,0			;Zero the checksum
ROMCheckLoop:
		Add	Al,DS:[Bx]		;Bx holds the offset
		Inc	Bx			;...inc it
		Loop	ROMCheckLoop		;...and loop till all added
		Or	Al,Al			;Affect Z flag with Al
		Ret				;...and return,if z=1,ros=ok
ROMCheck8k	Endp

;		****************************
;		*      Memory Test	   *
;		*--------------------------*
;		*  Es:80 = Start Address   *
;		*  Returns:		   *
;		*   If Cy = 0,NO ERROR	   *
;		*      else Es:Di = addr.  *
;		****************************


MemoryTest	Proc	Near
		Mov	Bx,1024			;Do a 1k Block
		Mov	Al,055H			;Start with 55H
		Xor	Di,Di			;Re-load pointer
		Mov	Cx,Bx			;Re-load count
	Rep	Stosb				;Write it
		Xor	Di,Di			;Re-load pointer
		Mov	Cx,Bx			;Re-load count
	Repe	Scasb				;Test memory with accum
		Jcxz	TestAA			;...jump if no error
		Stc				;Carry set indicates error
		Ret				;...return
TestAA:
		Xor	Di,Di			;Re-load pointer
		Mov	Cx,Bx			;Re-load count
		Not	Al			;Next is 55H
	Rep	Stosb				;Hrite it
		Xor	Di,Di			;Re-load pointer
		Mov	Cx,Bx			;Re-load count
	Repe	Scasb				;Test memory with accu
		Jcxz	Test01			;...jump if no error
		Stc				;Carry set indicates error
		Ret				;...return
Test01:
		Xor	Di,Di			;Re-load pointer
		Mov	Cx,Bx			;Re-load count
		Mov	Al,1			;Next is 1 (tests parity)
	Rep	Stosb				;Write it
		Xor	Di,Di			;Re-load pointer
		Mov	Cx,Bx			;Re-load count
	Repe	Scasb				;Test memory with accum
		Jcxz	Test00			;...jump if no error
		Stc				;Carry set indicates error
		Ret				;...return
Test00:
		Xor	Di,Di			;Re-load pointer
		Mov	Cx,Bx			;Re-load count
		Dec	Al			;Clear memory to zero & test
	Rep	Stosb				;Write it
		Xor	Di,Di			;Re-load pointer
		Mov	Cx,Bx			;Re-load count
	Repe	Scasb				;Test memory with accum
		Jcxz	NoMemError		;...jump if no error
		Stc				;Carry set indicates error
		Ret				;...return
NoMemError:
		Mov	Ax,Es			;Add 2K to segment register
		Add	Ax,1024 / 16		;...using paragraphs
		Mov	Es,Ax			;...put it back
		Ret				;Return carry clear if no error
MemoryTest	Endp

Bios	Ends

End