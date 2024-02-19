$Title ('DTC/PC BIOS Initialization Module  V1.0')
$Pagelength (80) Pagewidth (132) Debug Nogen
Name Video


;    Author:		Don K. Harrison

;    Start date:  October 18,1983	Last edit:	December 26, 1983


;		************************
;		*  Module Description  *
;		************************
;
;	The Initialization module serves to initialize the system
;    on power up, or during a keyboard or manual reset. Initialization
;    occurs for the system board peripherals and all attached option
;    adapters. Global memory location values are initialized by this module.



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

		Public ResetEntry,POREntry


;		*************
;		*  Equates  *
;		*************

BiosCksErr	Equ	00000001B		;Bios rom checksum error
MemErr		Equ	00000010B		;System memory error
VidMemErr	Equ	00000100B		;Video memory error
RefreshErr	Equ	00001000B		;Memory refresh error
First2kErr	Equ	00010000B		;Error in first 2k of RAM
IOROMErr	Equ	00100000B		;Error in expansion ch. ROM
AsciiCarriage	Equ	0DH			;Carriage return
AsciiLineFeed	Equ	0AH			;Line feed


;$Include (IbmInc.Asm)
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
		Extrn MemorySize:Word, ResetFlag:Word, EquipFlag:Word
		Extrn KeyBuffer:Byte, KeyBufHead:Word, KeyBufTail:Word
		Extrn BufferStart:Word, BufferEnd:Word
		Extrn PrintTimeOut:Word, RS232TimeOut:Word
		Extrn PrinterBase:Word, RS232Base:Word
		Extrn IOROMInit:Word, IOROMSegment:Word
		Extrn MfgErrFlag:Byte, PositionCursor:Near, ClearScreen:Near
		Extrn CrtMode:Byte, CrtColumns:Word
		Extrn CrtModeSet:Byte, ActiveCard:Word

BiosDataArea	Ends

BiosStack	Segment Public
		Extrn StackTop:Word
BiosStack	Ends

HiStack	Segment
HiStack 	Ends

IntSegment	Segment Public
		Extrn RAMVectors:DWord, ROMVectors:DWord, VideoTrapAddr: DWord
		Extrn BasicTrapAddr:DWord, NMITrapAddr:DWord
		Extrn VideoGraphicsTrapAddr:DWord, PrintScreenTrapAddr:DWord
IntSegment	Ends

BasicSeg	Segment Common
		Assume Cs:BasicSeg
		Org	0
Basic		Label Far
BasicSeg	Ends

IOROMSeg	Segment Common
IOROMSeg	Ends

FlasherSegment	Segment
DsZero		Label 	Byte
FlasherSegment	Ends

MonoSeg		Segment Public
MonoSeg		Ends

ColorSeg	Segment Public
ColorSeg	Ends


$Eject

;		******************************
;		*  Segment at End of Memory  *
;		******************************

ReleaseDate	Segment byte

;		***********************
;		*  Release Date Code  *
;		***********************

		Db	'12/23/83DKH'

ReleaseDate	Ends
$Eject
;		******************
;		*  Code Segment  *
;		******************
;		************************************
;		*  Initialization Code Entry Point  *
;		************************************

Bios		Segment Common

		Extrn PrintScreenInt:Near, NMIInt:Near, IllegalInt:Near
		Extrn WordOut:Near, ByteOut:Near, KeyIn:Near
		Extrn PrintMessage:Near, Beep:Near, CharOut:Near
		Extrn MemoryTest:Near, RomCheckCx:Near
		Extrn ROMCheck8K:Near, VideoInit:Near
		Extrn CrtCrlf:Near

		Org	0E000H			;Begin BIOS
StartOfBios	Label	Byte
LogonMsg	Db	'            MEGA-BIOS    V1.0'
		Db	AsciiCarriage, AsciiLineFeed, AsciiLineFeed
		Db	'(C) Display Telecommunications ',0
Logon2ndHalf	Db	'Corporation, 1983'
		Db	AsciiCarriage, AsciiLinefeed, AsciiLineFeed, 0


;		**********************
;		*  List of Printers  *
;		**********************

		Assume Cs:Bios			;Tell ASM86 what we think
PossiblePtrs:
		Dw	3BCH			;Printer on mono card
		Dw	378H			;Parallel printer card (pri.)
		Dw	278H			;Parallel printer card (sec.)

		Org	0E05BH			;Align with PC and XT

;		***************
;		*  COLD BOOT  *
;		***************

POREntry	Label far

		;	Prepare for Cold Boot

		Assume	Ds:BiosDataArea
		Mov	Ax,BiosDataArea		;Point at our memory
		Mov	Ds,Ax			;...segment
		Mov	ResetFlag,0		;...and be sure cold boot
		Assume	Ds:Nothing

;		***************
;		*  WARM BOOT  *
;		***************

ResetEntry	Label	Far

		;	Turn off interrupts

		Cli				;Reset interrupts till ready

		;	Test 8088 Flags

		Xor	Ax,Ax			;Cy,Of,Sf=0, Z,Pf=1
		Jc	Err8088			;...jump if carry set
		Jo	Err8088			;...jump if overflow
		Js	Err8088			;...jump if sign
		Jnz	Err8088			;...jump if not zero
		Jpo	Err8088			;...jump if parity odd
		Add	Ax,1			;Z=0,Pf=0
		Jz	Err8088			;...jump if zero stuck
		Jpe	Err8088			;...jump if parity stuck
		Sub	Ax,8002H		;Z=0,Pf=1,Sf=0,Of=0
		Js	Err8088			;...jump if sign set
		Inc	Ax			;...cause overflow
		Jno	Err8088			;...jump if not overflow
		Shl	Ax,1			;Test shifting
		Jnc	Err8088			;...Should shift into cy
		Jnz	Err8088			;...and leave Ax clear
		Shl	Ax,1			;Shift zero in
		Jc	Err8088			;...should clear carry

		;	Test Registers

		Mov	Bx,5555H		;Alternating pattern
RegTest:
		Mov	Bp,Bx			;................
		Mov	Cx,Bp			;.		.
		Mov	Sp,Cx			;.    Shift	.
		Mov	Dx,Sp			;.    thru	.
		Mov	Ss,Dx			;.  Registers	.
		Mov	Si,Ss			;.		.
		Mov	Es,Si			;.		.
		Mov	Di,Es			;.		.
		Mov	Ds,Di			;.		.
		Mov	Ax,Ds			;................
		Cmp	Ax,5555H		;Like we started?
		Jne	Not5555			;...jump if no
		Not	Ax			;Invert it
		Mov	Bx,Ax			;...and move to starting reg
		Jmp	RegTest			;...and do again
Not5555:
		Cmp	Ax,0AAAAH		;Second pass result?
		Je	Ok8088			;...jump if ok
Err8088:
		Hlt				;Common error halt
Ok8088:
		;	Begin the Initialization

		Cld				;Clear direction flag
		Mov	Al,NMIMask		;Mask NMI
		Out	PortNMIMask,Al		;...interrupts till ready

		;	Stabilize Color and Monochrome Adapters

		Mov	Dx,PortColorMode	;Preliminarily
		Mov	Al,0			;...disable
		Out	Dx,Al			;...color adapter
		Mov	Dx,PortMonoCntl1	;...and disable
		Inc	Al			;...monochrome adapter
		Out	Dx,Al			;...but enable Hi Res

		;	Setup Miscelaneous on Board I/O

		Mov	Al,PPIBStdMode		;Mode PPI
		Out	PortPPIMode,Al		;...for A,C=in, B=out

						;Speaker gate = open
						;...Speaker data = off
						;...Spare = hi
		Mov	Al,PPIBStartUpMode	;...Config. sw = sw0 - sw3
		Out	PortPPIPortB,Al		;...Sys parity = enabled
						;...I/O Check = disabled
						;...Keyboard clk = released
						;...Keyboard clr = released

		;	Turn on Memory Refresh and Init DMAC

		Mov	Al,01010100B		;Setup timer 1
		Out	PortCTCMode,Al		;...for LSB only,Mode 2, Bin
		Mov	Al,CTCRefreshDiv	;Load timer 1
		Out	PortCTCLoadCh1,Al	;...with refresh divisor
		Mov	Al,0			;Set DMA channel registers
		Out	PortPageChan1,Al	;...to base page
		Out	PortPageChan2,Al	;...do all three
		Out	PortPageChan3,Al	;...channels just in case
		Out	PortDMAReset,Al		;Reset DMA controller
		Mov	Al,01011000B		;Mode DMA
		Out	PortDMAMode,Al		;...Channel 0 = Read, auto-init
		Mov	Al,01000001B		;Mode DMA
		Out	PortDMAMode,Al		;...Channel 1 = Verify
		Mov	Al,01000010B		;Mode DMA
		Out	PortDMAMode,Al		;...Channel 2 = Verify
		Mov	Al,01000011B		;Mode DMA
		Out	PortDMAMode,Al		;...Channel 3 = Verify
		Mov	Al,0FFH			;Load max count in
		Out	PortDMACh0Count,Al	;...channel 0 for
		Out	PortDMACh0Count,Al	;...refresh of memories
		Mov	Al,00000000B		;Enable DMAC,
		Out	PortDMACommand,Al	;...and unmask channel 0
		Out	PortDMAMaskSngl,Al	;...turning on refresh

		;	Test if refresh working

		;	NOTE: this test was removed in cloned copies
		;	as it is likely to fail on anything other 
		;	than a 4.77 MHz 8088
%If (1) Then (
		Mov	Cx,0A00H		;Un-noticable wait time
RefTstLoop:
		Loop	RefTstLoop		;Loop for a short while
		In	Al,PortDMACh0Count	;Get count low byte
		Mov	Ah,Al			;Save it
		In	Al,PortDMACh0Count	;Get count high byte
		Xchg	Al,Ah			;...put them right
		Neg	Ax			;How far have we counted?
		Mov	Bp,0			;Clear error flag
		Cmp	Ax,270H			;Lowest allowed = 270H
		Jb	DmaErr			;...jump if below
		Cmp	Ax,290H			;Highest allowed = 290H
		Jbe	RefOk			;Jump if ok and continue
DmaErr:
		Mov	Bp,RefreshErr		;Error = Refresh Error
) Else (
		;	Bypass DMA refresh test
		Mov	Bp,0			;Clear error flag
%Repeat	(01CH) (Nop				;fill to maintain ORGs
)
) fI

		;	Initialize Real Time Clock (Channel 0 of 8253)
RefOk:
		Mov	Al,00110110B		;Mode = 2 byte, Sq. Wave
		Out	PortCTCMode,Al		;...binary counting
		Mov	Al,0			;Load counter with @ for
		Out	PortCTCLoadCh0,Al	;...maximum count and
		Out	PortCTCLoadCh0,Al	;...slowest clock available

		;	Enable expansion box

		Mov	Dx,PortEXPEnable	;Enable any
		Mov	Al,1			;...expansion
		Out	Dx,Al			;...chassis

		;	Retreive warm start flag

		Assume	Ds:BiosDataArea, Es:Nothing
		Mov	Ax,BiosDataArea		;Point at our data area
		Mov	Ds,Ax			;...and get
		Mov	Si,ResetFlag		;...reset flag, keep it in Si

		;	Clear Memory (initializing parity bits)

		Xor	Ax,Ax			;Writing a zero
		Mov	Bx,Ax			;Bx is segwent pointer
		Mov	Dx,0AA55H		;Load Dx with pattern
		Cld				;Set forward direction
ClearLoop:
		Xor	Di,Di			;Clear byte pointer
		Mov	Es,Bx			;Set segment register
		Mov	Es:[Di],Dx		;Store pattern
		Cmp	Dx,Es:[Di]		;...and test,is memory
		Jne	TopFound		;...there? if not, jump
		Mov	Cx,02000H		;Count 8K Words, or
	Rep	Stosw				;...16K bytes to write zeros

		Add	Bh,4			;Bump to next 16K segaent
		Cmp	Bh,0A0H			;...is it last one?
		Jne	ClearLoop		;...if not,loop,else done
TopFound:
		Mov	ResetFlag,Si		;Put warm boot flag back after
						;...clearing memory

		;	Perform memory test on first 2K,regardless of warmth

		Xor	Ax,Ax			;Segment starts at 0
		Mov	Es,Ax			;...load Es
		Mov	Ax,HiStack		;Setup Hi mem stack
		Mov	Ss,Ax			;...segment and
		Mov	Sp,Offset StackTop	;...stack pointer
		Push	Bp			;Save error from refresh test
		Push	Bx			;Save Memory Size
		Mov	Bp,2			;Count = 2k
		Call	MemoryTest		;Go test memory
		Pop	Ax			;Restore Memory Size
		Mov	Cl,6			;Convert from # of 64K's
		Shr	Ax,Cl			;...to # of 1K's
		Mov	MemorySize,Ax		;Store memory size
		Pop	Ax			;Restore error from refresh
		Jnc	First2kOk		;...jump if Ok
		Or	Al,First2kErr		;...else set error bit
First2kOk:
		Mov	MfgErrFlag,Al		;Save error status in memory
		Xor	Ax,Ax			;Clear stack to zero
		Push	Ax			;By pushing some zeros
		Push	Ax			;By pushing some zeros
		Push	Ax			;By pushing some zeros
		Push	Ax			;By pushing some zeros
		Push	Ax			;By pushing some zeros

		Assume	Ss:BiosStack, Ds:BiosDataArea, Es:Nothing
		Mov	Ax,BiosStack		;Setup bios stack
		Mov	Ss,Ax			;...segment and
		Mov	Sp,Offset StackTop	;...stack pointer

		;	Perform Checksum on Bios Rom

		Push	Ds			;Save our data segment
		Mov	Bx,Offset StartOfBios	;Point at our ROM
		Push	Cs			;Set Ds = Cs
		Pop	Ds			;...required byte subroutine
		Mov	Ah,1			;...do 1 8k segment
		Call	ROMCheck8K		;Check it
		Pop	Ds			;Restore Ds
		Jz	BiosRomOk		;...and jump if all ok

		;	Set error flag

		Or	MfgErrFlag,BiosCksErr	;Error type = Bios checksum
BiosRomOk:

		;	Initialize Interrupt Controller

		Cli				;Insure interrupts off
		Mov	Al,00010011B		;Edge trig, 4 byte vector,
		Out	PortPICICw1,Al		;...single,ICW4 needed
		Mov	Al,8			;Address 8
		Out	PortPICICW2,Al		;...to start vectors
		Mov	Al,00001001B		;Buffered mode,
		Out	PortPICICW4,Al		;...8086/8088 mode
		Mov	Al,11111111B		;Mask off all
		Out	PortPICOCW1,Al		;...interrupts for now

		;	Initialize Interrupt Vectors

		Assume	Es:IntSegment
		Push	Ds			;Save Ds value
		Mov	Ax,IntSegment		;Load segment register
		Mov	Es,Ax			;...with interrupt segment
		Push	Cs			;Get fixed seg value = Cs
		Pop	Ds			;...keep in Ax, load Ds
		Mov	Cx,8			;Setup first 8 vectors to
		Mov	Di,Offset RAMVectors	;Start at first interrupt
NullIntLoop:
		Mov	Ax,Offset IllegalInt	;Get offset of illegal int
		Stosw				;Store offset
		Mov	Ax,Cs			;Get segment of illegal int
		Stosw				;Store segment
		Loop	NullIntLoop		;Loop till done
		Mov	Si,Offset ROMVectors	;From rom based vectors
		Mov	Cx,24			;Initializing 24 more vectors
VectorLoop:
		Movsw				;Move data from ROM to RAM
		Mov	Ax,Cs			;Get segment of illegal int
		Stosw				;Store SEG value = CS
		Loop	VectorLoop		;Loop till 32 vectors written

		;	Test if Basic exists and plug vector if it does

		Mov	Ax,BasicSeg		;Point
		Mov	Ds,Ax			;...at Basic
		Mov	Bx,Offset Basic		;Offset of basic in our segment
		Mov	Ah,4			;...there are 4 8k segments
BasicCkLoop:
		Call	ROMCheck8k		;Check one
		Jne	NoBasic			;...jump if checksum fails
		Dec	Ah			;...count - 1
		Jnz	BasicCkLoop		;...loop till done
		Pop	Ds			;Restore data segment register
		Assume	Ds:BiosDataArea		;...and informs ASM86
		Mov	Di,Offset BasicTrapAddr ;Point at basic trap address
		Mov	Ax,Offset Basic		;Offset = 0
		Stosw				;...store it
		Mov	Ax,BasicSeg		;Segment = F600
		Stosw				;...store it
		Push	Ds			;Keeping the stack in order
NoBasic:
		Pop	Ds			;Restore data segment
		Assume	Ds:BiosDataArea		;...and inform ASM86

		;	Plug NMI Vector

		Mov	Es:Word Ptr NMITrapAddr,Offset NMIInt

		;	Plug Print Screen Vector

		Mov	Es:Word Ptr PrintScreenTrapAddr,Offset PrintScreenInt

		;	Plug User Graphics Pointer with 0000

		Mov	Es:Word Ptr VideoGraphicsTrapAddr, 0
		Mov	Es:Word Ptr VideoGraphicsTrapAddr + 2, 0

		;	Enable NMI Interrupts

		Mov	Dx,PortPPIPortB		;Point at PPI port B
		In	Al,Dx			;Reset parity check edge
		Or	Al,PPIBDisSysParit or PPIBDisIOParity	;...trigger
		Out	Dx,Al			;...flip flops
		And	Al,Not (PPIBDisSysParit or PPIBDisIOParity) ;Release
		Out	Dx,Al			;...flip flop clear inputs
		Mov	Al,NMIUnmask		;Ok, carefully
		Out	PortNMIMask,Al		;...unmask NMI interrupts

		;	Initialize Both Mono and Color Adapters, Regardless
		;	of Their Presence

		Mov	Ax,30H			;Switch value if mono
		Mov	EquipFlag,Ax		;...adapter
		Mov	Ah,VidCmdInit		;Command to initialize
		Int	TrapVideo		;Initialize monochrome adapter
		Mov	Ax,20H			;Switch value if color
		Mov	EquipFlag,Ax		;...adapter
		Mov	ah,VidCmdInit		;Command to initialize
		Int	TrapVideo		;Initialize color adapter

		;	Setup Configuration Data

		In	Al,PortPPIPortC		;Get first 4 switches
		And	Al,00001111B		;...into upper
		Mov	Ah,Al			;...Ax
		Mov	AL,PPIBConfigSlct + PPIBStartUpMode ;Select upper
		Out	PortPPIPortB,Al		;...configuration switches
		In	Al,PortPPIPortC		;Get next 4 switches
		Mov	Cl,4			;Shift it
		Shl	Al,Cl			;...into upper nibble
		Or	Al,Ah			;...and OR with lower switches
		Mov	Ah,0			;Store configuration
		Mov	EquipFlag,Ax		;...Word (upper byte = 0)
		And	Al,00110000B		;Isolate display bits
		Jnz	DisplayExistsJmp	;...and jump if display exists
		Mov	Ax,Offset NullReturn	;Get offset of null int return
		Mov	Es:Word ptr VideoTrapAddr,Ax	;...and force into video vector
		Jmp	Short DontInitVideos	;Don't init the videos
DisplayExistsJmp:

		;	Set Video Card Per Switches

		Call	VideoInit		;Proc init's per switches

		;	Initialize Keyboard and Keyboard Buffer
DontInitVideos: 
		Mov	Al,00001000B		;Clock line = 0
		Out	PortPPIPortB,Al		;...to signal remote 8048
		Mov	Cx,10582		;Delay for approx.
KeyResetLoop:
		Loop	KeyResetLoop		;...20 milliseconds
		Mov	Al,11001000B		;Release clock and clear
		Out	PortPPIPortB,Al		;...shift register and int
		Xor	Al,10000000B		;...request f/f, then enable
		Out	PortPPIPortB,Al		;...shift register output
		Mov	Ax,Offset KeyBuffer	;Setup keyboard buffer
		Mov	KeyBufHead,Ax		;Head pointer
		Mov	KeyBufTail,Ax		;Tail pointer
		Mov	BufferStart,Ax		;Starting address of buffer
		Add	Ax,32			;Length of buffer = 32
		Mov	BuFferEnd,Ax		;...store it
		Jmp	OverNMIEntry		;Jump over PC NMI entry point

		Org	0E2C3H			;Align with PC

		Jmp	NMIInt			;Jump to parity err. service
OverNMiEntry:
		;	Initialize Default RS-232 and Printer Timeout Values

		Mov	Ax,1414H		;Translated to 4 bytes of
		Mov	PrintTimeOut[0],Ax	;...decinal 20s corresponding
		Mov	PrintTimeOut[2],Ax	;...to 4 possible printers
		Mov	Ax,0101H		;Translated to 4 bytes of
		Mov	RS232TimeOut[0],Ax	;...decimal 1s corresponding
		Mov	RS232TimeOut[2],Ax	;...to 4 possible RS-232 ports

		;	Determine Printer Hardware and Setup Base I/O Addr.

		Mov	Si,Offset PossiblePtrs	;Point at list of printers
		Mov	Di,0			;Reset index value
		Mov	Cx,3			;Only three printers
PrintBaseLoop:
		Mov	Dx,Cs:[Si]		;Load Ax with first (next) base
		Mov	Al,0AAH			;Try to write bit pattern
		Out	Dx,Al			;...to printer port
		%Bus	(0FFH)			;Force floating bus hi
		In	Al,Dx			;...then read data back
		Cmp	Al,0AAH			;...and see if it took
		Jne	PrinterNotThere		;...jump if not
		Mov	PrinterBase[Di],Dx	;...else, store base address
		Inc	Di			;...and inc dest. pointer
		Inc	Di			;...to next slot
PrinterNotThere:
		Inc	Si			;Increment source to
		Inc	Si			;...next try
		Loop	PrintBaseLoop		;...and loop (max of 3 times)
		Mov	Ax,Di			;Calculate and put
		Mov	Cl,3			;...into position
		Ror	Al,Cl			;...by rotating end around
		Mov	Byte ptr EquipFlag+1,Al ;Save the # of printers

		;	Determine RS-232 Hardware and Setup Base I/O Addresses

		Mov	Di,0			;Reset index value
		Mov	Dx,PortSio1LCR		;Use LCR for test
		Mov	Al,00011010B		;Setup LCR for standard mode
		Out	Dx,Al			;...as a test of it's existance
		%Bus	(0FFH)			;Force floating bus hi
		In	Al,Dx			;...then read back data
		Cmp	Al,00011010B		;...and see if it took
		Jne	Sio1NotThere		;...jump if not else store
		Mov	RS232Base[Di],PortSio1RxData	;...store base address
		Inc	Di			;...and inc dest. pointer
		Inc	Di			;...to next slot
Sio1NotThere:
		Mov	Dx,PortSio2LCR		;Use LCR for test
		Mov	Al,00011010B		;Setup LCR for standard mode
		Out	Dx,Al			;...as a test of it's existance
		%Bus	(0FFH)			;Force floating bus hi
		In	Al,Dx			;...then read back data
		Cmp	Al,00011010B		;...and see if it took
		Jne	Sio2NotThere		;...jump if not else, store
		Mov	RS232Base[Di],PortSio2RxData	;...store base address
		Inc	Di			;...and inc dest. pointer
		Inc	Di			;...to next slot
Sio2NotThere:
		Mov	Ax,Di			;Or in the number of RS232
		Or	Byte ptr EquipFlag+1,Al ;...ports into equipflag

		;	Determine Game Card Equipment and Signify it

		Mov	Dx,PortGCAButtens	;Read buttons
		In	Al,Dx			;...and check
		Test	Al,00001111B		;...that all are = 0
		Jnz	NoGameCard		;jump if no game card, else
		Or	Byte ptr EquipFlag+1,00010000B ;...signify it
NoGameCard:
		;	Test memory if required

		Test	Byte Ptr EquipFlag,1	;Test Post switch
		Jz	NoMemTest		;...jump if post off
		Cmp	ResetFlag,1234H		;Test warm boot
		Je	NoMemTest		;...and jump if warm
		Call	SysMemTest		;...else do a memory test
NoMemTest:
		;	Initialize Expansion Modules,if Present

		Mov	Dx,IOROMSeg		;2K ROMs from C0000 to F6000
		Assume 	Ds:Nothing
		Push	Ds			;Save data segment
ExpansionChk:
		Mov	Ds,Dx			;Make ROM data segment
		Mov	Bx,0			;Bx = pointer to first word
		Mov	Ax,[Bx]			;...Get it
		Cmp	Ax,0AA55H		;Is signature correct?
		Jnz	SignatureNG		;...Jump if it isn't
		Assume 	Es:BiosDataArea
		Mov	Ax,BiosDataArea		;Point Es at our data segment
		Mov	Es,Ax
		Xor	Ah,Ah			;Clear accum upper and put
		Mov	Al,[Bx+2]		;...length in accum lower
		Mov	Cl,5			;Multiply Ax by 32 to get
		Shl	Ax,Cl			;...actual length in paragraphs
		Add	Dx,Ax			;Add it to pointer
		Mov	Cl,4			;Convert length from paragraphs
		Shl	Ax,Cl			;...to bytes
		Mov	Cx,Ax			;Move count to cx for proc.
		Call	ROMCheckCx		;Check rom checksum
		Jnz	ROMErrJmp		;...if bad, skip initialization
		Push	Dx			;Save pointer during init
		Mov	IOROMInit,3		;Offset into jump vector
		Mov	IOROMSegment,DS		;...Segment into jump vector
		Call	DWord ptr IOROMInit	;...and call init code
		Pop	Dx			;Restore pointer
		Jmp	ROMDone			;...and jump, rom init'ted
ROMErrJmp:
		Or	MfgErrFlag,IOROMErr	;Indicate Error

SignatureNG:
		Add	Dx,80H			;Skip to next ROM space
ROMDone:
		Cmp	Dx,BasicSeg		;Was that our last ROM?
		Jl	ExpansionChk		;...if Dx<F600, do some more
		Pop	Ds			;Restore data segment
		Assume 	Ds:BiosDataArea		;...and tell ASM86

		;	Enable Keyboard,Floppy and RTC Interrupts

		In	Al,PortPICOCW1		;Unmask timer, floppy
		And	Al,10111100B		;...and keyboard
		Out	PortPICOCW1,Al		;...interrupts

		;	Signal that we are warm

		Mov	ResetFlag,1234H		;Warmth code

		;	Beep once

		Mov	Bl,2			;Medium length Beep
		Call	Beep			;Prod operator
		Xor	Cx,Cx			;Pause

		;	Report any errors

		Test	MfgErrFlag,11111111B	;Any Bits set?
		Jz	BootItUp		;...jump if not

		;	Beep again for error
BeepPause:
		Nop				;...a
		Loop	BeepPause		;...while
		Mov	Bl,2			;Medium length Beep
		Call	Beep			;Prod operator
		Push	Ds			;Save Ds for later
		Push	Cs			;Load code pointer
		Pop	Ds			;...into data pointer
		Mov	Si,Offset ErrorMsg	;Point at error message
		Call	PrintMessage		;...and print it
		Pop	Ds			;Restore Ds

		;	Get response

		Mov	Ax,000EH		;Position cursor to end
		Call	PositionCursor		;...for printing error number
		Mov	Al,MfgErrFlag		;Get the error
		Mov	MfgErrFlag,0		;...clear the error
		Call	ByteOut			;Print byte
		Mov	Ax,001DH		;Position cursor to end
		Call	PositionCursor		;...for retreiving answer
		Call	KeyIn			;Get keyboard data
		Push	Ax			;Save Ax
		Call	CharOut			;Echo keyboard response
		Pop	Ax			;Restore Ax
		Cmp	Al,'Y'			;...Y?
		Je	BootItup		;...jump and continue if yes
		Cmp	Al,'y'			;...y?
		Je	BootItUp		;...jump and continue if yes
		Jmp	ResetEntry		;Re-boot


BootItUp:
		;	Logon with copyright notice

		Call	ClearScreen		;Clear the screen
		Mov	Al,Byte Ptr CrtColumns	;Save column count
		Push	Ax			;...in stack
		Push	Cs			;Make Ds
		Pop	Ds			;...Cs
		Mov	Si,Offset LogOnMsg	;Point at message
		Call	PrintMessage		;...and send it
		Pop	Ax			;Restore column count
		Cmp	Al,80			;...is it >= 80?
		Jae	SkipBootCr		;Jump if 80 or above
		Call	CrtCrlf			;...else do a carriage return
SkipBootCr:
		Mov	Si,Offset LogOn2ndHalf	;Point at message
		Call	PrintMessage		;...and send it

		;	Boot it Up

		Int	TrapBoot
NullReturn:
		Iret				;Null return from interrupt
ErrorMsg	Db	'System Error #  , Continue? ',0

$Eject
;		************************
;		*  System Memory Test  *
;		************************

SysMemTest	Proc	Near
		Mov	Ah,VidCmdCurType	;Turn off cursor
		Mov	Cx,2007H		;...by putting it on an
		Int	TrapVideo		;...immaginary scan line
		Mov	Si,Offset MemTstMsg	;Point at message
		Push	Ds			;Save current Ds
		Push	Cs			;Send message to screen
		Pop	Ds			;...telling about
		Call	PrintMessage		;...memory test

		;	Determine which video memory

		Pop	Ds			;Restore data segment
		Mov	Al,CrtMode		;Which monitor?
		Cmp	Al,7			;...Monochrome?
		Mov	Bx,ColorSeg		;Point at color
		Mov	Ax,16			;...and say 16K
		Jne	ColorMon		;...jump if color
		Mov	Bx,MonoSeg		;...else point at monochrome
		Mov	Al,4			;...and only 4K
ColorMon:
		Push	Bx			;...and save for memory test
		Push	Ax			;...save length of video mem

		;	Test system memory

		Mov	Bp,MemorySize		;Get # of ik Blocks in mem
		Dec	Bp			;...leave the first one alone
		Dec	Bp			;...and the second one
		Push	Ds			;Save data segment
		Inc	Bx			;...make seg 2
		Inc	Bx			;...paragraphs into display
		Mov	Ds,Bx			;Load segment for message
		Assume	Ds:FlasherSegment	;Dummy segment for DsZero def.
		Mov	Bx,2048 / 16		;Point at 3rd
		Mov	Es,Bx			;...1K block with Es
		Mov	DsZero,05CH		;Flasher character "\"
OuterMemLoop:
		Test	Bp,111B			;Flip only if lower three bits
		Jnz	SkipFlip		;...of counter are = 0
		Xor	DsZero,073H		;...alternate between \ and /
SkipFlip:
		Call	MemoryTest		;...test memory
		Jc	LoadMemErr		;...and jump if bad
		Dec	Bp			;Bp has count
		Jnz	OuterMemLoop		;...jump and loop
		Pop	Ds			;Restore data sequent
		Jmp	TestVidMem		;...and go test video
LoadMemErr:
		Pop	Ds			;Restore data segment
		Assume 	Ds:BiosDataArea		;...and tell ASM86
		Or	MfgErrFlag,MemErr	;Load error number

		;	Test video memory
TestVidMem:
		Mov	Al,CrtModeSet		;Current setting of video reg
		And	Al,11110111B		;...turn off video
		Mov	Dx,ActiveCard		;...on
		Add	Dx,4			;...active
		Out	Dx,Al			;...video card
		Pop	Bp			;Length in 1K blocks
		Pop	Es			;...Segment of video memory
OuterVidLoop:
		Call	MemoryTest		;...do the test
		Dec	Bp			;Bp has count
		Jnz	OuterVidLoop		;...jump and loop
		Jnc	MemTstRtn		;Return if ok
		Or	MfgErrFlag,VidMemErr	;...else, set error code

		;	Turn Video Back On
MemTstRtn:
		Call	Videoinit		;Initialize the video
		Ret				;...else return
MemTstMsg	Db	'Testing Memory  /',0	;Memory test message

SysMemTest	Endp

Bios	Ends
End	POREntry