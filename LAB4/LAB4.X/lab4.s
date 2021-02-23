;File: LAB3.s
;Dispositivo: PIC16F887
;Autor: Gerardo Fuentes
;Compilador: pic-as (v2.31), MPLABX V5.45

;Programa: contador en el puerto C Y en puertod 
;Hardware: LEDs en el puerto A, PUSH EN PORTA, 7seg en puertod
    
PROCESSOR 16F887
#include <xc.inc>

; CONFIG1
CONFIG  FOSC = INTRC_NOCLKOUT  ; Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
CONFIG  WDTE = OFF             ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
CONFIG  PWRTE = OFF             ; Power-up Timer Enable bit (PWRT enabled)
CONFIG  MCLRE = OFF            ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
CONFIG  CP = OFF               ; Code Protection bit (Program memory code protection is disabled)
CONFIG  CPD = OFF              ; Data Code Protection bit (Data memory code protection is disabled)
CONFIG  BOREN = OFF            ; Brown Out Reset Selection bits (BOR disabled)
CONFIG  IESO = OFF             ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
CONFIG  FCMEN = OFF             ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
CONFIG  LVP = ON               ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
CONFIG  BOR4V = BOR40V         ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
CONFIG  WRT = OFF              ; Flash Program Memory Self Write Enable bits (Write protection off)
  
    
;-------------------------------------------------------------------------------
;                                   MACROS
;-------------------------------------------------------------------------------    
rsttmr0 macro
    movlw	245        ; Mover la literal 0 a W
    movwf	TMR0       ; Mover W a al TMR0 para inciar conteo
    bcf		T0IF       ; limpiar la bandera siempre
    endm

;-------------------------------------------------------------------------------
;                                VARIALBLes
;-------------------------------------------------------------------------------
PSECT udata_bank0 ; Variables para interrupción 
W_temp:           DS 1    ; Variable para guardar W en interrupt
Status_temp:      DS 1    ; Variable para guardar Status en interrupt
contau:           DS 2    ; Variable para aumentar el tiempo del período
contb7:           DS 1    ; Variable para enviar número a PORTD
 
;-------------------------------------------------------------------------------
;                                VECTOR RESET
;-------------------------------------------------------------------------------
PSECT resVect, class=CODE, abs, delta=2 ; Establecer vector reset para iniciar
ORG 0x00
resetVec:
    goto main

;-------------------------------------------------------------------------------
;                               VECTOR INTERRUPT
;-------------------------------------------------------------------------------
PSECT intVect, class=CODE, abs, delta=2 ; Establecer vector reset para iniciar
ORG 0x04
push:
    movwf	W_temp          ;Guardar W y Status temporalmente
    swapf	STATUS, W
    movwf	Status_temp
    
isr:
    btfsc	RBIF            ;Subrutina de interrupción pullups
    call	int_iocb
    btfsc	T0IF
    call	int_t0
    
pop: 
    swapf	Status_temp, W  ;Regresar a W y Status Guardados
    movwf	STATUS
    swapf	W_temp, f
    swapf	W_temp, w
    retfie
    
;-------------------------------------------------------------------------------
;                       SUBRUTINAS INTERRUPT
;-------------------------------------------------------------------------------    
    
    
int_iocb:                   ;Subrutina de interrupción para el puerto B
    banksel	PORTA       ;Selección de banco
    btfss	PORTB, 0    ;Revisión de inputs, para inc o dec
    call        inca
    btfss	PORTB, 1
    call	deca
    bcf		RBIF        ;Clear de la bandera del puerto B
    return   
    
inca:
    btfss	PORTB, 0    ; Subrutina de incremento que pasa al 7SEG
    goto	$-1
    incf	PORTA
    movf	PORTA, W
    call	tbl
    movwf	PORTC
    return
    
deca:
    btfss	PORTB, 1    ; Subrutina de decremento que pasa al 7SEG
    goto	$-1
    decf	PORTA
    movf	PORTA, W
    call	tbl
    movwf	PORTC
    return
    
int_t0:               
    rsttmr0                  ; Subrutina de TMR0, inicia con reset
    incf	contau       ; Incremento de variable para aumentar período
    movf	contau, w
    sublw	50           ; Factor de multiplicación de incremento de periodo
    btfss	STATUS, 2    ; Revisión de bandera Z para iniciar de nuevo
    goto	$+2
    clrf	contau
    btfsc	STATUS, 2    ; Revisión para aumentar el PORTD (7SEG)
    incf	contb7
    movf	contb7, w
    call	tbl
    movwf	PORTD
    return
    
PSECT code, delta=2, abs   ; Lo que sigue será código y las inst. usan 2 loc.m
ORG 0x200                  ; Selección de localidad de memoria de tbl de conver.
tbl:
    clrf	PCLATH     ; Determinar los 5bits msb del contador
    bsf		PCLATH, 1  ; La cual debe concondar con la descrita en ORG
    andlw	0Fh        ; Dejar pasar únicamente los lsb de W
    addwf	PCL        ; Sumar 8lsb de PC con W para saltar a un número
    retlw	00111111B  ; 0
    retlw	00000110B  ; 1
    retlw	01011011B  ; 2
    retlw	01001111B  ; 3
    retlw       01100110B  ; 4
    retlw	01101101B  ; 5
    retlw	01111101B  ; 6
    retlw	00000111B  ; 7
    retlw	01111111B  ; 8
    retlw	01101111B  ; 9
    retlw	01110111B  ; A
    retlw	01111100B  ; B
    retlw	00111001B  ; C
    retlw	01011110B  ; D
    retlw	01111001B  ; E
    retlw	01110001B  ; F
    
;-------------------------------------------------------------------------------
;               INSTRUCCIONES PRINCIPALES (LOOP PRINCIPAL)
;-------------------------------------------------------------------------------
PSECT code, delta=2, abs   ; Lo que sigue será código y las inst. usan 2 loc.m
ORG 0x100                  ; Selección de localidad de memoria del main
main:
    call	cfg_io     ; Configuración de io, clk, ioc, inte, t0
    call	cfg_clk
    call	cfg_ioc
    call	cfg_inte
    call	cfg_t0
    
loop:
    goto	loop
    
    
;-------------------------------------------------------------------------------
;                      CONFIG (SUBRUTINAS 1ST LEVEL)
;-------------------------------------------------------------------------------

cfg_io:
    banksel	ANSEL      ; Selección banco 10
    clrf	ANSEL      ; Seteo de inputs como digitales
    clrf	ANSELH     
    
    banksel	TRISA      ; Selección banco 01
    clrf	TRISA      ; Seteo del puerto A en todos sus pines como salidas
    clrf        TRISD      ; Seteo del puerto D en todos sus pines como salidas
    clrf        TRISC      ; Seteo del puerto C en todos sus pines como salidas
    ;clrf	TRISB      ; Seteo de pines del puerto B como salidas
    bsf		TRISB, 0   ; Seteo de pin como inc
    bsf		TRISB, 1   ; Seteo de pin como dec
    
    bcf		OPTION_REG, 7 ; Clear de RPUB para poner los pullup
    bsf		WPUB, 0       ; Pull up activado
    bsf		WPUB, 1       ; Pull up activado
    
    banksel	PORTA      ; Selección del banco 00
    clrf	PORTA      ; Setear todos los pines para empezar en 0
    clrf	PORTC
    clrf	PORTD
    return                 ; Regresar automáticamente al main
    
cfg_clk:
    banksel	OSCCON     ; Banco para config del reloj interno (01)
    bcf         IRCF2      ; Seteo de frecuencia a 500kHz (011)
    bsf         IRCF1      ;   "    "     "           "
    bsf		IRCF0      ;   "    "     "           "
    bsf         SCS        ; Selección de reloj interno
    return                 ; Regresar al main
    
cfg_ioc:
    banksel	TRISB      ; Selección del banco 01
    bsf		IOCB, 0    ; Configurar bit como enable para interrupt
    bsf		IOCB, 1    ; " 
    bcf		RBIF       ; Es un bit de INTCONT(que está en todos bancos)
    return
    
cfg_inte:
    bsf		GIE        ; Enable del interrupt global
    bsf		RBIE       ; Enable del change interrupt
    bsf		T0IE
    bcf		RBIF       ; Clear a la bandera de interrupt en b
    return
    
cfg_t0:
    banksel	OPTION_REG ; Selección del banco a trabajar
    bcf		T0CS       ; Selecciónd el reloj a utilizar en tmr0 (interno)
    bcf		PSA        ; Selección del preescaler para el TMR0 y no WDT
    bsf		PS2        ; Selección del preescaler a 1:256 (111 en PS2-0)
    bsf		PS1
    bsf		PS0
    banksel	PORTA      ; regresar al banco del puerto A
    rsttmr0                ; resetear al timer 0 para que inicie su conteo
    return                 ; regresar al main

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
;-------------------------------------------------------------------------------
;                      MACROS NO UTILIZADOS
;-------------------------------------------------------------------------------   
    
    
    ;inca macro por1, por2
;    btfss	por1, 0
;    goto	$-1
;    incf	por2
;    endm
;deca macro por1, por2
;    btfss	por1, 0
;    goto	$-1
;    decf	por2
;    endm
