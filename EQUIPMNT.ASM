$Title ('DTC/PC BIOS Equipment Determination and Memory Size V1.0')
$Pagelength (80) Pagewidth (132) Debug Nogen
Name Equipmnt


;	Author:	Don K. Harrison

;	Start date:	December 7, 1983	Last edit:	December 17, 1983


;		************************
;		*  Module Description  *
;		************************

;	This module contains the memory size determination service 
; routine (Int 18) and the equipaent inventory service routine Int (17). 
; A dummy routine to serve the non-existant cassette interrupt (Int 21)
; is also included. 





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

		Public EquipDriver, MemorySizeDriver, CassetteDriver


;		*************
;		*  Equates  *
;		*************

		;	All Equates in include file: IbmInc

$Include (IbmInc)
;		*************************
;		*  Global Include File  *
;		*************************
$NoList
$Eject


;		*******************
;		*  Data Segments  *
;		*******************

BiosDataArea	Segment Public
		Extrn MemorySize:Word, EquipFlag:Word
BiosDataArea	Ends
$Eject


;		******************
;		*  Code Segment  *
;		******************


Bios	Segment Common

	Assume Cs:Bios, Ds:BiosDataArea

;		*****************
;		*  Memory Size  *
;		*****************

		Org	0F841H

MemorySizeDriver	Proc	Far
		Sti				;Restore interrupts
		Push	Ds			;Save data segment
		Mov	Ax,BiosDataArea		;...load ours
		Mov	Ds,Ax			;...in
		Mov	Ax,MemorySize		;Get the info
		Pop	Ds			;Restore
		Iret				;...and return
MemorySizeDriver	Endp

;		************************
;		* Equipment Inventory  *
;		************************

		Org	0F84DH

EquipDriver	Proc	Far
		Sti				;Restore interrupts
		Push	Ds			;Save data segment
		Mov	Ax,BiosDataArea		;...load ours
		Mov	Ds,Ax			;...in
		Mov	Ax,EquipFlag		;Get the info
		Pop	Ds			;Restore
		Iret				;...and return
EquipDriver	Endp

;		**************************
;		* Dummy Cassette Driver  *
;		**************************

		Org 0F859H
CassetteDriver	Proc	Far
		Stc				;Error return
		Mov	Ah,86H			;...value
		Ret	2 			;Toss flags and return
CassetteDriver Endp

Bios	Ends

End