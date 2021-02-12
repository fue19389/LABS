;File: LAB2.s
;Dispositivo: PIC16F887
;Autor: José Morales
;Compilador: pic-as (v2.31), MPLABX V5.45

;Programa: contador en el puerto A
;Hardware: LEDs en el puerto A
    
PROCESSOR 16F887
#include <xc.inc>
 
; CONFIG1
CONFIG  FOSC = XT             ; Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  
 
    
;-------------------------------------------------------------------------------
;                                VECTOR RESET
;-------------------------------------------------------------------------------
PSECT resVect, class=CODE, abs, delta=2 ; Establecer vector reset para iniciar
resetVec:
    goto main
 

;-------------------------------------------------------------------------------
;               INSTRUCCIONES PRINCIPALES (LOOP PRINCIPAL)
;-------------------------------------------------------------------------------
PSECT code, delta=2        ; Lo que sigue será código y las inst. usan 2 loc.m
ORG 0x100                  ; Selección de localidad de memoria del main
main:
    banksel    ANSEL       ; Colocar todos los input como digitales
    clrf       ANSEL       ;          "                "
    clrf       ANSELH	   ;          "                "  

    banksel    TRISD       ; Selección del PORTD como control maestro
    bsf        TRISD, 0    ;     Activador Incremento LED-BLUE
    bsf        TRISD, 1    ;     Activador Incremento LED-GREEN
    bsf        TRISD, 2    ;     Activador Decremento LED-GREEN
    bsf        TRISD, 3	   ;     Activador Decremento LED-BLUE
    bsf        TRISD, 4    ;     Activador del sumador LED-YELLOW
    
    clrf       TRISC       ; Limitar contador a 4bits (los lsb): PORTC
    bsf        TRISC, 7    ;          "                "               
    bsf        TRISC, 6    ;          "                "  
    bsf        TRISC, 5    ;          "                "  
    bsf        TRISC, 4    ;          "                "  
    
    clrf       TRISA       ; Limitar contador a 4bits (los lsb): PORTA
    bsf        TRISA, 7    ; Entrada OSC1
    bsf        TRISA, 6    ; Entrada OSC2
    bsf        TRISA, 5    ;          "                "
    bsf        TRISA, 4    ;          "                "
    
    clrf       TRISB       ; Limitar adder a 5bits (los lsb): PORTB
    bsf        TRISB, 7    ;          "                "
    bsf        TRISB, 6    ;          "                "
    bsf        TRISB, 5    ;          "                "
    
    
    banksel    PORTB       ; Establecer que todos los puertos inician en 0
    clrf       PORTC       ;          "                "
    clrf       PORTA       ;          "                "
    clrf       PORTB       ;          "                "

    
;-------------------------------------------------------------------------------
;                        Subrutina de activadores
;-------------------------------------------------------------------------------    
cont:
    btfsc      PORTD, 1    ; Revisar el activador-incremento LED-GREEN
    call       incr_pc     ; Si está presionado, ir a subrutina incr LED-GREEN
    btfsc      PORTD, 2    ; si no, revisar el activador-decremento LED-GREEN
    call       decr_pc     ; Si está presionado, ir a subrutina decr LED-GREEN
    btfsc      PORTD, 0    ; si no, revisar el activador-incremento LED-BLUE
    call       incr_pa     ; Si está presionado, ir a subrutina incr LED-BLUE
    btfsc      PORTD, 3    ; si no, revisar el activador-decremento LED-BLUE
    call       decr_pa     ; si está presionado, ir a subrutina decr LED-BLUE
    btfsc      PORTD, 4    ; si no, revisar el activador-adder LED-YELLOW
    call       addr        ; si está presionado, ir a subrutina adder
    goto       cont        ; si no, reiniciar revisión
    
;-------------------------------------------------------------------------------
;                   Incremento-Decremento contador: LED-GREEN
;-------------------------------------------------------------------------------    
incr_pc:
    btfsc      PORTD, 1    ; Si el botón no se ha soltado 
    goto       $-1         ; mantenerse allí para siempre
    incf       PORTC       ; Si se suelta, sumar 1
    return                 ; automáticamente regresar a selección de activador
    
decr_pc:
    btfsc      PORTD, 2    ; Si el botón no se ha soltado
    goto       $-1         ; mantenerse allí para siempre
    decf       PORTC       ; Si se suelta, restar 1
    return                 ; automáticamente regresar a selección de activador

;-------------------------------------------------------------------------------
;                   Incremento-Decremento contador: LED-BLUE
;-------------------------------------------------------------------------------    
incr_pa:
    btfsc      PORTD, 0    ; Si el botón no se ha soltado
    goto       $-1         ; mantenerse allí para siempre 
    incf       PORTA       ; si se suelta, sumar 1
    return                 ; automáticamente regresar a selección de activador
    
decr_pa:
    btfsc      PORTD, 3    ; Si el botón no se ha soltado
    goto       $-1         ; mantenerse allí para siempre
    decf       PORTA       ; si se suelta, restar 1
    return                 ; automáticamente regresar a selección de activador
  
;-------------------------------------------------------------------------------
;               Sumador de ContadorBlue y ContadorGreen: LED-YELLOW
;-------------------------------------------------------------------------------    
addr:
    btfsc      PORTD, 4    ; Si el botón no se ha soltado
    goto       $-1         ; mantenerse allí para siempre
    movf       PORTA, 0    ; si se suelta, mover LED-BLUE(F) a W
    addwf      PORTC, 0    ; luego sumar W con LED-GREEN(F) y mover a W
    movwf      PORTB       ; luego mover W a LED-YELLOW
    return                 ; automáticamente regresar a selección de activador



