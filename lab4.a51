TEMPO1			EQU	0x30

FREQ_COUNTER	EQU 0x31
	
INDICE			EQU	0x40
MODO_ONDA		EQU 0x41; 0-> serra, ff -> seno
AMPLITUDE 		EQU	0x42; 1->5v 2->2.5v 3->1.25v
FREQUENCIA 		EQU	0x43

SIG_OUT			EQU P1

ORG 0x0000
LJMP main

ORG 0x000B
;clr EA ; disable Interrupts
LJMP int_tmr0

ORG 0x2000
int_tmr0:
	;push PSW
	push ACC
	
	djnz FREQ_COUNTER, exit_tmr0
	mov FREQ_COUNTER, FREQUENCIA
	
	mov A, INDICE
	movc A, @A + DPTR
	mov SIG_OUT, A

	inc INDICE
	mov A, INDICE
	; dentro da tabela esreve valor
	cjne A, #200d, exit_tmr0
	mov INDICE, #000h

	;ACALL percorre_tabela

	;ljmp exit_tmr0


exit_tmr0:
	;mov TH0, #0ffh
	;mov TL0, #0ffh

	pop ACC
	;pop PSW

	;SETB EA ; Enable Interrupts

	reti

main:
	mov TMOD, #00100000b
	mov TH1, #0E6h;#0F3h
	mov TCON, #01000000b
	mov PCON, #10000000b
	mov SCON, #01000000b
	setb SCON.4
	mov IE,   #00000000b

	clr TI
	clr RI

	clr TR0
	clr TF0
	SETB EA ; Enable Interrupts

	mov INDICE, #000h
	mov DPTR, #TAB_SENO_5V
	mov MODO_ONDA, #0FFh
	mov AMPLITUDE, #004h ; 1,25V
	mov FREQUENCIA, #004h ; 100Hz
	mov FREQ_COUNTER, FREQUENCIA
	
	anl TMOD, #0F0h
	orl TMOD, #02h
	;mov TL0, #0FFh
	mov TH0, #0E7h
	
	SETB ET0 ; Enable Timer 0 Interrupt
	SETB TR0 ; Start Timer
loop:
	ACALL recebe
	ACALL escreve	
	ACALL update_data
	ljmp loop
	
recebe:
	JNB RI, $
	CLR RI
	MOV A, SBUF
	ret

escreve:
	MOV SBUF, A
	JNB TI, $
	CLR TI
	ret

update_data:
	MOV R1,A
	SUBB A,#045h ; BUG DO ASCII
	JZ mudar_forma_de_onda
	MOV A,R1
	SUBB A,#057h
	JZ aumentar_amplitude
	MOV A,R1
	SUBB A,#052h ; BUG DO ASCII
	JZ diminuir_amplitude
	MOV A,R1
	SUBB A,#040h ; BUG DO ASC
	JZ diminuir_frequencia
	MOV A,R1
	SUBB A,#044h
	JZ aumentar_frequencia
	MOV A,R1
	RET

mudar_forma_de_onda:
	MOV A, MODO_ONDA
	cpl A
	MOV MODO_ONDA, A
	ACALL atualizar_dptr
	ret

aumentar_amplitude:
	mov A, AMPLITUDE
	;CLR C
	RR A
	cjne A, #80h, aumentar_amplitude_1
	mov AMPLITUDE, #001h
	ACALL atualizar_dptr
	ret
aumentar_amplitude_1:
	mov AMPLITUDE, A
	ACALL atualizar_dptr
	ret

diminuir_amplitude:
	MOV A, AMPLITUDE
	;CLR C
	RL A
	cjne A, #008h, diminuir_amplitude_1
	mov AMPLITUDE, #004h
	ACALL atualizar_dptr
	ret
diminuir_amplitude_1:
	mov AMPLITUDE, A
	ACALL atualizar_dptr
	ret

aumentar_frequencia:
	mov A, FREQUENCIA
	;clr C
	RR A
	cjne A, #80h, aumentar_frequencia_1
	mov FREQUENCIA, #001h
	ACALL atualizar_dptr
	ret
aumentar_frequencia_1:
	mov FREQUENCIA, A
	ACALL atualizar_dptr
	ret

diminuir_frequencia:
	mov A, FREQUENCIA
	;CLR C
	RL A
	cjne A, #032d, diminuir_frequencia_1
	mov FREQUENCIA, #016d
	ACALL atualizar_dptr
	ret
diminuir_frequencia_1:
	mov FREQUENCIA, A
	ACALL atualizar_dptr
	ret

atualizar_dptr:
	mov A, MODO_ONDA
	jz atualizar_dptr_serra
	ljmp atualizar_dptr_seno

atualizar_dptr_serra:
	mov Acc, AMPLITUDE
	jb Acc.0, atualizar_dptr_serra_1
	jb Acc.1, atualizar_dptr_serra_2
	jb Acc.2, atualizar_dptr_serra_3
	ret
atualizar_dptr_serra_1:
	mov DPTR, #TAB_SERRA_5V
	ret
atualizar_dptr_serra_2:
	mov DPTR, #TAB_SERRA_2_5V
	ret
atualizar_dptr_serra_3:
	mov DPTR, #TAB_SERRA_1_25V
	ret

atualizar_dptr_seno:
	mov Acc, AMPLITUDE
	jb Acc.0, atualizar_dptr_seno_1
	jb Acc.1, atualizar_dptr_seno_2
	jb Acc.2, atualizar_dptr_seno_3
	ret
atualizar_dptr_seno_1:
	mov DPTR, #TAB_SENO_5V
	ret
atualizar_dptr_seno_2:
	mov DPTR, #TAB_SENO_2_5V
	ret
atualizar_dptr_seno_3:
	mov DPTR, #TAB_SENO_1_25V
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




TAB_SENO_5V:
DB 128d, 131d, 135d, 139d, 143d, 147d, 151d, 155d, 159d, 163d
DB 167d, 171d, 174d, 178d, 182d, 185d, 189d, 192d, 196d, 199d
DB 202d, 205d, 208d, 211d, 214d, 217d, 220d, 223d, 225d, 228d
DB 230d, 233d, 235d, 237d, 239d, 241d, 242d, 244d, 246d, 247d
DB 248d, 249d, 251d, 251d, 252d, 253d, 253d, 254d, 254d, 254d
DB 254d, 254d, 254d, 254d, 253d, 253d, 252d, 251d, 251d, 249d
DB 248d, 247d, 246d, 244d, 242d, 241d, 239d, 237d, 235d, 233d
DB 230d, 228d, 225d, 223d, 220d, 217d, 214d, 211d, 208d, 205d
DB 202d, 199d, 196d, 192d, 189d, 185d, 182d, 178d, 174d, 171d
DB 167d, 163d, 159d, 155d, 151d, 147d, 143d, 139d, 135d, 131d
DB 127d, 124d, 120d, 116d, 112d, 108d, 104d, 100d,  96d,  92d
DB  88d,  84d,  81d,  77d,  73d,  70d,  66d,  63d,  59d,  56d
DB  53d,  50d,  47d,  44d,  41d,  38d,  35d,  32d,  30d,  27d
DB  25d,  22d,  20d,  18d,  16d,  14d,  13d,  11d,   9d,   8d
DB   7d,   6d,   4d,   4d,   3d,   2d,   2d,   1d,   1d,   1d
DB   1d,   1d,   1d,   1d,   2d,   2d,   3d,   4d,   4d,   6d
DB   7d,   8d,   9d,  11d,  13d,  14d,  16d,  18d,  20d,  22d
DB  25d,  27d,  30d,  32d,  35d,  38d,  41d,  44d,  47d,  50d
DB  53d,  56d,  59d,  63d,  66d,  70d,  73d,  77d,  81d,  84d
DB  88d,  92d,  96d, 100d, 104d, 108d, 112d, 116d, 120d, 124d

TAB_SENO_2_5V:
DB  64d,  65d,  67d,  69d,  71d,  73d,  75d,  77d,  79d,  81d
DB  83d,  85d,  87d,  89d,  91d,  92d,  94d,  96d,  98d,  99d
DB 101d, 102d, 104d, 105d, 107d, 108d, 110d, 111d, 112d, 114d
DB 115d, 116d, 117d, 118d, 119d, 120d, 121d, 122d, 123d, 123d
DB 124d, 124d, 125d, 125d, 126d, 126d, 126d, 127d, 127d, 127d
DB 127d, 127d, 127d, 127d, 126d, 126d, 126d, 125d, 125d, 124d
DB 124d, 123d, 123d, 122d, 121d, 120d, 119d, 118d, 117d, 116d
DB 115d, 114d, 112d, 111d, 110d, 108d, 107d, 105d, 104d, 102d
DB 101d,  99d,  98d,  96d,  94d,  92d,  91d,  89d,  87d,  85d
DB  83d,  81d,  79d,  77d,  75d,  73d,  71d,  69d,  67d,  65d
DB  63d,  62d,  60d,  58d,  56d,  54d,  52d,  50d,  48d,  46d
DB  44d,  42d,  40d,  38d,  36d,  35d,  33d,  31d,  29d,  28d
DB  26d,  25d,  23d,  22d,  20d,  19d,  17d,  16d,  15d,  13d
DB  12d,  11d,  10d,   9d,   8d,   7d,   6d,   5d,   4d,   4d
DB   3d,   3d,   2d,   2d,   1d,   1d,   1d,   0d,   0d,   0d
DB   0d,   0d,   0d,   0d,   1d,   1d,   1d,   2d,   2d,   3d
DB   3d,   4d,   4d,   5d,   6d,   7d,   8d,   9d,  10d,  11d
DB  12d,  13d,  15d,  16d,  17d,  19d,  20d,  22d,  23d,  25d
DB  26d,  28d,  29d,  31d,  33d,  35d,  36d,  38d,  40d,  42d
DB  44d,  46d,  48d,  50d,  52d,  54d,  56d,  58d,  60d,  62d

TAB_SENO_1_25V:
DB  32d,  32d,  33d,  34d,  35d,  36d,  37d,  38d,  39d,  40d
DB  41d,  42d,  43d,  44d,  45d,  46d,  47d,  48d,  49d,  49d
DB  50d,  51d,  52d,  52d,  53d,  54d,  55d,  55d,  56d,  57d
DB  57d,  58d,  58d,  59d,  59d,  60d,  60d,  61d,  61d,  61d
DB  62d,  62d,  62d,  62d,  63d,  63d,  63d,  63d,  63d,  63d
DB  63d,  63d,  63d,  63d,  63d,  63d,  63d,  62d,  62d,  62d
DB  62d,  61d,  61d,  61d,  60d,  60d,  59d,  59d,  58d,  58d
DB  57d,  57d,  56d,  55d,  55d,  54d,  53d,  52d,  52d,  51d
DB  50d,  49d,  49d,  48d,  47d,  46d,  45d,  44d,  43d,  42d
DB  41d,  40d,  39d,  38d,  37d,  36d,  35d,  34d,  33d,  32d
DB  31d,  31d,  30d,  29d,  28d,  27d,  26d,  25d,  24d,  23d
DB  22d,  21d,  20d,  19d,  18d,  17d,  16d,  15d,  14d,  14d
DB  13d,  12d,  11d,  11d,  10d,   9d,   8d,   8d,   7d,   6d
DB   6d,   5d,   5d,   4d,   4d,   3d,   3d,   2d,   2d,   2d
DB   1d,   1d,   1d,   1d,   0d,   0d,   0d,   0d,   0d,   0d
DB   0d,   0d,   0d,   0d,   0d,   0d,   0d,   1d,   1d,   1d
DB   1d,   2d,   2d,   2d,   3d,   3d,   4d,   4d,   5d,   5d
DB   6d,   6d,   7d,   8d,   8d,   9d,  10d,  11d,  11d,  12d
DB  13d,  14d,  14d,  15d,  16d,  17d,  18d,  19d,  20d,  21d
DB  22d,  23d,  24d,  25d,  26d,  27d,  28d,  29d,  30d,  31d

TAB_SERRA_5V:
DB   0d,   1d,   2d,   3d,   5d,   6d,   7d,   8d,  10d,  11d
DB  12d,  14d,  15d,  16d,  17d,  19d,  20d,  21d,  22d,  24d
DB  25d,  26d,  28d,  29d,  30d,  31d,  33d,  34d,  35d,  36d
DB  38d,  39d,  40d,  42d,  43d,  44d,  45d,  47d,  48d,  49d
DB  51d,  52d,  53d,  54d,  56d,  57d,  58d,  59d,  61d,  62d
DB  63d,  65d,  66d,  67d,  68d,  70d,  71d,  72d,  73d,  75d
DB  76d,  77d,  79d,  80d,  81d,  82d,  84d,  85d,  86d,  87d
DB  89d,  90d,  91d,  93d,  94d,  95d,  96d,  98d,  99d, 100d
DB 102d, 103d, 104d, 105d, 107d, 108d, 109d, 110d, 112d, 113d
DB 114d, 116d, 117d, 118d, 119d, 121d, 122d, 123d, 124d, 126d
DB 127d, 128d, 130d, 131d, 132d, 133d, 135d, 136d, 137d, 138d
DB 140d, 141d, 142d, 144d, 145d, 146d, 147d, 149d, 150d, 151d
DB 153d, 154d, 155d, 156d, 158d, 159d, 160d, 161d, 163d, 164d
DB 165d, 167d, 168d, 169d, 170d, 172d, 173d, 174d, 175d, 177d
DB 178d, 179d, 181d, 182d, 183d, 184d, 186d, 187d, 188d, 189d
DB 191d, 192d, 193d, 195d, 196d, 197d, 198d, 200d, 201d, 202d
DB 204d, 205d, 206d, 207d, 209d, 210d, 211d, 212d, 214d, 215d
DB 216d, 218d, 219d, 220d, 221d, 223d, 224d, 225d, 226d, 228d
DB 229d, 230d, 232d, 233d, 234d, 235d, 237d, 238d, 239d, 240d
DB 242d, 243d, 244d, 246d, 247d, 248d, 249d, 251d, 252d, 253d

TAB_SERRA_2_5V:
DB   0d,   0d,   1d,   1d,   2d,   3d,   3d,   4d,   5d,   5d
DB   6d,   7d,   7d,   8d,   8d,   9d,  10d,  10d,  11d,  12d
DB  12d,  13d,  14d,  14d,  15d,  15d,  16d,  17d,  17d,  18d
DB  19d,  19d,  20d,  21d,  21d,  22d,  22d,  23d,  24d,  24d
DB  25d,  26d,  26d,  27d,  28d,  28d,  29d,  29d,  30d,  31d
DB  31d,  32d,  33d,  33d,  34d,  35d,  35d,  36d,  36d,  37d
DB  38d,  38d,  39d,  40d,  40d,  41d,  42d,  42d,  43d,  43d
DB  44d,  45d,  45d,  46d,  47d,  47d,  48d,  49d,  49d,  50d
DB  51d,  51d,  52d,  52d,  53d,  54d,  54d,  55d,  56d,  56d
DB  57d,  58d,  58d,  59d,  59d,  60d,  61d,  61d,  62d,  63d
DB  63d,  64d,  65d,  65d,  66d,  66d,  67d,  68d,  68d,  69d
DB  70d,  70d,  71d,  72d,  72d,  73d,  73d,  74d,  75d,  75d
DB  76d,  77d,  77d,  78d,  79d,  79d,  80d,  80d,  81d,  82d
DB  82d,  83d,  84d,  84d,  85d,  86d,  86d,  87d,  87d,  88d
DB  89d,  89d,  90d,  91d,  91d,  92d,  93d,  93d,  94d,  94d
DB  95d,  96d,  96d,  97d,  98d,  98d,  99d, 100d, 100d, 101d
DB 102d, 102d, 103d, 103d, 104d, 105d, 105d, 106d, 107d, 107d
DB 108d, 109d, 109d, 110d, 110d, 111d, 112d, 112d, 113d, 114d
DB 114d, 115d, 116d, 116d, 117d, 117d, 118d, 119d, 119d, 120d
DB 121d, 121d, 122d, 123d, 123d, 124d, 124d, 125d, 126d, 126d

TAB_SERRA_1_25V:
DB   0d,   0d,   0d,   0d,   1d,   1d,   1d,   2d,   2d,   2d
DB   3d,   3d,   3d,   4d,   4d,   4d,   5d,   5d,   5d,   6d
DB   6d,   6d,   7d,   7d,   7d,   7d,   8d,   8d,   8d,   9d
DB   9d,   9d,  10d,  10d,  10d,  11d,  11d,  11d,  12d,  12d
DB  12d,  13d,  13d,  13d,  14d,  14d,  14d,  14d,  15d,  15d
DB  15d,  16d,  16d,  16d,  17d,  17d,  17d,  18d,  18d,  18d
DB  19d,  19d,  19d,  20d,  20d,  20d,  21d,  21d,  21d,  21d
DB  22d,  22d,  22d,  23d,  23d,  23d,  24d,  24d,  24d,  25d
DB  25d,  25d,  26d,  26d,  26d,  27d,  27d,  27d,  28d,  28d
DB  28d,  29d,  29d,  29d,  29d,  30d,  30d,  30d,  31d,  31d
DB  31d,  32d,  32d,  32d,  33d,  33d,  33d,  34d,  34d,  34d
DB  35d,  35d,  35d,  36d,  36d,  36d,  36d,  37d,  37d,  37d
DB  38d,  38d,  38d,  39d,  39d,  39d,  40d,  40d,  40d,  41d
DB  41d,  41d,  42d,  42d,  42d,  43d,  43d,  43d,  43d,  44d
DB  44d,  44d,  45d,  45d,  45d,  46d,  46d,  46d,  47d,  47d
DB  47d,  48d,  48d,  48d,  49d,  49d,  49d,  50d,  50d,  50d
DB  51d,  51d,  51d,  51d,  52d,  52d,  52d,  53d,  53d,  53d
DB  54d,  54d,  54d,  55d,  55d,  55d,  56d,  56d,  56d,  57d
DB  57d,  57d,  58d,  58d,  58d,  58d,  59d,  59d,  59d,  60d
DB  60d,  60d,  61d,  61d,  61d,  62d,  62d,  62d,  63d,  63d

END