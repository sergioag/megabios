$Title ('DTC/PC BIOS Public Data Definitions V1.0')
$Pagelength (80)
$Pagewidth (132)
$Debug
$Nogen
;$Pagelength (82) Pagewidth (132) Debug Nogen
Name  Publics


;    Author:	  Don K. Harrison

;    Start date:  October 31, 1983	Last edit:  December 7, 1983



;		************************
;		*  Module Description  *
;		************************

;	This module contains variable (data) definitions for the
;    bios software




;		(c) Display Telecommunications Corporation, 1983
;			 All Rights Reserved

$Eject


;		**********************
;		*  Revision History  *
;		**********************




$Eject
												
;		********************
;		*  Public Symbols  *
;		********************

		Public RS232Base, PrinterBase, EquipFlag, MfgTest
		Public MemorySize, MfgErrFlag, KeyboardFlag1, KeyboardFlag2
		Public AltInput, KeyBufHead, KeyBufTail, KeyBuffer
		Public KeyBufEnd, SeekStatus, MotorStatus, MotorCount
		Public DisketteStat, FDCStatus, CrtMode, CrtColumns
		Public CrtLength, CrtStart, CursorPosn, CursorMode
		Public ActivePage, ActiveCard, CrtModeSet, CrtPalette
		Public IOROMInit, IOROMSegment, IntrFlag, TimerLow
		Public TimerHigh, TimerOverflow, BiosBreak, ResetFlag
		Public FixedDisk1, FixedDisk2, PrintTimeOut, RS232TimeOut
		Public BufferStart, BufferEnd, PrintScnStatus
$Eject

;		***********************
;		*  Bios Data Segment  *
;		***********************

;BiosDataArea	Segment Public
BiosDataArea	Segment At 40H
RS232Base	Label Word
RS2321Addr	Dw	1 Dup(?)		;Active RS232 Card f
RS2322Addr	Dw	1 Dup(?)		;Active RS232 Card 2
RS2323Addr	Dw	1 Dup(?)		;Active RS232 Card 3
RS2324Addr	Dw	1 Dup(?)		;Active RSege Card 4
PrinterBase	Label	Word
Printer1Addr	Dw	1 Dup(?)		;Active Printer Card 1
Printer2Addr	Dw	1 Dup(?)		;Active Printer Card 2
Printer3Addr	Dw	1 Dup(?)		;Active Printer Card 3
Printer4Addr	Dw	1 Dup(?)		;Active Printer Card 4
EquipFlag	Dw	1 Dup(?)		;Configuration status
Mfgtest		Db	1 Dup(?)		;Not used
MemorySize	Dw	1 Dup(?)		;Memory size in K bytes
MfgErrFlag	Db	1 Dup(?)		;Not used
		Db	1 Dup(?)		;Not used
KeyboardFlag1	Db	1 Dup(?)		;Keyboard
KeyboardFlag2	Db	1 Dup(?)		;...Status
AltInput	Db	1 Dup(?)		;Keypad data
KeyBufHead	Dw	1 Dup(?)		;Pointer to head of keyboard buffer
KeyBufTail	Dw	1 Dup(?)		;Pointer to tail of keyboard buffer
KeyBuffer	Db	31 Dup (?)		;Keyboard buffer area
KeyBufEnd	Db	1 Dup(?)		;...and last byte of it
SeekStatus	Db	1 Dup(?)		;Drives 0-3 recalibrate status
MotorStatus	Db	1 Dup(?)		;Drives 0-3 sotor state
MotorCount	Db	1 Dup(?)		;Drive turn off counter
DisketteStat	Db	1 Dup(?)		;Returned status byte
FDCStatus	Db	7 Dup (?)		;765 status bytes storage
CrtMode	 	Db	1 Dup(?)		;Current mode
CrtColumns	Dw	1 Dup(?)		;Number of columns
CrtLength	Dw	1 Dup(?)		;Linear length of screen
CrtStart	Dw	1 Dup(?)		;Screen starting address
CursorPosn	Dw	8 Dup (?)		;Cursor position on each page
CursorMode	Dw	1 Dup(?)		;Cursor mode
ActivePage	Db	1 Dup(?)		;Which page active
ActiveCard	Dw	1 Dup(?)		;I/O address of active video
CrtModeSet	Db	1 Dup(?)		;Mode register setting
CrtPalette	Db	1 Dup(?)		;Palette setting
IOROMInit	Dw	1 Dup(?)		;Not used
IOROMSegment	Dw	1 Dup(?)		;Not used
IntrFlag	Db	1 Dup(?)		;Not used
TimerLow	Dw	1 Dup(?)		;Timer
TimerHigh	Dw	1 Dup(?)		;...Storage
TimerOverflow	Db	1 Dup(?)		;Timer overflow flag
BiosBreak	Db	1 Dup(?)		;If D7=1, break key hit
ResetFlag	Dw	1 Dup(?)		;Set to 1234 after initialization
FixedDisk1	Dw	1 Dup(?)		;Used by hard disk
FixedDisk2	Dw	1 Dup(?)		;Used by hard disk
PrintTimeOut	Label	Word
PrintTO1	Db	1 Dup(?)		;Printer 1 time out value
PrintTO2	Db	1 Dup(?)		;Printer 2 time out value
PrintTO3	Db	1 Dup(?)		;Printer 3 time out value
PrintTO4	Db	1 Dup(?)		;Printer 4 time out value

RS232TimeOut	Label	Word
RS232TO1	Db	1 Dup(?)		;Sio 1 time out value
RS232TO2	Db	1 Dup(?)		;Sio 2 tise out value
RS232TO3	Db	1 Dup(?)		;Sio 3 time out value
RS232TO4	Db	1 Dup(?)		;Sio 4 time out value

BufferStart	Dw	1 Dup(?)		;Temporary keyboard driver data area
BufferEnd	DW	1 Dup(?)		;Temporary keyboard driver data area

		Org	100H			;Physical address = 500H

PrintScnStatus	Db	1 Dup(?)		;Print screen driver status byte

BiosDataArea	Ends

End
