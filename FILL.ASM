Title 'DTC/PC BIOS FF fill'


;    Author:      Sergio Aguayo

;    Start date:  March 2, 2024         Last edit:  March 2, 2024



;               ************************
;               *  Module Description  *
;               ************************

;       This module contains the FFH filler bytes for the
;   bios software




;            (c) Display Telecommunications Corporation, 1983
;                      All Rights Reserved



;               **********************
;               *  Revision History  *
;               **********************







Bios            Segment Byte Common 'CODE'
                Org     0E000H
				Db      2000H Dup (0FFH)        ;fill with FF
Bios            Ends

End
