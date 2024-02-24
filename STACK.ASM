Title 'DTC/PC BIOS Stack V1.0'


;    Author:      Don K. Harrison

;    Start date:  October 25, 1983      Last edit:  October 30, 1983




;               ************************
;               *  Module Description  *
;               ************************

;       This module contains the stack segment.




;            (c) Display Telecommunications Corporation, 1983
;                      All Rights Reserved
;               **********************
;               *  Revision History  *
;               **********************









;               ********************
;               *  Public Symbols  *
;               ********************

                Public  StackTop

;               *******************
;               *  Stack Segment  *
;               *******************

BiosStack       Segment At 30H
                Dw      128 Dup (?)             ;128 Level Temporary Stack
StackTop        Label   Word
BiosStack       Ends

End
