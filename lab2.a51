TEMPO1			EQU 0x31

TEMPO_PWM_L		EQU 0x32
TEMPO_PWM_H		EQU 0x33

CONTADOR_ENC_L	EQU 0x34
CONTADOR_ENC_H	EQU 0x35

CONTADOR_VOLTA	EQU 0x36

TIMER1_AUX		EQU	0x37

RPM_L			EQU 0x38
RPM_H			EQU 0x39

RPM_IDEAL_L		EQU 0x40
RPM_IDEAL_H		EQU 0x41

NUM_VOLTA		EQU 04h ; NUM VOLTAS * 2

COUNTER_FREQ	EQU 5000d ; 200Hz

BOTAO1			EQU P3.2
BOTAO2			EQU P3.4

LED3 			EQU P1.4
	
LCD_RS 			EQU	P2.5 ; 0->INSTRUCAO / 1->DADO
LCD_RW			EQU	P2.6 ; 0->ESCRITA / 1->LEITURA
LCD_EN			EQU	P2.7
LCD_DATA		EQU P0
	
LCD_RST_CMD		EQU	0x01 ; RESET
LCD_HME_CMD		EQU 0x02 ; HOME	 
LCD_CFG_CMD		EQU 0x3C ; CONFIG
						 ;20h + 
						 ;10h (modo 8 bits)
						 ;08h (2 linhas) 
						 ;04h (caracter5x10) 

CMOD			EQU 0D9h
CCON			EQU 0D8h
CCAPM0			EQU 0DAh
CCAP0H			EQU 0FAh
CCAP0L			EQU 0EAh

ORG 0x0000
LJMP main

ORG 0x000B
clr EA ; disable Interrupts
LJMP int_tmr0

ORG 0x001B
;reti
clr EA ; disable Interrupts
LJMP int_tmr1

ORG 0x0013
clr EA ; disable Interrupts
LJMP int_ext1
;reti

ORG 0x2000
int_tmr1:
	push PSW
	push ACC
	push 000h
	push 001h	

	dec TIMER1_AUX
	mov A, TIMER1_AUX
	jz calcula_rpm
	
	ljmp fim_int_tmr1		

calcula_rpm:
	mov TIMER1_AUX, #007h
	
	;CONTADOR_ENCOCER_L*255
	mov A, CONTADOR_ENC_L
	mov B, #0FFh
	mul	AB
	mov RPM_L, A
	mov RPM_H, B

	mov CONTADOR_ENC_L, #000h

	ljmp fim_int_tmr1


fim_int_tmr1:
	pop 001h
	pop 000h
	pop ACC
	pop PSW 

	SETB EA ; Enable Interrupts

	reti

int_ext1:
	; PUSH
	clr EA ; disable Interrupts
	push PSW
	push ACC
	push 000h
	push 001h

	dec CONTADOR_VOLTA
	mov A, CONTADOR_VOLTA
	jz incrementa_encoder

	ljmp fim_int_ext1	
	;djz CONTADOR_VOLTA, incrementa_encoder

fim_int_ext1:
	;POP
	pop 001h
	pop 000h
	pop ACC
	pop PSW 	

	SETB EA ; Enable Interrupts

	reti

incrementa_encoder:
	INC CONTADOR_ENC_L
	
	mov CONTADOR_VOLTA, #NUM_VOLTA

	ljmp fim_int_ext1


incrementa_encoder_H:
	inc CONTADOR_ENC_H
	ljmp fim_int_ext1
	;mov A, CONTADOR_ENC_H 
	;add A, #01h
	;mov CONTADOR_ENC_H, A
int_tmr0:
	clr EA ; disable Interrupts
	push PSW
	push ACC
	push 000h
	push 001h

	clr EA ; disable Interrupts

	clr TF0
	JB P1.3, pwm_low
	LJMP pwm_high
	
exit_tmr0:
	pop 001h
	pop 000h
	pop ACC
	pop PSW

	SETB EA ; Enable Interrupts

	reti

pwm_low: ;entrando no low do pwm
	mov R1, #013h ; parte superior dos 5000
	mov R0, #088h ; parte baixa dos 5000
	
	mov A, R0
	clr C
	subb A, TEMPO_PWM_L
	mov R0, A

	mov A, R1
	subb A, TEMPO_PWM_H
	mov R1, A

	mov A, #0FFh
	clr C
	subb A, R0
	mov R0, A

	mov A, #0FFh
	subb A, R1
	mov R1, A

	mov TL0, R0
	mov TH0, R1

;	mov TL0, TEMPOD_PWM_L
;	mov TH0, TEMPOD_PWM_H

	cpl P1.3

	ljmp exit_tmr0

pwm_high: ; entrando no high do pwm

	mov A, #0FFh
	clr C
	subb A, TEMPO_PWM_L
	mov TL0, A

	mov A, #0FFh
	subb A, TEMPO_PWM_H
	mov TH0, A

	cpl P1.3

;	mov TL0, TEMPOL_PWM_L
;	mov TH0, TEMPOL_PWM_H

	ljmp exit_tmr0

main:
	lcall lcd_init
	lcall write_msg_ini

	;mov TL0, #078h
	;mov TH0, #0ECh

	mov TL1, #00h
	mov TH1, #00h

	mov RPM_L, #000h
	mov RPM_H, #000h

	mov RPM_IDEAL_L, #068h
	mov RPM_IDEAL_H, #010h

	mov TIMER1_AUX, #007h
	; 0,032768

	mov CONTADOR_VOLTA, #NUM_VOLTA
	mov CONTADOR_ENC_L, #000h
	mov CONTADOR_ENC_H, #000h

	mov TMOD, #011h

	SETB EA ; Enable Interrupts
	SETB ET0 ; Enable Timer 0 Interrupt
	SETB ET1
	SETB TR0 ; Start Timer
	SETB TR1 

	mov TEMPO_PWM_H, #005h;#003h
	mov TEMPO_PWM_L, #0DCh;#0E8h

	; interrupcao externa
	SETB EX1 ; Enable external interrupt 1
	SETB IT1 ; External interrupt borda

loop:

	jnb BOTAO1, incrementa_tempo	
	jnb BOTAO2, decrementa_tempo
	
	mov R0, #00h
	mov R1, #00h
	mov R2, #00h
	mov R3, #00h
	mov R4, #00h
	mov R5, RPM_IDEAL_H
	mov R6, RPM_IDEAL_L
	lcall Hex16ToASCII
	lcall lcd_update_ideal

	mov R0, #00h
	mov R1, #00h
	mov R2, #00h
	mov R3, #00h
	mov R4, #00h
	mov R5, RPM_H
	mov R6, RPM_L
	lcall Hex16ToASCII
	lcall lcd_update_atual
		
	ljmp loop	

incrementa_tempo:

	mov A, #0FAh
	clr C
	add A, TEMPO_PWM_L
	mov TEMPO_PWM_L, A

	mov A, #001h
	addc A, TEMPO_PWM_H
	mov TEMPO_PWM_H, A 

	mov A, #088h
	clr C
	subb A, TEMPO_PWM_L

	mov A, #013h
	subb A, TEMPO_PWM_H

	jc limite_incrementa

	mov A, #078h
	clr C
	add A, RPM_IDEAL_L
	mov RPM_IDEAL_L, A

	mov A, #005h
	addc A, RPM_IDEAL_H
	mov RPM_IDEAL_H, A 

	ljmp espera_botao 


limite_incrementa:
	mov TEMPO_PWM_H, #013h
	mov TEMPO_PWM_L, #056h

	mov RPM_IDEAL_L, #0B0h
	mov RPM_IDEAL_H, #036h 

	ljmp espera_botao

decrementa_tempo:
	;inc CONTADOR_ENC_L
	;ljmp espera_botao
	
	mov A, TEMPO_PWM_L
	clr C
	subb A, #0FAh
	mov TEMPO_PWM_L, A

	mov A, TEMPO_PWM_H
	subb A, #001h
	mov TEMPO_PWM_H, A


	mov A, TEMPO_PWM_L
	clr C
	subb A, #0DCh

	mov A, TEMPO_PWM_H
	subb A, #005h

	jc limite_decrementa

	mov A, RPM_IDEAL_L
	clr C
	subb A, #078h
	mov RPM_IDEAL_L, A

	mov A, RPM_IDEAL_H
	subb A, #005h
	mov RPM_IDEAL_H, A

	ljmp espera_botao 

limite_decrementa:
	mov TEMPO_PWM_H, #005h
	mov TEMPO_PWM_L, #0DCh

	mov RPM_IDEAL_L, #068h
	mov RPM_IDEAL_H, #010h

	ljmp espera_botao 

espera_botao:
	lcall delay_1ms
	lcall delay_1ms
	lcall delay_1ms
	lcall delay_1ms
	lcall delay_1ms
	jnb BOTAO1, espera_botao
	jnb BOTAO2, espera_botao

	ljmp loop


lcd_update_ideal:
	clr LCD_RS
	mov LCD_DATA, #0x8A
	lcall lcd_write
	setb LCD_RS

	mov LCD_DATA, R0
	lcall lcd_write

	mov LCD_DATA, R1
	lcall lcd_write

	mov LCD_DATA, R2
	lcall lcd_write

	mov LCD_DATA, R3
	lcall lcd_write

	mov LCD_DATA, R4
	lcall lcd_write
	
	ret

lcd_update_atual:

	clr LCD_RS
	mov LCD_DATA, #0xCA
	lcall lcd_write
	setb LCD_RS

	mov LCD_DATA, R0
	lcall lcd_write

	mov LCD_DATA, R1
	lcall lcd_write

	mov LCD_DATA, R2
	lcall lcd_write

	mov LCD_DATA, R3
	lcall lcd_write

	mov LCD_DATA, R4
	lcall lcd_write
	
	ret

write_msg_ini:
	mov LCD_DATA, #'V'
	lcall lcd_write

	mov LCD_DATA, #'E'
	lcall lcd_write

	mov LCD_DATA, #'L'
	lcall lcd_write

	mov LCD_DATA, #' '
	lcall lcd_write

	mov LCD_DATA, #'I'
	lcall lcd_write

	mov LCD_DATA, #'D'
	lcall lcd_write

	mov LCD_DATA, #'E'
	lcall lcd_write

	mov LCD_DATA, #'A'
	lcall lcd_write

	mov LCD_DATA, #'L'
	lcall lcd_write

	clr LCD_RS
	mov LCD_DATA, #0xC0
	lcall lcd_write
	setb LCD_RS

	mov LCD_DATA, #'V'
	lcall lcd_write

	mov LCD_DATA, #'E'
	lcall lcd_write

	mov LCD_DATA, #'L'
	lcall lcd_write

	mov LCD_DATA, #' '
	lcall lcd_write

	mov LCD_DATA, #'A'
	lcall lcd_write

	mov LCD_DATA, #'T'
	lcall lcd_write

	mov LCD_DATA, #'U'
	lcall lcd_write

	mov LCD_DATA, #'A'
	lcall lcd_write

	mov LCD_DATA, #'L'
	lcall lcd_write

	ret
	
lcd_init:
	clr LCD_RS
	clr LCD_RW
	clr LCD_EN

	;espera 40ms só pra ter certeza que o lcd iniciou.
;	mov R1, #40d
;loop_40ms:
;	LCALL delay_1ms
;	DJNZ R1, loop_40ms
		
;	mov LCD_DATA, #0x30
;	lcall lcd_write

;	lcall delay_1ms
;	lcall delay_1ms
;	lcall delay_1ms
;	lcall delay_1ms

;	mov LCD_DATA, #0x30
;	lcall lcd_write

;	lcall delay_1ms

;	mov LCD_DATA, #0x30
;	lcall lcd_write

;	mov LCD_DATA, #0x38
;	lcall lcd_write

;	mov LCD_DATA, #0x0C
;	lcall lcd_write
 
;	mov LCD_DATA, #0x01
;	lcall lcd_write

;	lcall delay_1ms

;	mov LCD_DATA, #0x06
;	lcall lcd_write

;	mov LCD_DATA, #LCD_CFG_CMD

	;8bits mode, 2 linhas, fonte 5x8
	mov LCD_DATA, #00111000b
	lcall lcd_write
	lcall delay_1ms

	;display on, cursor on, cursor blink on
	mov LCD_DATA, #00001111b
	lcall lcd_write
	lcall delay_1ms

	;incrementa 1 para direita
	mov LCD_DATA, #00000110b
	lcall lcd_write

	;home display
	mov LCD_DATA, #0x01
	lcall lcd_write
	lcall delay_1ms

	mov LCD_DATA, #0x3C
	lcall lcd_write
	lcall delay_1ms
	;reset display
;	mov LCD_DATA, #LCD_RST_CMD
;	lcall lcd_write
	
;	lcall delay_1ms
	
	setb LCD_RS

	ret
	
lcd_write:
	nop
	setb LCD_EN
	nop
	clr LCD_EN
	
	lcall delay_1ms
	
	ret

;******************************
;	24Mhz -> 0.5uS por ciclo
;   1ms -> 2000 ciclos
delay_1ms: 
	mov TEMPO1, #249d 			;2ciclos
delay_1ms_loop:
	nop							;1ciclos
	nop							;1ciclos
	nop							;1ciclos
	nop							;1ciclos
	nop							;1ciclos
	nop							;1ciclos
	DJNZ TEMPO1, delay_1ms_loop ;2ciclos
								;8ciclos * 249 + 2 = 1994 ciclos
	nop							;1ciclos
	nop							;1ciclos
	nop							;1ciclos
	nop							;1ciclos
	ret							;2ciclos
								;1994 + 6 = 2000

;*******************************************************************************
;Hex16ToASCII:
;converts a 16 bit binary number to a 
;string of ASCII characters.
;*******************************************************************************

;Input:
;R6--low byte of the 16BIT hext data
;R5--hi byte
;output:
;R4-- 1'S dec nuber of ACII
;R3-- 10'S dec number of ASCII 
;R2-- 100'S dec nuber of ASCII
;R1-- 1000'S dec number of ASCII
;R0-- 10000'S dec number of ASCII

;usage:
;clear R0,R1,R2,R3,R4
;mov R5,High BYTE of the data to be converted
;mov R6,Low byte of the data to be converted
;--------------------------------
Hex16ToASCII:
push PSW
push ACC

CLR C
MOV R0,#0 ;10,000 counter clear

Hex16ASCIILoop1: 
MOV A,R6 ;16bit hex data - 10,000 (2710H)
SUBB A,#10H
MOV R6,A ;save left value

MOV A,R5
SUBB A,#27H
MOV R5,A

JC Hex16AsciiComp1 
;if 16bit hex data< 10,000,jump to skip1

INC R0 ;else save 10,000s counter 
jmp Hex16ASCIILoop1 
;again:16bit hex data - 10,000 (2710H)

Hex16AsciiComp1: 
;here is the compensation at condition
;16bit hex data< 10,000
;because we have subtrate it with 10,000
;so add 10,000

;get the 1,000s',100s',10s',1s' value to R5R6
MOV A,R6
ADD A,#10H
MOV R6,A
MOV A,R5
ADDC A,#27H
MOV R5,A
CLR C 
;End of the compensation 
MOV R1,#0 ;1,000 counter clear

Hex16ASCIILoop2: 
;subtrate the left data by 1,000(3E8)
;repeatedly,until R5R6<1,000
MOV A,R6
subb A,#0E8H
mov R6,A

MOV A,R5
subb A,#03H
MOV R5,A

JC Hex16AsciiComp2 
;the left R5R6 <1,000,jump to compesation 2

INC R1 ;else save the 1,000 counter R1
jmp Hex16ASCIILoop2

Hex16AsciiComp2: 
;Compensate because subbtrate 1000 from R5R6
;at the condition R5R6<1000
MOV A,R6
ADD A,#0E8H
MOV R6,A

MOV A,R5
ADDC A,#03H
MOV R5,A
CLR C

MOV R2,#0 
;100S' counter clear 

Hex16AsciiLoop3: 
;the 100s' (64H)condition
mov A,R6
SUBB A,#64H
mov R6,A

MOV A,R5
subb A,#0
mov R5, A

JC Hex16AcsiiComp3
INC R2 
jmp Hex16AsciiLoop3
Hex16AcsiiComp3:
mov A,R6
ADD A,#64H
MOV R6,A
MOV A,R5
ADDC A,#0
MOV R5,A

CLR C
MOV R3,#0 
;10S' counter clear
Hex16AsciiLoop4: 
;10S' CONDITION, (R5 =0,so despite it)
mov A,R6
SUBB A,#0AH
MOV R6,A

JC Hex16AsciiComp4
INC R3 
jmp Hex16AsciiLoop4
Hex16AsciiComp4:

add A,#0AH
MOV R6,A 
;here R6 represent 1S'
mov R4,a 
;1S' counter ->R4

;NOW R4,R3,R2,R1,R0 all add 30H,to get real 
;ASCII code
clr c

mov A,R4
addc A,#30H
MOV R4,A

MOV A,R3
ADD A,#30H
MOV R3,A

MOV A,R2
ADD A,#30H
MOV R2,A

MOV A,R1
ADD A,#30H
MOV R1,A

MOV A,R0
ADD A,#30H
MOV R0,A
pop ACC
pop PSW
ret
;END OF CONVERATION ROUTINE.
;=========================================

END
	
	