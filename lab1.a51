;Placa P51USB v1.0
;Programa de teste
;------------------------------------------------------
;Chave SW1(P3.2) faz toogle do Led3(P1.4)

#include "at89c5131.h"

;DEFINICOES DA TABELAS ASCII
		LT_A EQU 65d
		LT_B EQU 66d
		LT_C EQU 67d
		LT_D EQU 68d
		LT_E EQU 69d
		LT_F EQU 70d
		LT_G EQU 71d
		LT_H EQU 72d
		LT_I EQU 73d
		LT_J EQU 74d
		LT_K EQU 75d
		LT_L EQU 76d
		LT_M EQU 77d
		LT_N EQU 78d
		LT_O EQU 79d
		LT_P EQU 80d
		LT_Q EQU 81d
		LT_R EQU 82d
		LT_S EQU 83d
		LT_T EQU 84d
		LT_U EQU 85d
		LT_V EQU 86d
		LT_W EQU 87d
		LT_X EQU 88d
		LT_Y EQU 89d
		LT_Z EQU 90d
		LT_0 EQU 48d
		LT_1 EQU 49d
		LT_2 EQU 50d
		LT_3 EQU 51d
		LT_4 EQU 52d
		LT_5 EQU 53d
		LT_6 EQU 54d
		LT_7 EQU 55d
		LT_8 EQU 56d
		LT_9 EQU 57d
		SPC  EQU 32d 

;DEFINICOES DE PORT
		ATT EQU P3.7
		SW1  EQU P3.5
		SW2  EQU P3.6
		SG1	 EQU P2.0
		SG2  EQU P2.1
		SR1  EQU P2.2
	    SR2  EQU P3.3
			
;DEFINICOES LCD
		LCD_RS EQU P2.5 ;RS = 0 INSTRUCAO, RS = 1 DADO
		LCD_RW EQU P2.6;RW = 0 LCD EM MODO ESCRITA, RW = 1 LCD EM MODO LEITURA
		LCD_EN  EQU P2.7;EN = 0 DESABILITADO, EN = 1 HABILITADO
		LCD_D  EQU P0;D = BARRAMENTO DE DADOS DO LCD
			
;DEFINICOES DE CONFIGURACAO
		bits8	EQU 38h; Use 2 lines and 5x7 matrix
		stdinit EQU 0Fh; LCD ON, cursor ON, blinking
		inccurs EQU 06h; Increment cursor
		cHOME   EQU 01h; Clear screen
		hab2l   EQU 3CH; activate second line	
		jmpl1 	EQU 80h;Jump to first line, position 1	
		jmpl2 	EQU 0C0h;Jump to second line, position 1
		shiftl  EQU 1Eh;shift the entire display to the left

;DEFINICOES DE CONSTANTES
		MAX_PECAS EQU 09h
		
;DEFINICOES DO DELAY
		num  EQU 	74d
		num2 EQU 	27d
		num3 EQU	20d

		ORG 0x2000
		LJMP main

command:CLR LCD_RS
		CLR LCD_RW
		SETB LCD_EN
		LCALL wait1ms ;HOLD TIME DANDO PROBLEMA?
		CLR LCD_EN
		LCALL wait1ms ;sometimes more than 1ms is needed
		RET
		
wr:		MOV LCD_D,#jmpl1
		LCALL command
		LCALL wait1ms
		
		MOV LCD_D,#LT_G
		LCALL DISP
		MOV LCD_D,#LT_R
		LCALL DISP
		MOV LCD_D,#LT_A
		LCALL DISP
		MOV LCD_D,#LT_N
		LCALL DISP
		MOV LCD_D,#LT_D
		LCALL DISP
		MOV LCD_D,#LT_E
		LCALL DISP
		MOV LCD_D,#LT_S
		LCALL DISP
		MOV LCD_D,#SPC
		LCALL DISP
		MOV A,R5
		ADD A,#30h
		MOV LCD_D,A
		LCALL DISP
		
		MOV LCD_D,#jmpl2
		LCALL command
		LCALL wait1ms
		
		MOV LCD_D,#LT_P
		LCALL DISP
		MOV LCD_D,#LT_E
		LCALL DISP
		MOV LCD_D,#LT_Q
		LCALL DISP
		MOV LCD_D,#LT_U
		LCALL DISP
		MOV LCD_D,#LT_E
		LCALL DISP
		MOV LCD_D,#LT_N
		LCALL DISP
		MOV LCD_D,#LT_A
		LCALL DISP
		MOV LCD_D,#LT_S
		LCALL DISP
		MOV LCD_D,#SPC
		LCALL DISP
		MOV A,R4
		ADD A,#30h
		MOV LCD_D,A
		LCALL DISP
		RET

DISP:	SETB LCD_RS
		CLR LCD_RW
		SETB LCD_EN
		LCALL wait1ms
		CLR LCD_EN
		;LCALL wait1ms
		RET
		
init:	MOV LCD_D,#bits8
		LCALL command
		LCALL wait1ms
		MOV LCD_D,#stdinit
		LCALL command
		LCALL wait1ms
		MOV LCD_D,#inccurs
		LCALL command
		MOV LCD_D,#cHOME
		LCALL command
		MOV LCD_D,#hab2l //Activate second line
		RET

clrSem:	SETB SG1
		SETB SG2
		SETB SR1
		SETB SR2
		RET

wait:	MOV R2,#num3
wait2:	LCALL wait1ms
		DJNZ R2,wait2
		RET
		
wait1ms:MOV R1,#num2
delay2: MOV R0,#num
delay:	NOP
		DJNZ R0,delay
		DJNZ R1,delay2
		RET

main:	MOV R4,#00h;inicializa contador pequenas
		MOV R5,#00h;inicializa contador grandes
		LCALL init
		LCALL wr

s0:		;DEBOUNCE
		LCALL wait
		;OPERACOES
		LCALL clrSem
		MOV A, R4
		JZ npeq
		JMP temPc
npeq:	MOV A,R5
		JZ ntemPc
		JMP temPc
ntemPc:	CLR SR2
		JMP psem
temPc:	CLR SG2
		JMP psem
		
psem:	CLR SG1
		;CHECA MUDAR ESTADO
		JB SW1, p12
		JB SW2, p21
		JMP s0
		
p12:	;DEBOUNCE
		LCALL wait
		;OPERACOES
		LCALL clrSem
		CLR SG1
		CLR SR2
		;CHECA MUDAR ESTADO
		JNB SW1, p12p 
		JB  SW2, p12g
		JMP p12

p12p:	;DEBOUNCE
		LCALL wait
		;OPERACOES
		LCALL clrSem
		CLR SG1
		CLR SR2
		;CHECA MUDAR ESTADO
		JB  SW2, w1
		JMP p12p
		
w1:		;DEBOUNCE
		LCALL wait
		;OPERACOES
		LCALL clrSem
		CLR SG1
		CLR SR2
		;CHECA MUDAR ESTADO
		JNB  SW2, cp12p
		JMP w1

p12g:	;DEBOUNCE
		LCALL wait
		;OPERACOES
		LCALL clrSem
		CLR SG1
		CLR SR2
		;CHECA MUDAR ESTADO
		JNB  SW2, cp12g
		JMP p12g

p21:	;DEBOUNCE
		LCALL wait
		;OPERACOES
		LCALL clrSem
		CLR SG2
		CLR SR1
		;CHECA MUDAR ESTADO
		JB SW1, p21g 
		JNB  SW2, p21p
		JMP p21
		
p21p:	;DEBOUNCE
		LCALL wait
		;OPERACOES
		LCALL clrSem
		CLR SG2
		CLR SR1
		;CHECA MUDAR ESTADO
		JB SW1, w2 
		JMP p21p

w2:		;DEBOUNCE
		LCALL wait
		;OPERACOES
		LCALL clrSem
		CLR SG2
		CLR SR1
		;CHECA MUDAR ESTADO
		JNB SW1, cp21p 
		JMP w2
		
p21g:	;DEBOUNCE
		LCALL wait
		;OPERACOES
		LCALL clrSem
		CLR SG2
		CLR SR1
		;CHECA MUDAR ESTADO
		JNB SW1, cp21g 
		JMP p21g

cp12p:	INC R4
		JMP attL
		
cp12g:	INC R5
		JMP attL

cp21p:	DEC R4
		JMP attL

cp21g:	DEC R5
		JMP attL
		
attL:	LCALL wr
		SETB ATT
		CJNE R4,#MAX_PECAS,okp
		CLR ATT
		JMP s0
okp:	CJNE R5,#MAX_PECAS, okg
		CLR ATT
okg:	JMP s0

END