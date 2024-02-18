$Title ('DTC/PC BIOS EPROM FF byte fill  V1.0')
$Pagelength (80)
$Pagewidth (132)
$Debug
;$Nogen
Name Fill

Bios		Segment Common

		Org	0E000H			;Begin BIOS

		Db	2000H Dup(0FFH)


Bios	Ends
End