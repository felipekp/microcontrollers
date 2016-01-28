TEMPO1			EQU 0x30
DELAY_MOTOR		EQU 0x31
DELAY_COUNTER	EQU 0x32

NUM_PASSOS		EQU 0x33
PASSO			EQU 0x34

RAMPA_FLAG		EQU 0x35 ; 1 -> SUBIDA 2 -> DESCIDA
RAMPA_SUBIDA	EQU 001h
RAMPA_DESCIDA	EQU	002h

INDICE_RAMPA	EQU 0x36

RAMPA_COUNTER	EQU 0x37
RAMPA_SIZE		EQU 060d

TMR0_AUX		EQU 0x38

DEBUG_AUX		EQU 0x39

PORTA_MOTOR		EQU P2

BOTAO1			EQU P3.2
BOTAO2			EQU P3.4

LED3 			EQU P1.4
LED_SENTIDO		EQU P1.5
LED_MODO_PASSO	EQU P1.3
LED_PASSO		EQU P1.2

ORG 0x0000
LJMP main

ORG 0x000B
clr EA ; disable Interrupts
ljmp int_tmr0

ORG 0x0003
clr EA ; disable Interrupts
LJMP int_ext0

ORG 0x0013
clr EA ; disable Interrupts
LJMP int_ext1

ORG 0x2000
int_ext1:
	push PSW
	push ACC

	lcall delay_1ms ;perigoso, debouncer!
	lcall delay_1ms ;perigoso, debouncer!
	lcall delay_1ms ;perigoso, debouncer!
	lcall delay_1ms ;perigoso, debouncer!

	mov PASSO, #000h	

	cpl LED_MODO_PASSO
	jb LED_MODO_PASSO, int_passo_completo
	;meio passo
	mov NUM_PASSOS, #8d
		
	ljmp fim_int_ext0
		
int_passo_completo:
	mov NUM_PASSOS, #4d
		
	ljmp fim_int_ext0
		
fim_int_ext1:
	pop ACC
	pop PSW
		
	SETB EA
		
	reti
		
int_ext0:
	push PSW
	push ACC
	
	lcall delay_1ms ;perigoso, debouncer!
	lcall delay_1ms ;perigoso, debouncer!
	lcall delay_1ms ;perigoso, debouncer!
	lcall delay_1ms ;perigoso, debouncer!
		
	mov A, RAMPA_FLAG
	anl A, #RAMPA_DESCIDA
	jnz int_horario_anthorario

	;LIGA A RAMPA
	setb ET0
	setb TR0		
	mov RAMPA_FLAG, #RAMPA_DESCIDA
		
	ljmp fim_int_ext0
		
		
int_horario_anthorario:
	mov RAMPA_FLAG, #RAMPA_SUBIDA
		
	ljmp fim_int_ext0
		
fim_int_ext0:
	pop ACC
	pop PSW
		
	SETB EA
		
	reti

int_tmr0:
	push ACC
	push PSW	

	mov A, RAMPA_FLAG
	anl A, #RAMPA_SUBIDA
	jnz subir_rampa

	mov A, RAMPA_FLAG
	anl A, #RAMPA_DESCIDA
	jnz descer_rampa

	ljmp exit_tmr0

subir_rampa:
	dec DELAY_MOTOR

	inc RAMPA_COUNTER
	clr C
	mov A, RAMPA_COUNTER
	subb A, #RAMPA_SIZE
	jnc rampa_maxima
	
	ljmp exit_tmr0

rampa_maxima:
; DESLIGA TIMER, NAO PRECISA MAIS RAMPA
	clr ET0 
	clr TR0
	ljmp exit_tmr0
	
descer_rampa:
	inc DELAY_MOTOR
	djnz RAMPA_COUNTER, exit_tmr0
	;muda a rampa
	mov RAMPA_FLAG, #RAMPA_SUBIDA
	;mov RAMPA_COUNTER, #RAMPA_SIZE
	cpl LED_SENTIDO
	ljmp exit_tmr0


exit_tmr0:
	pop PSW
	pop ACC

	setb EA
	reti

main:
	mov TL0, #000h
	mov TH0, #000h

	mov TMOD, #001h
	
	mov PASSO, #000h

	mov DELAY_MOTOR, #80d
	
	mov RAMPA_FLAG, #RAMPA_SUBIDA
	mov RAMPA_COUNTER, #000h
	mov NUM_PASSOS, #004h

	mov DEBUG_AUX, #30d

	;mov TMR0_AUX, #30d ; 1 PASSO POR SEGUNDO

	SETB EA ; Enable Interrupts
	SETB ET0 ; Enable Timer 0 Interrupt
	SETB TR0 ; Start Timer

	SETB EX0 ; Enable external interrupt 0
	SETB EX1 ; Enable external interrupt 1
	SETB IT0 ; External interrupt borda 0
	SETB IT1 ; External interrupt borda 1
	
loop:
	mov DELAY_COUNTER, DELAY_MOTOR
loop_delay_motor:
	lcall delay_1ms
	djnz DELAY_COUNTER, loop_delay_motor

	cpl LED_PASSO
	
	jb LED_MODO_PASSO, passo_completo 
	jnb LED_MODO_PASSO, meio_passo

meio_passo:
	mov DPTR, #TAB_MEIO_PASSO
	ljmp executa_passo

passo_completo:
	mov DPTR, #TAB_PASSO_COMPLETO
	ljmp executa_passo

executa_passo: ; tabela tem que estar no dptr
	mov A, PASSO
	movc A, @A + DPTR
	
	anl PORTA_MOTOR, #0F0h
	orl PORTA_MOTOR, A
	
	ljmp ajusta_passo

ajusta_passo:
	jb LED_SENTIDO, incrementa_passo
	jnb LED_SENTIDO, decrementa_passo
	
incrementa_passo:
	inc PASSO
	mov A, PASSO
	cjne A, NUM_PASSOS, ajusta_rampa
	; passo == num_passos
	mov PASSO, #000h
	ljmp ajusta_rampa	
	
decrementa_passo:
	clr C
	mov A, PASSO
	subb A, #1
	
	jnc	decrementa_passo_1
	; passo == 0 -> passo = num_passos - 1
	mov PASSO, NUM_PASSOS
decrementa_passo_1:
	dec PASSO
	ljmp ajusta_rampa

ajusta_rampa:
	ljmp loop	
	
espera_botao:
	lcall delay_1ms
	lcall delay_1ms
	lcall delay_1ms
	jnb BOTAO1, espera_botao
	jnb BOTAO2, espera_botao
	lcall delay_1ms
	lcall delay_1ms
	lcall delay_1ms
	ljmp loop
	

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
				 	;  	TH    TL 
	   TAB_TH_TMR0: DB 000h, 020h, 040h, 080h, 0A0h, 0C0h, 0E0h
					;	A	 B	  /A	/B
TAB_PASSO_COMPLETO: DB 001h, 002h, 004h, 008h
					;	A	  AB	B	  B/A	/A	 /A/B   /B  /BA
	TAB_MEIO_PASSO:	DB 001h, 003h, 002h, 006h, 004h, 00Ch, 008h, 009h
								
END