Title 'DTC/PC BIOS Time of Day and Real Time Clock V1.0'


;    Author:      Don K. Harrison

;    Start date:  December 7, 1983      Last edit:  December 20, 1983


;               ************************
;               *  Module Description  *
;               ************************
;
;       This module contains the time of day driver routine (Int 26)
;   and the real time clock hardware interrupt service routine (Int 8)
;




;            (c) Display Telecommunications Corporation, 1983
;                      All Rights Reserved



;               **********************
;               *  Revision History  *
;               **********************








;               ********************
;               *  Public Symbols  *
;               ********************

                Public TodDriver, TimerHdwrInt


;               *************
;               *  Equates  *
;               *************

                ;       All Equates in include file: IbmInc

Include IBMINC

;               *******************
;               *  Data Segments  *
;               *******************


BiosDataArea    Segment Public
                Extrn TimerLow:Word, TimerHigh:Word,TimerOverflow:Byte
                Extrn MotorStatus:Byte, MotorCount:Byte
BiosDataArea    Ends

;               ******************
;               *  Code Segment  *
;               ******************

Bios            Segment Common

                Assume  Cs:Bios, Ds:BiosDataArea

;               ************************
;               *  Time of Day Driver  *
;               ************************

                Org     0FE6EH                  ;Align with Pc and Xt
TodDriver       Proc    Far
                Sti                             ;Restore interrupts
                Push    Ds                      ;Setup
                Push    Ax                      ;...our
                Mov     Ax,BiosDataArea         ;...data
                Mov     Ds,Ax                   ;...segment
                Pop     Ax                      ;Restore command
                Cli                             ;Allow no ints
                Or      Ah,Ah                   ;Command = 0 = Read
                Jz      ReadClock               ;...jump if so
                Dec     Ah                      ;Command = 1 = Set
                Jnz     TodReturn               ;...jump if not and return

                ;       Set the clock

                Mov     TimerLow,Dx             ;Low portion of day clock
                Mov     TimerHigh,Cx            ;High portion of day clock
                Mov     TimerOverflow,0         ;Overflow = false
                Jmp     Short TodReturn         ;...Return

                ;       Read the clock

ReadClock:
                Mov     Cx,TimerHigh            ;Return High portion
                Mov     Dx,TimerLow             ;Return Low portion
                Mov     Al,TimerOverflow        ;Return overflow status
TodReturn:
                Sti                             ;Restore interrupts
                Pop     Ds                      ;Restore user data seg.
                Iret                            ;...and return
TodDriver       Endp

;               *****************************
;               *  Real Time Clock Handler  *
;               *****************************

                Org     0FEA5H                  ;Align with PC and Xt

TimerHdwrInt    Proc    Far
                Sti                             ;Restore interrupts
                Push    Ds                      ;Save minimum registers
                Push    Dx                      ;...so this runs
                Push    Ax                      ;...fast
                Mov     Ax,BiosDataArea         ;Load segment register
                Mov     Ds,Ax                   ;...with bios segment

                ;       First, process diskette motor timer

                Dec     MotorCount              ;Reduce timer for motor by 1
                Jnz     MotorsStillRun          ;...and return if not 0
                And     MotorStatus,11110000B   ;Clear motor running bits
                Mov     Al,00001100B            ;...and turn off motors
                Mov     Dx,PortFDCAdptMode      ;Point at port
                Out     Dx,Al                   ;...turn them off
MotorsStillRun:

                ;       Now, process clock

                Inc     TimerLow                ;Inc the low part of timer
                Jnz     NoCarryToHi             ;...and jump if it didn't carry
                Inc     TimerHigh               ;...else increment High timer
NoCarryToHi:
                Cmp     TimerHigh,18H           ;Does the timer = 24 hrs
                Jne     NoCarryToOflo           ;...jump if not
                Cmp     TimerLow,0B0H           ;Does the timer = 24 hrs
                Jne     NoCarryToOflo           ;...jump if not

                ;       Set overflow

                Mov     TimerHigh,0             ;Clear the
                Mov     TimerLow,0              ;...timer and
                Mov     TimerOverflow,1         ;...set the overflow flag

NoCarryToOflo:
                ;       Now, process user RTC tick routine

                Int     TrapTimerBreak          ;Probably a dummy return

                ;       Acknowledge interrupt

                Mov     Al,PicEoi               ;End of interrupt
                Out     PortPICOCW2,Al          ;...to 8259A
                Pop     Ax                      ;Restore
                Pop     Dx                      ;...registers
                Pop     Ds                      ;...and
                Iret                            ;...return
TimerHdwrInt    Endp

Bios            Ends

End
