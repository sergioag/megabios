$Title ('DTC/PC BIOS Floppy Disk Driver V1.0')
$Pagelength (80) Pagewidth (132) Debug Nogen
Name Floppy


;    Author:       Don K. Harrison
;    Start date:   November 17, 1983        Last edit:   December 22, 1983


;                ************************
;                *  Module Description  *
;                ************************
;
;        This module contains the floppy disk driver routines and
;    the floppy disk interrupt service routines. The driver is
;    accessed via interrupt 14 (TrapFDisk). The interrupt service
;    is via interrupt 19 (TrapFDDriver).



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

		Public FloppyDriver, FloppyHdwrInt, FloppyParamsPointer


;		*************
;		*  Equates  *
;		*************

;		*****************************
;		*  Stack Frame Definitions  *
;		*****************************

PointerSegment	Equ	[BP+12]
PointerOffset	Equ	[BP+10]
DTL		Equ	Byte Ptr [BP+9]
GapSize		Equ	Byte Ptr [BP+8]
EOT		Equ	Byte Ptr [BP+7]
SectorSize	Equ	Byte Ptr [BP+6]
SectorNumber	Equ	Byte Ptr [BP+5]
HeadNumber	Equ	Byte Ptr [BP+4]
TrackNumber	Equ	Byte Ptr [BP+3]
DriveNumber	Equ	Byte Ptr [BP+2]
FDCCommand	Equ	Byte Ptr [BP+1]
NumberOfSectors	Equ	Byte Ptr [BP]

;		********************************
;		*  Disk Parameter Definitions  *
;		********************************

Specify1	Equ	Es:Byte Ptr [Si]
Specify2	Equ	Es:Byte Ptr [Si+1]
MotorWait	Equ	Es:Byte Ptr [Si+2]
FormatGap	Equ	Es:Byte Ptr [Si+7]
FormatFiller	Equ	Es:Byte Ptr [Si+8]
HeadSettle	Equ	Es:Byte Ptr [Si+9]
MotorStart	Equ	Es:Byte Ptr [Si+10]
SoftParams	Equ	Es:Byte Ptr [Si]

;		*****************
;		*  Status Bits  *
;		*****************

OkStat          Equ     000000000B            ;Ok status
TimeOutStat     Equ     10000000B             ;Timeout
BadSeekStat     Equ     01000000B             ;Seek error
BadFDCStat      Equ     00100000B             ;Floppy controller bad
BadCrcStat      Equ     00010000B             ;CRC error
DMAPageStat     Equ     00001001B             ;Dma requested to cross 64k
BadDMAStat      Equ     00001000B             ;Dma probably bad
SectNotFndStat  Equ     00000100B             ;Sector not found
WriteProtStat   Equ     00000011B             ;Disk write protected
BadAddMarkStat  Equ     00000010B             ;Address mark not found
BadCmdStat      Equ     00000001B             ;Unrecognizable command

;		***********
;		*  Modes  *
;		***********

DMAVerifyMode   Equ     01000010B             ;Channel 2 verify normal
DMAReadMode     Equ     01000110B             ;Channel 2 read normal
DMAWriteMode    Equ     01001010B             ;Channel 2 write normal

;		**************
;		*  Commands  *
;		**************

FDCReadCMD      Equ     11100110B             ;Read command
FDCWriteCMD     Equ     11000101B             ;Hrite command
FDCFormatCMD    Equ     01001101B             ;Format command
FDCRecalCMD     Equ     00000111B             ;Recalibrate command
FDCSpecifyCMD   Equ     00000011B             ;Specify command (timers)
FDCSenseIntCMD  Equ     00001000B             ;Sense interrupt command
FDCSeekCMD      Equ     00001111B             ;Seek command

$Include (IbmInc.Asm)
;               *************************
;               *  Global Include File  *
;               *************************
;$Nolist
$Eject


;               *******************
;               *  Data Segments  *
;               *******************

IntSegment      Segment Public
		Extrn FloppyParamsTrapAddr:Dword
IntSegment      Ends

BiosStack       Segment Public
BiosStack       Ends

BiosDataArea    Segment Public
		Extrn FDCStatus:Byte, DisketteStat:Byte, SeekStatus:Byte
		Extrn MotorStatus:Byte, MotorCount:Byte
BiosDataArea    Ends
$Eject


;               **************************************
;               *  Stack Frame After Initialization  *
;               **************************************


;         -------------------------------
;        |         Return Address        | BP+22
;         -------------------------------
;        |              BP               | BP+20
;         -------------------------------     
;        |              SI               | BP+18
;         -------------------------------
;        |              DI               | BP+16
;         -------------------------------
;        |              DS               | BP+14
;         -------------------------------
;        | DMA Memory Pointer (Segment)  | BP+12
;         -------------------------------
;        | DMA Memory Pointer (Offset )  | BP+10
;         -------------------------------
;        |    DTL       |    GAP         | BP+8
;         -------------------------------
;        |    EOT       | Sector Size    | BP+6
;         -------------------------------
;        |  Sector #    |    Head #      | BP+4
;         -------------------------------
;        |    Track#    |    Drive #     | BP+2
;         -------------------------------
;        |   Command    |  # of Sectors  |<- BP
;         ------------------------------- 
$Eject


;               ******************
;               *  Code Segment  *
;               ******************

Bios            Segment Common
		Assume  Cs:Bios, Ds:BiosDataArea, Ss:BiosStack
		Org     0EC59H                  ;Align with PC / XT
		;       Initialization of stack frame
FloppyDriver    Proc    Far
		Sti                             ;Restore higher interrupts
		Push    Bp                      ;Save Block pointers Bp
		Push    Si                      ;...Si
		Push    Di                      ;...Di
		Push    Ds                      ;...Data segment
		Push    Es                      ;...Memory pointer SEG
		Push    Bx                      ;......OFFSET
		Mov     Di, Ax                  ;Save accumulator

		;       Point ES:SI at disk parameters

		Assume  Ds:IntSegment           ;DS refers to segment at zero
		Xor     Ax,Ax                   ;Fill Command block
		Mov     Ds,Ax                   ;...from data
		Les     Si,FloppyParamsTrapAddr ;...pointed to by int 30
		Assume  Ds:BiosDataArea         ;Tell ASM86 to use bios data
		Mov     Ax,BiosDataArea         ;...set segment register
		Mov     Ds,Ax                   ;...to bios data

		;       Move values from disk parameters

		Mov     Bx,5                    ;... starting at byte 5
		Mov     Ax,Es:[Bx][Si]          ;Load ax
		Push    Ax                      ;...and push (DTL & GAP)
		Dec     Bx                      ;Decrement index
		Dec     Bx                      ;...by 2 and
		Mov     Ax,Es:[Bx][Si]          ;Load ax
		Push    Ax                      ;...and push (EDT & Sec Sz)
		Xchg    Cl,Dh                   ;Re-arrange for
		Xchg    Dl,Cl                   ;...command block
		Push    Dx                      ;Save Cl, Dh (Sec# & HD#)
		Push    Cx                      ;Save Ch, Dl (TK# & DV#)
		Push    Di                      ;Save Ah, Al (Cmd & #Sectors)
		Mov     Bp,Sp                   ;Point at base of stack frame

		;       Parse and dispatch command

		Call    ParseAndGo              ;Parse command and execute

		;       Set the motor timer and affect carry with status

		Mov     Ah,MotorWait            ;Plug timer to keep
		Mov     MotorCount,Ah           ;...drives running
		Mov     Ah,DisketteStat         ;Affect carry flag
		Cmp     Ah,1                    ;if >1, carry will be clear
		Cmc                             ;...not, if >1, carry set

		;       Dissolve stack frame

		Pop     Bx                      ;Pop Ah, Al (Cad & #Sectors)
		Pop     Cx                      ;Pop TK & DVE
		Pop     Dx                      ;Pop SEC# & HD
		Xchg    Dl,Cl                   ;Restore back to
		Xchg    Cl,Dh                   ;...calling convention
		Pop     Bx                      ;Pop EOT & SEC SIZE
		Pop     Bx                      ;Pop DIL & GAP
		Pop     Bx                      ;Restore DMA offset pointer
		Pop     Es                      ;Restore DMA segment pointer
		Pop     Ds                      ;Restore data sequent pointer
		Pop     Di                      ;Restore pointers Di
		Pop     Si                      ;...Si
		Pop     Bp                      ;...Bp
		Ret     2                       ;Return without restoring flags
FloppyDriver    Endp
$Eject


;               ***********************************
;               *  Command Parser and Dispatcher  *
;               ***********************************

ParseAndGo      Proc    Near
		Mov     Al,FDCCommand           ;Parse the command
		Or      Al,Al                   ;...Command = reset?
		Jz      ResetCommand            ;...jmp if Ah=0
		Dec     Al                      ;...command = status?
		Jz      StatusCommand           ;...jump if Ah=1
		Cmp     DriveNumber,3           ;Drive # must be 0 1 2 or 3
		Jz      BadDriveRtn             ;...jump if out of range
		Cmp     Al,DiskCmdFormat        ;Command =< Format (highest)
		Jbe     DiskIOShort             ;...jump if 2 thru 5
BadDriveRtn:
		Mov     DisketteStat,BadCmdStat ;...else, unrecognizable
		Ret                             ;...return with bad status
DiskIOShort:
		Jmp     DiskIO                  ;Jump and execute r/w/v/f
ParseAndGo      Endp


;               *****************************
;               *  Diskette Status Command  *
;               *****************************

StatusCommand   Proc    Near
		Mov     Al, DisketteStat        ;Return the status of
		Ret                             ;...the last operation
StatusCommand   Endp


$Eject


;               **********************************************************
;               *                  Reset Command Handler                 *
;               *  Returns are via ResetReturn or error conditions in    *
;               *  FDCOut, Probelnterrupt, and GetStatus causing 2 level *
;               *  return from those procs.                              *
;               **********************************************************

ResetCommand    Proc
		Mov	Dx,PortFDCAdptMode	;Point at adapter mode port
		Cli				;Prevent int level motor change
		And	MotorStatus,00001111B	;Strip all but motor bits
		Mov	Al,MotorStatus		;...and get it in Al
		Mov	Cl,4			;Shift motor to upper for i/o
		Shl	Al,Cl			;...to mode port
		Test	Al,00100000B		;Motor 1?
		Jnz	MotorOneBit		;...jump if yes
		Test	Al,01000000B		;Motor 2?
		Jnz	MotorTwoBit		;...jump if yes
		Test	Al,10000000B		;Motor 3?
		Jz	MotorZeroBit		;...jump if no (0 or no motor)
		Inc	Al			;Inc 3 times to sel drive 3
MotorTwoBit:
		Inc     Al                      ;Inc 2 times to sel drive 2
MotorOneBit:
		Inc     Al                      ;Inc 1 time to sel drive 1
MotorZeroBit:
		Mov     SeekStatus,0            ;Require resets on all drives
		Mov     DisketteStat,OkStat     ;...set OK status
		Or      Al,00001000B            ;Interrupt/dma bit
		Out     Dx,Al                   ;...turn on motor, select and reset
		Or      Al,00000100B            ;...turn off reset bit
		Out     Dx,Al                   ;...FDC now reset
		Sti                             ;Restore interrupts and
		Call    WaitForInt              ;...Wait for one
		Call    ProbeInterrupt          ;Get status
		Mov     Al,FDCStatus            ;Ready transition?
		Cmp     Al,11000000B            ;...indicated by C0 status
		Jz      ResetContinue           ;Jump if ok

		;       FDC Error Return

		Mov     DisketteStat,BadFDCStat ;...if not, FDC may be bad
		Jmp     ResetReturn             ;...jump and error out
ResetContinue:
		Mov     Al,FDCSpecifyCmd        ;Specify timer settings
		Call    FDCOut                  ;...to FDC
		Mov     Al,Specify1             ;Send SPT and HUT
		Call    FDCOut                  ;...send it to FDC
		Mov     Al,Specify2             ;Send HLT and ND
		Call    FDCOut                  ;...send it to FDC
ResetReturn:
		Ret                             ;Return, FDC will not respond
ResetCommand    Endp
$Eject


;               ***********************************************************
;               *  Diskette I/O Commands (Read / Write / Verify / Format  *
;               *  Returns are via ErrorReturn, ErrorRtnNum, OperationOk  *
;               *     or error conditions in FDCOut, ProbeInterrupt, and  *
;               *     GetStatus causing 2 level return from those procs.  *
;               *  No matter where the return, Al will have the actual    *
;               *  number of sectors transferred                          *
;               ***********************************************************

		;       Command and Mode Table

TableStruc	Struc
Command		Db      FDCSpecifyCMD           ;0 Specify command
		Db      0                       ;1 No command for status
		Db      FDCReadCMD              ;2 Read command
		Db      FDCWriteCMD             ;3 Write command
		Db      FDCReadCMD              ;4 Verify command
		Db      FDCFormatCMD            ;5 Format command
DMAMode		Db      0                       ;0 Dma Not used
		Db      0                       ;1 Dma Not used
		Db      DMAReadMode             ;2 Read command
		Db      DMAWriteMode            ;3 Write command
		Db      DMAVerifyMode           ;4 Verify command
		Db      DMAWriteMode            ;5 Format command
Write		Db      0                       ;0 Reset
		Db      0                       ;1 Status
		Db      0                       ;2 Read
		Db      80H                     ;3 Write
		Db      0                       ;4 Verify
		Db      80H                     ;5 Format
Bit		Db      1,2,4,8                 ;Quick bits
TheirError	Db      10000000B               ;End of track
		Db      00100000B               ;Data error
		Db      00010000B               ;Overrun error
		Db      00000100B               ;Sector not found
		Db      00000010B               ;Write protect error
		Db      00000001B               ;Missing address mark
OurError        Db      SectNotFndStat          ;Sector not found
		Db      BadCrcStat              ;Crc error
		Db      BadDmaStat              ;Dma error
		Db      SectNotFndStat          ;Sector not found
		Db      WriteProtStat           ;Write protect
		Db      BadAddMarkStat          ;Address mark not found
		Db      BadFDCStat              ;None of the above (??)

TableStruc      Ends

$Nolist

Table		TableStruc <>

$List

DiskIO          Proc    Near
		Cli                             ;Clear ints during I/O and
		Mov     DisketteStat,OkStat     ;...Set OK status
		Mov     Al,FDCCommand           ;Get command
		Xor     Ah,Ah                   ;...into Ax
		Mov     Di,Ax                   ;...and then into Di
		Out     PortDmaToggle,Al        ;Set first/last f/f = first
		Mov     Al,Table.DMAMode[Di]    ;Get DMA mde byte
		Out     PortDmaMode,Al          ;...and output it to DMA

		;          Translate SEG:0FF to physical address

		Mov     Ax,PointerSegment       ;Get segment part of pointer
		Mov     Cl,4                    ;Multiply by 16 (bytes
		Rol     Ax,Cl                   ;...in a paragraph)
		Mov     Ch,Al                   ;Save upper nibble
		And     Ch,00001111B            ;...in Ch
		And     Al,11110000B            ;isolate upper nibble in Al
		Add     Ax,PointerOffset        ;Add offset in
		Adc     Ch,0                    ;...and carry into Ch
		Mov     Dx,Ax                   ;Save lower 16 bits of address

		;          Send address to DMAC

		Out     PortDMACh2Base,Al       ;...and output it
		Mov     Al,Ah                   ;...to DMA
		Out     PortDmaCH2Base,Al       ;...base registers
		Mov     Al,Ch                   ;Now output top
		Out     PortPageChan2,Al        ;...address to page registers

		;       Calculate Word Count

		Mov     Ah,NumberOfSectors      ;Form # of sectors
		Xor     Al,Al                   ;...times 128
		Shr     Ax,1                    ;...in AX
		Mov     Cl,SectorSize           ;Multiply by the
		Shl     Ax,Cl                   ;...number of bytes in sector
		Dec     Ax                      ;Correct for dma requirement

		;       Output it to DMAC

		Out     PortDMACh2Count,Al      ;...and output
		Xchg    Al,Ah                   ;...to the
		Out     PortDMACh2Count,Al      ;...DMA controller

		;       Test for word count error

		Xchg    Al,Ah                   ;Restore count in Ax
		Add     Ax,Dx                   ;Set carry if crossing 64k
		Jnc     NoCrossing              ;...and Jump if so

		;       Crossed 64k,Error return

		Sti                             ;Interrupts Ok now
		Mov     DisketteStat,DMAPageStat;...else loadup error code
		Jmp     ErrorReturn             ;...and return

NoCrossing:                                                                
		Mov     Al,00000010B            ;Get mask bit for DMAC
		Out     PortDMAMaskSngl,Al      ;...and enable the transfer
										     
		;       Turn on drive motor and select drive                             

		Mov     MotorCount,255          ;Set large value during I/O

		;       Calculate Drive Bit from Drive Number

		Mov     Bl,DriveNumber          ;Get drive number in
		Xor     Bh,Bh                   ;...BX
		Mov     Al,Table.Bit[Bx]        ;...and calculate bit number
		Mov     Ch,Al                   ;...Save in ch for seek

		;       Indicate on for compatibility

		Or      MotorStatus,Al          ;indicate in status byte

		;       Actually turn it on and select drive

		Mov     Cl,4                    ;Move motor bit to
		Shl     Al,Cl                   ;...upper nibble
		Or      Al,Bl                   ;...then or in drive number
		Or      Al,00001100B            ;Add enable and not reset
		Mov     Dx,PortFDCAdptMode      ;...point at adapter 1/0 port
		Out     Dx,Al                   ;...and output the data

		;       Restore interrupts from DMA section above

		Sti                             ;Restore interrupts from above

		;       If write, wait for motor up to speed

		Mov     Al,Table.Write[Di]      ;Test if command involves write
		Or      MotorStatus,Al          ;...(for compatibility)
		Or      Al,Al                   ;...and affect flags
		Jns     WaitDone                ;...jump if read (upper bit=0)

		;       Write command,wait for motor up to speed

		Mov     Ah,MotorStart           ;Ah=# of 125ms to wait
		Or      Ah,Ah                   ;Affect flags
		Jz      WaitDone                ;...if no wait (??), comply
		Push    Cx                      ;Save bit position in Ch
OuterLoop:
		Xor     Cx,Cx                   ;Max count in Cx
EighthSecLoop:
		Loop    EighthSecLoop           ;Loop for 125 ms
		Dec     Ah                      ;Decrewent outer loop
		Jnz     OuterLoop               ;...and jump to the top of it
		Pop     Cx                      ;Restore bit position in Ch
WaitDone:

		;       Seek to track Ch = Motor Bit, Bl = Drive #

		Test    SeekStatus,Ch           ;Need recal?
		Jnz     NoRecalReqd             ;...jump if no
		Or      SeekStatus,Ch           ;Show as recal
		Mov     Al,FDCRecalCMD          ;...and send recal
		Call    FDCOut                  ;...command to FDC
		Mov     Al,Bl                   ;Then send drive number
		Call    FDCOut                  ;...which is in Bl from above
		Call    WaitForInt              ;Wait for results
		Call    ProbeInterrupt          ;Get status
NoRecalReqd:
		Mov     Al,FDCSeekCMD           ;Send seek command
		Call    FDCOut                  ;...to FDC
		Mov     Al,Bl                   ;Send drive nusber
		Call    FDCOut                  ;...to FDC
		Mov     Al,TrackNumber          ;Send track number
		Call    FDCOut                  ;...to FDC
		Call    WaitForInt              ;Wait for results
		Call    ProbeInterrupt          ;Get status
		Mov     Al,HeadSettle           ;Get head settling time
		Or      Al,Al                   ;...none (??), comply
		Jz      MSTimerDone             ;...and end timer
MSOuterLoop:
		Mov     Cx,558                  ;1 ms timer
OneMsLoop:
		Loop    OneMsLoop               ;Loop for a ms
		Dec     Al                      ;Decrement outer loop
		Jnz     MSOuterLoop             ;Loop till done
MSTimerDone:

		;       Perform the operation

		Mov     Al,Table.Command[Di]    ;Get operation command
		Call    FDCOut                  ;...and send it
		Mov     Al,HeadNumber           ;Get head number
		And     Al,00000001B            ;...Make sure 0 or 1
		Shl     Al,1                    ;...move it into
		Shl     Al,1                    ;...position
		Or      Al,Bl                   ;...Or in drive number
		Call    FDCOut                  ;...and output second byte
		Cmp     FDCCommand,DiskCmdFormat ;Are we formatting?
		Jne     NotFormatting           ;...Jump if not

		;       Load parameters for format

		Mov     Al,SectorSize           ;FDC "N" parameter
		Call    FDCOut                  ;...Send it out
		Mov     Al,EOT                  ;FDC “SC" parameter
		Call    FDCOut                  ;...Send it out
		Mov     Al,FormatGap            ;FDC "GPL" parameter
		Call    FDCOut                  ;...Send it out
		Mov     Al,FormatFiller         ;FDC "D" parameter
		Call    FDCOut                  ;...send it out
		Jmp     CommandLoaded           ;Continue below

		;       Load parameters for read / write / verify

NotFormatting:
		Mov     Cx,7                    ;Transfer 7 bytes from
		Mov     Di,3                    ;...stack frame starting at 9
FrameLoop:       
		Mov     Al,[Bp][Di]             ;Get byte from frame
		Call    FDCOut                  ;...and send it
		Inc     Di                      ;...inc index to next byte
		Loop    FrameLoop               ;Loop till 7 bytes moved
		;       Wait for interrupt

CommandLoaded:
		Call    WaitForInt              ;Wait for end of op. interrupt
		Call    GetStatus               ;...Read in the status

		;       Test for error

		Mov     Al,FDCStatus            ;Get first status byte
		And     Al,11000000B            ;...normal termination?
		Jz      OperationOk             ;...jump if ok
		Cmp     Al,01000000B            ;...abnormal termination?
		Je      Translate               ;...jump if yes
		Mov     DisketteStat,BadFDCStat ;...else error return
		Jmp     ErrorRtnNum             ;...actual transferred

		;       Translate FDC error to our error
Translate:
		Mov     Al,FDCStatus+1          ;Look at second byte
		Mov     Cx,6                    ;6 bits to translate
		Xor     Bx,Bx                   ;...point at byte 0
ErrorLoop:
		Test    Al,Table.TheirError[Bx] ;Test a bit from table
		Jnz     ErrorFound              ;...and jump if it is set
		Inc     Bx                      ;...bump pointer
		Loop    ErrorLoop               ;...and loop till done

		;       Falling thru to here means no bits were set (FDC error)

ErrorFound:
		Mov     Al,Table.OurError[Bx]   ;Translate from table
		Mov     DisketteStat,Al         ;...and into DisketteStat

		;       Calculate # of sectors transferred and return in Al
ErrorRtnNum:
OperationOk:
		Mov     Al,FDCStatus[3]         ;Get track we ended up on
		Cmp     Al,TrackNumber          ;...compare it to starting tk
		Mov     Al,FDCStatus[5]         ;...get last sector
		Je      OnSameTrack             ;...jump if didn’t roll over
		Mov     Al,EOT                  ;Get last track
		Inc     Al                      ;...plus 1 into Al
OnSameTrack:
		Sub     Al,SectorNumber         ;Return end minus start
		Ret                             ;...equals num transferred

		;       Return for pre-operation errors
ErrorReturn:
		Mov     Al,0                    ;No sectors transferred
		Ret                             ;Return, operation failed
DiskIO          Endp
	       
;               ******************************************
;               *  Wait for Interrupt and Return Result  *
;               ******************************************

WaitForInt      Proc    Near
		Sti                             ;Ints on
		Xor     Cx,Cx                   ;Setup for 2 second wait
		Mov     Al,2                    ;...for interrupt
IntWaitLoop:
		Test    SeekStatus,10000000B    ;interrupt will set this
		Clc                             ;...clear carry for return
		Jnz     IntOccurred             ;...jump if interrupt
		Loop    IntWaitLoop             ;Loop til int occurrs
		Dec     Al                      ;Decrement outer loop
		Jnz     IntWaitLoop             ;...and loop some more
		Mov     DisketteStat,TimeOutStat;Set error status
		Pop     Ax                      ;Discard return address
		Xor     Al,Al                   ;Indicate 0 bytes xferred
		Stc                             ;Set carry for error and
		Ret                             ;...return 2 levels up
IntOccurred:
		And     SeekStatus,01111111B    ;Turn off interrupt bit
		Ret                             ;...return
WaitForInt      Endp

;               *******************************
;               *  Read Data from Controller  *
;               *******************************

FDCIn           Proc    Near
		Push    Cx                      ;Save Cx
		Xor     Cx,Cx                   ;Maxigum timeout
		Mov     Dx,PortFDCStatus        ;Pointer to FDC Status port
FDCInLoop1:
		In      Al,Dx                   ;Get status
		Or      Al,Al                   ;Affect flags
		Js      MasterReady             ;If upper bit set, jump
		Loop    FDCInLoop1              ;Loop till master set or 7.0.
		Mov     DisketteStat,TimeOutStat;FDC did not respond, error
		Jmp     Short FDCInRtn          ;...return
MasterReady:
		Test    Al,01000000B            ;Correct direction?
		Jnz     CorrectDir              ;...Jump if so
		Mov     DisketteStat,BadFDCStat ;...else chip is bad, error out
FDCInRtn:
		Pop     Cx
		StC                             ;Indicate error
		Ret                             ;...and return

		;       Data ready

CorrectDir:
		Inc     Dx                      ;Point at data port
		In      Al,Dx                   ;Get a byte
		Push    Ax                      ;...and save it
		Mov     Cx,10                   ;Pause and let FDC get another
PauseLoop:
		Loop    PauseLoop               ;...byte ready if it has one
		Dec     Dx                      ;Point back at status
		In      Al,Dx                   ;...and get it
		Test    Al,00010000B            ;...test if still busy. Return
		Clc                             ;...carry clear and
		Pop     Ax                      ;...restore data
		Pop     Cx                      ;...and registers, return
		Ret                             ;...Z=1 if last byte
FDCIn           Endp


;               ************************************
;               *  Disk Interrupt Service Routine  *
;               ************************************

		Org     0EF57H

FloppyHdwrint   Proc    Far
		Sti                             ;Restore interrupts
		Push    Ds                      ;Save Data segment
		Push    Ax                      ;Save an intermediate register
		Mov     Ax,BiosDataArea         ;Load data segment
		Mov     Ds,Ax                   ;...with bios segment
		Or      SeekStatus,10000000B    ;Turn on indicator bit
		Mov	Al,PicEOI		;Interrupt ack to Pic
		Out     PortPICOCW2,Al          ;...to restore higher ints
		Pop     Ax                      ;Restore
		Pop     Ds                      ;...registers
		Iret                            ;Restore flags and return
FloppyHdwrint   Endp

;               ***************************
;               *  Read Operation Result  *
;               ***************************

ResultProc      Proc    Near
ProbeInterrupt:
		Mov     Al,FDCSenseIntCMD       ;Send command to sense int
		Call    FDCOut                  ;...to FDC
GetStatus:
		Push    Bx                      ;Save Bx
		Push    Cx                      ;...and Cx
		Mov     Cx,7                    ;Get 7 bytes max from FDC
		Mov     Bx,0                    ;...set pointer to first byte
ResultLoop:
		Call    FDCIn                   ;Get a byte
		Jc      StatErrRtn              ;...Jump if an error occurred
		Mov     FDCStatus[Bx],Al        ;...and store it
		Jz      StatusReturn            ;Jump if the FDC is empty
		Inc     Bx                      ;...else bump pointer and
		Loop    ResultLoop              ;...loop
		Mov     DisketteStat,BadFDCStat ;More than 7 bytes is an error
StatErrRtn:
		Stc                             ;Set carry for error return
		Pop     Cx                      ;Restore Cx
		Pop     Bx                      ;...and Bx
		Pop     Ax                      ;Discard return address
		Xor     Al,Al                   ;Indicate 0 bytes xferred
		Ret                             ;...and return 2 levels up
StatusReturn:
		Pop     Cx                      ;Restore Cx
		Pop     Bx                      ;...and Bx
		Ret                             ;and return error
ResultProc      Endp

;               ******************************
;               *  Write Data to Controller  *
;               ******************************

FDCOut          Proc    Near
		Push    Cx                      ;Save
		Push    Dx                      ;...registers
		Push    Ax                      ;...on Stack
		Xor     Cx,Cx                   ;Maximum timeout
		Mov     Dx,PortFDCStatus        ;Pointer to FDC Status port
FDCOutLoop1:
		In      Al,Dx                   ;Get status
		Or      Al,Al                   ;Affect flags
		Js      OutMasterRdy            ;If upper bit set, jump
		Loop    FDCOutLoop1		;Loop till master set or T.O.
		Mov     DisketteStat,TimeOutStat;FDC dic not respond, error
		Jmp     Short OutErrRtn         ;...jump and return error
OutMasterRdy:
		Test    Al,01000000B            ;Correct direction?
		Jz      OutCorrectDir           ;...jump   if so
		Mov     DisketteStat,BadFDCStat ;...else chip is bad, error out
		Jmp	Short OutErrRtn		;...jump and return error
OutCorrectDir:
		Inc	Dx			;Point at data port
		Pop	Ax			;Restore data to output
		Out	Dx,Al			;...and output it
		Clc                             ;Clear carry
		Pop     Dx                      ;Restore Dx
		Pop     Cx                      ;...and Cx
		Ret                             ;...and return
OutErrRtn:
		Pop     Ax                      ;Restore Ax
		Pop     Dx                      ;Restore Dx
		Pop     Cx                      ;...and Cx
		Pop     Ax                      ;Discard return address
		Xor     Al,Al			;Indicate 0 bytes xferred
		Stc				;...and set carry flag
		Ret				;...cand return 2 levels back
FDCOut          Endp

;               **************************
;               *  Disk Base Parameters  *
;               **************************

		Org     0EFC7H                  ;Align with PC / XT

FloppyParamsPointer     Db        11001111B             ;Specify byte 1
			Db        00000010B             ;Specify byte 2
			Db        37                    ;Motor timeout wait
			Db        2                     ;512 bytes per sector
			Db        8                     ;Last sector on a track
			Db        42                    ;Gap length
			Db        0FFH                  ;DTL
			Db        80                    ;Format gap length
			Db        0F6H                  ;Format fill byte
			Db        25                    ;Head settle time
			Db        4                     ;Motor start time

Bios        Ends

End