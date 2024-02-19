$Title ('DTC/PC BIOS Keyboard Interrupt Service Routine V1.0')
$Pagelength (80) Pagewidth (132) Debug Nogen
Name KeyInt


;	Author:	Don K. Harrison

;	Start date:	October 25, 1983	Last edit:	December 26, 1983


;		************************
;		*  Module Description  *
;		************************

;	This module processes the keyboard interrupt, interrupt 9.




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

		Public KeyboardHdwrInt

;		*************
;		*  Equates  *
;		*************

		;	Equates in include file: IbmInc

$Include (IbmInc.Asm)
;		*************************
;		*  Global Include File  *
;		*************************
$Nolist
InsBit		Equ	10000000B		;Flag bits
CapsBit		Equ	01000000B		;...indicating
NumBit		Equ	00100000B		;...shift
ScrollBit	Equ	00010000B		;...s
AltBit		Equ	00001000B		;...t
ControlBit	Equ	00000100B		;...a
LeftShiftBit	Equ	00000010B		;...t
RightShiftBit	Equ	00000001B		;...e
HoldBit		Equ	00001000B		;Hold state
BreakBit	Equ	10000000B		;Upper bit of scan
BiosBit		Equ	10000000B		;Break Key Flag

		;	Scan Code Definitions Used By Routine

Twokey		Equ	03H		;Scan code for 2 key
PrtScnkey	Equ	37H		;Scan code for print screen key
NumKey		Equ	45H		;Scan code for num lock key
ScrollKey	Equ	46H		;Scan code for scroll lock key
HomeKey		Equ	47H		;Scan code for home key
InsKey		Equ	52H		;Scan code for insert key
DelKey		Equ	53H		;Scan code for delete key
ControlZ	Equ	1AH		;Ascii code for control Z


$Eject
;		******************
;		*  Keyboard Map  *
;		******************

;Scan  Lower	Upper		Control		Alt		Table
;Code  Case	Case		Case		Case		Entry
;
;01 1BXX ESC	1BXX 1B		1BXX ESC	NO VALUE	37
;02 31XX 1	21XX !		NO VALUE	0078 ALT 1	2E
;03 32XX 2	40XX @		0003 NUL	0079 ALT 2	20
;04 33XX 3	23XX #		NO VALUE	007A ALT 3	2F
;05 34XX 4	24XX $		NO VALUE	007B ALT 4	30
;06 35XX 5	25XX Percent	NO VALUE	007C ALT 5	31
;07 36XX 6	5EXX ^		1EXX RS		007D ALT 6	21
;08 37XX 7	26XX &		NO VALUE	007E ALT 7	32
;09 38XX 8	2AXX *		NO VALUE	007F ALT A	33
;0A 39XX 9	2BXX (		NO VALUE	0080 ALT 9	34
;0B 30XX 0	29XX )		NO VALUE	0081 ALT 0	35
;0C 2DXX -	5FXX _		1FXX US		0082 ALT -	22
;0D 3DXX =	2BXX +		NO VALUE	0083 ALT =	36
;0E 08XX BS	08XX BS		7FXX DEL	NO VALUE	38
;0F 09XX TAB	000F BK TB	NO VALUE	NO VALUE	3E
;10 71XX q	51XX Q		11XX DC1	0010 ALT q	11
;11 77XX w	57XX W		17XX ETB	0011 ALT w	17
;12 75XX e	55XX E		05XX END	0012 ALT e	05
;13 72XX r	52XX R		12XX DC2	0013 ALT r	12
;14 74XX t	54XX T		14XX DC4	0014 ALT t	14
;15 79XX y	59XX Y		19XX EM		0015 ALT y	19
;16 7EXX u	55XX U		15XX NAK	0016 ALT u	15
;17 6AXX i	4AXX I		09XX HT		0017 ALT i	09
;18 6FXX o	4FXX O		0FXX SI		0018 ALT o	0F
;19 70XX p	50XX P		10XX DLE	0019 ALT p	10
;1A 5BXX [	7BXX {		1BXX ESC	NO VALUE	39
;1B 5DXX ]	7DXX }		1DXX GS		NO VALUE	3A
;1C 0DXX CR	0DXX CR		0AXX LF		NO VALUE	3B
;1D --  CTRL	--   CTRL	--  CTRL	-- CTRL      84	10000100
;1E 61XX a	41XX A		01XX SOH	001E ALT a	01
;1F 73XX s	53XX S		13XX DC3	001F ALT s	13
;20 64XX d	44XX D		04XX EOT	0020 ALT d	04
;21 66XX f	46XX F		06XX ACK	0021 ALT f	06
;22 67XX g	47XX G		07XX BEL	0022 ALT g	07
;23 68XX h	48XX H		08XX BS		0023 ALT h	08
;24 6AXX j	4AXX J		0AXX LF		0024 ALT j	0A
;25 6BXX k	4BXX K		0BXX VT		0022 ALT k	0B
;26 6CXX 1	4CXX L		0CXX FF		0026 ALT l	0C
;27 3BXX ;	3AXX :		NO VALUE	NO VALUE	3F
;28 27XX '	22XX "		NO VALUE	NO VALUE	40
;29 60XX `	7EXX ~		NO VALUE	NO VALUE	41
;2A -- SHIFT	-- SHIFT	-- SHIFT	-- SHIFT     82	10000010
;2B 5CXX \	7CXX |		1CXX FS		NO VALUE	3C
;2C 7AXX z	58XX Z		1AXX SUB	002C ALT z	1A
;2D 7BXX x	58XX X		18XX CAN	002D ALT x	18
;2E 63XX c	43XX C		03XX ETX	002E ALT c	03
;2F 76XX v	56XX V		16XX SYN	002F ALT v	16
;30 62XX b	42XX B		02XX STX	0030 ALT b	02
;31 6EXX n	4EXX N		0EXX SO		0031 ALT n	0E
;32 6DXX m	4DXX M		0DXX CR		0032 ALT m	0D
;33 2CXX ,	3CXX (		NO VALUE	NO VALUE	42
;34 2EXX .	3EXX )		NO VALUE	NO VALUE	43
;35 2FXX /	3FXX ?		NO VALUE	NO VALUE	44
;36 -- SHIFT	-- SHIFT	-- SHIFT	-- SHIFT     81	10000001
;37 2AXX *	SPCL PRT SC	0072 PR ECH	NO VALUE	3D
;38 -- ALT	-- ALT		-- ALT		-- ALT	     88	10001000
;39 20XX SPACE	20XX SPACE	20XX SPACE	20XX SPACE	2D
;3A -- CAP LK	-- CAP LK	-- CAP LK	-- CAP LK    C0	11000000
;3B 003B F1	0054 SHF F1	005E CTL F1	0068 ALT F1	23
;3C 003C F2	0055 SHF F2	005F CTL F2	0069 ALT F2	24
;3D 003D F3	0036 SHF F3	0062 CTL F3	086A ALT F3	25
;3E 003E F4	0057 SHF F4	0061 CTL F4	006B ALT F4	26
;3F 003F F5	0058 SHF F5	0062 CTL F5	006C ALT F5	27
;40 0040 F6	0059 SHF F6	0063 CTL F6	006D ALT F6	28
;41 0041 F7	005A SHF F7	0064 CTL F7	006E ALT F7	29
;42 0042 F8	005B SHF F8	0065 CTL F8	006F ALT F8	2A
;43 0042 F9	005C SHF F9	0066 CTL F9	0070 ALT F9	2B
;44 0044 F10	005D SHF F10	0067 CTL F10	0071 ALT F10	2C
;45 -- NUM LK 	--   NUM LK	-- NUM LK	-- NUM LK    A0 10100000
;46 -- SCL LK	--   SCL LK	-- SCL LK	-- SCL LK    98	10010000
$Eject

;		***************************
;		*  Keyboard Map By Value  *
;		***************************

;		Directly Encodable Values

;Scan  Lower	Upper		Control		Alt		Table
;Code  Case	Case		Case				Entry
;----  -----	-----		-----		----		-----
;1E 61XX a	41XX A		01XX SOH	001E ALT a	01
;30 62XX b	42XX B		02XX STX	0030 ALT b	02
;2E 63XX c	43XX C		03XX ETX	002E ALT c	03
;20 64XX d	44XX D		04XX EOT	0020 ALT d	04
;12 75XX e	55XX E		05XX ENQ	0012 ALT e	05
;21 66XX f	46XX F		06XX ACK	0021 ALT f	06
;22 67XX g	47XX G		07XX BEL	0022 ALT g	07
;23 68XX h	48XX H		08XX BS		0023 ALT h	08
;17 6AXY i	4AXX I		09XX HT		0017 ALT i	09
;24 6AXX j	4AXX J		0AXX LF		0024 ALT j	0A
;25 6BXX k	4BXX K		0BXX VT		0022 ALT k	0B
;26 6CXX l	4CXX L		0CXX FF		0026 ALT l	0C
;32 6DXX m	4DXX M		0DXX CR		0032 ALT m	0D
;31 6EXX n	4EXX N		0EXX SO		0031 ALT n	0E
;18 6FXX o	4FXX O		0FXX SI		0018 ALT o	0F
;19 70XX p	50XX P		10XX DLE	0019 ALT p	10
;10 71XX q	51XX Q		11XX DC1	0010 ALT q	11
;13 72XX r	53XX R		12XX DC2	0013 ALT r	12
;1F 73XX s	53XX S		13XX DC3	001F ALT s	13
;14 74XX t	54XX T		14XX DC4	0014 ALT t	14
;16 75XX u	55XX U		15XX NAK	0016 ALT u	15
;2F 76XX v	56XX V		16XX SYN	002F ALT v	16
;11 77XX w	57XX W		17XX ETB	0011 ALT w	17
;2D 78XX x	58XX X		19XX CAN	002D ALT x	18
;15 79XX y	59XX Y		19XX EM		0015 ALT y	19
;2C 7AXX z	58XX Z		1AXX SUB	002C ALT z	1A
$Eject


;		Level Two Values

;Scan Lower	Upper		Control		Alt		Table
;Code Case	Case		Case		Case		Entry
;---- -----	-----		-----		----		-----
;03 32XX 2	40XX 0		0003 NUL	0079 ALT 2	20
;07 3EXX 6	5EXX ^		1EXX RS		007D ALT 6	21
;0C 2DXX -	5FXX		1FXX US		0082 ALT -	22
;38 003B F1	0054 SHF F1	005E CTL F1	0068 ALT F1	23
;30 003C F2	0055 SHF F2	005F CTL F2	0069 ALT F2	24
;3D 003D F3	0056 SHF F3	0068 CTL F3	005A ALT F3	25
;3E 003E F4	0057 SHF F4	0051 CTL F4	005B ALT F4	26
;ar 003F FS	0058 SHF FS	0062 CTL FS	00EC ALT FS	27
;40 0040 FE	0059 SHF FG	0063 CTL F6	006D ALT F6	28
;41 0041 F7	005A SHF F7	0064 CTL F7	00GE ALT F7	29
;42 0042 F8	005B SHF F8	0065 CTL F8	00EF ALT F8	2A
;43 0042 F9	005C SHF F9	0066 CTL F9	0070 ALT F9	2B
;44 0044 F10	005D SHF F10	0067 CTL F10	0071 ALT F10	2C
;39 20XX SPACE	20XX SPACE	20XX SPACE	20XX SPACE	2D
;82 31XX 1	21XX !		NO VALUE	0078 ALT 1	2E
;04 33XX 3	23XX #		NO VALUE	007A ALT 3	2F
;05 34XX 4	24XX $		NO VALUE	007B ALT 4	38
;06 35XX 5	25XX Percent	NO VALUE	007C ALT 5	31
;08 37XX 7	26XX &		NO VALUE	007E ALT 7	3e
;09 38XX 8	2AXX *		NO VALUE	007F ALT 8	33
;0A 39XX 9	28XX (		NO VALUE	0080 ALT 9	34
;0B 30XX 0	29XX )		NO VALUE	0081 ALT 0	35
;0D 3DXX =	2BXX +		NO VALUE	0083 ALT =	36
;01 1BXX ESC	1BXX 1B		1BXX ESC	NO VALUE	37
;0E 08XX BS	08XX BS		7FXX DEL	NO VALUE	38
;1A 5BXX [	7BXX {		1BXX ESC	NO VALUE	39
;1B 5DXX 1	7DXX }		1DXX GS		NO VALUE	3A
;1C 0DXX CR	0DXX CR		0AXX LF		NO VALUE	3B
;2B 5CXX \	7CXX |		iCXX FS		NO VALUE	3C
;37 2AXX +	SPCL PRT SC	0072 PR ECH	NO VALUE	3D
;0F 09XX TAB	000F BK TB	NO VALUE	NO VALUE	3E
;27 3BXX ;	3AXX :		NO VALUE	NO VALUE	3F
;28 27XX '	22XX "		NO VALUE	NO VALUE	40
;29 60XX `	7EXX ~		NO VALUE	NO VALUE	4l
;33 2CXX ,	3CXX {		NO VALUE	NO VALUE	42
;34 2EXX .	3EXX }		NO VALUE	NO VALUE	43
;35 2FXX /	3FXX ?		NO VALUE	NO VALUE	44
;
;
;		Shift Keys
;
;Scan Lower	Upper		Control		Alt		Table
;Code Case	Case		Case		Case		Entry
;---- -----	-----		-----		----		-----
;36 --	SHIFT	--   SHIFT	--  SHIFT	-- SHIFT	81 10000001
;2A --	SHIFT	--   SHIFT	--  SHIFT	-- SHIFT	82 10000010
;1D --	CTRL	--   CTRL	--  CTRL	-- CTRL		84 10000100
;38 --	ALT	--   ALT	--  ALT		-- ALT		88 10001000
;46 --	SCL LK	--   SCL LK	--  SCL LK	-- SCL LK	90 10010000
;45 --	NUN LK	--   NUM LK	--  NUM	LK	-- NUM LK	A0 10100000
;3A --	CAP LK	--   CAP LK	--  CAP LK	-- CAP LK	C0 11000000
$Eject

;		*******************
;		*  Data Segments  *
;		*******************

BiosDataArea	Segment Public
		Extrn KeyboardFlag1:Byte, KeyboardFlag2:Byte
		Extrn AltInput:Byte, KeybufHead:Word, KeyBufTail:Word
		Extrn KeyBuffer:Byte, ResetFlag:Word, BufferStart:Word
		Extrn BufferEnd:Word, BiosBreak:Byte
		Extrn CrtMode:Byte, CrtModeSet:Byte
BiosDataArea	Ends
$Eject

;		******************
;		*  Code Segment  *
;		******************

Bios		Segment Common
ByteType	Label	Byte			;Used for xlat instruction typing

		Extrn ResetEntry:Far

;		*********************
;		*  Level One Table  *
;		*********************

		;	This table is pointed to by scan codes 1 - 70
		;	It's value (V) is encoded as follows:
		;
		;	1<=V<=1FH	V     = Control code for key.
		;			V+40H = Upper case code for key.
		;			V+60H = Lower case code for key.
		;			Scan  = Alt case code for key.
		;	20H<=V<=44H	V-20H = Offset into level two table.
		;				(Key requires two levels of
		;				 encoding. )
		;	81H<=V<=0C4H	V-80H = Shift Key encoding for
		;				KeyboardFlagi and KeyboardFlagé
		;				(INS key handled as special
		;				and is not encoded)

LevelOneStruc	Struc							;-Scan-
		Db	000H, 037H, 02EH, 020H, 02FH, 030H, 031H, 021H	; 0 - 7
		Db	032H, 033H, 034H, 035H, 022H, 036H, 038H, 03EH	; 8 - 15
		Db	011H, 017H, 005H, 012H, 014H, 019H, 015H, 009H	;16 - 22
		Db	00FH, 010H, 039H, 03AH, 03BH, 084H, 001H, 013H	;24 - 31
		Db	004H, 006H, 007H, 008H, 00AH, 00BH, 00CH, 03FH	;32 - 39
		Db	040H, 041H, 082H, 03CH, 01AH, 018H, 003H, 016H	;40 - 47
		Db	002H, 00EH, 00DH, 042H, 043H, 044H, 081H, 03DH	;48 - 55
		Db	088H, 02DH, 0C0H, 023H, 024H, 025H, 026H, 027H	;56 - 63
		Db	028H, 029H, 02AH, 02BH, 02CH, 0A0H, 090H	;64 - 70
LevelOneStruc	Ends
			
;		**********************
;		*  Level Two Tables  *
;		**********************

		;	These tables are pointed to by the level
		;	one table. Each section of the table is
		;	37 bytes long. The values (V) are encoded as
		;	follows:
		;
		;	0<=V<=4	     Return Ah=V+80H, Al=0 (Special extended)
		;	V=5	     Return Nothing (No value for key comb.)
		;	6<=V<=7FH    Return Ah=Scan,  Al=V (Normal)
		;	80H<=V<=0FFH Return Ah=Scan,  Al=0 (Extended)

LevelTwoStruc	Struc				;Define structure

		;	Lower Case Tables

LowerCase	Db	032H, 036H, 02DH, 0BBH, 0BCH, 0BDH, 0BEH, 0BFH
		Db	0C0H, 0C1H, 0C2H, 0C3H, 0C4H, 020H, 031H, 033H
		Db	034H, 035H, 037H, 038H, 039H, 030H, 03DH, 01BH
		Db	008H, 05BH, 05DH, 00DH, 05CH, 02AH, 009H, 03BH
		Db	027H, 060H, 02CH, 02EH, 02FH

		;	Upper Case Tables

UpperCase	Db	040H, 05EH, 05FH, 0D4H, 0D5H, 0D6H, 0D7H, 0D8H
		Db	0D9H, 0DAH, 0DBH, 0DCH, 0DDH, 020H, 021H, 023H
		Db	024H, 025H, 026H, 02AH, 028H, 029H, 02BH, 01BH
		Db	008H, 07BH, 07DH, 00DH, 07CH, 005H, 08FH, 03AH
		Db	022H, 07EH, 03CH, 03EH, 03FH

		;	Control Case Tables

ControlCase	Db	003H, 01EH, 01FH, 0DEH, 0DFH, 0E0H, 0E1H, 0E2H
		Db	0E3H, 0E4H, 0E5H, 0E6H, 0E7H, 020H, 005H, 005H
		Db	005H, 005H, 005H, 005H, 005H, 005H, 005H, 01BH
		Db	07FH, 01BH, 01DH, 00AH, 01CH, 0F2H, 005H, 005H
		Db	005H, 005H, 005H, 005H, 005H

		;	ALT Case Tables

ALTCase		Db	0F9H, 0FDH, 002H, 0E8H, 0E9H, 0EAH, 0EBH, 0ECH
		Db	0EDH, 0EEH, 0EFH, 0F0H, 0F1H, 020H, 0F8H, 0FAH
		Db	0FBH, 0FCH, 0FEH, 0FFH, 000H, 001H, 003H, 005H
		Db	005H, 005H, 005H, 005H, 005H, 005H, 005H, 005H
		Db	005H, 005H, 005H, 005H, 005H

LevelTwoStruc	Ends

$Eject

;		******************************
;		*  Keypad Translation Table  *
;		******************************

PadStruc	Struc
Shift		Db	'789-456+1230.'
Control		Db	0F7H, 005H, 004H, 005H, 0F3H, 005H, 0F4H, 005H
		Db	0F5H, 005H, 0F6H, 005H, 005H
Base		Db	0C7H, 0C8H, 0C9H, 02DH, 0CBH, 005H, 0CDH, 02BH
		Db	0CFH, 0D0H, 0D1H, 0D2H, 0D3H
PadStruc	Ends

$List
;		*********************************
;		*  Structure Memory Allocation  *
;		*********************************
;	Align next to Keyboard Driver
Org	0E987H - (Size(LevelOneStruc) + Size(LevelTwoStruc) + Size(PadStruc))

;$Nolist

LevelOneTable	LevelOneStruc <>	;
LevelTwoTable	LevelTwoStruc <>	;
PadTable	PadStruc <>

LastTableByte	Equ	$-1		; This byte should be 0E986H
$Eject

;		**************************
;		*  Keyboard Driver Code  *
;		**************************

		Assume Cs:Bios, Ds:BiosDataArea

		Org	0E987H			;Align with Pe and Xt

KeyboardHdwrInt Proc	Far
		Sti				;Restore interrupts
		Push	Ax			;Save all registers
		Push	Bx			;...R
		Push	Cx			;...e
		Push	Dx			;...g
		Push	Si			;...i
		Push	Di			;...s
		Push	Ds			;...t
		Push	Es			;...e
						;...r
						;...s
		Cld				;Set string direction forward
		Mov	Ax,BiosDataArea		;Load data segment
		Mov	Ds,Ax			;...register with bios data
		In	Al,PortPPIPortA		;Get keyboard scan code
		Push	Ax			;...and save it for later
		In	Al,PortPPIPortB		;Get B port data
		Push	Ax			;...and save it
		Or	Al,10000000B		;Set reset bit
		Out	PortPPIPortB,Al		;...clearing int rq f/f
		Pop	Ax			;Restore B port value
		Out	PortPPIPortB,Al		;...and reset keyboard i/f
		Pop	Ax			;Restore scan code
		Mov	Ah,Al			;...and make a copy in AH

		;	FF in scan code indicates an overrun

		Cmp	Al,0FFH			;Is it overrun?
		Jne	KeyNotOverrun		;...jump if not
		Jmp	KeyBeepReturn		;...else beep and return
KeyIntReturn:
		Mov	Al,PICEOI		;Restore interrupts
		Out	PortPICOCW2,Al		;...for futher keyboard entry
KeyReturnNoEOI:
		Pop	Es			;Restore the
		Pop	Ds			;...R
		Pop	Di			;...e
		Pop	Si			;...g
		Pop	Dx			;...i
		Pop	Cx			;...s
		Pop	Bx			;...t
		Pop	Ax			;...e
		Iret				;...r
						;...s
						;...and return
KeyNotOverrun:
		And	Al,07FH			;Remove shift bit
		Cmp	Al,ScrollKey		;Keypad, or reguiar key?
		Jbe	InTable			;...jump if regular
		Jmp	KeyPadState		;...else process keypad
InTable:
		Mov	Bx,Offset LevelOneTable ;Point [Bx] to table
		Xlat	Cs:ByteType		;...and convert scan from table
		Or	Al,Al			;Is value shift code?
		Js	ModifierTest		;...jump if it is
		Or	Ah,Ah			;Is break bit on? (key release)
		Js	KeyIntReturn		;...if it is, ignore and return
		Jmp	KeyContinue1		;...else, process non-modifier

;		***************************
;		*  Process Modifier Keys  *
;		***************************

;	Note:	The insert key is both a modifier and a data key.
;		It is processed in the data key section as a special case.

ModifierTest:
		And	Al,7FH			;Remove Modifier flag bit
		Or	Ah,Ah			;Test scan code if make/break
		Js	BreakingModifier	;...and jump if key released

		;	Modifier Key Being Pressed

		Cmp	Al,ScrollBit		;Test if toggle type or normal
		Jae	ToggleMake		;...and jump if toggle

		;	Normal (not a toggle) Modifier

		Or	KeyboardFlag1,Al	;...else set bit indicating
		Jmp	KeyIntReturn		;...a modifier is pressed

		;	Toggle Modifier

ToggleMake:
		Test	KeyboardFlag1,ControlBit ;Do not toggle if control
		Jnz	KeyContinue1		;...key (ctl num lock, etc...)
		Test	Al,KeyboardFlag2	;Is the key depressed now?
		Jnz	KeyIntReturn		;...jump if it is and ignore
		Or	KeyboardFlag2,Al	;...else show dep. in flag 2
		Xor	KeyboardFlag1,Al	;Toggle state bit if flag 1
		Jmp	KeyIntReturn		;...and return

		;	Modifier Key Being Released

BreakingModifier:
		Cmp	Al,ScrollBit		;Test if toggle type or normal
		Jae	ToggleBreak		;...and jump if toggle

		;	Normal (not a toggle) Modifier - Breaking

		Not	Al			;Turn off key depressed
		And	KeyboardFlag1,Al	;...bit
		Cmp	Al,Not AltBit		;(Value of alt key mask here)
		Jne	KeyIntReturn		;Jump if not alt key release

		;	Return collected data on release of ALT key

		Mov	Al,AltInput		;Get the data
		Xor	Ah,Ah			;Get a zero
		Mov	AltInput,Ah		;...and zero data for next try
		Cmp	Al,Ah			;If input = 0, don't
		Je	KeyIntReturn		;...return any data
		Jmp	KeyBufLoad		;...else return data w/scan=2

		;	Toggle Modifier - Breaking

ToggleBreak:
		Not	Al			;turn off toggle key
		And	KeyboardFlag2,Al	;...depressed bit
		Jmp	KeyIntReturn		;...and return

;		*****************************
;		*  Test Special Conditions  *
;		*****************************

KeyContinue1:
		;	Control Num Lock Hold State Test

		Test	KeyboardFlag2,HoldBit	;Is hold state bit set?
		Jz	KeyContinue4		;...jump if not
			
		;	Restore from hold state

		Cmp	Ah,NumKey		;Is this control num?
		Je	HoldIntReturn		;...if so, don't restore
		And	KeyboardFlag2,Not HoldBit  ;...else clear hold state
HoldIntReturn:
		Jmp	KeyIntReturn		;...and return

;		*********************************
;		*  What Shift State are We In?	*
;		*********************************

		;	Ah = Scan Code, Al = Value From Level 1 Table

KeyContinue4:
		Test	KeyboardFlag1,AltBit		;Alt?
		Jnz	AltState		;...Yes, Jump
		Test	KeyboardFlag1,ControlBit	;Control?
		Jnz	ControlState		;...Yes, jump, else test shift
		Test	KeyboardFlag1,LeftShiftBit Or RightShiftBit
		Jnz	ShiftStateShort		;...yes, jump
		Jmp	BaseCaseState		;No shift state active
ShiftStateShort:
		Jmp	ShiftState		;Convert to near jump


;		*************************
;		*  Alt State Processor	*
;		*************************

AltState:
		Cmp	Al,ControlZ		;Is Level 1 <= Control Z?
		Ja	AltNotAZ		;...jump if not and continue
		Mov	Al,0			;...else return extended
		Jmp	KeyBufLoad2		;...Al = 0, Ah = Scan
ALtNotAZ:
		Mov	Bx,Offset LevelTwoTable.ALTCase ;Load Level Two Pointer
		Sub	Al,20H			;Remove level two char offset
		Xlat 	Cs:ByteType		;Translate level 1 to level 2
		Jmp	KeyBufLoad		;Jump and load buffer

;		*****************************
;		*  Control State Processor  *
;		*****************************

		;	Process specials

		;	Control Break?
ControlState:
		Cmp	Ah,ScrollKey		;Are we processing Scroll Key?
		Jnz	KeyContinue5		;...jump if not
		Mov	BiosBreak,BiosBit	;Turn on Bios Break Bit
		Mov	Ax,Bufferstart		;Clear keyboard buffer
		Mov	KeyBufTail,Ax		;...
		Mov	KeyBufHead,Ax		;...
		Int	TrapKeyBreak		;Trap to keyboard break driver
		Sub	Ax,Ax			;...In case of return
		Jmp	KeyBufLoad		;...send some data back

		;	Set Hold State?

KeyContinue5:
		Cmp	Ah,NumKey		;Are we processing Num key?
		Jnz	KeyContinue3		;...jump if not
		Or	KeyboardFlag2,HoldBit	;...else set hold bit
		Mov	Al,PICEOI		;Restore interrupts
		Out	PortPICOCW2,Al		;...for futher keyboard entry
		Cmp	CrtMode,7		;Test if monochrome adapter
		Je	HoldLoop		;...and jump if if is
		Mov	Dx,PortColorMode	;...else, turn color card
		Mov	Al,CrtModeSet		;...on during keyboard pause
		Out	Dx,Al			;...so user can see screen
HoldLoop:
		Test	KeyboardFlag2,HoldBit	;Wait for recursive interrupt
		Jnz	HoldLoop		;...to clear flag
		Jmp	KeyReturnNoEOI		;...and return

		;	Null?
KeyContinue3:
		Cmp	Ah,TwoKey		;Control 2?
		Jne	KeyContinue7		;...jump if not
		Mov	Al,0			;...else return a null
CtlBufLoad:
		Jmp	KeyBufLoad2		;Jump and load buffer

		;	Else process normal control key
KeyContinue7:
		Cmp	Al,ControlZ		;Is Level 1 (= Control 2?
		Jbe	CtlBufLoad		;...return level 1 val. if so
		Mov	Bx,Offset LevelTwoTable.ControlCase  ;Load level 2
		Sub	Al,20H			;Remove level two char offset
		Xlat	Cs:ByteType		;Translate level 2 data into Al
		Jmp	KeyBufLoad		;...and load into buffer

;		***************************
;		*  Shift State Processor  *
;		***************************
ShiftState:

		;	Handle Special Cases

		Cmp	Ah,PrtScnKey		;Are we processing print scn
		Jnz	KeyContinue6		;...jump if not
		Mov	Al,PICEOI		;Allow futher interrupts
		Out	PortPICOCW2,Al		;...and keystrokes
		Int	TrapPrintScreen		;Perform print screen
		Jmp	KeyReturnNoEoi		;...and return

KeyContinue6:
		Cmp	Al,ControlZ		;Is Level 1 <= Control 72?
		Ja	ShiftNotAZ		;...jump if not and continue
		Add	Al,40H			;...else return extended
		Jmp	KeyBufLoad		;...Al = L1+40H Ah = Scan
ShiftNotAZ:
		Mov	Bx,Offset LevelTwoTable.UpperCase  ;Load level 2
		Sub	Al,20H			;Remove level two char offset
		Xlat	Cs:ByteType		;Translate level 2 data into Al
		Jmp	KeyBufLoad		;Jump and load buffer

;		*************************
;		*  Base Case Processor  *
;		*************************

BaseCaseState:
		Cmp	Al,ControlZ		;Is Level 1 <= Control Z?
		Ja	BaseNotAz		;...jump if not and continue
		Add	Al,60H			;...else return extended
		Jmp	KeyBufLoad		;...Al = LI+60H Ah = Scan
BaseNotAZ:
		Mov	Bx,Offset LevelTwoTable.LowerCase ;Load level 2
		Sub	Al,20H			;Remove level two char offset
		Xlat	Cs:ByteType		;Translate level 2 data into Al
		Jmp	KeyBufLoad		;Jump and load buffer

;		**********************
;		*  Keypad Processor  *
;		**********************

KeyPadState:
		Sub	Al,HomeKey		;Calculate table offset
		Mov	Bl,KeyboardFlag1	;Use Bl for faster action
		Test	Bl,AltBit		;Alt?
		Jnz	PadALTState		;...yes, Jump process numeric
		Test	Bl,ControlBit		;Control?
		Jnz	PadControlState		;...yes, jump else test shift
		Test	Bl,NumBit		;Num Lock?
		Jz	KeyPadContinue		;...jump if not
		Test	Bl,LeftShiftBit Or RightShiftBit  ;Shifted?
		Jnz	PadBaseState		;...Shifted numloc=BaseState
		Jmp	Short PadShiftState	;...Unshifted numloc=ShiftState
KeyPadContinue:
		Test	Bl,LeftShiftBit Or RightShiftBit  ;Shifted?
		Jnz	PadShiftState		;...Yes, jump
		Jmp	PadBaseState		;No shift state active
PadALTState:
		Or	Ah,Ah			;Affect flags
		Js	PadReturn		;...ignore if breaking

		;	Test for Reset sequence

		;	Are we in the control and alt shift state?

		Test	KeyboardFlag1,ControlBit	;Is control pressed?
		Jz	KeyPadCont2		;...........jump if not
		Cmp	Ah,DelKey		;Are we processing DEL?
		Jne	KeyPadCont2		;...jump if not
		Mov	ResetFlag,1234H		;...else, set reset flag
		Jmp	ResetEntry		;...and reset the system
KeyPadCont2:
		Mov	Bx,Offset PadTable.Shift  ;Point at numeric translation
		Xlat	Cs:ByteType		;Translate from table
		Cmp	Al,'0'			;Test if ( @ (.+)
		Jb	PadReturn		;...and return null if it is
		Sub	Al,'0'			;...else remove ascii offset
		Mov	Bl,Al			;Free up accumulator
		Mov	Al,AltInput		;Get keypad accumulator
		Mov	Ah,10			;...and shift it left 1 decimal
		Mul	Ah			;...then add
		Add	Al,Bl			;...this number
		Mov	AltInput,Al		;...in
PadReturn:
		Jmp	KeyIntReturn		;...and return

PadControlState:
		Or	Ah,Ah			;Affect Flags
		Js	PadReturn		;...ignore if breaking
		Mov	Bx,Offset PadTable.Control ;Use control table
		Xlat	Cs:ByteType		;Translate from scan to data
		Jmp	KeyBufLoad
PadBaseState:
		Cmp	Ah,Inskey Or 80H	;Breaking INS key?
		Jne	NotBrkIns		;...jump if not
		And	KeyboardFlag2,Not InsBit	;Show INS key released
		Jmp	PadReturn		;...and return
NotBrkIns:
		Or	Ah,Ah			;Affect flags
		Js	PadReturn		;...ignore if breaking
		Cmp	Ah,InsKey		;Special case of insert key
		Jne	NotInskey		;...jump if not that key
		Test	KeyboardFlag2,InsBit	;Is the insert key pressed now?
		Jnz	PadReturn		;...if it is, ignore repeat
		Xor	KeyboardFlag1,InsBit	;...else toggle Ins shift bit
		Or	KeyboardFlag2,InsBit	;...and show key depressed
						;...then go ahead and send code
NotInskey:
		Mov	Bx,Offset PadTable.Base ;Use base table
		Xlat	Cs:ByteType		;Translate from scan to data
		Jmp	KeyBufLoad
PadShiftState:
		Or	Ah,Ah			;Affect flags
		Js	PadReturn		;...ignore 1f breaking
		Mov	Bx,Offset PadTable.Shift ;Use Shift table
		Xlat	Cs:ByteType		;translate from scan to data
		Jmp	KeyBufLoad
$Eject
;		**************************
;		*  Load Keyboard Buffer  *
;		**************************

	;	Upon entry, Al = ASCII code from table, Ah = scan code
	;	Entry one, KeyBufLoad, will perform a Final translation
	;	if the value in Al is between 0 and 4, 80 will be added.
	;
	;	Entry two, KeyBufLoad2, will not perform this translation.
	;	It is used by the control state processor to return control
	;	codes which fall in this range. In either case, if the
	;	upper bit is set upon entry, the value in Al is moved into
	;	Ah and, the upper bit reset, and a zero is returned as the
	;	Character from Al. The buffer is then loaded

KeyBufLoad:
		Cmp	Al,5			;No value?
		Je	BufLoadReturn		;...return and ignore
		Cmp	Al,4			;Is value (= 4?
		Ja	BufNotSpcl		;...jump if not
		Or	Al,10000000B		;Turn on upper bit
		Jmp	Short BufContinue	;...and continue below
BufNotSpcl:
		Test	Al,10000000B		;Is upper bit set?
		Jz	BufContinue2		;...jump if not
		And	Al,01111111B		;Turn off upper bit
BufContinue:
		Mov	Ah,Al			;...and move it in as scan
		Mov	Al,0			;Indicate extended code

		;	Caps Lock

BufContinue2:
		Test	KeyboardFlag1,CapsBit	;Are we in capslock?
		Jz	BufLoad			;...jump if not
		Test	KeyboardFlag1,LeftShiftBit Or RightShiftBit		;Shift?
		Jz	BufLowerToUpper		;...jump if not, conv. lo to up

		;	Convert Upper to Lower

		Cmp	Al,'A'			;>= A
		Jb	BufLoad			;...jump if not and load buffer
		Cmp	Al,'Z'			;<= Z
		Ja	BufLoad			;...jump if not and load buffer
		Add	Al,'a'-'A'		;Add offset to lower
		Jmp	BufLoad			;...and go load buffer

		;	Convert Lower to Upper

BufLowerToUpper:
		Cmp	Al,'a'			;>= a
		Jb	BufLoad			;...jump if not and load buffer
		Cmp	Al,'z'			;<= z
		Ja	BufLoad			;...jump if not and load buffer
		Sub	Al,'a'-'A'		;Add offset to lower

		;	Finally done, load buffer

KeyBufLoad2:
BufLoad:
		Mov	Bx,KeyBufTail		;Get the tail (target address)
		Mov	Di,Bx			;Di points where we'll put char
		Inc	Bx			;Bump the tail
		Inc	Bx			;...
		Cmp	Bx,BufferEnd		;Are we at the end?
		Jne	BufCont2		;...jump if not
		Mov	Bx,BufferStart		;...else, move the pointer
BufCont2:
		Cmp	Bx,KeyBufHead		;Tail = Head?
		Jne	BufCont3		;...jump if not
		Jmp	KeyBeepReturn		;...else beep and return
BufCont3:
		Mov	[Di],Ax			;Store scan and ascii in buf.
		Mov	KeyBufTail,Bx		;...move the pointer
BufLoadReturn:
		Jmp	KeyIntReturn		;...and return

;		*******************
;		*  Keyboard Beep  *
;		*******************

KeyBeepReturn:
		Mov	Al,PICEOI		;Restore interrupts
		Out	PortPICOCW2,Al		;...and futher keyboard
		Mov	Bx,128			;Short tone, same as PC
		In	Al,PortPPIPortB		;Get audio control state
		Push	Ax			;...and save it
BeepCycle:
		And	Al,011111100B		;Turn off gate
		Out	PortPPIPortB,Al		;...and data
BeepHalfCycle:
		Mov	Cx,100			;Half cycle time
BeepLoop:
		Loop	BeepLoop		;...loop for half a cycle
		Xor	Al,00000010B		;Turn on speaker
		Out	PortPPIPortB,Al		;...Speaker data
		Test	Al,00000010B		;Is this second pass?
		Jz	BeepHalfCycle		;...loop if not
		Dec	Bx			;Decrement cycle count
		Jnz	BeepCycle		;...and cycle till done
		Pop	Ax			;Restore port value
		Out	PortPPIPortB,Al		;...from stack and output it
		Mov	Cx,50			;Pause at end of beep
PauseBeep:
		Loop	PauseBeep		;...for tonal quality
		Jmp	KeyReturnNoEOI		;...and return

KeyboardHdwrint Endp

Bios		Ends
End