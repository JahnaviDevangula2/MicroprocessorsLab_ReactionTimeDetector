LCD_data equ P2    
LCD_rs   equ P0.0  
LCD_rw   equ P0.1  
LCD_en   equ P0.2  
lowerCOUNT EQU 15H    
upperCOUNT EQU 45H   
num EQU 113D
ORG 0000H
LJMP MAIN

ORG 000BH ; 
INC A
RETI

ORG 0100H
MAIN:
CLR C
MOV A, #00H
MOV P1, A
SUBB A, #lowerCOUNT
MOV R0, A
MOV A, #00H
SUBB A, #upperCOUNT 
MOV R1, A
MOV A, #00H
; --------------------------
ACALL msgSTART 
ACALL timerDELAY  
ACALL timerDELAY  
; set up timer T0
MOV TL0, #00H
MOV TH0, #00H
MOV IE, #82H ; IE = 10000010b (timer 0 on)
SETB P1.4 ; turn on LED
MOV A, #00H
SETB P1.0
SETB TR0 ; start timer
LOOP: JNB P1.0, LOOP
CLR TR0
MOV B,A
CLR P1.4
MOV R5, TL0
MOV R6, TH0
ACALL msgEND 
ACALL timerDELAY   
ACALL timerDELAY   
ACALL timerDELAY 
ACALL timerDELAY    
ACALL timerDELAY    
; -------
LJMP MAIN
HERE: SJMP HERE

ORG 0200H
timerDELAY:
MOV R2, #num
REPEAT:
; set up timer T1
MOV TMOD, #11H ; timer 0 and 1, GATE=0, C/T=0, mode 1
MOV TL1, R0
MOV TH1, R1
SETB TR1 ; start timer
WAIT: JNB TF1, WAIT
CLR TR1
CLR TF1
DJNZ R2, REPEAT
RET

org 0300h
msgSTART:
acall lcd_init      ;initialise LCD
acall delay
acall delay
mov a,#83h		 ;Put cursor on row 1, column 3 (and DB7 = 1)
acall lcd_command	 ;send command to LCD
acall delay
mov   dptr,#line1   ;Load DPTR with sring line1
acall lcd_sendstring	   ;call text strings sending routine
acall delay
mov a,#0C1h		 ;Put cursor on row 1, column 1 (and DB7 = 1)
acall lcd_command	 ;send command to LCD
acall delay
mov   dptr,#line2   ;Load DPTR with sring line2
acall lcd_sendstring	   ;call text strings sending routine
RET

org 0400h
msgEND:
acall lcd_init      ;initialise LCD
acall delay
acall delay
mov a,#81h		 ;Put cursor on row 1, column 3 (and DB7 = 1)
acall lcd_command	 ;send command to LCD
acall delay
mov   dptr,#end1   ;Load DPTR with sring line1
acall lcd_sendstring	   ;call text strings sending routine
acall delay
mov a,#0C0h		 ;Put cursor on row 1, column 0 (and DB7 = 1)
acall lcd_command	 ;send command to LCD
acall delay
mov   dptr,#end2   ;Load DPTR with sring line2
acall lcd_sendstring	   ;call text strings sending routine
; number of times
ACALL delay
MOV A, #0F0H
ANL A, B
SWAP A
ACALL writeBYTE
MOV A, #0FH
ANL A, B
ACALL writeBYTE
; space
acall delay
mov   dptr,#Hspace   ;Load DPTR with sring line2
acall lcd_sendstring	   ;call text strings sending routine
acall delay
; TH0 value
MOV A, #0F0H
ANL A, R6
SWAP A
ACALL writeBYTE
MOV A, #0FH
ANL A, R6
ACALL writeBYTE

; TL0 value
MOV A, #0F0H
ANL A, R5
SWAP A
ACALL writeBYTE
MOV A, #0FH
ANL A, R5
ACALL writeBYTE
RET

org 0500h
;------------------------LCD Initialisation routine----------------------------------------------------
lcd_init:
         mov   LCD_data,#38H  ;Function set: 2 Line, 8-bit, 5x7 dots
         clr   LCD_rs         ;Selected command register
         clr   LCD_rw         ;We are writing in instruction register
         setb  LCD_en         ;Enable H->L
		 acall delay
         clr   LCD_en
	     acall delay

         mov   LCD_data,#0CH  ;Display on, Cursor off
         clr   LCD_rs         ;Selected instruction register
         clr   LCD_rw         ;We are writing in instruction register
         setb  LCD_en         ;Enable H->L
		 acall delay
         clr   LCD_en
         
		 acall delay
         mov   LCD_data,#01H  ;Clear LCD
         clr   LCD_rs         ;Selected command register
         clr   LCD_rw         ;We are writing in instruction register
         setb  LCD_en         ;Enable H->L
		 acall delay
         clr   LCD_en
         
		 acall delay

         mov   LCD_data,#06H  ;Entry mode, auto increment with no shift
         clr   LCD_rs         ;Selected command register
         clr   LCD_rw         ;We are writing in instruction register
         setb  LCD_en         ;Enable H->L
		 acall delay
         clr   LCD_en

		 acall delay
         
         ret                  ;Return from routine

;-----------------------command sending routine-------------------------------------
 lcd_command:
         mov   LCD_data,A     ;Move the command to LCD port
         clr   LCD_rs         ;Selected command register
         clr   LCD_rw         ;We are writing in instruction register
         setb  LCD_en         ;Enable H->L
		 acall delay
         clr   LCD_en
		 acall delay
    
         ret  
;-----------------------data sending routine-------------------------------------		     
 lcd_senddata:
         mov   LCD_data,A     ;Move the command to LCD port
         setb  LCD_rs         ;Selected data register
         clr   LCD_rw         ;We are writing
         setb  LCD_en         ;Enable H->L
		 acall delay
         clr   LCD_en
         acall delay
		 acall delay
         ret                  ;Return from busy routine

;-----------------------text strings sending routine-------------------------------------
lcd_sendstring:
	push 0e0h
	lcd_sendstring_loop:
	 	 clr   a                 ;clear Accumulator for any previous data
	         movc  a,@a+dptr         ;load the first character in accumulator
	         jz    exit              ;go to exit if zero
	         acall lcd_senddata      ;send first char
	         inc   dptr              ;increment data pointer
	         sjmp  LCD_sendstring_loop    ;jump back to send the next character
exit:    pop 0e0h
         ret                     ;End of routine

;----------------------delay routine-----------------------------------------------------
delay:	 push 0
	 push 1
         mov r0,#1
loop2:	 mov r1,#255
	 loop1:	 djnz r1, loop1
	 djnz r0, loop2
	 pop 1
	 pop 0 
	 ret
; ------------------
; to write hex value of byte
ORG 0700H
writeBYTE:
JZ write0
DEC A
JZ write1
DEC A
JZ write2
DEC A
JZ write3
DEC A
JZ write4
DEC A
JZ write5
DEC A
JZ write6
DEC A
JZ write7
DEC A
JZ write8
DEC A
JZ write9
DEC A
JZ writeA
DEC A
JZ writeB
DEC A
JZ writeC
DEC A
JZ writeD
DEC A
JZ writeE
DEC A
JZ writeF
write0: mov dptr,#H0
LJMP end_write
write1: mov dptr,#H1
LJMP end_write
write2: mov dptr,#H2
LJMP end_write
write3: mov dptr,#H3
LJMP end_write
write4: mov dptr,#H4
LJMP end_write
write5: mov dptr,#H5
LJMP end_write
write6: mov dptr,#H6
LJMP end_write
write7: mov dptr,#H7
LJMP end_write
write8: mov dptr,#H8
LJMP end_write
write9: mov dptr,#H9
LJMP end_write
writeA: mov dptr,#HA
LJMP end_write
writeB: mov dptr,#HB
LJMP end_write
writeC: mov dptr,#HC
LJMP end_write
writeD: mov dptr,#HD
LJMP end_write
writeE: mov dptr,#HE
LJMP end_write
writeF: mov dptr,#HF
LJMP end_write
end_write:
acall lcd_sendstring
acall delay
RET

;------------- ROM text strings---------------------------------------------------------------
org 0800h
line1:  DB   "Toggle SW1", 00H
line2:  DB   "if LED glows", 00H
end1:  DB "Reaction Time", 00H
end2:  DB "Count is ", 00H
H0:   DB  "0",00H
H1:   DB  "1",00H
H2:   DB  "2",00H
H3:   DB  "3",00H
H4:   DB  "4",00H
H5:   DB  "5",00H
H6:   DB  "6",00H
H7:   DB  "7",00H
H8:   DB  "8",00H
H9:   DB  "9",00H
HA:   DB  "A",00H
HB:   DB  "B",00H
HC:   DB  "C",00H
HD:   DB  "D",00H
HE:   DB  "E",00H
HF:   DB  "F",00H
Hspace:   DB " ", 00H
end