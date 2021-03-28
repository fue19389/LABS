;File: LAB6.s
;Dispositivo: PIC16F887
;Autor: Gerardo Fuentes
;Compilador: pic-as (v2.31), MPLABX V5.45

;Programa: contador automático 7segHEX(2 disp controlado por C) en PORTD
;Hardware: LEDs en el puerto A, que hace parpadear 7seg
    
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
    movlw	254        ; Mover la literal 254 a W
    movwf	TMR0       ; Mover W a al TMR0 para inciar conteo
    bcf		T0IF       ; limpiar la bandera siempre
    endm
    
rsttmr1 macro 
    movlw	0          ; Mover la literal 0 a W
    movwf	TMR1H      ; Mover W a al TMR0 para inciar conteo CAMBIAR A T1
    movwf	TMR1L
    bcf		TMR1IF     ; limpiar la bandera siempre CAMBIAR A T1
    endm
    
rsttmr2 macro
    banksel	PIR1       ; RST TM2 solo baja la bandera
    bcf		TMR2IF
    endm
    
seg1 macro varin, t, porto ; Macro para display de MSB HEX
    swapf	varin, W
    call	t
    movwf	porto
    endm
    
seg0 macro varin, t, porto ; Macro para display de LSB HEX
    movf	varin, W
    call	t
    movwf	porto
    endm  
;-------------------------------------------------------------------------------
;                                VARIALBLes
;-------------------------------------------------------------------------------
Global W_temp, Status_temp, cont, contaux, vaux, nvar, ledinter, cont2, vaux2
PSECT udata_bank0 ; Variables para interrupción 
W_temp:           DS 1    ; Variable para guardar W en interrupt
Status_temp:      DS 1    ; Variable para guardar Status en interrupt
cont:             DS 1    ; Variable para cambiar de valor 7seg (>2ms)
cont2:		  DS 1    ; Variable para encender y apagar 250ms
contaux:          DS 1    ; Variable para contar en HEX
vaux:             DS 1    ; Variable para guardar el número del v.cont T0
vaux2:		  DS 1    ; Variable para guardar el número del v.cont2 T2
nvar:		  DS 1    ; Variable para guardar literal que va a PORTC
ledinter:         DS 1    ; Variable para guardar literal que va a PORTA



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
    btfsc	T0IF            ; Bandera del timer1
    call	int_t0
    btfsc	TMR1IF          ; Bandera del timer0
    call	int_t1
    btfsc	TMR2IF	        ; Bandera del timer2
    call	int_t2
    
pop: 
    swapf	Status_temp, W  ;Regresar a W y Status Guardados
    movwf	STATUS
    swapf	W_temp, f
    swapf	W_temp, w
    retfie
    
;-------------------------------------------------------------------------------
;                       SUBRUTINAS INTERRUPT
;-------------------------------------------------------------------------------    

int_t0:                       ; Sub-int TMR0
    rsttmr0
    incf	cont          ; Incrementar variable para encender PORTC
    movf	cont, w
    call	leds	      ; Sub para revisar cual literal llevar a PORTC
    movf	nvar, w
    movwf       PORTC
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
    
    sublw       0x02
    btfsc	STATUS, 2
    clrf	cont
    return
    
    
intpc1:                     ; Subrutina para evaluar si se enciende dicho BIT
    movlw	01B         ; 1RO
    movwf	nvar
    return
intpc2:
    movlw	10B         ; 2NDO
    movwf	nvar
    return
  
    
int_t1:                     ; Sub-int TMR1 únicamente aumenta el contador
    rsttmr1
    incf	contaux
    return
 
   
int_t2:                     ; Sub-int TMR2 
    rsttmr2                  
    incf	cont2       ; Incremento en la variable para PORTA
    movf	cont2, w
    call	leds2       ; Sub para encender o apagar PORTA Y 7SEG
    movf	ledinter, w
    movwf       PORTA
    return   
    
leds2:
    clrf	ledinter    ; Clear de la variable que va a PORTA
    movwf	vaux2       ; Guardar cont2 para operaciones aritm.
    
    sublw       0x01        ; Sub para encender  
    btfsc	STATUS, 2
    call	ledinter1
    movf	vaux2, w
    
    sublw       0x01          
    btfsc	STATUS, 2
    bsf		T0IE         ; Encender interrupt del T0
    movf	vaux2, w
    
    sublw       0x02         ; Sub para apagar
    btfsc	STATUS, 2
    call	ledinter2
    movf	vaux2, w
    
    sublw       0x02
    btfsc	STATUS, 2
    bcf		T0IE          ; Apagar interrupt del T0
    movf	vaux2, w
    
    sublw       0x02
    btfsc	STATUS, 2
    clrf	cont2
    
    return
    
ledinter1:
    movlw	0x01         ; Encender
    movwf	ledinter
    return
ledinter2: 
    movlw	0x00         ; APAGAR
    movwf	ledinter
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
;                      INSTRUCCIONES PRINCIPALES 
;-------------------------------------------------------------------------------
PSECT code, delta=2, abs   ; Lo que sigue será código y las inst. usan 2 loc.m
ORG 0x200                  ; Selección de localidad de memoria del main
main:
    call	cfg_io     ; Configuración de io, clk, ioc, inte, t0
    call	cfg_clk
    call	cfg_inte
    call	cfg_t0
    call	cfg_t1
    call	cfg_t2
    clrf	cont       ; Clear de las variables
    clrf	cont2
    clrf	vaux
    clrf	nvar
    clrf	contaux
    clrf	ledinter

    
loop:                       ; Revisión de PORTC para dato del TMR1
    btfsc	PORTC, 1
    call	unodis
    btfsc	PORTC, 0
    call	cerodis
    goto	loop

    
;-------------------------------------------------------------------------------
;                        SUBRUTINAS DEL LOOP PRINCIPAL
;-------------------------------------------------------------------------------
    
unodis:
    seg1	contaux, tbl, PORTD ; Display de MSB del BINARIO (EN HEX)
    return
cerodis:
    seg0	contaux, tbl, PORTD ; Display de LSB del BINARIO (EN HEX)
    return
    
;-------------------------------------------------------------------------------
;                               CONFIG GENERAL
;-------------------------------------------------------------------------------

cfg_io:
    banksel	ANSEL      ; Selección banco 10
    clrf	ANSEL      ; Seteo de inputs como digitales
    clrf	ANSELH     
    
    banksel	TRISA      ; Selección banco 01
    clrf	TRISA      ; Seteo del puerto A en todos sus pines como salidas
    clrf	TRISC      ;
    clrf        TRISD      ; Seteo del puerto D en todos sus pines como salidas
    clrf	TRISB      ; Seteo de pines del puerto B como salidas
    bsf		TRISC, 2   ; 
    bsf		TRISC, 3   ; 
    bsf		TRISC, 4   ; 
    bsf		TRISC, 5   ; 
    bsf		TRISC, 6   ;
    bsf		TRISC, 7   ;
 
    
    banksel	PORTA      ; Selección del banco 00
    clrf	PORTA      ; Setear todos los pines para empezar en 0
    clrf	PORTB
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
    
cfg_inte:
    banksel     INTCON
    bsf		GIE        ; Enable del interrupt global
    bsf		PEIE       ; Enable interrupt periferico
    bsf		T0IE       ; Enable global del t0
    
    banksel     PIE1
    bsf		TMR1IE     ; Enable dentro de perifericos t1 
    bsf		TMR2IE     ; Enable dentro de perifericos t2
    
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
    
cfg_t1:
    banksel	T1CON      ; Selección del banco a trabajar
    bcf		TMR1CS     ; Selección del reloj a utilizar en tmr1 (interno) 
    bcf		T1CKPS1    ; Prescaler a 1:2
    bsf		T1CKPS0
    bcf		T1OSCEN    ; Oscilador de bajo voltaje apagado
    bsf		TMR1ON     ; Enable del TMR1
    bcf		TMR1GE     ; Gate option apagado
    banksel	PORTA      ; regresar al banco del puerto A
    rsttmr1                ; resetear al timer 1 para que inicie su conteo
    return                 ; regresar al main

cfg_t2:
    banksel	T2CON
    bsf		TOUTPS3    ; Postscaler a 1:16
    bsf		TOUTPS2
    bsf		TOUTPS1
    bsf		TOUTPS0
    
    bsf		TMR2ON     ; Enable del TMR2
    
    bsf		T2CKPS1    ; prescaler en 00: es decir 1:16
    bsf		T2CKPS0
    
    banksel	PR2        ; Seleccion del valor del PR2
    movlw	61
    movwf	PR2
    
    rsttmr2                ; RESET TMR2 para iniciar
    return
    
    