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
CONFIG  PWRTE = OFF            ; Power-up Timer Enable bit (PWRT enabled)
CONFIG  MCLRE = OFF            ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
CONFIG  CP = OFF               ; Code Protection bit (Program memory code protection is disabled)
CONFIG  CPD = OFF              ; Data Code Protection bit (Data memory code protection is disabled)
CONFIG  BOREN = OFF            ; Brown Out Reset Selection bits (BOR disabled)
CONFIG  IESO = OFF             ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
CONFIG  FCMEN = OFF            ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
CONFIG  LVP = ON               ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
CONFIG  BOR4V = BOR40V         ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
CONFIG  WRT = OFF              ; Flash Program Memory Self Write Enable bits (Write protection off)
  
    
;-------------------------------------------------------------------------------
;                                   MACROS
;-------------------------------------------------------------------------------    
rsttmr0 macro
    clrf	PORTD
    movlw	150        ; Mover la literal 254 a W
    movwf	TMR0       ; Mover W a al TMR0 para inciar conteo
    bcf		T0IF       ; limpiar la bandera siempre
    endm

seg0 macro varin, t, porto ; Macro para display de MSB HEX
    swapf	varin, W
    call	t
    movwf	porto
    endm
    
seg1 macro varin, t, porto ; Macro para display de LSB HEX
    movf	varin, W
    call	t
    movwf	porto
    endm  
;-------------------------------------------------------------------------------
;                                VARIALBLes
;-------------------------------------------------------------------------------
Global W_temp, Status_temp, cont, contaux, vaux, nvar, cdu0, cdu1, cdu2, cdu
PSECT udata_bank0 ; Variables para interrupción 
W_temp:           DS 1    ; Variable para guardar W en interrupt
Status_temp:      DS 1    ; Variable para guardar Status en interrupt
cont:             DS 1    ; Variable para aumentar el tiempo del período
contaux:          DS 1
vaux:             DS 1
nvar:		  DS 1
cdu0:		  DS 1
cdu1:		  DS 1
cdu2:		  DS 1
cdu:		  DS 1

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
    call        incr1
    btfss	PORTB, 1
    call	decr
    bcf		RBIF        ;Clear de la bandera del puerto B
    return  
    
int_t0:                     ; Sub-int TMR0
    rsttmr0
    incf	cont
    movf	cont, w
    call	leds	    ; Sub para enables de displays
    movf	nvar, w
    movwf	PORTC
    return   

incr1:      
    incf	PORTA        ; Subrutina para incrementar displays
    movf	PORTA, W
    movwf	contaux
    return
    
decr:              
    decf	PORTA         ; Subrutina para decrementar displays
    movf	PORTA, w
    movwf	contaux
    return
    
leds:
    clrf	nvar          ; Clear a la variable que entra al PORTC
    movwf	vaux          ; variable auxiliar para WREG
    
    sublw       0x01          ; Subrutina para desplegar BITS 1 por 1
    btfsc	STATUS, 2
    call	intpc1
    movf	vaux, w
    
    sublw       0x02
    btfsc	STATUS, 2
    call	intpc2
    movf	vaux, w
    
    sublw       0x03
    btfsc	STATUS, 2
    call	intpc3
    movf	vaux, w
    
    sublw       0x04
    btfsc	STATUS, 2
    call	intpc4
    movf	vaux, w
   
    sublw       0x05
    btfsc	STATUS, 2
    call	intpc5
    btfsc	STATUS, 2
    clrf	cont
    movf	vaux, w
    return
    
intpc1:                     ; Subrutina para evaluar si se enciende dicho BIT
    movlw	11110B      ; 1RO
    movwf	nvar
    return
intpc2:
    movlw	11101B      ; 2NDO
    movwf	nvar
    return
intpc3:
    movlw	11011B      ; 3RO
    movwf	nvar
    return
intpc4:
    movlw	10111B      ; 4TO
    movwf	nvar
    return
intpc5:
    movlw	01111B      ; 5TO
    movwf	nvar
    return

;-------------------------------------------------------------------------------
;                            Tabla 7seg
;-------------------------------------------------------------------------------   
PSECT code, delta=2, abs   ; Lo que sigue será código y las inst. usan 2 loc.m
ORG 0x100                  ; Selección de localidad de memoria de tbl de conver.
tbl:
    clrf	PCLATH     ; Determinar los 5bits msb del contador
    bsf		PCLATH, 0  ; La cual debe concondar con la descrita en ORG
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
ORG 0x200                  ; Selección de localidad de memoria del main
main:
    call	cfg_io     ; Configuración de io, clk, ioc, inte, t0
    call	cfg_clk
    call	cfg_ioc
    call	cfg_inte
    call	cfg_t0
    clrf	cont
    clrf	vaux
    clrf	nvar
    clrf	cdu0
    
loop:                     ; loop para determinar que se despliega en cada BIT
    btfss	PORTC, 0
    call	primdis
    btfss	PORTC, 1
    call	secodis
    btfss	PORTC, 2
    call	tercdis
    btfss	PORTC, 3
    call	cuardis
    btfss	PORTC, 4
    call	fivedis
    goto	loop
    
;-------------------------------------------------------------------------------
;               SUBRUTINAS DEL LOOP PRINCIPAL
;-------------------------------------------------------------------------------
    
primdis:
    seg0	contaux, tbl, PORTD ; Display de MSB del BINARIO (EN HEX)
    return
secodis:
    seg1	contaux, tbl, PORTD ; Display de LSB del BINARIO (EN HEX)
    return
    
tercdis:                    ; Display de las centenas
    clrf	cdu2
    clrf	cdu1
    clrf	cdu0
    clrf	cdu
    
    movf	contaux, w
    movwf	cdu
    
    movlw	0x64
    subwf	cdu, f
    
    btfss	STATUS, 0
    goto	$+3
    incf	cdu0
    goto	$-4
    
     
    addwf	cdu  
    movlw	0x0A
    subwf	cdu, f
    
    btfss	STATUS, 0
    goto	$+3
    incf	cdu1
    goto	$-4
    
    addwf	cdu
    
    movlw	0x01
    subwf	cdu, f
    
    btfss	STATUS, 0
    goto	$+3
    incf	cdu2
    goto	$-4
    
    movf	cdu0, w
    andlw	0x0f
    call	tbl
    movwf	PORTD

    return

cuardis:                  ; Display de las decenas 
    clrf	cdu2
    clrf	cdu1
    clrf	cdu0
    clrf	cdu
    
    movf	contaux, w
    movwf	cdu
    
    movlw	0x64
    subwf	cdu, f
    
    btfss	STATUS, 0
    goto	$+3
    incf	cdu0
    goto	$-4
    
    addwf	cdu   
    
    movlw	0x0A
    subwf	cdu, f
    
    btfss	STATUS, 0
    goto	$+3
    incf	cdu1
    goto	$-4
    
    addwf	cdu
    
    movlw	0x01
    subwf	cdu, f
    
    btfss	STATUS, 0
    goto	$+3
    incf	cdu2
    goto	$-4
    
    movf	cdu1, w
    andlw	0x0f
    call	tbl
    movwf	PORTD

    return
    
fivedis:                        ; Display de las unidades
    clrf	cdu2
    clrf	cdu1
    clrf	cdu0
    clrf	cdu
    
    movf	contaux, w
    movwf	cdu
    
    movlw	0x64
    subwf	cdu, f
    
    btfss	STATUS, 0
    goto	$+3
    incf	cdu0
    goto	$-4
    
    addwf	cdu   
    
    movlw	0x0A
    subwf	cdu, f
    
    btfss	STATUS, 0
    goto	$+3
    incf	cdu1
    goto	$-4
    
    addwf	cdu
    
    movlw	0x01
    subwf	cdu, f
    
    btfss	STATUS, 0
    goto	$+3
    incf	cdu2
    goto	$-4
    
    movf	cdu2, w
    andlw	0x0f
    call	tbl
    movwf	PORTD

    return


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
    clrf	TRISB      ; Seteo de pines del puerto B como salidas
    bsf		TRISB, 0   ; Seteo de pin como inc
    bsf		TRISB, 1   ; Seteo de pin como dec
    bsf		TRISC, 7   ; Seteo de pines para contador de 5 bits
    bsf		TRISC, 6   ; 
    bsf		TRISC, 5   ; 
    
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

    
    
    
    

