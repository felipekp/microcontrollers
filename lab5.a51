TEMPO1			EQU	0x30
FOO				EQU 0x31
SAMPLE0 		EQU 0x40

#include <at89c5131.h>

#define SPI_SS P1.1

#define SPIF 0x80 
#define SPEN 0x40 

;============================================================
; Definições de cada bit do byte de config do ADC
;============================================================
; Bit3 = start bit
#define START	0x08
; Bit2 = single/diff
#define SINGLE	0x04
; Bit1 = Signal
#define CH1p	0x02

;============================================================
; Conversões
;============================================================
; Single
#define CVT_CH0 (START | SINGLE)
#define CVT_CH1 (START | SINGLE | CH1p)
;============================================================
; Diferencial
#define CVT_DF1 (START | CH1p)
#define CVT_DF0 (START)
;============================================================
;============================================================
; Vetor de interrupções
;============================================================
	ORG 0x0000 ; reset
	LJMP main
	
	ORG 0x0023 ; serial placeholder
	RETI

	ORG	0x004B ; SPI placeholder
	RETI	 ; não iremos utilizar a int da SPI
;============================================================
; Programa
;============================================================
	ORG 0x207B ; após o intvec, começa o progama
main:
	;config serial
	mov TMOD, #00100000b
	mov TH1, #0F3h;#0F3h
	mov TCON, #01000000b
	mov PCON, #10000000b
	mov SCON, #01000000b
	
	;config spi
	;MOV SPCON, #10110010b
		; SPR = 110, fclk_periph/128
	MOV SPCON, #10111110b 
			;	||||||||__ 	SPR0
			;	|||||||___	SPR1
			;	||||||____	Phase 1
			;	|||||_____	Polarity 1
			;	||||______	Master
			;	|||_______	¬SPI_SS
			;	||________	SPEN (disabled at configuring)
			;	|_________	SPR2
	
	; liga o SPI
	MOV A, SPCON
	ORL A, #SPEN
	MOV SPCON, A
	
	mov IEN0, #00h

	clr TI
	clr RI

loop:
;	INC A
	LCALL ADC_SAMPLE
	LCALL escreve

;	MOV A, #CVT_CH1
	ljmp loop

escreve:
	MOV SBUF, A
	JNB TI, $
	CLR TI
	ret

;============================================================
; Nome: ADC_SAMPLE
; Descrição: amostra o ADC utilizando a SPI
; Parâmetros:
; Retorna: SAMPLE0, SAMPLE1, SAMPLE2
; Destrói: A
;============================================================
ADC_SAMPLE:

	CLR SPI_SS;	habilita o ADC

	MOV A, #CVT_CH0

	; carrega o buffer de saída com o primeiro byte.
	MOV SPDAT, A
	LCALL Tx	; aguarda concluir a operação
	
	MOV A, SPDAT ;MOV SAMPLE2, SPDAT
	;MOV R0, A
	; recarrego com DUMMY (tanto faz o valor)
	MOV SPDAT, #0AAh;#DUMMY
	LCALL Tx

	MOV A, SPDAT ;MOV SAMPLE1, SPDAT

	; recarrego com DUMMY (tanto faz o valor)
	;MOV SPDAT, #0AAh;#DUMMY
	;LCALL Tx

	;MOV A, SPDAT ;MOV SAMPLE0, SPDAT ; lê para liberar o SPI

;	MOV DPTR, #TABELA_ENDIANNESS
;	MOVC A, @A + DPTR
;
;	MOV R0, SPDAT ; lê para liberar o SPI

	SETB SPI_SS; desabilita o ADC

	RET
;Tx_1:
;	nop
Tx:
	MOV A, SPSTA
	ANL A, #SPIF ; isola o bit.
	JZ	Tx
	RET

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

END