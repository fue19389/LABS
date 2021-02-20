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
CONFIG  PWRTE = ON             ; Power-up Timer Enable bit (PWRT enabled)
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
;                                VARIALBLE CONT
;-------------------------------------------------------------------------------
PSECT udata_bank0 ; Establecer la variable cont, que servirá para el 
conta:    DS 1     ; funcionamiento de la alarma, de 4bits
 
    
;-------------------------------------------------------------------------------
;                                VECTOR RESET
;-------------------------------------------------------------------------------
PSECT resVect, class=CODE, abs, delta=2 ; Establecer vector reset para iniciar
resetVec:
    goto main

;-------------------------------------------------------------------------------
;                         INSTRUCCIONES GENERALES
;------------------------------------------------------------------------------- 
main:
    call	relojcfg    ; Configuración del reloj a utilizar
    call	cfg_inout   ; Configuración de las entradas y salidas
    call	timer0cfg   ; Configuración del TIMER0
    banksel     PORTA       ; Elegir el puerto A para trabajar
   
loop:
    incf        conta       ; Incrementar la variable conta
    call	rev         ; Ir a subrutinas de revisión
    btfsc	T0IF        ; Testear el overflow del TIMER0
    call	rsttmr0     ; Ir al reset, si hay overflow de TIMERO
    goto        loop        ; Repetir todo el proceso
    

    
;-------------------------------------------------------------------------------
;                         REVISIONES (SUBRUTINAS 1ST LEVEL)
;-------------------------------------------------------------------------------    
rev:
    btfsc      PORTD, 5    ; Revisar el activador-incremento 7SEG
    call       incr_7SEG   ; Si está presionado, ir a subrutina incr_7seg
    btfsc      PORTD, 6    ; si no, revisar el activador-decremento 7SEG
    call       decr_7SEG   ; Si está presionado, ir a subrutina decr_7seg
    call       alarm       ; Ir a verificar el sistema de alarma
    return    
;-------------------------------------------------------------------------------
;                         ACCIONES   (SUBRUINAS  2ND LEVEL)
;-------------------------------------------------------------------------------    
incr_7SEG:
    btfsc      PORTD, 5    ; Si el botón no se ha soltado 
    goto       $-1         ; mantenerse allí para siempre
    incf       PORTB       ; Si se suelta, sumar 1
    movf       PORTB, W	   ; Mover el puerto B a W
    call       tbl         ; Ir a la tabla de conversión
    movwf      PORTC       ; Colocar el nuevo valor de W en el 7seg
    return                 ; automáticamente regresar a revisión 
    
decr_7SEG:
    btfsc      PORTD, 6    ; Si el botón no se ha soltado
    goto       $-1         ; mantenerse allí para siempre
    decf       PORTB       ; Si se suelta, restar 1
    movf       PORTB, W    ; Mover el puerto B a W
    call       tbl         ; Ir a la tabla de conversión
    movwf      PORTC       ; Colocar el nuevo valor de W en el 7seg
    return                 ; Automáticamente regresar a la revisión
    
alarm:
    movwf      PORTB,  0   ; Mover el valor de PORTB a W
    subwf      PORTD,  0   ; Restar al cont de tmr0 el valor del 7seg
    btfsc      STATUS, 2   ; Testear si la operación da 0 (es decir son iguales)
    bsf        PORTA,  0   ; Si es así, encender alarma
    btfsc      STATUS, 2   ; Testear si la operación da 0 (es decir son iguales)
    clrf       conta       ; Si es así, poner en 0 el contador de alarma
    btfsc      STATUS, 2   ; Testear si la operación da 0 (es decir son iguales)
    clrf       PORTD       ; Limpiar el contador de tmr0
    btfsc      STATUS, 2   ; Testear si la operación da 0 (es decir son iguales)
    call       rsttmr0     ; Si es así, resetear el tmr0
    return                 ; Si no es 0, automáticamente regresar a la revisión
;-------------------------------------------------------------------------------
;                   TRANSFORMACIÓN 7SEG (SUBRUTINA 3RD LEVEL)
;-------------------------------------------------------------------------------
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
;                      CONFIG (SUBRUTINAS 1ST LEVEL)
;-------------------------------------------------------------------------------
relojcfg:
    banksel	OSCCON     ; Selección de banco para config del reloj interno
    bcf         IRCF2      ; Seteo de frecuencia a 500kHz (011)
    bsf         IRCF1      ;   "    "     "           "
    bsf		IRCF0      ;   "    "     "           "
    bsf         SCS        ; Selección de reloj interno
    return                 ; Regresar al main
         
cfg_inout:
    banksel	ANSEL      ; Seteo de inputs como digitales
    clrf	ANSEL      
    clrf	ANSELH     
    
    banksel	TRISA      ; Seteo del puerto A como salidas únicamente
    clrf	TRISA
    
    clrf        TRISD      ; Seteo de pines del puerto D como salidas
    bsf		TRISD, 7   ; Seteo de pines del puerto D como entradas
    bsf		TRISD, 6  
    bsf		TRISD, 5
    bsf         TRISD, 4
   
    clrf        TRISC      ; Seteo del puerto C en todos sus pines como salidas
    
    clrf	TRISB      ; Seteo de pines del puerto B como salidas
    bsf		TRISB, 7   ; Seteo de pines del puerto B como entradas
    bsf		TRISB, 6
    bsf		TRISB, 5
    bsf         TRISB, 4
    
    banksel	PORTA      ; Selección del banco para setear pines
    clrf	PORTA      ; Setear todos los pines para empezar en 0
    clrf	PORTB
    clrf	PORTC
    clrf	PORTD
    clrf        conta       ; Seteo del contador de alarma como 0
    return                 ; Regresar automáticamente al main
    
timer0cfg:
    banksel	OPTION_REG ; Selección del banco a trabajar
    bcf		T0CS       ; Selecciónd el reloj a utilizar en tmr0
    bcf		PSA        ; Selección del preescaler para el TMR0 y no WDT
    bsf		PS2        ; Selección del preescaler a 1:256 (111 en PS2-0)
    bsf		PS1
    bsf		PS0
    banksel	PORTA      ; regresar al banco del puerto A
    call	rsttmr0    ; resetear al timer 0 para que inicie su conteo
    return                 ; regresar al main
;-------------------------------------------------------------------------------
;                  RST TIMER0 (SUBRUTINA 2ND & 3RD LEVEL)
;-------------------------------------------------------------------------------    
rsttmr0:
    incf	PORTD      ; Incrementar el valor del PORTD
    movlw	0          ; Mover la literal 0 a W
    movwf	TMR0       ; Mover W a al TMR0 para inciar conteo
    bcf		T0IF       ; limpiar la bandera siempre
    btfsc       conta, 0   ; Si el bit 0 de la variable está en 0 saltar
    bcf         PORTA, 0   ; si no, limpiar la salida del led de alarma 
    return                 ; regresar a main, loop o alarma
        