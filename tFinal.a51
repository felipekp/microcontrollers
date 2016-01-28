;============================================================
; Variáveis
;============================================================
TEMPO1				EQU	0x30
	
SAMPLE_CH0 			EQU 0x40
PICO_CH0			EQU 0x41
FLAG_HIT_CH0    	EQU 0x42
SAMPLE_COUNTER_CH0	EQU 0x43
INDEX_TABLE_CH0_L	EQU 0x44
INDEX_TABLE_CH0_H	EQU 0x45
INTENSITY_CH0		EQU 0x46
;TABLE_CH0_L			EQU 0x47
;TABLE_CH0_H			EQU 0x48
SOUND_CH0			EQU 0x49

SAMPLE_CH1	 		EQU 0x50
PICO_CH1			EQU 0x51
FLAG_HIT_CH1    	EQU 0x52
SAMPLE_COUNTER_CH1	EQU 0x53
INDEX_TABLE_CH1_L	EQU 0x54
INDEX_TABLE_CH1_H	EQU 0x55
INTENSITY_CH1		EQU 0x56
;TABLE_CH1_L			EQU 0x57
;TABLE_CH1_H			EQU 0x58
SOUND_CH1			EQU 0x59

;============================================================
; Definições
;============================================================
SAMPLE_TRESHOLD 		EQU 30d
HARD_HIT_TRESHOLD		EQU 100d

SOUND_PORT				EQU	P2

TABLE_CRASH_SIZE_L		EQU 0x30
TABLE_CRASH_SIZE_H		EQU 0x11

TABLE_PERC2_SIZE_L		EQU 0x16
TABLE_PERC2_SIZE_H		EQU 0x0F

NUM_SAMPLES_TRESHOLD	EQU 200d

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
	ORG 0x2000 ; reset
	LJMP main
	
	ORG 0x2023 ; serial placeholder
	RETI

	ORG 0x200B
	CLR EA ; disable Interrupts
	LJMP int_tmr0

	;ORG	0x004B ; SPI placeholder
	;RETI	 ; não iremos utilizar a int da SPI
;============================================================
; Programa
;============================================================
	ORG 0x207B ; após o intvec, começa o progama
int_tmr0:
	PUSH Acc
	PUSH PSW	

	;jmp seta_som_CH0
	
seta_som_CH0:
	
	MOV A, INTENSITY_CH0
	JZ seta_som_CH1

	INC INDEX_TABLE_CH0_L
	MOV A, INDEX_TABLE_CH0_L
	JNZ verifica_limite_index_CH0

	INC INDEX_TABLE_CH0_H

verifica_limite_index_CH0:
	MOV A, INDEX_TABLE_CH0_L
	CLR C
	SUBB A, #TABLE_CRASH_SIZE_L
	JC seta_som_na_var_CH0

	MOV A, INDEX_TABLE_CH0_H
	SUBB A, #TABLE_CRASH_SIZE_H
	JC seta_som_na_var_CH0

	MOV INDEX_TABLE_CH0_H, #00h
	MOV INDEX_TABLE_CH0_L, #00h
	MOV INTENSITY_CH0, #00h
	MOV SOUND_CH0, #00h
	JMP seta_som_CH1

seta_som_na_var_CH0:

	MOV DPTR, #TABLE_CRASH
	CLR C
	MOV A, DPL
	ADD A, INDEX_TABLE_CH0_L
	MOV DPL, A
	MOV A, DPH
	ADDC A, INDEX_TABLE_CH0_H
	MOV DPH, A
	
	CLR C
	MOV A, INTENSITY_CH0
	subb A, #HARD_HIT_TRESHOLD
	jc seta_som_na_var_CH0_1
	
	MOV A, #00h
	MOVC A, @A + DPTR
	MOV SOUND_CH0, A
	
	jmp seta_som_CH1

seta_som_na_var_CH0_1:
	MOV A, #00h
	MOVC A, @A + DPTR
	
	CLR C
	RRC A ; divide por 2

	MOV SOUND_CH0, A
	;ljmp seta_som_CH1
	
seta_som_CH1:
	MOV A, INTENSITY_CH1
	JZ toca_som_final

	INC INDEX_TABLE_CH1_L
	MOV A, INDEX_TABLE_CH1_L
	JNZ verifica_limite_index_CH1

	INC INDEX_TABLE_CH1_H

verifica_limite_index_CH1:
	MOV A, INDEX_TABLE_CH1_L
	CLR C
	SUBB A, #TABLE_PERC2_SIZE_L
	JC seta_som_na_var_CH1

	MOV A, INDEX_TABLE_CH1_H
	SUBB A, #TABLE_PERC2_SIZE_H
	JC seta_som_na_var_CH1

	MOV INDEX_TABLE_CH0_H, #00h
	MOV INDEX_TABLE_CH0_L, #00h
	MOV INTENSITY_CH1, #00h
	MOV SOUND_CH1, #00h
	JMP toca_som_final

seta_som_na_var_CH1:
	MOV DPTR, #TABLE_PERC2
	CLR C
	MOV A, DPL
	ADD A, INDEX_TABLE_CH1_L
	MOV DPL, A
	MOV A, DPH
	ADDC A, INDEX_TABLE_CH1_H
	MOV DPH, A
	
	CLR C
	MOV A, INTENSITY_CH1
	subb A, #HARD_HIT_TRESHOLD
	jc seta_som_na_var_CH1_1
	
	MOV A, #00h
	MOVC A, @A + DPTR
	MOV SOUND_CH1, A
	
	ljmp toca_som_final

seta_som_na_var_CH1_1:
	MOV A, #00h
	MOVC A, @A + DPTR
	
	CLR C
	RRC A ; divide por 2

	MOV SOUND_CH1, A
	
	ljmp toca_som_final
	
toca_som_final:
	;toca o som final .. fazer a parte da soma e jogar no sound_port
	MOV A, SOUND_CH0
	CLR C
	RRC A
	MOV SOUND_CH0, A
	
	CLR C
	MOV A, SOUND_CH1
	RRC A

	ADD A, SOUND_CH0

	MOV SOUND_PORT, A

exit_tmr0:
	SETB EA

	POP PSW
	POP Acc
	
	RETI
		
main:
	;config serial
	MOV TMOD, #00000010b
	
	MOV TH0, #0A5h ; 22khz
	
	;config spi
	;MOV SPCON, #10110010b
		; SPR = 010, fclk_periph/8
	MOV SPCON, #00111110b 
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
	
	MOV SAMPLE_CH0, #00h
	MOV PICO_CH0, #00h
	MOV SAMPLE_COUNTER_CH0, #00h
	MOV FLAG_HIT_CH0, #00h
	MOV INDEX_TABLE_CH0_L, #00h	
	MOV INDEX_TABLE_CH0_H, #00h	
	MOV INTENSITY_CH0, #00h
	
	MOV SAMPLE_CH1, #00h
	MOV PICO_CH1, #00h
	MOV SAMPLE_COUNTER_CH1, #00h
	MOV FLAG_HIT_CH1, #00h
	MOV INDEX_TABLE_CH1_L, #00h	
	MOV INDEX_TABLE_CH1_H, #00h	
	
	SETB ES ; SERIAL INTERRUPT - DEBUGGER
	SETB ET0 ; TIMER 0 INTERRUPT
	SETB TR0 ; Start Timer
	SETB EA 

	MOV DPTR, #TABLE_CRASH

	;CLR TI
	;CLR RI

loop:
	MOV A, #CVT_CH0
	LCALL ADC_SAMPLE
	MOV SAMPLE_CH0, A
	
	MOV A, FLAG_HIT_CH0
	JZ ler_CH1
	
	INC SAMPLE_COUNTER_CH0
	MOV A, SAMPLE_COUNTER_CH0 
	CJNE A, #NUM_SAMPLES_TRESHOLD, ler_CH1 ; se for 255 continua aqui na sequencia
	
reseta_CH0:
	MOV SAMPLE_COUNTER_CH0, #00h
	MOV FLAG_HIT_CH0, #00h
	MOV INTENSITY_CH0, PICO_CH0
	MOV INDEX_TABLE_CH0_L, #00h
	MOV INDEX_TABLE_CH0_H, #00h
	MOV PICO_CH0, #00h
	
ler_CH1:
	MOV A, #CVT_CH1
	LCALL ADC_SAMPLE
	MOV SAMPLE_CH1, A
	
	MOV A, FLAG_HIT_CH1
	JZ detecta_picos
	
	INC SAMPLE_COUNTER_CH1
	MOV A, SAMPLE_COUNTER_CH1
	CJNE A, #NUM_SAMPLES_TRESHOLD, detecta_picos ; se for 255 continua aqui na sequencia
	
reseta_CH1:
	MOV SAMPLE_COUNTER_CH1, #00h
	MOV FLAG_HIT_CH1, #00h
	MOV INTENSITY_CH1, PICO_CH1
	MOV INDEX_TABLE_CH1_L, #00h
	MOV INDEX_TABLE_CH1_H, #00h
	MOV PICO_CH1, #00h
	; indica final de batida.. tocar som

detecta_picos:
	LCALL detecta_pico_SAMPLE_CH0
	LCALL detecta_pico_SAMPLE_CH1
	LJMP loop

; pega pico canal 2
detecta_pico_SAMPLE_CH0:
	CLR C
	MOV A, SAMPLE_CH0
	SUBB A, #SAMPLE_TRESHOLD
	;if carry setado A e menor
	JNC pega_pico_CH0
; se ja estava no threshold zera o pico
; se nao estava so RETorna
	RET
	
pega_pico_CH0:
; seta flag que tem sinal
	MOV FLAG_HIT_CH0, #0FFh
	CLR C
	MOV A, PICO_CH0
	SUBB A, SAMPLE_CH0
	JC pega_pico_CH0_1
	RET
	
pega_pico_CH0_1:
	MOV PICO_CH0, SAMPLE_CH0
	RET
	
; pega pico canal 1
detecta_pico_SAMPLE_CH1:
	CLR C
	MOV A, SAMPLE_CH1
	SUBB A, #SAMPLE_TRESHOLD
	;if carry setado A e menor
	JNC pega_pico_CH1
	RET
	
pega_pico_CH1:
	MOV FLAG_HIT_CH1, #0FFh
	CLR C
	MOV A, PICO_CH1
	SUBB A, SAMPLE_CH1
	JC pega_pico_CH1_1
	RET
	
pega_pico_CH1_1:
	MOV PICO_CH1, SAMPLE_CH1
	RET

;============================================================
; Nome: ADC_SAMPLE
; Descrição: amostra o ADC utilizando a SPI
; Parâmetros:
; Retorna: SAMPLE0, SAMPLE1, SAMPLE2
; Destrói: A
;============================================================
ADC_SAMPLE:
	CLR SPI_SS;	habilita o ADC

	MOV SPDAT, A
	LCALL Tx
	
	MOV A, SPDAT
	MOV SPDAT, #0AAh
	LCALL Tx

	MOV A, SPDAT
	
	SETB SPI_SS

	RET
Tx:
	MOV A, SPSTA
	ANL A, #SPIF
	JZ	Tx
	RET

;******************************
;	24Mhz -> 0.5uS por ciclo
;   1ms -> 2000 ciclos
delay_1ms: 
	MOV TEMPO1, #249d 			;2ciclos
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
	RET							;2ciclos
								;1994 + 6 = 2000
								
; TAMANHO : 4400
TABLE_CRASH:
DB 0d, 0d, 0d, 0d, 1d, 1d, 1d, 2d, 2d, 2d, 2d, 3d, 3d, 3d, 4d, 4d, 4d, 5d, 6d, 6d, 6d, 6d, 6d, 6d, 6d, 7d, 7d, 7d, 8d, 7d
DB 7d, 8d, 8d, 10d, 10d, 10d, 10d, 10d, 9d, 11d, 13d, 10d, 10d, 12d, 12d, 12d, 10d, 11d, 17d, 15d, 11d, 18d, 17d, 11d, 16d, 18d, 16d, 17d, 17d, 15d
DB 13d, 14d, 13d, 17d, 17d, 15d, 21d, 19d, 19d, 21d, 21d, 22d, 19d, 20d, 22d, 23d, 21d, 17d, 23d, 24d, 22d, 27d, 23d, 21d, 21d, 21d, 25d, 25d, 24d, 25d
DB 22d, 25d, 29d, 28d, 27d, 26d, 28d, 31d, 27d, 26d, 27d, 30d, 33d, 31d, 33d, 31d, 25d, 34d, 33d, 26d, 31d, 35d, 39d, 33d, 26d, 31d, 34d, 36d, 33d, 28d
DB 31d, 36d, 39d, 31d, 31d, 40d, 37d, 40d, 45d, 34d, 36d, 45d, 33d, 28d, 39d, 47d, 44d, 32d, 27d, 37d, 50d, 44d, 40d, 42d, 37d, 46d, 41d, 31d, 40d, 36d
DB 45d, 41d, 25d, 46d, 56d, 46d, 42d, 45d, 56d, 53d, 49d, 47d, 37d, 39d, 46d, 52d, 54d, 49d, 51d, 49d, 49d, 47d, 48d, 57d, 52d, 44d, 49d, 53d, 44d, 42d
DB 48d, 44d, 52d, 60d, 51d, 53d, 59d, 57d, 57d, 60d, 66d, 59d, 44d, 47d, 53d, 49d, 56d, 55d, 52d, 64d, 73d, 63d, 45d, 46d, 55d, 62d, 51d, 51d, 75d, 67d
DB 57d, 59d, 59d, 64d, 63d, 67d, 55d, 58d, 83d, 73d, 58d, 58d, 62d, 53d, 63d, 85d, 61d, 54d, 63d, 71d, 94d, 67d, 57d, 78d, 64d, 56d, 54d, 57d, 75d, 73d
DB 45d, 58d, 94d, 74d, 77d, 92d, 68d, 79d, 83d, 73d, 94d, 71d, 42d, 76d, 70d, 49d, 84d, 63d, 41d, 68d, 56d, 88d, 104d, 46d, 70d, 113d, 67d, 47d, 100d, 92d
DB 65d, 84d, 75d, 91d, 84d, 52d, 78d, 61d, 79d, 114d, 66d, 67d, 94d, 77d, 72d, 87d, 88d, 108d, 108d, 59d, 79d, 113d, 92d, 97d, 88d, 55d, 61d, 78d, 81d, 86d
DB 72d, 74d, 115d, 90d, 68d, 102d, 70d, 78d, 130d, 92d, 69d, 94d, 111d, 98d, 64d, 88d, 113d, 99d, 103d, 94d, 81d, 74d, 93d, 97d, 83d, 127d, 105d, 57d, 89d, 101d
DB 107d, 90d, 72d, 102d, 106d, 82d, 95d, 118d, 64d, 60d, 133d, 101d, 70d, 107d, 108d, 101d, 105d, 115d, 119d, 102d, 111d, 115d, 81d, 77d, 93d, 117d, 120d, 99d, 115d, 82d
DB 91d, 137d, 80d, 94d, 134d, 111d, 110d, 101d, 121d, 127d, 109d, 102d, 111d, 135d, 94d, 71d, 92d, 101d, 141d, 112d, 57d, 90d, 111d, 131d, 123d, 80d, 132d, 131d, 87d, 138d
DB 120d, 79d, 114d, 135d, 141d, 108d, 73d, 104d, 136d, 122d, 111d, 123d, 121d, 102d, 123d, 121d, 74d, 109d, 147d, 128d, 124d, 119d, 113d, 115d, 94d, 87d, 136d, 128d, 114d, 139d
DB 93d, 107d, 135d, 105d, 136d, 134d, 140d, 123d, 84d, 178d, 172d, 97d, 132d, 143d, 128d, 117d, 104d, 107d, 116d, 120d, 120d, 122d, 120d, 142d, 131d, 83d, 117d, 149d, 170d, 144d
DB 110d, 167d, 107d, 91d, 170d, 127d, 130d, 138d, 126d, 124d, 98d, 154d, 155d, 107d, 97d, 98d, 157d, 135d, 81d, 101d, 107d, 153d, 181d, 115d, 78d, 126d, 172d, 147d, 107d, 92d
DB 129d, 163d, 122d, 114d, 109d, 101d, 165d, 142d, 82d, 127d, 171d, 181d, 116d, 75d, 146d, 165d, 126d, 116d, 127d, 120d, 147d, 181d, 106d, 89d, 152d, 133d, 117d, 107d, 102d, 164d
DB 129d, 62d, 117d, 114d, 126d, 156d, 84d, 100d, 162d, 168d, 155d, 120d, 120d, 139d, 159d, 144d, 113d, 116d, 108d, 121d, 142d, 132d, 122d, 109d, 110d, 138d, 118d, 91d, 152d, 151d
DB 97d, 107d, 99d, 134d, 155d, 90d, 135d, 165d, 103d, 116d, 147d, 152d, 121d, 111d, 144d, 121d, 120d, 141d, 122d, 91d, 111d, 171d, 158d, 140d, 112d, 111d, 156d, 116d, 133d, 139d
DB 92d, 137d, 146d, 112d, 101d, 139d, 168d, 121d, 121d, 125d, 114d, 151d, 96d, 58d, 124d, 131d, 154d, 146d, 66d, 108d, 178d, 139d, 76d, 104d, 180d, 140d, 117d, 146d, 110d, 145d
DB 194d, 125d, 69d, 130d, 172d, 117d, 114d, 121d, 112d, 155d, 144d, 115d, 91d, 84d, 178d, 177d, 83d, 112d, 151d, 121d, 129d, 139d, 110d, 111d, 119d, 120d, 154d, 130d, 91d, 155d
DB 165d, 126d, 125d, 125d, 144d, 130d, 122d, 120d, 102d, 160d, 154d, 82d, 108d, 121d, 82d, 124d, 175d, 116d, 83d, 164d, 164d, 96d, 148d, 149d, 96d, 144d, 114d, 104d, 187d, 143d
DB 101d, 139d, 117d, 132d, 171d, 114d, 86d, 99d, 128d, 160d, 119d, 131d, 115d, 99d, 167d, 106d, 88d, 141d, 134d, 161d, 108d, 80d, 188d, 175d, 106d, 123d, 116d, 125d, 142d, 137d
DB 141d, 103d, 132d, 151d, 112d, 148d, 87d, 83d, 167d, 95d, 114d, 151d, 87d, 109d, 135d, 142d, 117d, 95d, 141d, 141d, 141d, 157d, 123d, 106d, 147d, 149d, 120d, 145d, 118d, 121d
DB 153d, 95d, 134d, 163d, 108d, 113d, 103d, 120d, 139d, 106d, 115d, 108d, 97d, 146d, 152d, 126d, 137d, 128d, 130d, 151d, 126d, 136d, 175d, 135d, 66d, 100d, 164d, 142d, 132d, 88d
DB 88d, 186d, 109d, 80d, 184d, 130d, 97d, 135d, 99d, 104d, 166d, 134d, 78d, 123d, 130d, 121d, 174d, 143d, 105d, 170d, 134d, 80d, 168d, 150d, 97d, 134d, 106d, 118d, 176d, 133d
DB 93d, 92d, 105d, 155d, 142d, 135d, 137d, 73d, 120d, 145d, 102d, 151d, 142d, 103d, 125d, 124d, 124d, 175d, 158d, 112d, 126d, 104d, 120d, 159d, 124d, 105d, 133d, 138d, 117d, 122d
DB 142d, 152d, 111d, 76d, 118d, 191d, 184d, 98d, 109d, 127d, 90d, 114d, 150d, 135d, 79d, 115d, 146d, 116d, 160d, 132d, 121d, 149d, 67d, 110d, 197d, 126d, 94d, 124d, 129d, 136d
DB 119d, 130d, 136d, 140d, 140d, 69d, 132d, 204d, 119d, 128d, 145d, 61d, 93d, 207d, 126d, 35d, 118d, 143d, 137d, 149d, 121d, 120d, 161d, 147d, 84d, 128d, 150d, 122d, 159d, 61d
DB 34d, 223d, 191d, 84d, 132d, 112d, 128d, 169d, 117d, 136d, 178d, 124d, 91d, 124d, 94d, 101d, 171d, 120d, 93d, 135d, 153d, 175d, 138d, 84d, 92d, 148d, 134d, 64d, 110d, 154d
DB 126d, 101d, 137d, 176d, 134d, 133d, 135d, 125d, 137d, 115d, 152d, 172d, 127d, 115d, 115d, 127d, 100d, 94d, 152d, 120d, 108d, 153d, 126d, 126d, 127d, 96d, 150d, 172d, 99d, 130d
DB 174d, 126d, 146d, 144d, 106d, 139d, 156d, 142d, 87d, 69d, 95d, 101d, 157d, 144d, 87d, 131d, 126d, 94d, 158d, 164d, 123d, 157d, 170d, 128d, 114d, 152d, 137d, 100d, 121d, 103d
DB 104d, 140d, 125d, 122d, 142d, 88d, 82d, 212d, 157d, 38d, 139d, 140d, 81d, 158d, 158d, 131d, 139d, 84d, 99d, 164d, 149d, 134d, 155d, 133d, 95d, 139d, 153d, 113d, 93d, 91d
DB 162d, 169d, 118d, 112d, 104d, 139d, 129d, 124d, 159d, 124d, 119d, 120d, 86d, 93d, 146d, 164d, 132d, 123d, 91d, 101d, 185d, 164d, 85d, 103d, 132d, 129d, 145d, 112d, 86d, 133d
DB 120d, 107d, 172d, 117d, 71d, 179d, 146d, 87d, 180d, 161d, 102d, 130d, 109d, 120d, 135d, 122d, 169d, 116d, 92d, 162d, 123d, 130d, 112d, 64d, 163d, 142d, 71d, 145d, 133d, 88d
DB 136d, 164d, 150d, 122d, 136d, 134d, 107d, 154d, 156d, 161d, 170d, 67d, 97d, 178d, 101d, 79d, 123d, 115d, 93d, 106d, 152d, 150d, 109d, 87d, 120d, 149d, 113d, 123d, 127d, 110d
DB 146d, 167d, 165d, 127d, 129d, 153d, 103d, 94d, 144d, 179d, 159d, 104d, 79d, 104d, 168d, 153d, 92d, 73d, 73d, 146d, 181d, 127d, 121d, 116d, 118d, 137d, 138d, 145d, 109d, 108d
DB 135d, 117d, 151d, 170d, 140d, 108d, 86d, 120d, 166d, 149d, 124d, 136d, 91d, 102d, 208d, 128d, 52d, 148d, 141d, 98d, 114d, 124d, 152d, 140d, 92d, 84d, 149d, 156d, 90d, 132d
DB 127d, 89d, 169d, 187d, 125d, 77d, 132d, 176d, 107d, 132d, 151d, 115d, 122d, 106d, 117d, 141d, 120d, 81d, 115d, 142d, 91d, 123d, 145d, 136d, 144d, 116d, 149d, 142d, 131d, 155d
DB 126d, 146d, 140d, 130d, 163d, 132d, 111d, 118d, 143d, 141d, 82d, 82d, 111d, 114d, 127d, 116d, 98d, 118d, 137d, 136d, 109d, 90d, 135d, 168d, 146d, 132d, 136d, 133d, 146d, 143d
DB 108d, 143d, 149d, 110d, 145d, 121d, 106d, 148d, 127d, 111d, 134d, 132d, 100d, 144d, 148d, 55d, 119d, 164d, 93d, 139d, 148d, 99d, 120d, 154d, 146d, 108d, 145d, 167d, 145d, 148d
DB 91d, 116d, 197d, 126d, 64d, 141d, 161d, 104d, 149d, 129d, 54d, 119d, 160d, 132d, 97d, 73d, 138d, 174d, 137d, 119d, 144d, 173d, 94d, 84d, 169d, 119d, 103d, 148d, 148d, 108d
DB 77d, 149d, 136d, 84d, 114d, 135d, 138d, 121d, 143d, 114d, 79d, 139d, 136d, 146d, 166d, 130d, 120d, 119d, 143d, 154d, 139d, 132d, 104d, 111d, 140d, 117d, 128d, 137d, 104d, 121d
DB 137d, 116d, 100d, 122d, 128d, 96d, 125d, 153d, 144d, 146d, 120d, 92d, 114d, 169d, 145d, 94d, 138d, 137d, 77d, 118d, 182d, 143d, 123d, 122d, 80d, 137d, 185d, 114d, 106d, 122d
DB 103d, 152d, 165d, 106d, 87d, 107d, 115d, 127d, 146d, 108d, 129d, 177d, 118d, 130d, 166d, 135d, 132d, 124d, 134d, 128d, 116d, 157d, 157d, 106d, 65d, 108d, 160d, 123d, 104d, 99d
DB 120d, 140d, 114d, 155d, 144d, 79d, 119d, 158d, 158d, 148d, 122d, 112d, 125d, 154d, 161d, 135d, 95d, 102d, 116d, 113d, 152d, 128d, 108d, 154d, 107d, 95d, 148d, 134d, 132d, 151d
DB 129d, 119d, 136d, 129d, 114d, 133d, 128d, 97d, 126d, 164d, 131d, 121d, 135d, 107d, 118d, 167d, 155d, 103d, 89d, 112d, 138d, 126d, 109d, 124d, 106d, 124d, 152d, 130d, 125d, 98d
DB 118d, 178d, 133d, 96d, 150d, 165d, 131d, 125d, 113d, 117d, 155d, 126d, 106d, 142d, 112d, 104d, 132d, 116d, 105d, 109d, 120d, 110d, 123d, 156d, 140d, 127d, 140d, 157d, 157d, 138d
DB 111d, 119d, 161d, 135d, 96d, 111d, 140d, 127d, 107d, 113d, 102d, 127d, 153d, 138d, 114d, 113d, 143d, 138d, 122d, 114d, 137d, 148d, 87d, 107d, 157d, 134d, 123d, 93d, 116d, 186d
DB 137d, 117d, 138d, 84d, 130d, 167d, 109d, 131d, 122d, 103d, 165d, 129d, 80d, 127d, 154d, 144d, 100d, 93d, 154d, 157d, 135d, 129d, 94d, 115d, 170d, 149d, 129d, 125d, 102d, 145d
DB 174d, 111d, 91d, 135d, 134d, 82d, 116d, 163d, 109d, 122d, 143d, 120d, 150d, 145d, 117d, 139d, 139d, 128d, 143d, 117d, 105d, 132d, 96d, 94d, 132d, 132d, 146d, 123d, 105d, 119d
DB 97d, 140d, 174d, 115d, 135d, 125d, 94d, 156d, 146d, 121d, 126d, 124d, 164d, 166d, 118d, 108d, 136d, 122d, 106d, 127d, 133d, 115d, 92d, 122d, 149d, 139d, 125d, 110d, 126d, 142d
DB 128d, 103d, 118d, 148d, 144d, 120d, 86d, 114d, 144d, 122d, 129d, 130d, 131d, 147d, 133d, 128d, 118d, 105d, 129d, 141d, 147d, 122d, 81d, 128d, 152d, 112d, 131d, 142d, 111d, 118d
DB 140d, 124d, 106d, 117d, 129d, 124d, 113d, 134d, 156d, 141d, 105d, 116d, 176d, 157d, 113d, 124d, 121d, 134d, 140d, 118d, 128d, 129d, 133d, 123d, 100d, 133d, 130d, 127d, 146d, 97d
DB 98d, 147d, 151d, 132d, 107d, 109d, 138d, 157d, 141d, 109d, 120d, 138d, 130d, 146d, 139d, 89d, 104d, 131d, 118d, 117d, 116d, 130d, 137d, 109d, 117d, 147d, 150d, 133d, 120d, 135d
DB 126d, 113d, 147d, 153d, 110d, 112d, 128d, 109d, 128d, 128d, 113d, 144d, 118d, 113d, 162d, 127d, 104d, 124d, 115d, 133d, 145d, 137d, 134d, 116d, 119d, 135d, 139d, 139d, 135d, 132d
DB 115d, 113d, 137d, 125d, 106d, 136d, 142d, 107d, 111d, 129d, 131d, 137d, 126d, 123d, 137d, 122d, 123d, 146d, 135d, 107d, 106d, 142d, 146d, 116d, 114d, 115d, 122d, 142d, 133d, 124d
DB 127d, 118d, 124d, 127d, 123d, 123d, 130d, 155d, 133d, 99d, 122d, 137d, 142d, 141d, 114d, 113d, 140d, 140d, 125d, 132d, 124d, 111d, 134d, 149d, 122d, 109d, 128d, 137d, 136d, 117d
DB 118d, 153d, 137d, 100d, 106d, 123d, 139d, 131d, 123d, 130d, 115d, 119d, 134d, 126d, 132d, 142d, 139d, 115d, 105d, 139d, 146d, 123d, 124d, 136d, 124d, 111d, 140d, 139d, 102d, 121d
DB 141d, 141d, 144d, 114d, 112d, 127d, 112d, 127d, 150d, 138d, 116d, 124d, 138d, 111d, 116d, 149d, 138d, 119d, 117d, 117d, 124d, 139d, 139d, 124d, 120d, 128d, 133d, 124d, 131d, 122d
DB 97d, 132d, 158d, 142d, 123d, 101d, 108d, 131d, 127d, 123d, 145d, 145d, 123d, 120d, 129d, 134d, 127d, 132d, 136d, 122d, 124d, 119d, 120d, 128d, 111d, 120d, 143d, 131d, 127d, 122d
DB 110d, 120d, 126d, 140d, 147d, 132d, 132d, 120d, 125d, 126d, 117d, 147d, 138d, 130d, 131d, 100d, 125d, 142d, 121d, 120d, 116d, 136d, 126d, 96d, 120d, 128d, 126d, 139d, 129d, 127d
DB 122d, 113d, 135d, 132d, 103d, 134d, 165d, 127d, 110d, 124d, 138d, 144d, 121d, 123d, 130d, 129d, 141d, 127d, 110d, 114d, 123d, 124d, 129d, 122d, 110d, 128d, 131d, 131d, 131d, 135d
DB 154d, 133d, 119d, 125d, 126d, 142d, 128d, 124d, 133d, 119d, 133d, 129d, 114d, 125d, 108d, 121d, 151d, 129d, 130d, 131d, 115d, 118d, 110d, 137d, 156d, 111d, 101d, 129d, 141d, 132d
DB 117d, 132d, 128d, 110d, 132d, 145d, 130d, 118d, 125d, 140d, 133d, 126d, 134d, 132d, 116d, 116d, 123d, 121d, 132d, 146d, 129d, 96d, 117d, 155d, 118d, 110d, 151d, 129d, 107d, 141d
DB 147d, 128d, 125d, 120d, 132d, 124d, 112d, 148d, 148d, 104d, 98d, 130d, 152d, 129d, 105d, 119d, 118d, 107d, 128d, 146d, 126d, 113d, 134d, 138d, 125d, 122d, 129d, 145d, 136d, 122d
DB 130d, 136d, 145d, 130d, 110d, 123d, 129d, 134d, 131d, 121d, 117d, 105d, 118d, 134d, 136d, 144d, 115d, 105d, 132d, 122d, 118d, 125d, 137d, 145d, 116d, 120d, 132d, 120d, 129d, 140d
DB 142d, 132d, 128d, 145d, 133d, 110d, 115d, 134d, 147d, 133d, 113d, 120d, 122d, 125d, 137d, 119d, 109d, 131d, 138d, 120d, 107d, 123d, 131d, 120d, 136d, 146d, 119d, 113d, 136d, 128d
DB 109d, 133d, 154d, 123d, 106d, 127d, 138d, 133d, 117d, 123d, 135d, 127d, 137d, 146d, 126d, 101d, 120d, 152d, 137d, 122d, 134d, 127d, 111d, 119d, 132d, 135d, 135d, 138d, 131d, 105d
DB 110d, 141d, 137d, 119d, 114d, 127d, 130d, 118d, 126d, 136d, 119d, 101d, 134d, 155d, 138d, 131d, 117d, 115d, 130d, 144d, 154d, 135d, 111d, 112d, 128d, 138d, 137d, 126d, 117d, 121d
DB 124d, 128d, 127d, 116d, 122d, 131d, 119d, 114d, 129d, 146d, 132d, 101d, 102d, 139d, 154d, 126d, 114d, 116d, 112d, 136d, 147d, 130d, 125d, 124d, 120d, 118d, 134d, 145d, 130d, 131d
DB 124d, 114d, 133d, 144d, 145d, 112d, 95d, 134d, 141d, 133d, 128d, 111d, 122d, 127d, 118d, 123d, 131d, 129d, 119d, 132d, 138d, 118d, 130d, 143d, 113d, 104d, 142d, 148d, 129d, 135d
DB 124d, 118d, 128d, 133d, 127d, 115d, 123d, 130d, 124d, 122d, 130d, 136d, 132d, 130d, 124d, 126d, 115d, 103d, 152d, 153d, 107d, 124d, 146d, 135d, 114d, 121d, 132d, 103d, 116d, 151d
DB 136d, 117d, 113d, 130d, 137d, 120d, 118d, 126d, 144d, 143d, 117d, 120d, 133d, 147d, 150d, 124d, 116d, 126d, 135d, 130d, 124d, 127d, 111d, 118d, 136d, 126d, 119d, 110d, 114d, 121d
DB 115d, 139d, 139d, 116d, 129d, 113d, 115d, 152d, 139d, 133d, 130d, 115d, 134d, 145d, 142d, 127d, 113d, 134d, 132d, 111d, 116d, 125d, 126d, 120d, 123d, 138d, 129d, 112d, 130d, 129d
DB 105d, 126d, 150d, 136d, 130d, 127d, 117d, 126d, 143d, 145d, 126d, 101d, 122d, 143d, 120d, 121d, 134d, 133d, 125d, 119d, 140d, 125d, 109d, 141d, 140d, 124d, 120d, 138d, 154d, 107d
DB 103d, 137d, 121d, 111d, 130d, 141d, 110d, 95d, 133d, 150d, 127d, 97d, 111d, 144d, 134d, 128d, 142d, 138d, 124d, 124d, 139d, 142d, 125d, 116d, 127d, 126d, 127d, 134d, 118d, 121d
DB 133d, 120d, 127d, 132d, 123d, 124d, 128d, 140d, 138d, 129d, 139d, 136d, 124d, 106d, 115d, 151d, 138d, 112d, 105d, 113d, 128d, 124d, 137d, 137d, 113d, 114d, 134d, 146d, 132d, 122d
DB 135d, 141d, 134d, 138d, 136d, 118d, 117d, 120d, 109d, 120d, 144d, 124d, 97d, 119d, 132d, 122d, 121d, 132d, 134d, 130d, 131d, 132d, 146d, 139d, 121d, 138d, 126d, 107d, 131d, 154d
DB 131d, 87d, 105d, 150d, 150d, 120d, 119d, 134d, 112d, 120d, 155d, 135d, 105d, 119d, 140d, 127d, 114d, 126d, 142d, 134d, 107d, 120d, 136d, 122d, 130d, 133d, 115d, 112d, 132d, 156d
DB 134d, 101d, 110d, 129d, 138d, 140d, 136d, 126d, 114d, 122d, 125d, 117d, 137d, 139d, 121d, 127d, 123d, 130d, 139d, 124d, 130d, 134d, 126d, 127d, 128d, 121d, 105d, 106d, 125d, 139d
DB 125d, 112d, 132d, 138d, 129d, 127d, 137d, 142d, 133d, 131d, 124d, 130d, 137d, 126d, 138d, 124d, 106d, 126d, 138d, 133d, 112d, 109d, 129d, 136d, 133d, 122d, 104d, 118d, 148d, 128d
DB 118d, 141d, 124d, 127d, 155d, 133d, 107d, 106d, 137d, 152d, 119d, 110d, 130d, 142d, 121d, 102d, 128d, 134d, 125d, 138d, 138d, 124d, 111d, 116d, 141d, 136d, 110d, 125d, 139d, 115d
DB 121d, 131d, 119d, 131d, 139d, 134d, 125d, 125d, 138d, 122d, 121d, 141d, 124d, 110d, 117d, 124d, 130d, 127d, 130d, 133d, 126d, 130d, 124d, 125d, 131d, 113d, 138d, 169d, 131d, 110d
DB 129d, 130d, 125d, 134d, 131d, 120d, 128d, 131d, 120d, 128d, 120d, 112d, 129d, 125d, 114d, 101d, 108d, 147d, 139d, 117d, 135d, 143d, 139d, 135d, 119d, 129d, 138d, 118d, 132d, 149d
DB 121d, 108d, 123d, 138d, 138d, 116d, 114d, 133d, 124d, 123d, 137d, 122d, 121d, 131d, 120d, 127d, 119d, 111d, 142d, 138d, 122d, 125d, 133d, 137d, 116d, 132d, 134d, 105d, 131d, 140d
DB 131d, 126d, 115d, 144d, 134d, 114d, 146d, 138d, 114d, 120d, 131d, 132d, 123d, 122d, 123d, 120d, 115d, 133d, 146d, 111d, 107d, 140d, 144d, 129d, 122d, 135d, 125d, 99d, 125d, 140d
DB 117d, 120d, 131d, 125d, 106d, 124d, 150d, 134d, 128d, 133d, 128d, 134d, 137d, 132d, 130d, 131d, 136d, 138d, 136d, 129d, 112d, 115d, 126d, 125d, 142d, 132d, 109d, 122d, 123d, 124d
DB 136d, 122d, 118d, 129d, 133d, 137d, 128d, 121d, 130d, 133d, 118d, 114d, 125d, 123d, 124d, 130d, 123d, 122d, 137d, 139d, 125d, 112d, 112d, 135d, 150d, 139d, 123d, 119d, 135d, 133d
DB 127d, 129d, 112d, 122d, 127d, 121d, 126d, 127d, 130d, 109d, 118d, 144d, 122d, 121d, 133d, 129d, 127d, 128d, 140d, 149d, 136d, 114d, 126d, 142d, 120d, 115d, 124d, 137d, 135d, 110d
DB 124d, 144d, 124d, 113d, 126d, 132d, 122d, 131d, 144d, 118d, 106d, 124d, 140d, 138d, 122d, 122d, 122d, 115d, 124d, 134d, 132d, 123d, 115d, 125d, 136d, 116d, 116d, 134d, 128d, 141d
DB 145d, 124d, 129d, 133d, 127d, 117d, 124d, 142d, 136d, 119d, 113d, 121d, 126d, 121d, 131d, 133d, 114d, 126d, 136d, 120d, 127d, 130d, 125d, 131d, 130d, 125d, 127d, 131d, 120d, 124d
DB 138d, 131d, 132d, 141d, 125d, 115d, 130d, 127d, 119d, 125d, 121d, 116d, 130d, 138d, 124d, 125d, 131d, 126d, 124d, 134d, 145d, 125d, 124d, 138d, 125d, 132d, 132d, 117d, 124d, 125d
DB 122d, 124d, 127d, 123d, 120d, 122d, 121d, 122d, 127d, 130d, 128d, 129d, 128d, 138d, 140d, 118d, 124d, 136d, 126d, 129d, 134d, 129d, 128d, 126d, 125d, 136d, 122d, 109d, 134d, 138d
DB 123d, 114d, 122d, 142d, 134d, 125d, 126d, 108d, 115d, 142d, 129d, 112d, 119d, 131d, 140d, 130d, 119d, 124d, 127d, 133d, 130d, 125d, 139d, 133d, 130d, 129d, 110d, 125d, 132d, 124d
DB 126d, 113d, 121d, 129d, 128d, 135d, 119d, 113d, 128d, 129d, 120d, 130d, 135d, 121d, 130d, 141d, 137d, 134d, 141d, 136d, 113d, 107d, 123d, 144d, 132d, 114d, 125d, 124d, 129d, 129d
DB 121d, 125d, 122d, 128d, 138d, 134d, 114d, 115d, 131d, 118d, 134d, 139d, 115d, 132d, 140d, 128d, 122d, 133d, 151d, 139d, 126d, 125d, 130d, 127d, 114d, 131d, 130d, 109d, 123d, 130d
DB 130d, 121d, 110d, 126d, 131d, 116d, 114d, 136d, 131d, 109d, 126d, 138d, 137d, 128d, 126d, 135d, 115d, 119d, 140d, 138d, 131d, 115d, 116d, 130d, 136d, 121d, 117d, 142d, 130d, 133d
DB 150d, 130d, 127d, 126d, 124d, 134d, 122d, 124d, 129d, 117d, 120d, 114d, 113d, 135d, 132d, 120d, 117d, 118d, 137d, 137d, 122d, 127d, 128d, 137d, 141d, 118d, 112d, 133d, 144d, 129d
DB 121d, 126d, 133d, 134d, 119d, 116d, 115d, 128d, 138d, 114d, 117d, 123d, 127d, 144d, 131d, 124d, 134d, 134d, 129d, 131d, 131d, 107d, 118d, 157d, 140d, 114d, 112d, 117d, 122d, 120d
DB 113d, 122d, 137d, 126d, 127d, 143d, 138d, 122d, 120d, 134d, 130d, 122d, 139d, 140d, 120d, 119d, 139d, 143d, 116d, 121d, 136d, 111d, 114d, 135d, 134d, 134d, 119d, 105d, 120d, 125d
DB 118d, 128d, 130d, 117d, 123d, 137d, 134d, 127d, 129d, 125d, 116d, 135d, 136d, 120d, 134d, 132d, 125d, 127d, 134d, 153d, 128d, 112d, 125d, 114d, 125d, 134d, 124d, 124d, 114d, 110d
DB 128d, 133d, 128d, 132d, 129d, 131d, 141d, 132d, 129d, 132d, 117d, 122d, 140d, 137d, 132d, 129d, 123d, 114d, 115d, 135d, 138d, 133d, 121d, 112d, 136d, 137d, 121d, 125d, 137d, 135d
DB 111d, 114d, 139d, 136d, 130d, 127d, 118d, 121d, 132d, 124d, 114d, 119d, 107d, 117d, 154d, 142d, 119d, 122d, 119d, 125d, 133d, 139d, 134d, 122d, 125d, 131d, 131d, 123d, 114d, 127d
DB 137d, 125d, 117d, 135d, 139d, 123d, 124d, 133d, 139d, 133d, 130d, 127d, 114d, 131d, 146d, 123d, 120d, 130d, 126d, 118d, 112d, 127d, 134d, 120d, 125d, 126d, 111d, 114d, 133d, 141d
DB 124d, 124d, 146d, 149d, 130d, 114d, 129d, 134d, 130d, 139d, 130d, 114d, 116d, 131d, 121d, 114d, 135d, 131d, 130d, 133d, 120d, 120d, 125d, 139d, 132d, 118d, 131d, 131d, 123d, 121d
DB 121d, 123d, 116d, 124d, 135d, 128d, 120d, 119d, 127d, 129d, 137d, 143d, 131d, 125d, 128d, 138d, 132d, 130d, 142d, 136d, 128d, 117d, 116d, 124d, 116d, 124d, 127d, 115d, 124d, 137d
DB 127d, 120d, 120d, 120d, 134d, 141d, 133d, 123d, 120d, 128d, 128d, 128d, 131d, 125d, 121d, 119d, 124d, 135d, 129d, 127d, 138d, 126d, 119d, 132d, 126d, 120d, 123d, 128d, 136d, 125d
DB 131d, 138d, 115d, 114d, 128d, 129d, 130d, 121d, 125d, 136d, 121d, 121d, 133d, 131d, 128d, 128d, 128d, 119d, 125d, 143d, 134d, 122d, 124d, 129d, 130d, 125d, 118d, 121d, 131d, 135d
DB 132d, 127d, 131d, 127d, 118d, 128d, 132d, 129d, 125d, 120d, 131d, 133d, 116d, 122d, 137d, 128d, 117d, 119d, 122d, 126d, 131d, 129d, 124d, 128d, 135d, 130d, 123d, 123d, 122d, 129d
DB 133d, 128d, 126d, 125d, 124d, 131d, 128d, 121d, 128d, 129d, 126d, 125d, 125d, 132d, 126d, 124d, 133d, 124d, 122d, 127d, 129d, 124d, 117d, 130d, 140d, 133d, 126d, 123d, 128d, 132d
DB 131d, 125d, 128d, 137d, 126d, 123d, 129d, 129d, 126d, 118d, 120d, 122d, 121d, 121d, 125d, 131d, 120d, 126d, 142d, 132d, 123d, 126d, 133d, 136d, 134d, 134d, 131d, 123d, 121d, 131d
DB 125d, 122d, 136d, 128d, 119d, 120d, 121d, 129d, 126d, 122d, 121d, 125d, 136d, 130d, 126d, 123d, 125d, 138d, 129d, 122d, 136d, 131d, 121d, 128d, 132d, 135d, 131d, 117d, 119d, 128d
DB 127d, 126d, 128d, 126d, 127d, 128d, 126d, 129d, 129d, 122d, 120d, 126d, 132d, 129d, 129d, 134d, 129d, 125d, 128d, 128d, 129d, 123d, 122d, 125d, 126d, 137d, 137d, 125d, 119d, 122d
DB 130d, 133d, 126d, 124d, 131d, 129d, 121d, 122d, 130d, 132d, 122d, 117d, 127d, 132d, 133d, 130d, 122d, 127d, 133d, 126d, 127d, 130d, 119d, 120d, 135d, 134d, 132d, 131d, 127d, 123d
DB 117d, 128d, 130d, 123d, 131d, 131d, 125d, 123d, 127d, 134d, 132d, 125d, 121d, 128d, 132d, 125d, 127d, 131d, 128d, 128d, 127d, 123d, 124d, 127d, 119d, 121d, 135d, 133d, 131d, 133d
DB 124d, 118d, 123d, 128d, 129d, 127d, 121d, 125d, 132d, 128d, 125d, 129d, 130d, 124d, 125d, 121d, 120d, 130d, 128d, 125d, 125d, 131d, 138d, 124d, 119d, 123d, 127d, 134d, 128d, 127d
DB 136d, 131d, 123d, 122d, 119d, 130d, 141d, 124d, 115d, 124d, 134d, 134d, 123d, 124d, 135d, 128d, 121d, 133d, 130d, 117d, 122d, 131d, 131d, 129d, 127d, 128d, 127d, 124d, 125d, 125d
DB 128d, 132d, 128d, 123d, 120d, 128d, 133d, 125d, 121d, 123d, 130d, 133d, 125d, 126d, 128d, 124d, 129d, 124d, 119d, 129d, 128d, 119d, 119d, 128d, 132d, 128d, 129d, 127d, 127d, 130d
DB 127d, 128d, 132d, 133d, 129d, 129d, 132d, 129d, 126d, 120d, 119d, 130d, 129d, 122d, 127d, 128d, 121d, 120d, 128d, 127d, 123d, 129d, 128d, 128d, 131d, 132d, 136d, 127d, 128d, 137d
DB 126d, 126d, 130d, 118d, 123d, 127d, 122d, 128d, 123d, 121d, 124d, 115d, 128d, 133d, 123d, 134d, 134d, 127d, 128d, 128d, 137d, 130d, 119d, 127d, 128d, 128d, 134d, 129d, 122d, 121d
DB 129d, 133d, 126d, 125d, 122d, 123d, 129d, 132d, 137d, 129d, 121d, 131d, 129d, 116d, 128d, 134d, 121d, 122d, 127d, 127d, 125d, 125d, 129d, 123d, 124d, 138d, 136d, 124d, 125d, 130d
DB 125d, 125d, 126d, 133d, 133d, 113d, 117d, 130d, 126d, 127d, 122d, 123d, 128d, 122d, 123d, 126d, 130d, 131d, 125d, 125d, 132d, 138d, 131d, 120d, 129d, 137d, 135d, 136d, 129d, 123d
DB 129d, 126d, 120d, 121d, 125d, 132d, 125d, 118d, 127d, 128d, 125d, 128d, 123d, 120d, 128d, 128d, 130d, 133d, 124d, 130d, 137d, 131d, 134d, 128d, 119d, 129d, 134d, 124d, 120d, 130d
DB 137d, 125d, 111d, 117d, 128d, 131d, 132d, 125d, 124d, 130d, 134d, 132d, 123d, 126d, 126d, 123d, 128d, 129d, 130d, 123d, 122d, 133d, 128d, 122d, 133d, 131d, 120d, 121d, 131d, 132d
DB 127d, 128d, 129d, 124d, 120d, 125d, 132d, 131d, 132d, 131d, 125d, 123d, 125d, 132d, 128d, 116d, 123d, 132d, 129d, 128d, 124d, 121d, 126d, 132d, 134d, 126d, 127d, 128d, 118d, 122d
DB 129d, 133d, 132d, 124d, 130d, 128d, 120d, 125d, 130d, 128d, 127d, 126d, 128d, 125d, 121d, 129d, 129d, 125d, 133d, 134d, 129d, 129d, 125d, 126d, 129d, 130d, 134d, 130d, 121d, 118d
DB 119d, 127d, 130d, 121d, 117d, 125d, 129d, 120d, 118d, 130d, 132d, 126d, 128d, 129d, 133d, 136d, 127d, 127d, 131d, 131d, 138d, 131d, 118d, 120d, 123d, 126d, 127d, 126d, 128d, 128d
DB 120d, 117d, 123d, 131d, 131d, 123d, 125d, 133d, 132d, 130d, 121d, 128d, 134d, 124d, 126d, 129d, 124d, 119d, 127d, 134d, 123d, 121d, 130d, 127d, 116d, 117d, 129d, 134d, 137d, 130d
DB 128d, 131d, 123d, 130d, 129d, 119d, 126d, 126d, 126d, 128d, 125d, 127d, 125d, 123d, 133d, 134d, 119d, 122d, 128d, 125d, 132d, 134d, 130d, 122d, 122d, 134d, 127d, 123d, 130d, 133d
DB 132d, 124d, 126d, 131d, 128d, 130d, 121d, 121d, 133d, 127d, 125d, 135d, 129d, 124d, 129d, 128d, 129d, 128d, 115d, 120d, 129d, 127d, 125d, 129d, 127d, 113d, 116d, 133d, 135d, 130d
DB 124d, 125d, 129d, 129d, 129d, 121d, 122d, 135d, 133d, 125d, 121d, 123d, 136d, 133d, 120d, 128d, 137d, 129d, 126d, 118d, 114d, 130d, 134d, 131d, 130d, 122d, 124d, 132d, 133d, 130d
DB 131d, 129d, 126d, 127d, 124d, 122d, 124d, 118d, 120d, 127d, 121d, 123d, 126d, 118d, 114d, 117d, 129d, 132d, 116d, 113d, 122d, 119d, 118d, 127d, 126d, 121d, 123d, 119d, 116d, 123d
DB 122d, 120d, 114d, 107d, 112d, 117d, 117d, 109d, 107d, 114d, 116d, 118d, 113d, 112d, 110d, 111d, 121d, 115d, 115d, 117d, 108d, 113d, 111d, 108d, 117d, 119d, 112d, 105d, 106d, 113d
DB 112d, 105d, 107d, 110d, 105d, 106d, 107d, 107d, 110d, 108d, 107d, 105d, 108d, 108d, 100d, 97d, 97d, 103d, 108d, 103d, 97d, 96d, 108d, 108d, 96d, 99d, 105d, 105d, 102d, 102d
DB 99d, 99d, 107d, 100d, 96d, 101d, 99d, 98d, 96d, 98d, 100d, 92d, 96d, 100d, 96d, 94d, 92d, 96d, 100d, 93d, 93d, 97d, 93d, 94d, 93d, 94d, 99d, 91d, 88d, 90d
DB 93d, 92d, 85d, 88d, 88d, 89d, 95d, 89d, 88d, 93d, 89d, 93d, 92d, 85d, 87d, 89d, 86d, 86d, 85d, 87d, 87d, 81d, 81d, 82d, 87d, 88d, 81d, 82d, 85d, 84d
DB 81d, 85d, 85d, 79d, 80d, 80d, 81d, 84d, 81d, 78d, 79d, 82d, 79d, 78d, 79d, 75d, 76d, 77d, 78d, 81d, 79d, 79d, 79d, 76d, 79d, 79d, 79d, 83d, 74d, 67d
DB 74d, 76d, 74d, 72d, 71d, 70d, 70d, 72d, 73d, 72d, 69d, 69d, 71d, 71d, 70d, 72d, 70d, 66d, 67d, 70d, 72d, 70d, 68d, 70d, 68d, 63d, 65d, 71d, 71d, 64d
DB 63d, 63d, 62d, 65d, 65d, 66d, 64d, 60d, 63d, 66d, 64d, 64d, 60d, 60d, 62d, 62d, 66d, 61d, 57d, 62d, 61d, 60d, 58d, 58d, 61d, 57d, 54d, 56d, 57d, 60d
DB 56d, 53d, 57d, 57d, 57d, 54d, 57d, 60d, 55d, 53d, 54d, 56d, 56d, 55d, 52d, 50d, 52d, 54d, 53d, 52d, 47d, 48d, 53d, 50d, 48d, 48d, 49d, 50d, 48d, 48d
DB 49d, 47d, 47d, 46d, 44d, 46d, 49d, 50d, 47d, 45d, 46d, 45d, 47d, 47d, 43d, 43d, 45d, 44d, 44d, 43d, 44d, 44d, 40d, 38d, 42d, 44d, 41d, 37d, 38d, 41d
DB 40d, 41d, 40d, 38d, 37d, 38d, 40d, 37d, 37d, 39d, 38d, 36d, 36d, 36d, 37d, 36d, 33d, 30d, 34d, 36d, 35d, 34d, 31d, 32d, 34d, 34d, 32d, 30d, 32d, 33d
DB 32d, 30d, 29d, 32d, 31d, 27d, 29d, 28d, 27d, 29d, 28d, 26d, 28d, 29d, 28d, 26d, 25d, 26d, 26d, 25d, 26d, 26d, 26d, 25d, 24d, 24d, 23d, 23d, 23d, 22d
DB 23d, 23d, 23d, 22d, 20d, 20d, 20d, 20d, 21d, 21d, 18d, 18d, 20d, 20d, 19d, 17d, 17d, 17d, 16d, 17d, 17d, 16d, 16d, 16d, 15d, 15d, 16d, 15d, 14d, 13d
DB 14d, 15d, 14d, 13d, 12d, 12d, 12d, 11d, 12d, 11d, 10d, 10d, 9d, 10d, 11d, 10d, 9d, 8d, 8d, 8d, 8d, 8d, 7d, 7d, 7d, 7d, 6d, 6d, 5d, 5d
DB 5d, 5d, 4d, 5d, 4d, 3d, 3d, 3d, 3d, 3d, 2d, 2d, 1d, 1d, 1d, 1d, 0d, 0d, 0d, 0 


;[3862]
TABLE_PERC2:
DB 0d, 0d, 0d, 0d, 1d, 1d, 1d, 2d, 2d, 3d, 3d, 4d, 4d, 1d, 1d, 2d, 2d, 4d, 4d, 6d, 7d, 8d, 9d, 10d, 12d, 13d, 13d, 14d, 14d, 14d
DB 14d, 13d, 12d, 11d, 10d, 9d, 8d, 6d, 6d, 5d, 5d, 5d, 5d, 6d, 7d, 9d, 11d, 13d, 15d, 18d, 20d, 22d, 24d, 26d, 27d, 28d, 29d, 28d, 28d, 27d
DB 25d, 23d, 21d, 19d, 16d, 14d, 12d, 11d, 10d, 9d, 9d, 10d, 11d, 13d, 16d, 19d, 22d, 25d, 29d, 32d, 35d, 38d, 40d, 42d, 43d, 43d, 42d, 41d, 39d, 37d
DB 34d, 31d, 27d, 24d, 21d, 18d, 16d, 15d, 14d, 14d, 15d, 17d, 20d, 23d, 27d, 31d, 36d, 40d, 44d, 48d, 51d, 54d, 55d, 56d, 56d, 55d, 53d, 51d, 47d, 44d
DB 40d, 36d, 31d, 28d, 25d, 22d, 20d, 20d, 20d, 21d, 24d, 27d, 31d, 36d, 41d, 46d, 51d, 56d, 61d, 64d, 67d, 69d, 70d, 70d, 68d, 66d, 62d, 58d, 54d, 49d
DB 44d, 39d, 35d, 30d, 28d, 26d, 25d, 26d, 27d, 30d, 34d, 40d, 45d, 51d, 57d, 63d, 69d, 73d, 77d, 80d, 82d, 83d, 82d, 81d, 77d, 73d, 69d, 63d, 57d, 51d
DB 46d, 41d, 37d, 34d, 31d, 31d, 32d, 34d, 37d, 42d, 48d, 54d, 61d, 68d, 75d, 81d, 86d, 91d, 94d, 96d, 96d, 95d, 93d, 89d, 85d, 79d, 73d, 66d, 59d, 53d
DB 47d, 43d, 40d, 38d, 37d, 38d, 41d, 45d, 50d, 57d, 64d, 72d, 79d, 87d, 94d, 99d, 104d, 107d, 109d, 109d, 107d, 105d, 100d, 95d, 89d, 81d, 74d, 67d, 60d, 54d
DB 49d, 46d, 43d, 44d, 45d, 48d, 53d, 59d, 66d, 74d, 82d, 91d, 99d, 106d, 112d, 116d, 120d, 121d, 121d, 120d, 116d, 111d, 105d, 98d, 90d, 82d, 74d, 67d, 61d, 55d
DB 52d, 50d, 50d, 52d, 56d, 61d, 68d, 76d, 84d, 93d, 103d, 110d, 118d, 124d, 129d, 132d, 134d, 133d, 131d, 127d, 121d, 115d, 107d, 98d, 90d, 81d, 74d, 67d, 62d, 58d
DB 57d, 57d, 60d, 64d, 70d, 77d, 86d, 95d, 104d, 114d, 122d, 130d, 137d, 141d, 144d, 146d, 145d, 142d, 138d, 132d, 124d, 116d, 107d, 97d, 89d, 81d, 74d, 69d, 66d, 64d
DB 64d, 67d, 72d, 79d, 87d, 96d, 106d, 116d, 126d, 134d, 142d, 149d, 154d, 157d, 157d, 156d, 153d, 148d, 141d, 133d, 125d, 115d, 105d, 96d, 88d, 81d, 76d, 73d, 72d, 72d
DB 76d, 81d, 88d, 96d, 106d, 117d, 127d, 136d, 146d, 154d, 161d, 166d, 168d, 169d, 167d, 164d, 158d, 151d, 142d, 133d, 123d, 113d, 103d, 96d, 88d, 83d, 81d, 80d, 81d, 84d
DB 90d, 97d, 106d, 115d, 125d, 135d, 145d, 154d, 161d, 167d, 171d, 173d, 173d, 171d, 166d, 160d, 152d, 143d, 134d, 124d, 114d, 105d, 97d, 90d, 85d, 82d, 82d, 83d, 87d, 92d
DB 99d, 108d, 117d, 127d, 136d, 146d, 154d, 161d, 166d, 170d, 171d, 171d, 168d, 164d, 158d, 150d, 141d, 132d, 123d, 113d, 105d, 97d, 91d, 86d, 84d, 84d, 85d, 89d, 95d, 102d
DB 110d, 119d, 128d, 137d, 146d, 154d, 160d, 165d, 168d, 169d, 168d, 166d, 161d, 155d, 148d, 139d, 131d, 121d, 113d, 104d, 97d, 92d, 88d, 86d, 86d, 88d, 92d, 95d, 107d, 120d
DB 126d, 135d, 142d, 149d, 155d, 159d, 162d, 164d, 163d, 161d, 157d, 152d, 146d, 139d, 131d, 123d, 116d, 108d, 102d, 97d, 94d, 92d, 91d, 93d, 96d, 100d, 106d, 113d, 120d, 128d
DB 136d, 143d, 149d, 154d, 158d, 161d, 162d, 161d, 159d, 155d, 150d, 144d, 137d, 130d, 122d, 115d, 108d, 103d, 98d, 95d, 93d, 93d, 95d, 98d, 102d, 108d, 115d, 122d, 129d, 136d
DB 143d, 149d, 154d, 157d, 159d, 160d, 159d, 157d, 153d, 148d, 142d, 136d, 129d, 121d, 115d, 108d, 103d, 99d, 96d, 95d, 95d, 97d, 100d, 104d, 110d, 116d, 123d, 130d, 137d, 143d
DB 148d, 153d, 156d, 158d, 158d, 157d, 155d, 151d, 146d, 140d, 134d, 127d, 121d, 114d, 109d, 104d, 100d, 98d, 97d, 97d, 99d, 102d, 106d, 112d, 118d, 124d, 131d, 137d, 143d, 148d
DB 152d, 155d, 156d, 156d, 155d, 153d, 149d, 144d, 139d, 133d, 126d, 120d, 114d, 109d, 104d, 101d, 99d, 98d, 98d, 100d, 104d, 108d, 113d, 119d, 125d, 131d, 137d, 143d, 148d, 151d
DB 154d, 155d, 155d, 154d, 151d, 148d, 143d, 138d, 132d, 125d, 119d, 114d, 109d, 104d, 101d, 99d, 99d, 100d, 102d, 105d, 109d, 114d, 120d, 126d, 131d, 137d, 142d, 147d, 151d, 153d
DB 155d, 155d, 153d, 151d, 147d, 143d, 137d, 132d, 126d, 120d, 114d, 109d, 105d, 102d, 100d, 100d, 100d, 102d, 105d, 109d, 114d, 120d, 126d, 132d, 137d, 142d, 147d, 150d, 153d, 154d
DB 153d, 152d, 150d, 146d, 141d, 136d, 131d, 125d, 119d, 114d, 109d, 105d, 102d, 101d, 100d, 101d, 103d, 107d, 111d, 116d, 121d, 127d, 132d, 138d, 143d, 147d, 150d, 152d, 153d, 152d
DB 151d, 148d, 145d, 140d, 135d, 130d, 124d, 119d, 113d, 109d, 105d, 103d, 102d, 101d, 102d, 105d, 108d, 112d, 117d, 122d, 128d, 133d, 138d, 143d, 147d, 149d, 151d, 152d, 151d, 150d
DB 147d, 143d, 139d, 134d, 129d, 123d, 118d, 113d, 109d, 106d, 104d, 102d, 102d, 104d, 106d, 109d, 113d, 118d, 123d, 128d, 134d, 138d, 143d, 146d, 149d, 150d, 151d, 150d, 149d, 146d
DB 142d, 138d, 133d, 128d, 123d, 118d, 113d, 109d, 106d, 104d, 103d, 103d, 105d, 107d, 110d, 114d, 119d, 124d, 129d, 134d, 139d, 143d, 146d, 148d, 150d, 150d, 149d, 147d, 145d, 141d
DB 137d, 132d, 127d, 122d, 117d, 112d, 113d, 112d, 108d, 108d, 107d, 107d, 109d, 111d, 114d, 118d, 122d, 126d, 130d, 134d, 138d, 141d, 144d, 146d, 146d, 146d, 145d, 143d, 141d, 137d
DB 134d, 130d, 125d, 121d, 117d, 114d, 111d, 109d, 108d, 108d, 108d, 110d, 112d, 115d, 119d, 123d, 127d, 131d, 135d, 138d, 141d, 144d, 145d, 146d, 145d, 144d, 142d, 140d, 137d, 133d
DB 129d, 125d, 121d, 117d, 114d, 112d, 110d, 109d, 109d, 109d, 111d, 113d, 116d, 120d, 123d, 127d, 131d, 135d, 138d, 141d, 143d, 144d, 145d, 145d, 143d, 141d, 139d, 136d, 132d, 128d
DB 124d, 121d, 117d, 114d, 112d, 110d, 109d, 109d, 110d, 112d, 113d, 116d, 120d, 124d, 128d, 131d, 135d, 138d, 141d, 143d, 144d, 145d, 144d, 143d, 141d, 139d, 135d, 132d, 128d, 124d
DB 120d, 117d, 114d, 112d, 110d, 109d, 109d, 110d, 112d, 114d, 117d, 121d, 124d, 128d, 132d, 135d, 138d, 141d, 143d, 144d, 144d, 144d, 142d, 140d, 138d, 135d, 131d, 127d, 124d, 120d
DB 117d, 114d, 112d, 111d, 110d, 110d, 111d, 113d, 115d, 118d, 121d, 125d, 128d, 132d, 135d, 138d, 140d, 142d, 146d, 146d, 145d, 144d, 141d, 138d, 134d, 130d, 126d, 122d, 118d, 114d
DB 112d, 109d, 109d, 107d, 106d, 116d, 122d, 122d, 126d, 127d, 130d, 132d, 133d, 136d, 136d, 137d, 137d, 137d, 137d, 135d, 134d, 132d, 130d, 128d, 125d, 123d, 121d, 119d, 118d, 117d
DB 117d, 117d, 117d, 118d, 120d, 122d, 123d, 126d, 128d, 130d, 132d, 134d, 135d, 136d, 137d, 137d, 137d, 136d, 135d, 133d, 131d, 129d, 127d, 125d, 123d, 121d, 120d, 119d, 118d, 117d
DB 118d, 118d, 119d, 120d, 122d, 124d, 126d, 128d, 130d, 132d, 133d, 135d, 136d, 136d, 136d, 136d, 135d, 134d, 133d, 131d, 129d, 127d, 125d, 123d, 121d, 120d, 119d, 118d, 118d, 118d
DB 119d, 120d, 121d, 122d, 124d, 126d, 128d, 130d, 132d, 133d, 135d, 135d, 136d, 136d, 136d, 135d, 134d, 132d, 131d, 129d, 127d, 125d, 123d, 121d, 120d, 119d, 118d, 118d, 118d, 119d
DB 120d, 121d, 123d, 124d, 127d, 128d, 130d, 132d, 133d, 134d, 135d, 136d, 136d, 135d, 135d, 134d, 132d, 131d, 129d, 127d, 125d, 123d, 122d, 122d, 120d, 120d, 119d, 119d, 119d, 120d
DB 121d, 122d, 124d, 125d, 127d, 129d, 130d, 132d, 133d, 134d, 135d, 135d, 135d, 134d, 133d, 132d, 131d, 129d, 127d, 126d, 124d, 123d, 121d, 120d, 120d, 119d, 119d, 120d, 120d, 121d
DB 123d, 124d, 126d, 127d, 129d, 131d, 132d, 133d, 134d, 134d, 135d, 135d, 133d, 132d, 131d, 130d, 128d, 127d, 125d, 124d, 123d, 122d, 121d, 120d, 120d, 120d, 121d, 121d, 122d, 124d
DB 125d, 126d, 128d, 129d, 131d, 132d, 133d, 133d, 134d, 134d, 133d, 133d, 132d, 131d, 130d, 128d, 127d, 125d, 124d, 123d, 121d, 121d, 121d, 121d, 121d, 122d, 122d, 123d, 124d, 125d
DB 126d, 128d, 129d, 130d, 131d, 132d, 132d, 133d, 133d, 132d, 132d, 131d, 130d, 129d, 128d, 127d, 126d, 124d, 123d, 123d, 122d, 121d, 121d, 121d, 122d, 122d, 123d, 124d, 125d, 127d
DB 128d, 129d, 130d, 131d, 132d, 132d, 133d, 133d, 132d, 132d, 131d, 130d, 129d, 128d, 127d, 125d, 124d, 123d, 123d, 122d, 122d, 121d, 122d, 122d, 123d, 124d, 124d, 126d, 126d, 128d
DB 132d, 132d, 132d, 133d, 133d, 133d, 132d, 131d, 131d, 129d, 129d, 127d, 126d, 127d, 126d, 125d, 124d, 123d, 122d, 122d, 121d, 121d, 122d, 122d, 123d, 124d, 125d, 126d, 127d, 129d
DB 130d, 131d, 132d, 132d, 132d, 133d, 132d, 132d, 131d, 130d, 129d, 128d, 127d, 126d, 125d, 124d, 123d, 122d, 122d, 121d, 122d, 122d, 122d, 123d, 124d, 125d, 126d, 128d, 129d, 129d
DB 131d, 131d, 132d, 132d, 132d, 133d, 131d, 132d, 134d, 133d, 131d, 130d, 129d, 127d, 125d, 123d, 121d, 120d, 119d, 118d, 118d, 118d, 119d, 120d, 121d, 123d, 124d, 126d, 128d, 130d
DB 132d, 133d, 135d, 135d, 136d, 136d, 135d, 135d, 134d, 132d, 130d, 129d, 127d, 125d, 123d, 121d, 120d, 119d, 118d, 118d, 118d, 119d, 120d, 121d, 123d, 125d, 127d, 129d, 130d, 132d
DB 135d, 136d, 137d, 137d, 137d, 136d, 135d, 133d, 131d, 129d, 127d, 125d, 123d, 121d, 119d, 118d, 118d, 117d, 117d, 118d, 119d, 120d, 122d, 124d, 126d, 128d, 130d, 132d, 134d, 135d
DB 136d, 137d, 137d, 136d, 135d, 134d, 133d, 131d, 129d, 127d, 125d, 123d, 121d, 119d, 118d, 118d, 118d, 118d, 118d, 119d, 121d, 123d, 125d, 127d, 129d, 131d, 132d, 134d, 135d, 136d
DB 136d, 136d, 136d, 135d, 134d, 132d, 130d, 128d, 127d, 125d, 123d, 121d, 120d, 119d, 118d, 118d, 118d, 119d, 120d, 121d, 123d, 124d, 127d, 129d, 130d, 133d, 134d, 135d, 136d, 136d
DB 136d, 136d, 135d, 133d, 132d, 130d, 128d, 126d, 124d, 123d, 121d, 120d, 119d, 118d, 118d, 118d, 119d, 120d, 122d, 123d, 125d, 127d, 129d, 131d, 132d, 134d, 135d, 136d, 136d, 136d
DB 135d, 135d, 133d, 132d, 130d, 128d, 126d, 124d, 123d, 121d, 120d, 119d, 118d, 118d, 119d, 119d, 120d, 122d, 123d, 125d, 127d, 129d, 130d, 132d, 134d, 135d, 136d, 135d, 134d, 134d
DB 133d, 132d, 131d, 129d, 128d, 127d, 125d, 124d, 123d, 122d, 121d, 120d, 120d, 121d, 121d, 122d, 123d, 124d, 125d, 127d, 128d, 130d, 131d, 132d, 133d, 133d, 134d, 133d, 133d, 132d
DB 132d, 130d, 129d, 128d, 126d, 125d, 124d, 123d, 122d, 121d, 121d, 121d, 121d, 121d, 122d, 123d, 124d, 126d, 127d, 128d, 130d, 131d, 132d, 133d, 133d, 133d, 133d, 133d, 132d, 131d
DB 130d, 129d, 128d, 126d, 125d, 124d, 123d, 122d, 121d, 121d, 121d, 121d, 122d, 123d, 124d, 125d, 126d, 127d, 128d, 130d, 131d, 132d, 132d, 133d, 133d, 133d, 132d, 132d, 131d, 130d
DB 129d, 127d, 126d, 125d, 124d, 123d, 122d, 122d, 122d, 121d, 122d, 122d, 123d, 124d, 125d, 127d, 127d, 125d, 126d, 128d, 129d, 131d, 132d, 132d, 133d, 133d, 133d, 133d, 132d, 131d
DB 130d, 129d, 128d, 127d, 125d, 124d, 123d, 122d, 121d, 121d, 121d, 121d, 121d, 122d, 123d, 124d, 126d, 127d, 129d, 130d, 131d, 132d, 133d, 133d, 133d, 133d, 133d, 132d, 131d, 130d
DB 129d, 127d, 126d, 125d, 124d, 123d, 122d, 121d, 121d, 121d, 121d, 122d, 123d, 124d, 124d, 126d, 127d, 128d, 130d, 131d, 132d, 133d, 133d, 133d, 133d, 132d, 132d, 131d, 130d, 129d
DB 127d, 126d, 125d, 124d, 123d, 122d, 122d, 121d, 121d, 122d, 122d, 123d, 124d, 125d, 126d, 127d, 129d, 130d, 131d, 132d, 132d, 132d, 132d, 132d, 132d, 131d, 131d, 130d, 128d, 127d
DB 126d, 125d, 124d, 123d, 123d, 122d, 122d, 122d, 122d, 123d, 123d, 124d, 125d, 126d, 128d, 129d, 130d, 130d, 132d, 132d, 130d, 130d, 131d, 130d, 130d, 130d, 129d, 128d, 127d, 127d
DB 126d, 125d, 125d, 126d, 125d, 125d, 124d, 124d, 124d, 124d, 125d, 125d, 125d, 126d, 127d, 127d, 128d, 128d, 129d, 129d, 130d, 130d, 130d, 130d, 129d, 129d, 129d, 128d, 128d, 127d
DB 126d, 126d, 125d, 125d, 124d, 124d, 124d, 124d, 124d, 125d, 125d, 126d, 126d, 127d, 128d, 128d, 129d, 129d, 129d, 130d, 130d, 130d, 129d, 129d, 129d, 128d, 128d, 127d, 127d, 126d
DB 126d, 125d, 125d, 125d, 125d, 124d, 124d, 124d, 125d, 125d, 126d, 126d, 127d, 128d, 128d, 129d, 130d, 130d, 130d, 130d, 130d, 130d, 129d, 129d, 128d, 128d, 127d, 126d, 126d, 125d
DB 125d, 124d, 124d, 124d, 124d, 124d, 125d, 125d, 125d, 126d, 127d, 127d, 128d, 129d, 129d, 130d, 130d, 130d, 130d, 130d, 130d, 129d, 129d, 128d, 128d, 127d, 126d, 126d, 125d, 125d
DB 124d, 124d, 124d, 124d, 124d, 125d, 125d, 126d, 127d, 127d, 128d, 128d, 129d, 129d, 130d, 130d, 130d, 130d, 130d, 129d, 129d, 128d, 128d, 127d, 126d, 126d, 125d, 125d, 125d, 124d
DB 124d, 124d, 124d, 125d, 125d, 126d, 126d, 127d, 127d, 128d, 128d, 129d, 129d, 130d, 130d, 130d, 130d, 130d, 130d, 129d, 129d, 128d, 127d, 126d, 126d, 126d, 126d, 125d, 125d, 124d
DB 124d, 124d, 124d, 124d, 125d, 125d, 125d, 126d, 126d, 127d, 128d, 129d, 129d, 130d, 130d, 130d, 130d, 130d, 130d, 130d, 129d, 128d, 128d, 127d, 126d, 126d, 125d, 124d, 124d, 124d
DB 124d, 124d, 124d, 124d, 125d, 125d, 126d, 127d, 128d, 128d, 129d, 129d, 130d, 130d, 130d, 130d, 130d, 130d, 129d, 129d, 128d, 127d, 126d, 126d, 125d, 126d, 126d, 125d, 125d, 125d
DB 125d, 125d, 125d, 125d, 125d, 125d, 126d, 127d, 127d, 128d, 128d, 128d, 129d, 129d, 129d, 129d, 129d, 129d, 129d, 128d, 128d, 127d, 127d, 126d, 126d, 126d, 125d, 125d, 125d, 125d
DB 125d, 125d, 125d, 126d, 126d, 127d, 127d, 128d, 128d, 128d, 129d, 129d, 129d, 129d, 129d, 129d, 129d, 128d, 128d, 128d, 127d, 127d, 126d, 126d, 126d, 125d, 125d, 125d, 125d, 126d
DB 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 128d, 129d, 129d, 129d, 128d, 128d, 128d, 127d, 127d, 126d, 126d, 126d, 125d, 125d, 125d, 125d
DB 125d, 125d, 126d, 126d, 126d, 127d, 127d, 127d, 128d, 128d, 128d, 128d, 129d, 129d, 129d, 129d, 129d, 129d, 129d, 128d, 128d, 128d, 127d, 127d, 126d, 126d, 125d, 125d, 125d, 125d
DB 125d, 125d, 125d, 125d, 125d, 127d, 128d, 128d, 128d, 129d, 129d, 129d, 129d, 129d, 129d, 128d, 128d, 128d, 128d, 127d, 127d, 126d, 126d, 126d, 125d, 125d, 125d, 125d, 125d, 126d
DB 126d, 126d, 126d, 127d, 127d, 127d, 128d, 128d, 128d, 128d, 129d, 129d, 129d, 129d, 128d, 128d, 128d, 127d, 127d, 127d, 126d, 126d, 126d, 125d, 125d, 125d, 126d, 126d, 126d, 127d
DB 127d, 127d, 127d, 127d, 127d, 128d, 128d, 128d, 128d, 128d, 128d, 128d, 128d, 128d, 128d, 128d, 128d, 128d, 128d, 127d, 127d, 127d, 126d, 125d, 125d, 125d, 125d, 125d, 125d, 125d
DB 126d, 126d, 127d, 127d, 128d, 128d, 129d, 129d, 129d, 130d, 129d, 128d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 126d, 126d, 126d, 126d, 126d, 127d, 127d, 127d, 127d, 127d, 128d
DB 128d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 126d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d
DB 127d, 127d, 127d, 127d, 127d, 128d, 127d, 127d, 128d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d
DB 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 127d, 126d, 126d, 126d, 126d, 126d
DB 126d, 127d, 127d, 127d, 128d, 128d, 128d, 129d, 129d, 128d, 128d, 128d, 128d, 128d, 128d, 128d, 128d, 127d, 127d, 127d, 126d, 126d, 126d, 126d, 126d, 125d, 124d, 124d, 125d, 126d
DB 126d, 127d, 127d, 128d, 129d, 129d, 129d, 129d, 130d, 131d, 130d, 130d, 129d, 128d, 128d, 127d, 126d, 125d, 125d, 124d, 124d, 124d, 124d, 124d, 124d, 124d, 125d, 125d, 126d, 127d
DB 128d, 128d, 129d, 130d, 130d, 130d, 130d, 130d, 130d, 130d, 129d, 129d, 129d, 128d, 127d, 126d, 126d, 125d, 124d, 124d, 124d, 123d, 123d, 123d, 124d, 124d, 125d, 126d, 126d, 127d
DB 128d, 129d, 130d, 130d, 131d, 131d, 131d, 131d, 130d, 130d, 129d, 128d, 127d, 127d, 126d, 126d, 125d, 124d, 124d, 124d, 123d, 124d, 124d, 124d, 125d, 125d, 126d, 127d, 127d, 128d
DB 129d, 129d, 130d, 130d, 131d, 131d, 130d, 130d, 130d, 129d, 128d, 128d, 127d, 126d, 125d, 125d, 124d, 124d, 124d, 123d, 124d, 124d, 124d, 125d, 125d, 126d, 127d, 127d, 128d, 129d
DB 129d, 130d, 130d, 130d, 130d, 130d, 130d, 130d, 129d, 129d, 128d, 127d, 126d, 125d, 124d, 124d, 123d, 124d, 124d, 124d, 124d, 125d, 125d, 126d, 127d, 127d, 128d, 129d, 129d, 130d
DB 130d, 130d, 130d, 130d, 130d, 130d, 129d, 129d, 128d, 127d, 126d, 125d, 125d, 124d, 124d, 124d, 124d, 124d, 124d, 125d, 125d, 126d, 126d, 127d, 128d, 129d, 129d, 130d, 130d, 130d
DB 130d, 129d, 129d, 129d, 128d, 128d, 127d, 127d, 126d, 125d, 125d, 124d, 124d, 124d, 124d, 124d, 125d, 125d, 126d, 126d, 127d, 128d, 129d, 129d, 129d, 130d, 130d, 130d, 130d, 130d
DB 130d, 129d, 129d, 128d, 127d, 126d, 126d, 125d, 125d, 124d, 124d, 124d, 124d, 124d, 124d, 125d, 125d, 126d, 127d, 127d, 128d, 129d, 129d, 130d, 130d, 130d, 130d, 130d, 130d, 129d
DB 129d, 130d, 129d, 128d, 127d, 127d, 126d, 125d, 124d, 124d, 123d, 123d, 123d, 123d, 123d, 124d, 125d, 126d, 126d, 127d, 128d, 129d, 129d, 130d, 131d, 131d, 131d, 131d, 131d, 130d
DB 130d, 129d, 128d, 127d, 127d, 126d, 125d, 124d, 123d, 123d, 123d, 123d, 123d, 123d, 124d, 125d, 125d, 126d, 127d, 128d, 129d, 130d, 130d, 131d, 131d, 131d, 131d, 131d, 130d, 130d
DB 130d, 129d, 128d, 127d, 126d, 125d, 124d, 123d, 123d, 123d, 123d, 123d, 123d, 124d, 124d, 125d, 126d, 127d, 128d, 129d, 130d, 131d, 131d, 131d, 131d, 131d, 131d, 131d, 130d, 130d
DB 129d, 128d, 127d, 126d, 125d, 124d, 123d, 123d, 122d, 122d, 122d, 122d, 123d, 124d, 125d, 126d, 127d, 128d, 129d, 130d, 131d, 132d, 132d, 132d, 132d, 132d, 131d, 130d, 130d, 129d
DB 128d, 127d, 126d, 125d, 124d, 123d, 122d, 121d, 121d, 121d, 122d, 122d, 123d, 124d, 125d, 126d, 128d, 129d, 130d, 131d, 131d, 132d, 132d, 132d, 132d, 132d, 132d, 131d, 130d, 129d
DB 128d, 126d, 125d, 124d, 123d, 122d, 121d, 121d, 121d, 121d, 122d, 123d, 124d, 125d, 126d, 127d, 128d, 130d, 131d, 132d, 132d, 133d, 133d, 133d, 132d, 132d, 131d, 130d, 129d, 128d
DB 127d, 125d, 124d, 123d, 122d, 122d, 121d, 121d, 121d, 122d, 123d, 124d, 125d, 126d, 127d, 128d, 130d, 131d, 132d, 133d, 133d, 133d, 132d, 132d, 131d, 130d, 129d, 128d, 126d, 125d
DB 124d, 123d, 123d, 122d, 122d, 122d, 122d, 123d, 124d, 124d, 125d, 126d, 127d, 128d, 129d, 130d, 131d, 131d, 132d, 132d, 132d, 132d, 131d, 131d, 130d, 129d, 128d, 127d, 126d, 125d
DB 124d, 123d, 123d, 122d, 122d, 123d, 123d, 123d, 124d, 125d, 126d, 127d, 128d, 129d, 130d, 130d, 131d, 132d, 132d, 132d, 131d, 131d, 130d, 129d, 128d, 127d, 126d, 126d, 125d, 124d
DB 123d, 123d, 122d, 122d, 123d, 123d, 124d, 125d, 125d, 126d, 128d, 129d, 130d, 130d, 130d, 131d, 131d, 131d, 131d, 131d, 130d, 130d, 129d, 128d, 127d, 126d, 125d, 125d, 124d, 123d
DB 123d, 123d, 123d, 123d, 123d, 124d, 124d, 126d, 126d, 127d, 128d, 128d, 129d, 130d, 131d, 131d, 132d, 132d, 131d, 131d, 130d, 130d, 129d, 128d, 127d, 126d, 125d, 124d, 123d, 123d
DB 123d, 122d, 123d, 123d, 123d, 124d, 125d, 126d, 127d, 128d, 129d, 130d, 131d, 131d, 131d, 132d, 132d, 132d, 131d, 131d, 130d, 129d, 128d, 127d, 126d, 125d, 124d, 123d, 122d, 122d
DB 122d, 122d, 123d, 123d, 124d, 125d, 126d, 127d, 128d, 130d, 130d, 131d, 132d, 132d, 132d, 132d, 131d, 130d, 129d, 129d, 128d, 127d, 126d, 125d, 124d, 123d, 123d, 122d, 122d, 122d
DB 123d, 123d, 124d, 125d, 126d, 127d, 128d, 129d, 130d, 131d, 132d, 132d, 132d, 132d, 132d, 131d, 131d, 130d, 129d, 127d, 126d, 125d, 124d, 123d, 123d, 122d, 122d, 122d, 122d, 123d
DB 123d, 124d, 125d, 126d, 127d, 128d, 129d, 130d, 131d, 131d, 132d, 132d, 132d, 131d, 131d, 130d, 129d, 128d, 127d, 126d, 125d, 125d, 124d, 123d, 123d, 122d, 122d, 122d, 123d, 123d
DB 124d, 125d, 126d, 127d, 128d, 129d, 130d, 131d, 132d, 132d, 132d, 132d, 132d, 131d, 131d, 130d, 128d, 127d, 126d, 124d, 124d, 123d, 122d, 122d, 122d, 122d, 122d, 123d, 124d, 125d
DB 126d, 127d, 128d, 129d, 130d, 131d, 131d, 132d, 132d, 132d, 132d, 131d, 131d, 130d, 129d, 128d, 126d, 125d, 124d, 123d, 123d, 122d, 122d, 122d, 122d, 123d, 123d, 124d, 125d, 125d
DB 126d, 128d, 129d, 130d, 131d, 131d, 132d, 132d, 132d, 132d, 132d, 131d, 130d, 129d, 128d, 127d, 126d, 125d, 124d, 123d, 122d, 122d, 122d, 122d, 122d, 122d, 123d, 124d, 125d, 126d
DB 128d, 129d, 130d, 131d, 132d, 132d, 132d, 132d, 132d, 132d, 131d, 130d, 129d, 128d, 127d, 126d, 125d, 124d, 123d, 122d, 122d, 122d, 122d, 122d, 122d, 123d, 124d, 125d, 126d, 128d
DB 129d, 130d, 130d, 131d, 131d, 132d, 132d, 132d, 132d, 132d, 131d, 130d, 129d, 128d, 127d, 125d, 124d, 123d, 122d, 122d, 121d, 121d, 121d, 121d, 122d, 123d, 124d, 126d, 127d, 128d
DB 130d, 132d, 132d, 133d, 133d, 134d, 133d, 133d, 132d, 131d, 129d, 128d, 127d, 125d, 124d, 122d, 122d, 121d, 121d, 120d, 121d, 121d, 122d, 123d, 125d, 126d, 128d, 129d, 130d, 131d
DB 132d, 133d, 133d, 133d, 133d, 132d, 132d, 131d, 130d, 128d, 127d, 125d, 124d, 122d, 122d, 121d, 121d, 121d, 121d, 122d, 123d, 124d, 125d, 126d, 127d, 128d, 129d, 130d, 131d, 132d
DB 133d, 133d, 133d, 133d, 133d, 132d, 131d, 130d, 128d, 127d, 125d, 124d, 123d, 122d, 121d, 121d, 121d, 121d, 121d, 122d, 123d, 124d, 125d, 127d, 128d, 129d, 130d, 131d, 132d, 132d
DB 133d, 133d, 133d, 132d, 131d, 130d, 129d, 128d, 127d, 126d, 124d, 123d, 123d, 122d, 122d, 121d, 122d, 122d, 123d, 124d, 125d, 126d, 127d, 128d, 129d, 130d, 132d, 132d, 133d, 133d
DB 133d, 132d, 132d, 131d, 130d, 128d, 127d, 126d, 124d, 123d, 122d, 122d, 122d, 121d, 121d, 122d, 122d, 124d, 124d, 125d, 127d, 128d, 129d, 130d, 131d, 132d, 132d, 132d, 132d, 132d
DB 131d, 131d, 130d, 129d, 128d, 126d, 125d, 124d, 123d, 122d, 122d, 121d, 121d, 122d, 122d, 123d, 124d, 125d, 126d, 127d, 128d, 130d, 131d, 131d, 132d, 132d, 133d, 133d, 132d, 132d
DB 131d, 130d, 129d, 128d, 126d, 125d, 124d, 123d, 122d, 122d, 121d, 121d, 121d, 122d, 123d, 124d, 125d, 126d, 128d, 129d, 130d, 131d, 131d, 132d, 132d, 132d, 132d, 132d, 131d, 130d
DB 129d, 128d, 127d, 126d, 125d, 124d, 123d, 123d, 122d, 122d, 122d, 122d, 123d, 123d, 124d, 125d, 126d, 127d, 129d, 130d, 131d, 131d, 132d, 132d, 132d, 132d, 131d, 130d, 128d, 127d
DB 126d, 125d, 123d, 122d, 121d, 119d, 119d, 118d, 117d, 117d, 118d, 117d, 118d, 118d, 118d, 119d, 120d, 120d, 121d, 121d, 122d, 122d, 122d, 122d, 122d, 120d, 120d, 119d, 117d, 116d
DB 115d, 114d, 113d, 112d, 111d, 110d, 109d, 108d, 108d, 108d, 108d, 109d, 109d, 110d, 110d, 110d, 111d, 111d, 112d, 112d, 112d, 111d, 112d, 112d, 111d, 110d, 110d, 109d, 107d, 106d
DB 104d, 103d, 103d, 102d, 101d, 100d, 99d, 99d, 98d, 98d, 99d, 98d, 99d, 99d, 101d, 101d, 101d, 102d, 102d, 102d, 102d, 102d, 102d, 101d, 100d, 100d, 99d, 98d, 97d, 96d
DB 94d, 93d, 92d, 91d, 91d, 91d, 90d, 90d, 90d, 90d, 90d, 91d, 91d, 91d, 91d, 92d, 92d, 92d, 92d, 92d, 91d, 91d, 91d, 90d, 89d, 88d, 87d, 86d, 85d, 84d
DB 84d, 83d, 83d, 82d, 81d, 81d, 81d, 81d, 81d, 81d, 81d, 81d, 81d, 81d, 81d, 81d, 81d, 82d, 81d, 81d, 81d, 80d, 80d, 80d, 79d, 78d, 77d, 76d, 76d, 75d
DB 74d, 73d, 73d, 73d, 72d, 72d, 72d, 71d, 72d, 71d, 72d, 72d, 72d, 72d, 72d, 72d, 72d, 72d, 71d, 71d, 71d, 70d, 70d, 69d, 68d, 68d, 67d, 66d, 66d, 65d
DB 64d, 64d, 63d, 63d, 63d, 62d, 62d, 62d, 62d, 62d, 62d, 62d, 62d, 62d, 62d, 62d, 62d, 61d, 61d, 61d, 60d, 60d, 59d, 59d, 58d, 57d, 57d, 56d, 56d, 55d
DB 55d, 54d, 54d, 53d, 53d, 53d, 53d, 53d, 53d, 53d, 52d, 53d, 52d, 52d, 52d, 52d, 52d, 51d, 51d, 51d, 50d, 49d, 49d, 48d, 48d, 47d, 47d, 47d, 46d, 45d
DB 45d, 45d, 45d, 44d, 44d, 44d, 44d, 43d, 43d, 43d, 43d, 43d, 42d, 42d, 42d, 42d, 41d, 41d, 41d, 40d, 40d, 39d, 39d, 39d, 38d, 37d, 37d, 37d, 36d, 36d
DB 35d, 35d, 35d, 34d, 34d, 34d, 34d, 33d, 33d, 33d, 33d, 33d, 32d, 32d, 32d, 32d, 31d, 31d, 31d, 30d, 30d, 29d, 29d, 28d, 28d, 28d, 27d, 27d, 26d, 26d
DB 26d, 25d, 25d, 25d, 25d, 24d, 24d, 24d, 24d, 23d, 23d, 23d, 23d, 22d, 22d, 22d, 21d, 21d, 20d, 20d, 20d, 19d, 19d, 18d, 18d, 18d, 17d, 17d, 17d, 16d
DB 16d, 16d, 15d, 15d, 15d, 15d, 14d, 14d, 14d, 13d, 13d, 13d, 13d, 12d, 12d, 11d, 11d, 11d, 10d, 10d, 10d, 9d, 9d, 9d, 8d, 8d, 8d, 7d, 7d, 7d
DB 6d, 6d, 6d, 5d, 5d, 5d, 4d, 4d, 4d, 4d, 3d, 3d, 3d, 2d, 2d, 1d, 1d, 1d, 0d, 0d, 0d, 0

END