$Title ('DTC/PC BIOS Video Driver V1.0')
$Pagelength (80) Pagewidth (132) Debug Nogen
Name Video


;    Author:		 Don K. Harrison

;    Start date:  November 26,1983	Last edit:  December 27,1983


;		************************
;		*  Module Description  *
;		************************
;
;	This module,accessed via interrupt 10H,handles both alpha
;   and graphics video modes of either type viceo interface card.





;		   (c) Display Telecommunications Corporation,1983
;			All Rights Reserved

$Eject


;		**********************
;		*  Revision History  *
;		**********************







$Eject

;		********************
;		*  Public Symbols  *
;		********************

		Public VideoDriver,VidParamsPointer



;		*************
;		*  Equates  *
;		*************

AsciiBackspace	Equ	08H			;Ascii characters
AsciiLineFeed	Equ	0AH			;...for
AsciiCarriage	Equ	0DH			;...TTY
AsciiBell	Equ	07H			;...procedure

$Include (IbmInc.Asm)
;		*************************
;		*  Global Include File	*
;		*************************
;$Nolist
$Eject

;		*******************
;		*  Data Segments  *
;		*******************

IntSegment	Segment Public
		Extrn	VidParamsTrapAddr:DWord,VideoGraphicsTrapAddr:DWord
IntSegment	Ends

;               *******************
;               *  Data Segments  *
;               *******************

BiosDataArea	Segment Public
		Extrn CrtMode:Byte, CrtColumns:Word, CrtLength:Word
		Extrn CrtStart:Word, CursorPosn:Word, CursorMode:Word
		Extrn ActivePage:Byte, ActiveCard:Word, CrtModeSet:Byte
		Extrn CrtPalette:Byte, EquipFlag:Word
BiosDataArea	Ends

MonoSeg		Segment Public
MonoSeg		Ends

ColorSeg	Segment Public
ColorSeg	Ends

$Eject

;		*****************
;		*  Stack Frame	*
;		*****************
;	 -------------------------------
;	|		Es		| Bp[16]
;	 -------------------------------	
;	|		Ds		| Bp[14]
;	 -------------------------------
;	|		Si		| Bp[12]
;	 -------------------------------
;	|		Di		| Bp[10]
;	 -------------------------------
;	|     Dh	|	Dl	| Bp[8]
;	 -------------------------------
;	|     Ch	|	Cl	| Bp[6]
;	 -------------------------------
;	|     Bh	|	Bl	| Bp[4]
;	 -------------------------------
;	|   Command	|	Al	| Bp[2]
;	 -------------------------------
;	|         Video  Segment	| Bp[0]
;	 ------------------------------- 

;		*************************
;		*  Stack Frame Equates	*
;		*************************

Command		Equ	Byte Ptr [Bp+3]		;All	- command
Mode		Equ	Byte Ptr [Bp+2]		;Set mode/state - mode in/out
CursStartLine	Equ	Byte Ptr [Bp+7]		;Curs type- start line
CursEndLine	Equ	Byte Ptr [Bp+6]		;Curs type- end line
CursCommand	Equ	Word Ptr [Bp+6]		;Curs type- start and end
SetRow		Equ	Byte Ptr [Bp+9]		;Set curs- row
SetCol		Equ	Byte Ptr [Bp+8]		;Set curs- column
SetRowCol	Equ	Word Ptr [Bp+8]		;Set curs -row and column
ReadRow		Equ	Byte Ptr [Bp+9]		;Read curs- row
ReadCol		Equ	Byte Ptr [Bp+8]		;Read curs- column
ReadRowCol	Equ	Word Ptr [Bp+8]		;Read curs -row anc coluan
ReturnCursMode	Equ	Word Ptr [Bp+6]		;Read curs -current cursor mode
LpRow		Equ	Byte Ptr [Bp+9]		;Read Lp - row
LpCol		Equ	Byte Ptr [Bp+8]		;Read Lp - col
LpRowCol	Equ	Word Ptr [Bp+8]		;Read Lp - row and column
LpRasterLine	Equ	Byte Ptr [Bp+7]		;Read Lp - Raster line
LpPixel		Equ	Word Ptr [Bp+4]		;Read Lp - Pinel #
LpStatus	Equ	Byte Ptr [Bp+3]		;Read Lp - Exit status
NewPage		Equ	Byte Ptr [Bp+2]		;Sel Active - new active page
ScrollNumRows	Equ	Byte Ptr [Bp+2]		;Scroll - # of rows to blank
ScrollUpperRow	Equ	Byte Ptr [Bp+7]		;Scroll - Upper row
ScrollLowerRow	Equ	Byte Ptr [Bp+9]		;Scroll - Lower row
ScrollUpperCol	Equ	Byte Ptr [Bp+6]		;Scroll - Upper column
ScrollLowerCol	Equ	Byte Ptr [Bp+8]		;Seroll - Lower column
ScrollUpper	Equ	Word Ptr [Bp+6]		;Scroll - Upper row and column
ScrollLower	Equ	Word Ptr [Bp+8]		;Ssroll - Lower row and column
ScrollAttrib	Equ	Byte Ptr [Bp+5]		;Scroll - blanking attribute
DisplayPage	Equ	Byte Ptr [Bp+5]		;Char handling - display page
Char		Equ	Byte Ptr [Bp+2]		;Char handling - char in/out
AttribOut	Equ	Byte Ptr [Bp+3]		;Char handling - attrib out
CharCount	Equ	Word Ptr [Bp+6]		;Char handling - repeat count
AttribIn	Equ	Byte Ptr [Bp+4]		;Char handling - attrib in
ColorId		Equ	Byte Ptr [Bp+5]		;Set Pallette - Color Id
ColorValue	Equ	Byte Ptr [Bp+4]		;Set Pallette - Color value
DotRow		Equ	Word Ptr [Bp+8]		;Read/write dot - row number
DotCol		Equ	Word Ptr [Bp+6]		;Read/write dot - col number
Dot		Equ	Byte Ptr [Bp+2]		;Read/write dot - dot in/out
TTYForeground	Equ	Byte Ptr [Bp+4]		;TTY - foreground color
Columns		Equ	Byte Ptr [Bp+3]		;State - # of columns
VideoSegment	Equ	Word Ptr [Bp+0]		;Video segment



$Eject
;		******************
;		*  Code Segment	*
;		******************

Bios		Segment Common
		Extrn	VideoGraphicsPointer:Byte, Beep:Near
		Assume	Cs:Bios, Ds:BiosDataArea, Es:Nothing
		Org	0F045H
JumpTable	Label	Word
		Dw	Offset	SetMode		;Change modes
		Dw	Offset	SetCursorType	;Set cursor type
		Dw	Offset	SetCursorPos	;Move cursor to position
		Dw	Offset	ReadCursorPos	;Read current cursor position
		Dw	Offset	ReadLpPos	;Read Light pen position
		Dw	Offset	ActivatePage	;Activate new page
		Dw	Offset	Scroll		;Scroll UP
		Dw	Offset	Scroll		;Scrol] DOWN
		Dw	Offset	ReadWrite	;Read char and attrib at cursor
		Dw	Offset	ReadWrite	;Write char and attrib at cursor
		Dw	Offset	ReadWrite	;Write char at cursor
		Dw	Offset	SetColor	;Set color and background
		Dw	Offset	WriteDot	;Whrite a dot
		Dw	Offset	ReadDot		;Read a dot
		Dw	Offset	WriteTTY	;Write glass tty
		Dw	Offset	VideoState	;Return current video state

VideoDriver	Proc	Far
		Sti				;Restore interrupts
		Cld				;Clear direction
		Push	Bp			;...................
		Push	Es			;.		   .
		Push	Ds			;.		   .
		Push	Si			;.  Save	   .
		Push	Di			;.		   .
		Push	Dx			;.	Registers  .
		Push	Cx			;.		   .
		Push	Bx			;.		   .
		Push	Ax			;;..................
		Mov	Bx,BiosDataArea		;Load our segment
		Mov	Ds,Bx			;...register
		Mov	Bl,Byte Ptr EquipFlag	;Get display type
		And	Bl,00110000B		;...isolate bits
		Cmp	Bl,00110000B		;...and test if monochrome
		Mov	Bx,ColorSeg		;Pre-load Bx with color card seg
		Jne	SegNotMono		;Jump if not monochrome
		Mov	Bx,MonoSeg		;...else use mono segment
SegNotMono:
		Push	Bx			;Push video segment into stack

		Mov	Bp,Sp			;Bp points at stack frame
		Call	CommandDispatch		;Perform the command

		Pop	Si			;Toss video segment
		Pop	Ax			;...................
		Pop	Bx			;.		   .
		Pop	Cx			;.		   .
		Pop	Dx			;.  Restore	   .
		Pop	Di			;.		   .
		Pop	Si			;.	Registers  .
		Pop	Ds			;.		   .
		Pop	Es			;.		   .
		Pop	Bp			;...................
		Iret				;And return
VideoDriver	Endp

$Eject

;		******************************************
;		*  Mode Tables - Aligned with PC and Xt	 *
;		******************************************

ParameterStruc	Struc
Alpha40x25	Db	038H,028H,02DH,00AH,01FH,006H,019H,01CH
		Db	002H,007H,006H,007H,000H,000H,000H,000H
Alpha80x25	Db	071H,050H,05AH,00AH,01FH,006H,019H,01CH
		Db	002H,007H,006H,007H,000H,000H,000H,000H
Graphics	Db	038H,028H,02DH,00AH,07FH,006H,064H,070H
		Db	002H,001H,006H,007H,000H,000H,000H,000H
AlphaMono	Db	061H,050H,052H,00FH,019H,006H,019H,019H
		Db	002H,00DH,00BH,00CH,000H,000H,000H,000H
Mem40x25	Dw	2048
Mem80x25	Dw	4096
MemGraphics	Dw	16384
		Dw	16384
NumCols		Db	028H,028H,050H,050H,028H,028H,050H,050H
ModeSets	Db	02CH,028H,02DH,029H,02AH,02EH,01EH,029H
ParameterStruc	Ends
ParamOffStruc	Struc
		Db	0	;Offset in parameter structure for mode 0
		Db	0	;Offset in parameter structure for mode 1
		Db	16	;Offset in parameter structure for mode 2
		Db	16	;Offset in parameter structure for mode 3
		Db	32	;Offset in parameter structure for mode 4
		Db	32	;Offset in parameter structure for mode 5
		Db	32	;Offset in parameter structure for mode 6
		Db	48	;Offset in parameter structure for mode 7
ParamOffStruc	Ends
		;	Table definition - done under $NoList

$Nolist
		Org	0F0A4H			;Align with PC and Xt
VidParamsPointer	ParameterStruc <>

		Org	0F0FCH
OffsetTable		ParamOffStruc <>

$List

$Eject
;		************************
;		*  Command Dispatcher  *
;		************************

CommandDispatch Proc	Near
		Cmp	Ah,15			;Is command in range?
		Jbe	ComInRange		;...jump if it is
		Ret				;...else return
ComInRange:
		Shl	Ah,1			;Multiply command by 2
		Mov	Bl,Ah			;Put in index register
		Xor	Bh,Bh			;...and extend to word
		Jmp	JumpTable[Bx]		;...and jump to routine
CommandDispatch Endp
$Eject

;		**************************************
;		*  Command Procedure - Set New Mode  *
;		**************************************

SetMode		Proc	Near			;Change mode
		
		;	Set ActiveCard Global Variable

		Mov	Al,Byte Ptr EquipFlag	;Get switches
		Mov	Dx,PortMonoIndex	;...pre-load with mono card
		And	Al,00110000B		;Isolate
		Cmp	Al,00110000B		;...and test switches
		Mov	Al,MonoResMode		;...(null mode command)
		Mov	Bl,7			;Get internal mode for mono
		Je	SetModeJump1		;...jump if monochrome
		Mov	Bl,Mode			;Get new mode into Bl
		Mov	Dl,Low(PortColorIndex)	;...else load color address
		Dec	Al			;...modify null mode for color
SetModeJump1:
		Mov	ActiveCard,Dx		;Save base address in global

		;	Reset card to null mode

		Add	Dl,4			;...point at control register
		Out	Dx,Al			;...and setup null mode
		Mov	CrtMode,Bl		;Set mode

		;	Point at 6845 parameters

		Assume	Ds:IntSegment		;Point ASM86 at int segment
		Push	Ds			;Save Ds
		Xor	Ax,Ax			;Go there
		Mov	Ds,Ax			;...ourselves with data segment
		Les	Si,VidParamsTrapAddr	;Point De:Si to parameters
		Pop	Ds			;Restore data segment
		Assume	Ds:BiosDataArea		;...and tell ASM86

		;	Pump parameters into 6845

		Xor	Bh,Bh			;Form index into table (Bl=mode)
		Push	Bx			;Save Bx=crt mode
		Mov	Bl,byte ptr Cs:OffsetTable[Bx]	;Load the offset
		Add	Si,Bx			;...and point at right list
		Mov	Cx,16			;Do 16 bytes

		;	Ah is 6845 index, initialized to zero from above
PumpModeLoop:
		Mov	Al,Es:[Si]		;Get byte from table
		Call	Load6845		;...5end it
		Inc	Ah			;Increment 6845 index
		Inc	Si			;Increment memory pointer
		Loop	PumpModeLoop		;...and loop till 16 done

		;	Clear the memory

		Mov	Bx,VideoSegment		;Set segment
		Mov	Es,Bx			;...Es points to video buffer
		Mov	Di,0			;Byte pointer
		Call	WhichMode		;Which mode are we in?
		Mov	Cx,8192			;Memory size on color card
		Mov	Ax,0			;Clear for graphics
		Jc	SetModeClr3		;...carry set if graphics
		Jnz	SetModeClr1		;...Z Set if monochrome

SetModeClr2:
		Mov	Cx,2048			;Memory size on mono card
SetModeClr1:
		Mov	Ax,0000011100100000B	;Alpha mode space & attrib=7
SetModeClr3:
	Rep	Stosw				;Repeat and store data

		;	Set Mode from Table

		Mov	Dx,ActiveCard		;Get port address
		Add	Dl,4			;...and point at mode port
		Pop	Bx			;Get CrtMode from stac
		Mov	Al,VidParamsPointer.ModeSets[Bx] ;Get mode from table
		Out	Dx,Al			;...........and output it
		Mov	CrtModeSet,Al		;...........and Seg global

		;	Set overscan mode

		Inc	Dx			;Point at register
		Mov	Al,00110000B		;Default value
		Cmp	Bl,6			;640x208 mode
		Jne	OverscanHires		;...jump if is
		Mov	Al,00111111B		;...else set special mode
OverscanHires:
		Mov	CrtPalette,AL		;...Store it and
		Out	Dx,Al			;...send it

		;	Init Some Globals

		Xor	Ax,Ax			;Get a zero
		Mov	CrtStart,Ax		;...Set start address
		Mov	ActivePage,Al		;...and active page
		Mov	Cx,8			;Clear cursor positions
		Mov	Di,Offset CursorPosn	;Point at them
CursPosClr:
		Mov	[Di],Ax			;Clear one
		Inc	Di			;...increment pointer
		Loop	CursPosClr		;...and loop
		Mov	CursorMode,607H		;Cursor mode line 6-7
		Mov	Al,VidParamsPointer.NumCols[Bx] ;Init CrtColumns from
		Mov	CrtColumns,Ax		;...........table
		And	Bl,11111110B		;Make mode even
		Mov	Ax,VidParamsPointer.Mem40x25[Bx] ;Init size
		Mov	CrtLength,Ax		;.............from table
		Ret				;Return, init complete
SetMode		Endp
$Eject
;		**********************************************
;		*  Command Procedure - Set New Cursor Value  *
;		**********************************************

	
SetCursorType	Proc	Near			;Set cursor type	
		Mov	Cx,CursCommand		;Get parameter
		Mov	CursorMode,Cx		;Store new global value
		Mov	Ah,10			;Address of 6845 Cursor spec.
		Call	Load6845Double		;...send it
		Ret				;...and return
SetCursorType	Endp

;		*****************************************
;		*  Command Procedure - Position Cursor	*
;		*****************************************

SetCursorPos	Proc	Near			;Move cursor to position
		Mov	Bl,DisplayPage		;Get page arameter
		Shl	Bl,1			;...Multiply by 2
		Xor	Bh,Bh			;Clear the top
		Mov	Ax,SetRowCol		;Get new row and column
		Mov	CursorPosn[Bx],Ax	;...and store it
		Cmp	ActivePage,Bl		;Page now on screen?
		Jne	SetCursorReturn		;...jump if not
		Call	LoadCursor		;...else load the cursor
SetCursorReturn:
		Ret				;...to caller
SetCursorPos	Endp

;		************************************************
;		*  Command Procedure - Return Cursor Position  *
;		************************************************

ReadCursorPos	Proc	Near			;Read current cursor position
		Mov	Bl,DisplayPage		;Get page Gatauser
		Shl	Bl,1			;...Multiply by 2
		Xor	Bh,Bh			;Clear the top
		Mov	Ax,CursorPosn[Bx]	;jGet cursor position
		Mov	ReadRowCol,Ax		;...and store it in stack frame
		Mov	Ax,CursorMode		;Get cursor mode
		Mov	ReturnCursMode,Ax	;...and store it in stack frame
		Ret				;Then return
ReadCursorPos	Endp
$Eject
;		*******************************
;		*  Return Light Pen Position  *
;		*******************************

Skew		Db	3,3,5,5,3,3,4

ReadLpPos	Proc	Near			;Read Light pen position
		Mov	Dx,ActiveCard		;Point at 6845
		Add	Dl,6			;...and the status register
		Mov	LpStatus,0		;Returned status = not pressed
		In	Al,Dx			;Get status
		Test	Al,00000100B		;...and test bit
		Jz	ResetTrigRtn		;If not set, return and reset
		Test	Al,00000010B		;If not trigger, return no reset
%If (%BugFix Eq 0) Then (
		Jnz	LpPosJmp1		;...jump over return if trigger
) Else (
		Jz	LpPosJmp1		;...jump over return if trigger (BUGFIX)
) fI
		Ret				;...return not triggered
LpPosJmp1:
		Mov	Ah,16			;Fetch value from 6845
		Call	Fetch6845Double		;...into Cx
		Mov	Bl,CrtMode		;Load Bx with mode
		Mov	Cl,Bl			;...and keep it,
		Xor	Bh,Bh			;...then
		Mov	Bl,Skew[Bx]		;...load it with skew value
		Sub	Cx,Bx			;Subtract skew
		Jns	LpPosJmp2		;Jump if negative
		Xor	Ax,Ax			;...Don't go past origin
LpPosJmp2:
		Call	WhichMode		;Which mode are we in?
		Jnc	LpAlpha			;...jump if alpha mode

		;	Graphics Light Pen

		Mov	Ch,40			;Divide into 48 columns
		Div	Dl			;...per row

		;	Al=0-99 rows	Ah=0-39 columns

		Mov	Bl,Ah			;Return pixels in Bx
		Xor	Bh,Bh			;...calculated as 8
		Mov	Cl,3			;...times
		Shl	Bx,Cl			;...Column value
		Mov	Ch,Al			;Scan line in Ch
		Shl	Ch,1			;...double for interlace
		Mov	Dl,Ah			;Char coluan in Dl
		Mov	Dh,Al			;Char row in Dh
		Shr	Dh,1			;Get char row value in
		Shr	Dh,1			;...range (div by 4)

		;	Adjust for Hi-Res

		Cmp	CrtMode,6		;Hi-Res?
		Jne	LpReturnValues		;...jump if no and return
		Shl	Dl,1			;Column # * 2
		Shl	Bx,1			;Pixels * 2
		Jmp	Short LpReturnValues	;Return

		;	Alpha Light Pen

LpAlpha:
		Div	Byte Ptr CrtColumns	;Divide address by columns
		Xchg	Al,Ah			;...Dh = rows
		Mov	Dx,Ax			;...Dl = columns
		Mov	Cl,3			;Calculate scan lines
		Shl	Ah,Cl			;...from rows * 8
		Mov	Ch,Ah			;...and return it in Ch
		Mov	Bl,Al			;Calculate pixels
		Xor	Bh,Bh			;...from rows * 8
		Shl	Bx,CL			;...and return in Bx

		;	Return with Values

LpReturnValues:
		Mov	LpStatus,1		;Signal trigger
		Mov	LpRowCol,Dx		;Store Dx
		Mov	LpPixel,Bx		;Store Bx
		Mov	LpRasterLine,Ch		;Store Ch
ResetTrigRtn:
		Mov	Dx,ActiveCard		;Clear Lp Flip Flop
		Add	Dx,7			;...before returning
		Out	Dx,Al			;...(data irrelevent)
		Ret				;...and return normally
ReadLpPos	Endp
$Eject

;		***************************************
;		*  Command Procedure - Activate Page  *
;		***************************************

ActivatePage	Proc	Near			;Activate new page
		Mov	Al,NewPage		;Get the new page
		Mov	ActivePage,Al		;...Store it and
		Xor	Ah,Ah			;...put it into Ax
		Push	Ax			;Save for cursor positioning
		Mov	Bx,CrtLength		;Multiply it by the
		Mul	Bx			;...length of a page
		Mov	CrtStart,Ax		;Store start addr of page
		Shr	Ax,1			;Get character only length
		Mov	Cx,Ax			;Pump it into
		Mov	Ah,12			;...6845
		Call	Load6845Double		;...Double register 12
		Pop	Bx			;Restore page to Bx
		Call	LoadCursor		;...and go load the cursor
		Ret				;...then return
ActivatePage	Endp
$Eject
;		********************************************
;		*  Command Procedure - Scroll Up and Down  *
;		********************************************

Scroll		Proc	Near			;Scroll Down
		Call	WhichMode		;Graphics or Alpha?
		Jnc	ScrollAlpha		;...jump if alpha
		Jmp	ScrollGraph		;..-0150 jump to graphics
Scroll		Endp

;		***********************************
;		*  Common Alpha Scroll Procedure  *
;		***********************************

ScrollAlpha	Proc	Near
		Cld				;Clear direction
		Cmp	CrtMode,2		;40 x 25?
		Jb	NoScrollWait		;Jump if not
		Cmp	CrtMode,3		;80 x 25?
		Ja	NoScrollWait		;Jump if it isn't
VerticalWait:
		Mov	Dx,PortColorStatus	;Point at status port
VWaitLoop:
		In	Al,Dx			;Get status
		Test	Al,00001000B		;...Wait for vertical retrace
		Jz	VWaitLoop		;Loop till retrace
		Mov	Dx,PortColorMode	;Turn off video
		Mov	Al,00100101B		;...while
		Out	Dx,Al			;...scrolling

		;	Calculate window start address

NoScrollWait:
		Mov	Ax,ScrollLower		;Get lower right hand xy
		Push	Ax			;...and save it
		Cmp	Command,7		;Down?
		Je	ScrollCont2		;...jump if down
		Mov	Ax,Scrollupper		;...else start at upper left
ScrollCont2:
		Call	Convert			;Convert it to a linear address
		Add	Ax,CrtStart		;...on current page
		Mov	Si,Ax			;Store in source register
		Mov	Di,Ax			;...and destination register

		;	Calculate # or rows and # of colums

		Pop	Dx			;Restore upper left
		Sub	Dx,ScrollUpper		;Calculate width and height
		Add	Dx,0101H		;...adding 1 to form a count

		;	Get Linear difference between rows

		Mov	Bx,CrtColumns		;# of columns
		Shl	Bx,1			;...double for attributes

		;	Calculate To / From Offset

		Push	Ds			;Save Ds
		Mov	Al,ScrollNumRows	;Number of rows
		Mul	Bl			;...difference between rows

		;	Load Source and Destination Segment Registers

		Assume 	Ds:Nothing		;All ref. must be annonymous
		Mov	Cx,VideoSegment		;Get the segment
		Mov	Es,Cx			;...destination segment
		Mov	Ds,Cx			;...source segment

		;	Set sign of offsets based on direction

		Cmp	Command,6		;Up?
		Je	ScrollCont1		;...jump if up
		Neg	Ax			;...else make Ax negative
		Neg	Bx			;...and make Bx negative
		Std				;Set direction
ScrollCont1:

;		***********************************
;		* At this point:		  *
;		*				  *
;		* Dh = # of rows		  *
;		* Dl = # of cols		  *
;		* Ax = Linear to / from offset	  *
;		* Bx = Differences between rows	  *
;		* Si & Di = linear start address  *
;		* Es & Ds = Video segment	  *
;		***********************************

		Mov	Cl,ScrollNumRows	;Number of rows
		Or	Cl,Cl			;...affect flags
		Jz	BlankOnly		;Jump if blanking only
		Add	Si,Ax			;Fix dif. between src and dest
		Sub	Dh,ScrollNumRows	;...Calculate rows to move
MoveLoop:
		Xor	Ch,Ch			;Clear counter top
		Mov	Cl,Dl			;Load # of columns to move
		Push	Di			;Save pointers
		Push	Si			;...that will be incremented
	Rep	Movsw				;Move the row

		Pop	Si			;Restore pointers
		Pop	Di			;...to original value
		Add	Si,Bx			;Point at next row
		Add	Di,Bx			;...both source and destination
		Dec	Dh			;...count down
		Jnz	MoveLoop		;..and loop till all moved
		Mov	Dh,ScrollNumRows	;Load count of rows to blank

		;	Clear rows at bottom or top

BlankOnly:
		Xor	Ch,Ch			;Clear counter top
		Mov	Ah,ScrollAttrib		;Get the attribute
		Mov	Al,' '			;...and a space
BlankBotLoop:
		Mov	Cl,Dl			;Dl has # of columns in block
		Push	Di			;Save pointer
	Rep	Stosw				;Clear row

		Pop	Di			;Restore pointer
		Add	Di,Bx			;...bump to next row
		Dec	Dh			;Decrement count and
		Jnz	BlankBotLoop		;...loop till done
		Pop	Ds			;Restore Bios data seqment
		Assume 	Ds:BiosDataArea		;...and tell ASM86
		Call	WhichMode		;Mono card?
		Jz	ScrolLReturn		;...return if so
		Mov	Al,CrtModeSet		;Get current mode
		Mov	Dx,PortColorMode	;...and restore it
		Out	Dx,Al			;...to re-enable video
ScrollReturn:
		Ret				;and return
ScrollAlpha	Endp
$Eject

;		****************************
;		*  Common Graphics Scroll  *
;		****************************

ScrollGraph	Proc	Near
		Cld				;Clear direction for scroll up
		Mov	Ax,ScrollLower		;Get upper right hand corner xy
		Push	Ax			;Save upper right hand corner
		Cmp	Command,7		;Scroll Down?
		Je	GraphDn1		;...jump if yes
		Mov	Ax,ScrollUpper		;...else reload upper left
GraphDn1:
		Call	ConvertGraph		;Calculate linear addr for HiRes
		Mov	Di,Ax			;This is destination

		;	Calculate Dh = # of rows, Dl = # of columns in window

		Pop	Dx			;Dx = Upper left hand corner
		Sub	Dx,ScrollUpper		;Calculate offset
		Add	Dx,0101H		;...and make it a length
		Shl	Dh,1			;In graphics, 4 even field rows
		Shl	Dh,1			;...per char. row, so shift it

		;	Adjust for medium resolution

		Mov	Al,Command		;Get command
		Cmp	CrtMode,6		;Is it HiRes? (mode 6)
		Je	HiresSkip		;...jump if so
		Shl	Dl,1			;Twice as many bytes per column
		Shl	Di,1			;...offset correction for LoRes
		Cmp	Al,7			;Down?
		Jne	HiresSkip		;...jump if not
		Inc	Di			;...bump to last byte

		;	Adjust # of rows to scroll to even field scan lines

HiresSkip:
		Cmp	Al,7			;Down?
		Jne	DownSkip1		;...jump if not
		Add	Di,240			;Go to last row of dots if down
DownSkip1:
		Mov	Bl,ScrollNumRows	;Get character rows
		Shl	Bl,1			;...times 2
		Shl	Bl,1			;...times 2 again

		;	Calculate byte length offset from source to dest

		Push	Bx			;Save num scan lines for blank
		Sub	Dh,Bl			;Calculate # scans to move
		Mov	Al,80			;Calc by multiplying # scans
		Mul	Bl			;...times 88 bytes per scan

		;	Set sign of offsets based on direction

		Mov	Bx,2000H-80		;Pre-load *UP® row offset
		Cmp	Command,6		;Up?
		Je	ScrollGrph1		;...jump if up
		Neg	Ax			;...else make Ax negative
		Mov	Bx,2000H+80		;Scroll down goes up in menory
		Std				;Set direction
ScrollGrph1:
		;	Set to / from offset

		Mov	Si,Di			;Get destination and figure
		Add	Si,Ax			;...Si/Di diff. by offset

		;	Test if planting function only
		;	        &
		;	Lead Video Segments

		Pop	Ax			;Get # of scans to scroll
		Or	Al,Al			;...affect Z.  Blank only? ---
		Mov	Cx,VideoSegment		;Load segment registers	      |
		Mov	Ds,Cx			;...with		      |
		Mov	Es,Cx			;...video segment	      |
		Jz	GraphBlankOnly		;...jump if blanking only  <--
		Push	Ax			;Save # of scans to scroll
		Xor	Ch,Ch			;Clear length upper byte

		;		Move Loop
MoveGraph:
		Xor	Ch,Ch			;Clear counter top
		Mov	Cl,Dl			;Get # of bytes (columns)
		Push	Si			;Save pointers
		Push	Di			;...for future use
	Rep	Movsb				;Move even row
			
		Pop	Di			;Restore pointers
		Pop	Si			;...and
		Add	Si,2000H		;...point them to
		Add	Di,2000H		;...odd field
		Mov	Cl,Dl			;Get # of bytes (columns)
		Push	Si			;Save pointers
		Push	Di			;...for future use
	Rep	Movsb				;Move odd ros

		Pop	Di			;Restore pointers
		Pop	Si			;...and 2 rows moved
		Sub	Si,Bx			;Back to even field-1 row
		Sub	Di,Bx			;...for both pointers
		Dec	Dh			;Decrement count
		Jnz	MoveGraph		;...and loop till moved
		Pop	Ax			;Restore # of scans to scroll
		Mov	Dh,Al			;Count using Dh

		;	Blank lines at bottom or top

GraphBlankOnly:
		Mov	Al,ScrollAttrib		;Get the data
		Xor	Ch,Ch			;Clear counter top

		;	Clear Loop
ClearGraphLoop:
		Mov	Cl,Dl			;Get # of columns
		Push	Di			;Save pointer
	Rep	Stosb				;Store data on row in columns

		Pop	Di			;Restore pointer
		Add	Di,2000H		;Point at odd field
		Mov	Cl,Dl			;Get # of columns
		Push	Di			;Save pointer again
	Rep	Stosb				;Store data on row in columns

		Pop	Di			;Restore pointer
		Sub	Di,Bx			;Point at next row to clear
		Dec	Dh			;Decrement count of scans to do
		Jnz	ClearGraphLoop		;...and loop till clear
		Ret				;...then return
ScrollGraph	Endp
$Eject
;		**********************************************************
;		*  Command Procedure - Read / Write Char. and/or Attrib  *
;		**********************************************************

ReadWrite	Proc	Near
		Call	WhichMode		;Which mode are we in?
		Jc	ReadWriteGraph		;...jump if graphics

		;	Convert xy to linear

		Mov	Bl,DisplayPage		;Get page number
		Xor	Bh,Bh			;...into Bx
		Push	Bx			;and save it
		Call	ConvertCursor		;Convert cursor to linear
		Mov	Di,Ax			;Save result in Di
		Pop	Ax			;Restore page #
		Mul	CrtLength		;...Multiply page x length
		Add	Di,Ax			;...and add in converted value
		Mov	Si,Di			;Read and write pointers

		;	Get port address

		Mov	Dx,ActiveCard		;Get port address
		Add	Dx,6			;...and point at status reg.

		;	Save segments

		Push	Ds			;Save data segment
		Mov	Bx,VideoSegment		;...get video segment
		Mov	Ds,Bx			;...into data segment
		Mov	Es,Bx			;...and extra segment
		Assume	Ds:Nothing		;We know nothing about segment

		;	Read / Write Split

		Mov	Al,Command		;Get command
		Cmp	Al,8			;Command = Read?
		Jne	WriteChar		;...if not then jump

		;	Read Branch

HWaitRead:
		In	Al,Dx			;Get status
		Test	Al,1			;...horiz pulse?
		Jnz	HWaitRead		;...jump and wait for it if not
		Cli				;Tight timing here
HWaitRead2:
		In	Al,Dx			;Get status
		Test	Al,1			;...gone back hi?
		;Jz	HWaitRead		;...wait till it does
		Jz	HWaitRead2		;...wait till it does (BUGFIX)
		Lodsw				;...read it quick
		Pop	Ds			;Restore Ds
		Assume 	Ds:BiosDataArea		;...and tell ASMBS
		Mov	Char,Al			;...store char for return
		Mov	AttribOut,Ah		;...then store attrib
		Ret				;...and return

		;	Write Branch

WriteChar:
		Mov	Bl,Char			;Get Char
		Mov	Bh,AttribIn		;...and attribute
		Mov	Cx,CharCount		;Repeat count

		;	Char only or char/attrib write split

		Cmp	Al,10			;Command = char only?
		Je	CharOnly		;...jump if yes

		;	Char and attrib branch

HWaitWrite1:
		In	Al,Dx			;Get status
		Test	Al,1			;...horiz pulse?
		Jnz	HWaitWrite1		;...jump and wait for if if not
		Cli				;Tight timing here
HWaitWrite2:
		In	Al,Dx			;Get status
		Test	Al,1			;...gone back hi?
		Jz	HWaitWrite2		;...wait till it does
		Mov	Ax,Bx			;Get char and attribute
		Stosw				;Write char and attrib
		Loop	HWaitWrite1		;...do for repeat count
		Pop	Ds			;Restore Ds
		Assume	Ds:BiosDataArea		;...and tell ASM86
		Ret				;...and return

		;	Char only branch

CharOnly:
HWaitWrite3:
		In	Al,Dx			;Get status
		Test	Al,1			;...horiz pulse?
		Jnz	HWaitWrite3		;...jump and wait for it if not
		Cli				;Tight timing here
HWaitWrite4:
		In	Al,Dx			;Get status
		Test	Al,1			;...gone back hi?
		Jz	HWaitWrite4		;...Wait till it does
		Mov	Al,Bl			;Get char back
		Stosb				;Write char only
		Inc	Di			;...skip attribute
		Loop	HWaitWrite3		;...and loop
		Pop	Ds			;Restore Ds
		Assume	Ds:BiosDataArea		;...and tell ASMB6
		Ret				;...and return
ReadWrite	Endp
$Eject

;		*************************
;		*  Read Write Graphics  *
;		*************************

ReadWriteGraph 	Proc	Near
		Cmp	Command,8		;Read?
		Jne	Writegraph		;...jump if not and write
		Jmp	ReadGraph		;...else read
ReadWriteGraph 	Endp							

;		********************
;		*  Write Graphics  *
;		********************

WriteGraph	Proc	Near
		;	Convert Cursor position to linear

		Mov	Ax,CursorPosn[0]	;Get page 0 cursor posn
		Call	ConvertGraph		;Convert to linear HiRes
		Mov	Di,Ax			;...and use as destination

		;	Determine image pointer

		Push	Ds			;Save data segment
		Mov	Al,Char			;Get char
		Xor	Ah,Ah			;...into Ax
		Or	Al,Al			;Affect flags
		Js	UserImages		;...and jump if upper bit

		;	Rom images

		Mov	Dx,Cs			;Rom images in code segment
		Mov	Si,Offset VideoGraphicsPointer ;Images = Dx:Si
		Jmp	Short RWGCont1		;Jump over

UserImages:
		And	Al,01111111B		;Strip upper bit, conv. to word
		Xor	Bx,Bx			;...point at int segment
		Mov	Ds,Bx			;...to find pointer
		Assume	Ds:IntSegment		;...to user images
		Lds	Si,VideoGraphicsTrapAddr  ;User images at Ds:Si
		Mov	Dx,Ds			;...make it Dx:Si
RWGCont1:
		Assume	Ds:BiosDataArea		;Tell ASM86 data segment
		Pop	Ds			;Restore our segment

		;	Figure offset into table

		Mov	Cl,3			;Multiply by 8 rows of
		Shl	Ax,Cl			;...dots per page
		Add	Si,Ax			;Add in image pointer

		;	Load Video Segment Register

		Mov	Ax,VideoSegment		;Get segment pointer
		Mov	Es,Ax			;...and load it

		;	Load character count and toggle bit
			
		Mov	Cx,CharCount		;Character count

		;	Mode Split and Load Segment register

		Cmp	CrtMode,6		;HiRes?
		Push	Ds			;Save data segment
		Mov	Ds,Dx			;Load Data Segment
		Assume	Ds:Nothing		;We know nothink
		Je	HiResWrite		;...jump if yes

		;	Medium Resolution Write

		Shl	Di,1			;Med res is 2 bytes per char

		;	Expand color into Ax

		Mov	Al,AttribIn		;Get color
		And	Ax,0000000000000011B	;...and isolate
		Mov	Bx,0101010101010101B	;Magic multiplier
		Mul	Bx			;Replicate bits across Ax
		Mov	Dx,Ax			;...and keep it in Dx
		Mov	Bl,AttribIn		;Get the color attribute

		;	     Ax = not used
		;	     Bh = not used
		;	     Bl = attribute
		;	     Cx = character count
		;	     Dx = expanded attribute
		;	     Es:Di = screen pointer
		;	     Ds:Si = image pointer

		;	Write (Cx) Characters
RepeatWrMed:
		Mov	Bh,8			;Write 4 odd/even pairs of rows
		Push	Di			;Save pointers
		Push	Si			;...for next write

		;	Move dots

MedResWrLoop:
		Lodsb				;Get even row of dots [Si]

		;	Double all bits

		Push	Cx			;Save Cx
		Push	Bx			;Save Bx (room to work)
		Xor	Bx,Bx			;Clear accumulator
		Mov	Cx,8			;8 bits to double
DoubleUp:
		Shr	Al,1			;Shift dots Rt into carry bit
		Rcr	Bx,1			;Shift accum Rt from carry
		Sar	Bx,1			;Shift accum rt and rep .bit 15
		Loop	DoubleUp		;Loop till 8 bits doubled
		Mov	Ax,Bx			;Get shift accum back to Ax
		Pop	Bx			;Restore pushed registers
		Pop	Cx			;...from above
		And	Ax,Dx			;Convert color
		Xchg	Ah,Al			;Hi byte lo byte
		Or	Bl,Bl			;...is; attrib upper bit set?
		Jns	MedXorSkip		;...jump if it is
		Xor	Ax,Es:[Di]		;Xor source with destination
MedXorSkip:
		Mov	Es:[Di],Ax		;Put the row of dots [Di]
		Xor	Di,2000H		;Toggle odd/even field bit
		Test	Di,2000H		;Even field?
		Jnz	OddFieldWrMed		;...jump if not
		Add	Di,80			;Increment to next row
OddFieldWrMed:
		Dec	Bh			;Decrement count
		Jnz	MedResWrLoop		;...and loop till 1 char done
		Pop	Si			;Restore pointers
		Pop	Di			;...for next write
		Inc	Di			;Bumpto next video position
		Inc	Di			;...for repeat loop
		Loop	RepeatWrMed		;Loop till Cx written
		Pop	Ds			;estore data segment
		Assume Ds:BiosDataArea		;Tell ASM86 data segment
		Ret				;...then return

		;	Hi Resolution Write

HiResWrite:
		Mov	Bl,AttribIn		;Set the color attribute
		Mov	Dx,2000H		;Odd even bit

		;	Write (Cx) Characters
RepeatWrLoop:
		Mov	Bh,8			;Write 4 odd/even pairs of rows
		Push	Di			;Save pointers
		Push	Si			;...for next write

		;	Move dots

HiResWrLoop:
		Lodsb				;Get even row of dots [Si]
		Or	Bl,Bl			;...is attrib upper bit set?
		Jns	XorSkip			;...jump if it is
		Xor	Al,Es:[Di]		;Xor source with destination
XorSkip:
		Mov	Es:[Di],Al		;Put the row of dots [Di]
		Xor	Di,Dx			;Toggle odd/even field bit
		Test	Di,Dx			;Even field?
		Jnz	OddFieldWr		;...jump if not
		Add	Di,80			;Increment to next row
OddFieldWr:
		Dec	Bh			;Decrement count
		Jnz	HiResWrLoop		;...and loop till i char done
		Pop	Si			;Restore pointers
		Pop	Di			;...for next write
		Inc	Di			;Bump to next video position
		Loop	RepeatWrLoop		;Loop till Cx written
		Pop	Ds			;Restore data segment
		Assume	Ds:BiosDataArea		;Tell ASMB6 data segment
		Ret				;...then return
WriteGraph	Endp
$Eject

		;	*******************
		;	*  Read Graphics  *
		;	*******************

ReadGraph	Proc	Near
		Cld				;Positive direction
		Mov	Ax,CursorPosn[0]	;Get page 0 cursor posn
		Call	ConvertGraph		;Convert to linear HiRes
		Mov	Si,Ax			;...and use as source
		Sub	Sp,8			;Make room in stack for area
		Mov	Di,Sp			;...Di is index pointer

		;	Split for Med / Hi resolution

		Cmp	CrtMode,6		;HiRes?
			
		;	Load segment pointer before branching

		Mov	Ax,VideoSegment		;Video segment pointer
		Push	Ds			;Save data segment register
		Push	Di			;Save pointer to frame
		Mov	Ds,Ax			;Load it
		Assume	Ds:Nothing		;...we know nothing

		;	Branch

		Je	HiResRead		;...jump if it is

		;	Medium Resolution Read

		;	Move data to stack frame

		Mov	Dh,8			;8 lines of dots
		Shl	Si,1			;2 bytes per char
		Mov	Bx,2000H		;Setup register with toggle bit
MedReadLoop:
		Mov	Ax,[Si]			;Get a row of dots from video
		Xchg	Ah,Al			;...Hi byte Lo byte correct
		Mov	Cx,1100000000000000B	;Start testing for bkgnd
		Mov	Dl,0			;...clear accumulator
MedReadLp2:
		Test	Ax,Cx			;Any bits set in pair?
		Clc				;Prepare for no answer
		Jz	ShiftBitsIn		;...jump if no
		Stc				;...yes,set bit to shift in
ShiftBitsIn:
		Rcl	Dl,1			;Shift bit into accumulator
		Shr	Cx,1			;Move mask
		Shr	Cx,1			;...to the next bit
		Jnc	MedReadLp2		;Loop till mask clears reg.

		;	Store character under stack frame

		Mov	Ss:[Di],Dl		;Store the char
		Inc	Di			;...bump pointer

		;	Increment to next row

		Xor	Si,Bx			;Toggle even/odd field bit
		Test	Si,Bx			;...and test if we need to
		Jnz	OddFieldRd		;...add 80
		Add	Si,80			;Increment to next row
OddFieldRd:
		Dec	Dh			;Decrement count
		Jnz	MedReadLoop		;...and loop till done
		Jmp	Short ImageMatch	;Go match it up

		;	Hi Resolution Read

HiResRead:

		Mov	Dh,4			;4 lines of dots
HiReadLoop:
		Mov	Ah,[Si]			;Get odd row of dots from video

		;	Store character under stack frame

		Mov	Ss:[Di],Ah		;Store the char
		Inc	Di			;...bump pointer

		;	Increment to next row

		Mov	Ah,[Si][2000H]		;Get odd row of dots from video

		;	Store character under stack frame

		Mov	Ss:[Di],Ah		;Store the char
		Inc	Di			;...bump pointer

		;	Increment to next row

		Add	Si,80			;Increment to next row
		Dec	Dh			;Decrement count
		Jnz	HiReadLoop		;...and loop till done

		;	Character in stack frame,match with images

ImageMatch:
		Mov	Dx,Cs			;Rom images in code segment
		Mov	Di,Offset VideoGraphicsPointer  ;Images = Dx:Di
		Mov	Es,Dx			;........Images = Es:Di
		Mov	Dx,Ss			;Point at stack segment
		Mov	Ds,Dx			;...and let data seg. ref. it
		Pop	Si			;Restore pointer to frame

		;	Pointers set,compare with images

		Mov	Al,0			;ASCII Value
ImageTry2:
		Mov	Dx,128			;There are 128 of them
ImageLoop:
		Push	Si			;Save pointers
		Push	Di			;...while comparing
		Mov	Cx,8			;Compare 8 bytes
	Repe	Cmpsb				;...for a match

		Pop	Di			;Restore pointers
		Pop	Si			;...
		Jz	MatchFound		;Jump if match found
		Inc	Al			;Increment ASCII
		Add	Di,8			;Try next image
		Dec	Dx			;Exhausted?
		Jnz	ImageLoop		;...jump if not

		;	Image not in ROM images, try user

		Or	Al,Al			;Register wrap?
		Jz	NoMatch			;...jump if so and end

		;	Point at user images

		Xor	Bx,Bx			;...point at int segment
		Mov	Ds,Bx			;...to find pointer
		Assume	Ds:IntSegment		;...to user Images
		Les	Di,VideoGraphicsTrapAddr  ;User images at Es:Di
		Mov	Bx,Es			;Test if Es:Di = 0
		Or	Bx,Di			;...if 50,no images there
		Jz	NoMatch			;...jump if no match
		Jmp	ImageTry2		;Jump and re-try images

NoMatch:
MatchFound:
		Mov	Char,Al			;Return in Char

		Assume	Ds:BiosDataArea		;Tell ASM86 data segment
		Pop	Ds			;Restore our seqment
		Add	Sp,8			;Toss the temp area
		Ret				;....and return
ReadGraph	Endp
$Eject
;		***********************************
;		*  Command Procedure ~ Set Color  *
;		***********************************

SetColor	Proc	Near			;Set color and background
		Mov	Dx,ActiveCard		;Point at card
		Add	Dx,5			;...and then to palette
		Mov	Al,CrtPalette		;Get the palette as it stands
		Mov	Ah,ColorId
		Or	Ah,Ah			;...Set Backgrowhl!
		Mov	Ah,ColorValue		;Pre-load color value
		Jnz	SetFore			;...jump if not

		;	Set Background

		And	Al,11100000B		;Strip and merge values
		And	Ah,00011111B		;...old with
		Or	Al,Ah			;...new
		Jmp	Short SetPalAndReturn	;...and return

		;	Set Foreground
SetFore:
		And	Al,11011111B		;Palette = Grn Red Yellow
		Test	Ah,1			;...Right?
		Jz	SetPalAndReturn		;...jump if right
		Or	Al,00100000B		;Palette = Blue Cyan Magenta

		;	Set palette and return

SetPalAndReturn:
		Mov	CrtPalette,Al		;Set in ram and
		Out	Dx,Al			;...send to hardware
		Ret				;...and return
SetColor	Endp
$Eject

;		***********************************
;		*  Command Procedure - Write Dot  *
;		***********************************

WriteDot	Proc	Near			;Write a dot
		Mov	Ax,VideoSegment		;yGet the segment value
		Mov	Es,Ax			;...into segment register
		Mov	Dx,DotRow		;Get Row
		Mov	Cx,DotCol		;...and column
		Call	ConvertDot		;Get info about dot position
		Jnz	WrDotLoRes		;...and jump if medium res

		;	Write Dot Hi Res

		Mov	Al,Dot			;Get the dot
		Mov	Bl,Al			;...and keep a copy
		And	Al,00000001B		;Only one bit in HiRes
		Ror	Al,1			;...Move it to upper bit
		Mov	Ah,01111111B		;Also shift mask bit same
		Jmp	WrDotCont2		;...Continue below

		;	Write Dot Lo Res
WrDotLoRes:
		Shl	Cl,1			;Shifting 2 bits for lo res
		Mov	Al,Dot			;Get the dot
		Mov	Bl,Al			;...and keep a copy
		And	Al,00000011B		;Only one bit in HiRes
		Ror	Al,1			;...move it to upper bit
		Ror	Al,1			;...move it to upper bit
		Mov	Ah,00111111B		;Also shift mask bit same

		;	Common

WrDotCont2:
		Ror	Ah,Cl			;...amount for anding
		Shr	Al,Cl			;...Out the old data
		Mov	Cl,Es:[Si]		;Get existing byte
		Or	Bl,Bl			;Affect flags with upper bit
		Jns	WrDotNoXor		;...jump if not Xor
		Xor	Cl,Al			;...else XOR new with old
		Jmp	Short XorDot		;...and store it
WrDotNoXor:
		And	Cl,Ah			;Strip
		Or	Cl,Al			;...and or in new bits
XorDot:
		Mov	Es:[Si],Cl		;Store new dot
		Ret				;...and return
WriteDot	Endp
$Eject

;		**********************************
;		*  Command Procedure - Read Dot  *
;		**********************************

ReadDot		Proc	Near			;Read a dot
		Mov	Ax,VideoSegment		;Get the seqment value
		Mov	Es,Ax			;...into segment register
		Mov	Dx,DotRow		;Get Row
		Mov	Cx,DotCol		;...and column
		Call	ConvertDot		;Get info about dot position
		Mov	Al,Es:[Si]		;Get byte containing dot
		Jnz	RdDotLoRes		;...and jump if medium res

		;	Read dot Hi Res

		Shl	Al,Cl			;Shift dot to upper bit
		Rol	Al,1			;...hen to lower bit
		And	Al,00000001B		;Strip other dots
		Jmp	Short RdDotReturn	;...and return

		;	Read dot Med Res

RdDotLoRes:
		Shl	Cl,1			;Shifting 2 dots at once
		Shl	Al,Cl			;Shift dots to upper bit
		Rol	Al,1			;...then to lower bit
		Rol	Al,1			;...then to lower bit
		And	Al,00000011B		;Strip other dots
RdDotReturn:
		Mov	Dot,Al			;Return in stack frame
		Ret				;...and return
ReadDot		Endp
$Eject

;		***********************************
;		*  Command Procedure - Write TTY  *
;		***********************************

WriteTTY	Proc	Near			;Write glass tty
		Mov	Ah,VidCmdRdCurPos	;...Recurse and read
		Mov	Bh,ActivePage		;...cursor position
		Int	TrapVideo		;...of current screen
		Mov	Al,Char			;Get the char to write

		;	Test special char

		Cmp	Al,AsciiBackspace	;Backspace?
		Je	BSHandler		;...jump if yes
		Cmp	Al,AsciiLinefeed	;Line feed?
		Je	LFHandler		;...jump if yes
		Cmp	Al,AsciiBell		;Bell?
		Je	BellHandler		;...jump if yes
		Cmp	Al,AsciiCarriage	;Carriage Return
		Je	CRHandler		;...jump if yes

		;	Must be printable char

		Mov	Bl,TTYForeground	;Get fore. col. incase graphics
		Mov	Ah,VidCmdWrCurCh	;Write at cursor
		Mov	Cx,1			;...length of 1
		Int	TrapVideo		;Recurse to save stack frame

		;	Bump Cursor in Dh Dl

		Inc	Dl			;Column + 1
		Cmp	Dl,Byte Ptr CrtColumns	;...overflow?
		Jnz	SetCursAndReturn	;...jump if not
		Xor	Dl,Dl			;Clear row count
		Jmp	Short LFHandler		;...and go do line feed

		;	Special char handlers

		;	Backspace

BSHandler:
		Cmp	Dl,0			;Left margin?
		Je	SetCursAndReturn	;...if so,do nothing
		Dec	Dl			;...else backup
		Jmp	Short SetCursAndReturn;...and return

		;	Bell

BellHandler:
		Mov	Bl,2			;Call external beep routine
		Call	Beep			;...ard
		Ret				;...return

		;	Carriage Return

CRHandler:
		Mov	Dl,0			;Coluan 0

		;	Set cursor and return

SetCursAndReturn:
		Mov	Ah,VidCmdCurPos		;Set cursor
		Int	TrapVideo		;...recursing
		Ret				;...and return

		;	Line Feed

LFHandler:
		Cmp	Dh,24			;Last line?
		Je	TTYScroll		;...jump and scroll if so
		Inc	Dh			;...else go to next line
		Jnz	SetCursAndReturn	;...jump if not and return

		;	Position cursor and read attribute
TTYScroll:
		Mov	Ah,VidCmdCurPos		;Set cursor
		Int	TrapVideo		;...recursing

		;	Mode Split

		Call	WhichMode		;Which mode are we in?
		Mov	Bh,0			;Pre-load for graphics
		Jc	TTYGraphics		;...jump if aver
		Mov	Ah,VidCmdRdCurChAt	;...else read attrib
		Int	TrapVideo		;...to use during scroll
		Mov	Bh,Ah			;Scroll requires in Bh
TTYGraphics:
		Mov	Ah,VidCmdScrollUp	;Scroll up command
		Mov	Al,1			;...one line
		Xor	Cx,Cx			;Upper left = 0
		Mov	Dh,24			;Lower limit = line 24
		Mov	Dl,Byte Ptr CrtColumns	;Right Margin = Column
		Dec	Dl			;...80 or 40
		Int	TrapVideo		;Do scroll
		Ret				;...and return
WriteTTY	Endp
$Eject

;		**********************
;		*  Local Procedures  *
;		**********************


;		********************************
;		*  Return Current Video State  *
;		********************************

VideoState	Proc	Near			;Return current	video state
		Mov	Al,Byte Ptr CrtColumns	;Plug columns
		Mov	Columns,Al		;...into return	frame
		Mov	Al,CrtMode		;Plug mode
		Mov	Mode,Al			;...into return	frame
		Mov	Al,ActivePage		;Plug page
		Mov	DisplayPage,Al		;...into return	frame
		Ret				;...and return
VideoState	Endp
;		**************************
;		*  Which Mode Are We In  *
;		*  On return:		 *
;		*   C = 0 for Alpha	 *
;		*   C= 1 for Graphics    *
;		*   Z = 0 for Color Card *
;		*   1 = 1 for Mono Card  *
;		**************************

WhichMode	Proc	Near
		Push	Ax			;Save Ax
		Mov	Al,CrtMode		;Get the mode
		Cmp	al,7			;Monochrome?
		Je	WhichReturn		;Carry = 0, Z = 1
		Cmp	Al,4			;Graphics?
		Cmc				;...Carry = 0, Z = 0
		Jnc	WhichReturn		;...jump if alpha on color board
		Sbb	Al,Al			;...Carry = 1, Z = 0
		Stc				;...for graphics on color card
WhichReturn:
		Pop	Ax			;Restore Ax
		Ret				;Return
WhichMode	Endp
$Eject

;		*********************************************
;		*  Load Crt Controller with Word Parameter  *
;		*	  Ah = Index	Cx = Word	    *
;		*********************************************

Load6845Double	Proc	Near
		Mov	Al,Ch			;Get High byte
		Call	Load6845		;...load it
		Inc	Ah			;...Inc to next byte
		Mov	Al,Cl			;Get Low Byte and fall through

;		*********************************************
;		*  Load Crt Controller with Byte Parameter  *
;		*	  Ah = Index	Cx = Byte	    *
;		*********************************************

Load6845	Proc	Near
		Push	Dx			;Save Dx
		Mov	Dx,ActiveCard		;Get port address
		Xchg	Al,Ah			;...and send index from Ah
		Out	Dx,Al			;...to point 6845 at register
		Xchg	Al,Ah			;Get back data to send
		Inc	Dl			;...inc to data port
		Out	Dx,Al			;...and send if
		Pop	Dx			;Restore Dx
		Ret				;...and return
Load6845	Endp
Load6845Double	Endp

;		******************************
;		*  Convert Cursor to Linear  *
;		******************************

ConvertCursor	Proc	Near
		Xor	Bh,Bh			;Get page number in Bx
		Shl	Bx,1			;...double for word offset
		Mov	Ax,CursorPosn[Bx]	;Get and set the cursor
		Jmp	Convert			;Convert xy to linear address
ConvertCursor	Endp
$Eject

;		***************************
;		*  Convert Dot to Linear  *
;		* Dx = row (1-199)	  *
;		* Cx = column (1-639)	  *
;		* Returns:		  *
;		* Z = 0 for LoRes	  *
;		* Z = 1 for HiRes	  *
;		* Si Points to Byte	  *
;		* Ch = Bit #		  *
;		***************************

ConvertDot	Proc	Near
		Mov	Al,80			;# of bytes across
		Xor	Si,Si			;Pre-load start of even field
		Shr	Dl,1			;Divide rows by odd/even
		Jnc	CDEven			;...jump if even field
		Mov	Si,2000H		;Re-load start of odd field
CDEven:
		Mul	Dl			;Multiply rows by 88
		Add	Si,Ax			;Keep in source pointer
		Mov	Dx,Cx			;Need Cx for shift
		Mov	Cx,0302H		;Mask & # of bits in byte - Lo
		Cmp	CrtMode,6		;HiRes?
		Pushf				;...save result for return
		Jne	CDLoRes			;...jump if not
		Mov	Cx,0703H		;sMask &# of bits in byte - Hi
CdLoRes:
		And	Ch,Dl			;Convert Ch to bit # in byte
		Shr	Dx,Cl			;...then shift it out
		Add	Si,Dx			;Add offset in line
		Xchg	Cl,Ch			;...swap shift to cl
		Popf				;Z = 1 for HiRes
		Ret				;...and return
ConvertDot	Endp

;		***************************
;		*  Load 6845 With Cursor  *
;		*     Bl = Page  	  *
;		***************************
LoadCursor	Proc	Near
		Call	ConvertCursor		;Convert cursor to linear
		Add	Ax,CrtStart		;...add to start of page
		Shr	Ax,1			;...get character only address
		Mov	Cx,Ax			;Send it to 6845
		Mov	Ah,14			;...register 14
		Call	Load6845Double		;...and return
		Ret
LoadCursor	Endp
$Eject

;		**********************************************
;		*  Fetch Crt Controller with Word Parameter  *
;		*	   Ah = Index    Cx = Word	     *
;		**********************************************

Fetch6845Double Proc	Near
		Call	Fetch6845		;Get a byte from the 6845
		Mov	Ch,Al			;...it is half of word
		Inc	Ah			;...Inc to next byte
		Call	Fetch6845		;Get next byte from the 6845
		Mov	Cl,Al			;...it is nent half of word
		Ret				;...return with word value
Fetch6845Double Endp

;		**********************************************
;		*  Fetch Crt Controller with Byte Parameter  *
;		*	  Ah = Index	Cx = Byte	     *
;		**********************************************

Fetch6845	Proc	Near
		Push	Dx			;Save Dx
		Mov	Dx,ActiveCard		;Get port address
		Xchg	Al,Ah			;...and send index from Ah
		Out	Dx,Al			;...to point 6845 at register
		Inc	Dl			;...inc to data port
		In	Al,Dx			;...and get byte
		Pop	Dx			;Restore Dx
		Ret				;...and return
Fetch6845	Endp

;		*************************************************
;		*  Convert from Row / Colusm to Linear Address  *
;		*************************************************
Convert		Proc	Near
		Push	Bx			;Save a register
		Mov	Bl,Al			;Get coluwns
		Mov	Al,Ah			;Get rows in Al
		Mul	Byte Ptr CrtColumns	;...and multiply by
		Xor	Bh,Bh			;Add in column
		Add	Ax,Bx			;...to get char address
		Shl	Ax,1			;...convert to real address
		Pop	Bx			;...restore and
		Ret				;...return
Convert		Endp

;		*********************
;		* Graphics Convert  *
;		*********************

ConvertGraph	Proc	Near
		Push	Bx			;Using Bx,save it
		Mov	Bl,Al			;Keep column value
		Mov	Al,Ah			;Multiply rows by
		Mul	Byte Ptr CrtColumns	;...# columns on screen then by
		Shl	Ax,1			;...4, Cause in graphics mode,
		Shl	Ax,1			;...there are 4 even field rows
						;...per character row
		Xor	Bh,Bh			;Add in columns to figure as if
		Add	Ax,Bx			;...each char was ony 1 byte
		Pop	Bx			;...which is correct for HiRes
		Ret				;Multiply x 0 for LoRes address
ConvertGraph	Endp

Bios		Ends

End