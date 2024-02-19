$Title ('DTC/PC BIOS RS232 Driver V1.0')
$Pagelength (80) Pagewidth (132) Debug Nogen
Name RS232


;	Author:	Don K. Harrison

;	Start date:	October 30, 1983	Last edit:	December 28, 1983


;		************************
;		*  Module Description  *
;		************************

;		This module contains the serial interface driver.	The driver
;	is entered via interrupt 20 (TrapSIODriver).



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

		Public CommsDriver

;		*************
;		*  Equates  *
;		*************

		;	All Equates in include file: IbmInc

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

IntSegment	Segment Public

IntSegment	Ends

BiosDataArea	Segment Public
		Extrn RS232Base:Word, RS232TimeOut:Byte
BiosDataArea	Ends
$Eject

;		******************
;		*  Code Segment  *
;		******************

Bios		Segment Common

		Assume 	Cs:Bios, Ds:BiosDataArea

		Org	0E729H			;Align with Pc and Xt

BaudTable	Dw	SIO110Baud		;110 Baud
		Dw	SIO150Baud		;150 Baud
		Dw	SIO300Baud		;300 Baud
		Dw	SIO600Baud		;600 Baud
		Dw	SIO1200Baud		;1200 Baud
		Dw	SIO2400Baud		;2400 Baud
		Dw	SIO4800Baud		;4800 Baud
		Dw	SIO9600Baud		;9600 Baud

CommsDriver	Proc	Far
		Sti				;Restore interrupts
		Push	Ds			;Save all but Ax
		Push	Dx			;...Dx has card #
		Push	Si
		Push	Di
		Push	Cx
		Push	Bx
		Mov	Bx,BiosDataArea		;Setup our
		Mov	Ds,Bx			;...data segment
		Mov	Di,Dx			;Save card # for send/receive
		Mov	Bx,Dx			;Calculate index
		Shl	Bx,1			;...into base addresses
		Mov	Dx,RS232Base [Bx]	;Fetch base address to Dx
		Or	Dx,Dx			;Test for existance
		Jz	SIOReturn		;...and jump if not there
		Or	Ah,Ah			;Command = 0?
		Jz	SIOInit			;...if it is, jump to init
		Dec	Ah			;Command = 1?
		Jz	SIOSend			;...if it is, jump to send
		Dec	Ah			;Command = 2?
		Jz	SIOReceive		;...if it is, jump to receive
		Dec	Ah			;Command = 3?
		Jz	SIOStatus		;...if it is, return status
SIOReturn:
		Pop	Bx			;Restore registers
		Pop	Cx
		Pop	Di
		Pop	Si
		Pop	Dx
		Pop	Ds
		Iret				;...and return

;		************************
;		*  SIO Initialization  *
;		************************

SIOInit:
		;	Set the baud rate

		Push	Ax			;Save mode
		Mov	Bl,Al			;Save parameters
		Add	Dx,3			;Point at SIO control reg
		Mov	Al,SioAccessBrgDiv	;...and point at baud port
		Out	Dx,Al			;...(Dlab = 1)
		Mov	Cl,4			;Rotate parameter left 4 places
		Rol	Bl,Cl			;...placing baud index into
		And	Bx,0000000000001110B	;...2nd, 3rd and 4th bits of Bx
		Mov	Ax,Cs:BaudTable[Bx]	;...and retreive divisor
		Sub	Dx,3			;Restore I/O pointer to base
		Out	Dx,Al			;Send lower divisor to SIO
		Inc	Dx			;Set I/O pointer to base+1
		Mov	Al,Ah			;Send upper divisor
		Out	Dx,Al			;...to SIO

		;	 Send line control

		Pop	Ax			;Restore mode
		Inc	Dx			;Point at line
		Inc	Dx			;...control register
		And	Al,000000011111B	;Strip baud bits from
		Out	Dx,Al			;...mode and send to SIO

		;	Disable all interrupts

		Mov	Al,0			;Turn off all
		Dec	Dx			;Point back at interrupt enable
		Dec	Dx			;...register
		Out	Dx,Al			;...and set to no ints

		;	 Point back at base

		Dec	Dx			;Point back at base
		Jmp	Short SIOStatus		;Jump and return status

;		************************
;		*  SIO Send Character  *
;		************************

SioSend:
		Push	AX			;Save the character
		Mov	Al,SioEnabRTS Or SioEnabDTR	;Al has modem setup
		Mov	Bh,SioCTS Or SioDSR	;Bh has value for modem reg
		Mov	Bl,SioTxReady		;Bl has value for line reg
		Call	SetupandWait		;Setup port and wait
		Jnz	SendTimeOut		;If non zero, timeout
		Sub	Dx,5			;Point back to data port
		Pop	Cx			;Recover char, saving Ah
		Mov	Al,Cl			;...then move it into
		Out	Dx,Al			;...Al and output it
		Jmp	SioReturn		;...and return Ah = status
SendTimeOut:
 		Pop	Cx			;Recover data byte
		Mov	Al,Cl			;...into Al, preserving Ah
ReceiveTimeOut :
		Or	Ah,10000000B		;Return error bit and
		Jmp	SioReturn		;...return

;		***************************
;		*  SIO Receive Character  *
;		***************************

SIOReceive:
		Mov	Al,SioEnabDTR		;Al has modem setup
		Mov	Bh,SioDSR		;Bh has value for modem reg
		Mov	Bl,SioRxReady		;Bl has value for line reg
		Call	SetupandWait		;Setup port and wait
		Jnz	ReceiveTimeOut		;If non zero, timeout
		And	Ah,00011110B		;Mask off error flags
		Sub	Dx,5			;Point back at data register
		In	Al,Dx			;Get the character
		Jmp	SioReturn		;...and return with it Ah=stat.

;		*********************************
;		*  SIO Status Return Procedure  *
;		*   Ah = Line control register  *
;		*********************************

SIOStatus:
		Add	Dx,5		;Point at line status
		In	Al,Dx		;...and get it
		Mov	Ah,Al		;...and put in Ah for return
		Inc	Dx		;Point at modem status
		In	Al,Dx		;...get it and return it
		Jmp	SioReturn	;...in Al
CommsDriver	Endp


;		*********************************
;		*  Proc used by Setup and Wait  *
;		*   Ah = Line control register  *
;		*********************************

TimeOutProc	Proc	Near
		Mov	Bl,RS232TimeOut[Di]	;Di=Card # (dx at entry)
SioTimeOuter:
		Sub	Cx,Cx		;Maximum loop count
SioTimeInner:
		In	Al,Dx		;Get status
		Mov	Ah,Al		;...into Ah
		And	Al,Bh		;And with Bh mask
		Cmp	Al,Bh		;...and test if it matches
		Je	MatchReturn	;...jump if it does
		Loop	SioTimeInner	;Loop till sowething happens
		Dec	Bl		;...decrementing outer pointer
		Jnz	SioTimeOuter	;...and looping till timed out
		Or	Bh,Bh		;Return timed out, z flag clear
MatchReturn:
		Ret			;...indicating error
TimeOutProc	Endp

;		*****************************************
;		*  Modem Setup and Status Wait Routine  *
;		*       Ah = Line control register	*
;		*****************************************

SetupAndWait	Proc	Near
		Add	Dx,4		;Move from base to modem control
		Out	Dx,Al		;...register and output command
		Inc	Dx		;Move I/O pointer to modem status
		Inc	Dx		;...register
		Push	Bx		;Save Bl
		Call	TimeOutProc	;Wait for timeout or correct status
		Pop	Bx		;Restore Bx regardless
		Jnz	TimedOut	;Jump if not timed out
		Dec	Dx		;Point back at line status
		Mov	Bh,Bl		;Match for line register
		Call	TimeOutProc	;Wait for timeout or correct status
TimedOut:
		Ret			;...and return
SetupAndWait	Endp

Bios		Ends

End