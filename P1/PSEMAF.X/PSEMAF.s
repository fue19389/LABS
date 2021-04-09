;File: PSEMAF.s
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
    movlw	254       ; Mover la literal 254 a W
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
    
decimal macro var, dece, uni, comod
    clrf        dece
    clrf	uni
    movf	var, w
    movwf	comod
     
    movlw	0x0A
    subwf	comod, f
    
    btfss	STATUS, 0
    goto	$+3
    incf	dece
    goto	$-4
    
    addwf	comod
    
    movlw	0x01
    subwf	comod, f
    
    btfss	STATUS, 0
    goto	$+3
    incf	uni
    goto	$-4    
    endm
    
prp_dig macro vd1, vd0, t, dgt1, dgt0
    movf	dgt0, w
    call	t
    movwf	vd0
    movf	dgt1, w
    call	t
    movwf	vd1
    endm

rsemaf macro
    movf	temp+1, w
    movwf	lim
    movf	temp+2, w
    movwf	lim+1
    movf	temp+3, w
    movwf	lim+2
    
    movlw	4
    movwf	cont
    movwf	cont+1
    movwf	cont+2
    clrf	ciclo+1
    clrf	ciclo+2
    clrf	ciclo+3
    bcf		TMR2ON
    bcf		PORTA, 0
    bcf		PORTA, 3
    bcf		PORTB, 5
    bcf		PORTA, 1
    bcf		PORTA, 4
    bcf		PORTB, 6
    bsf		ciclo, 0
    endm

;-------------------------------------------------------------------------------
;                                VARIALBLes
;-------------------------------------------------------------------------------
Global W_temp, Status_temp, contaux, vaux2, cont, ciclo, lim
PSECT udata_bank0 ; Variables para interrupción 
W_temp:           DS 1    ; Variable para guardar W en interrupt
Status_temp:      DS 1    ; Variable para guardar Status en interrupt
cont:		  DS 5    ; Variable para encender y apagar 250ms
contaux:          DS 1    ; Variable para contar en HEX
vaux2:		  DS 1    ; Variable para guardar el número del v.cont2 T2
dispvar:          DS 2
dispvar1:         DS 2
dispvar2:         DS 2
dispvar3:         DS 2
banderas:         DS 1
banderas2:        DS 1
cdu:              DS 1
cdu0:             DS 4
cdu1:             DS 4
vaux:		  DS 1
lim:		  DS 3
ciclo:            DS 4
temp:		  DS 4
modo:		  DS 5
cmod:		  DS 1
    



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
    btfsc	RBIF            ;Subrutina de interrupción pullups
    call	int_iocb
    
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
    movlw	0xff
    movwf	PORTC
    incf	banderas
    movf	banderas, w
    
    sublw       0x01          
    btfsc	STATUS, 2
    call	disp0
    movf	banderas, w
    
    sublw       0x02
    btfsc	STATUS, 2
    call	disp1
    movf	banderas, w

    sublw       0x03
    btfsc	STATUS, 2
    call	disp2
    movf	banderas, w
    
    sublw       0x04
    btfsc	STATUS, 2
    call	disp3
    movf	banderas, w
    
    sublw       0x05
    btfsc	STATUS, 2
    call	disp4
    movf	banderas, w
    
    sublw       0x06
    btfsc	STATUS, 2
    call	disp5
    movf	banderas, w
    
    sublw       0x07
    btfsc	STATUS, 2
    call	disp6
    movf	banderas, w
    
    sublw       0x08
    btfsc	STATUS, 2
    call	disp7
    movf	banderas, w
    
    sublw       0x08
    btfsc	STATUS, 2
    clrf	banderas
    return
    
disp0:
    movf	dispvar, w
    movwf	PORTD
    bcf		PORTC, 0
    return	
disp1:
    movf	dispvar+1, w
    movwf	PORTD
    bcf		PORTC, 1
    return    
disp2:
    movf	dispvar1, w
    movwf	PORTD
    bcf		PORTC, 2
    return   
disp3:
    movf	dispvar1+1, w
    movwf	PORTD
    bcf		PORTC, 3
    return    
disp4:
    movf	dispvar2, w
    movwf	PORTD
    bcf		PORTC, 4
    return   
disp5:
    movf	dispvar2+1, w
    movwf	PORTD
    bcf		PORTC, 5
    return
disp6: 
    movf	dispvar3, w
    movwf	PORTD
    bcf		PORTC, 6
    return
disp7: 
    movf	dispvar3+1, w
    movwf	PORTD
    bcf		PORTC, 7
    return
        

    
int_t1:                     ; Sub-int TMR1 únicamente aumenta el contador
    rsttmr1
    decf	cont
    decf	cont+1
    decf	cont+2
    return
 
   
int_t2:                     ; Sub-int TMR2 
    rsttmr2
    btfsc	ciclo+1, 0
    bcf		PORTA, 0
    btfsc	ciclo+2,0
    bcf		PORTA, 3
    btfsc	ciclo+3, 0 
    bcf		PORTB, 5
    btfsc	banderas2, 0
    goto	enc
apg:
    btfsc	ciclo+1, 0
    bcf		PORTA, 0
    btfsc	ciclo+2,0
    bcf		PORTA, 3
    btfsc	ciclo+3, 0
    bcf		PORTB, 5
    goto	cambio
enc:
    btfsc	ciclo+1, 0
    bsf		PORTA, 0
    btfsc	ciclo+2,0
    bsf		PORTA, 3
    btfsc	ciclo+3, 0
    bsf		PORTB, 5
cambio:
    movlw	0x01
    xorwf	banderas2, f
    return    


int_iocb:                   ;Subrutina de interrupción para el puerto B
    banksel	PORTA       ;Selección de banco

    btfss	PORTB, 0    ;Revisión de inputs, para inc o dec
    call        incr1
    btfss	PORTB, 1
    call	decr1
    btfss	PORTB, 2
    call	init

    
    bcf		RBIF        ;Clear de la bandera del puerto B
    return 
 
incr1:                      ; Subrutina para incrementar displays
    btfss	modo+4, 0
    incf	temp 
    btfsc	modo+4, 0
    call	rsmf
    return    
decr1:                      ; Subrutina para decrementar displays
    btfss	modo+4, 0
    decf	temp
    btfsc	modo+4, 0
    nop
    return   
init:
    clrf	modo
    clrf	modo+1
    clrf	modo+2
    clrf	modo+3
    clrf	modo+4
    
    incf	cmod
    movf	cmod, w
    
    sublw       0x01          
    btfsc	STATUS, 2
    call	md1
    movf	cmod, w
    
    sublw       0x02
    btfsc	STATUS, 2
    call	md2
    movf	cmod, w

    sublw       0x03
    btfsc	STATUS, 2
    call	md3
    movf	cmod, w
    
    sublw       0x04
    btfsc	STATUS, 2
    call	md4
    movf	cmod, w
    
    sublw       0x05
    btfsc	STATUS, 2
    call	md5
    movf	cmod, w
    
    sublw       0x05
    btfsc	STATUS, 2
    clrf	cmod
    return
    
md1:
    bsf		modo, 0
    return
md2:
    bsf		modo+1, 0
    return
md3:
    bsf		modo+2, 0
    return
md4:
    bsf		modo+3, 0
    return
md5:
    bsf		modo+4, 0
    return
    
rsmf:
    rsemaf
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
    call	cfg_iocb
    call	cfg_t0
    call	cfg_t1
    call	cfg_t2  
    
    clrf	cont      ; Clear de las variables
    clrf	banderas
    clrf	cdu
    clrf	cdu0
    clrf	cdu1
    clrf	cmod
    
    bsf		ciclo, 0
    clrf	ciclo+1
    clrf	ciclo+2
    clrf	ciclo+3
    
    movlw       10
    movwf	lim
    
    movlw       10
    movwf	lim+1
    
    movlw       10
    movwf	lim+2    
    
    bsf		modo, 0
    
    movlw	3
    movwf	cont
    movwf	cont+1
    movwf	cont+2
    
    movlw	15
    movwf	temp
    


    
;-------------------------------------------------------------------------------
;                         Loop Principal
;-------------------------------------------------------------------------------     

    
loop:                       ; Revisión de PORTC para dato del TMR1
    
sevseg:
    decimal	cont, cdu1, cdu0, cdu
    prp_dig	dispvar+1, dispvar, tbl, cdu1, cdu0
    
    decimal	cont+1, cdu1+1, cdu0+1, cdu
    prp_dig	dispvar1+1, dispvar1, tbl, cdu1+1, cdu0+1
    
    decimal	cont+2, cdu1+2, cdu0+2, cdu
    prp_dig	dispvar2+1, dispvar2, tbl, cdu1+2, cdu0+2
    
    
    
states:
    btfsc	modo, 0
    call	t0
    btfsc	modo+1, 0
    call	t1
    btfsc	modo+2, 0
    call	t2
    btfsc	modo+3, 0
    call	t3
    btfsc	modo+4, 0
    call	t4
    
cicl:         
    btfsc	ciclo, 0
    call	cyclex
    
    btfsc	ciclo+1, 0
    goto	cycle00

    btfsc	ciclo+2,0
    goto	cycle10
 
    btfsc	ciclo+3,0
    goto	cycle20
     
    goto	loop
    
;-------------------------------------------------------------------------------
;                        SUBRUTINAS DEL LOOP PRINCIPAL
;-------------------------------------------------------------------------------
t0:
    movlw	0
    movwf	cont+3
    decimal	cont+3, cdu1+3, cdu0+3, cdu
    prp_dig	dispvar3+1, dispvar3, tbl, cdu1+3, cdu0+3
    return
t1:

    bcf		PORTE, 2
    bsf		PORTE, 0
    movlw	15
    movwf	cont+3
    call	tmslc
    movf	temp, w
    movwf	cont+3
    movwf	temp+1
    
    decimal	cont+3, cdu1+3, cdu0+3, cdu
    prp_dig	dispvar3+1, dispvar3, tbl, cdu1+3, cdu0+3 
    
    return
t2:
    bcf		PORTE, 0
    bsf		PORTE, 1
    movlw	15
    movwf	cont+3
    call	tmslc
    movf	temp, w
    movwf	cont+3
    movwf	temp+2
    
    decimal	cont+3, cdu1+3, cdu0+3, cdu
    prp_dig	dispvar3+1, dispvar3, tbl, cdu1+3, cdu0+3 
    return
t3:
    bcf		PORTE, 1
    bsf		PORTE, 2
    movlw	15
    movwf	cont+3
    call	tmslc
    movf	temp, w
    movwf	cont+3
    movwf	temp+3
    
    decimal	cont+3, cdu1+3, cdu0+3, cdu
    prp_dig	dispvar3+1, dispvar3, tbl, cdu1+3, cdu0+3
    return
t4:
    clrf	PORTE
    movlw	99
    movwf	cont+3
    decimal	cont+3, cdu1+3, cdu0+3, cdu
    prp_dig	dispvar3+1, dispvar3, tbl, cdu1+3, cdu0+3
    return
    
tmslc:    
    movlw	9
    subwf	temp, w
    btfsc	STATUS, 2
    call	down    
    movlw	21
    subwf	temp , w
    btfsc	STATUS, 2
    call	up  
    return
up:
    movlw	10
    movwf	temp
    return
down:
    movlw	20
    movwf	temp
    return
    
cyclex:
    bsf		PORTB, 7
    bsf		PORTA, 2
    bsf		PORTA, 5  
    movlw	0
    subwf	cont   
    btfsc	STATUS, 2
    call	strt
    return
    
cycle00:

    movlw	7
    subwf	cont, w
    
    btfsc	STATUS, 2
    bsf		TMR2ON
   
    movlw	3
    subwf	cont, w
    
    btfsc	STATUS, 2
    call	yell0
 
    movlw	0
    subwf	cont
    
    btfsc	STATUS, 2
    goto	reini00
    goto	loop
    
cycle10:
    movlw	7
    subwf	cont+1, w
    
    btfsc	STATUS, 2
    bsf		TMR2ON
    
    movlw	3
    subwf	cont+1, w
    
    btfsc	STATUS, 2
    call	yell1
       
    movlw	0
    subwf	cont+1
    
    btfsc	STATUS, 2
    goto	reini10
    goto	loop
    
cycle20:

    movlw	7
    subwf	cont+2, w
    
    btfsc	STATUS, 2
    bsf		TMR2ON
    
    movlw	3
    subwf	cont+2, w
    
    btfsc	STATUS, 2
    call	yell2
       
    movlw	0
    subwf 	cont+2
    
    btfsc	STATUS,	2
    goto	reini20
    goto	loop
    
    
reini00:
    bcf		PORTA, 1
    bcf		PORTA, 5
    bsf	        PORTA, 2
    
    bcf		PORTA, 0
    bsf		PORTA, 3
    
    movf	lim+2, w
    addwf	lim+1, w
    movwf	cont
 
    movf	lim+1, w
    movwf	cont+1

    movf	lim+1, w
    movwf	cont+2
    
    clrf	ciclo+1
    bsf		ciclo+2,0
    goto        loop
    
reini10:
    bcf		PORTA, 4
    bcf		PORTB, 7
    bsf		PORTA, 5
    
    bcf		PORTA, 3
    bsf		PORTB, 5
    
    movf	lim+2, w
    movwf	cont    
  
    movf        lim, w
    addwf	lim+2, w
    movwf	cont+1   

    movf	lim+2, w
    movwf	cont+2
    
    clrf	ciclo+2
    bsf		ciclo+3,0
    goto	loop
    
reini20:
    bcf		PORTB, 6
    bcf		PORTA, 2
    bsf		PORTB, 7
    
    bcf		PORTB, 5
    bsf		PORTA, 0
    
    movf	lim, w
    movwf	cont  

    movf        lim, w
    movwf       cont+1

    movf	lim+1,w
    addwf	lim, w
    movwf	cont+2
    
    clrf	ciclo+3
    bsf		ciclo+1,0
    goto	loop
         
yell0:
    bcf		TMR2ON
    bcf		PORTA, 0
    bsf		PORTA, 1
    return
yell1:
    bcf		TMR2ON
    bcf		PORTA, 3
    bsf		PORTA, 4
    return
yell2:
    bcf		TMR2ON
    bcf		PORTB, 5
    bsf		PORTB, 6
    return   
strt:
    bcf		PORTA, 2
    bsf		PORTA, 5
    bsf		PORTA, 0
    bsf		PORTB, 7
    movf	lim, w
    movwf	cont
    movwf	cont+1
    
    movf	lim, w
    addwf	lim+1, w
    movwf	cont+2
    
    bcf		ciclo, 0
    bsf		ciclo+1, 0
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
    clrf	TRISE
    clrf        TRISD      ; Seteo del puerto D en todos sus pines como salidas
    clrf	TRISB      ; Seteo de pines del puerto B como salidas
    bsf		TRISB, 0   ; Seteo de pin como inc
    bsf		TRISB, 1   ; Seteo de pin como dec
    bsf		TRISB, 2   ; Botón de modo
    
    bcf		OPTION_REG, 7 ; Clear de RPUB para poner los pullup
    bsf		WPUB, 0       ; Pull up activado
    bsf		WPUB, 1       ; Pull up activado
    bsf		WPUB, 2
 
    
    banksel	PORTA      ; Selección del banco 00
    clrf	PORTA      ; Setear todos los pines para empezar en 0
    clrf	PORTB
    clrf	PORTC
    clrf	PORTD
    clrf	PORTE
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
    bsf		RBIE       ; Enable del change interrupt
    bcf		RBIF
    
    banksel     PIE1
    bsf		TMR1IE     ; Enable dentro de perifericos t1 
    bsf		TMR2IE     ; Enable dentro de perifericos t2
    
    return
    
cfg_iocb:
    banksel	IOCB       ; Selección del banco 01
    bsf		IOCB, 0    ; Configurar bit como enable para interrupt
    bsf		IOCB, 1    ; " 
    bsf		IOCB, 2
    bcf		RBIF       ; Bandera de interrupt b
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
    
    bcf		TMR2ON     ; Enable del TMR2
    
    bsf		T2CKPS1    ; prescaler en 00: es decir 1:16
    bsf		T2CKPS0
    
    banksel	PR2        ; Seleccion del valor del PR2
    movlw	61
    movwf	PR2
    
    rsttmr2                ; RESET TMR2 para iniciar
    return

    