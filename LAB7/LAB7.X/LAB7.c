//File: LAB7
//Dispositivo: PIC16F887
//Autor: Gerardo Fuentes
//Compilador: XC8, MPLABX V5.45

//Programa: contador automático y con interrupción
//Hardware: LEDS Y 7SEG

/*------------------------------------------------------------------------------
                        BITS DE CONFIGURACIÓN
------------------------------------------------------------------------------*/
// PIC16F887 Configuration Bit Settings

// 'C' source line config statements

// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = ON       // RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = ON         // Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

#include <xc.h>
#include <stdio.h>
#include <stdlib.h>



/*------------------------------------------------------------------------------
                       DECLARACIONES Y VARIABLES
------------------------------------------------------------------------------*/
void cfg_io();
void cfg_clk();
void cfg_inte();
void cfg_iocb();
void cfg_t0();
void int_t0();
void int_iocb();
int num = 0;
int num0 = 0;
int num1 = 0;
int num2 = 0;
int disp();



/*------------------------------------------------------------------------------
                              INTERRUPCIONES
------------------------------------------------------------------------------*/
void __interrupt() isr(void){

    if (INTCONbits.T0IF){
        int_t0();
    }
    if (INTCONbits.RBIF){
        int_iocb();
    }
}
void int_t0(){
    
    PORTA = PORTA + 1;
    TMR0 = 0; // 
    INTCONbits.T0IF = 0;
    
    return;
}
void int_iocb(){
    
    if (PORTBbits.RB0 == 0){
        while(PORTBbits.RB0 == 0){
                
            }
        PORTC = PORTC +1;
    }
    if (PORTBbits.RB1 == 0){
        while(PORTBbits.RB1 == 0){
                
            }
        PORTC = PORTC -1;
    }
    return;
}
/*------------------------------------------------------------------------------
                                    MAIN
------------------------------------------------------------------------------*/
void main (void) {
    cfg_io();
    cfg_clk();
    cfg_inte();
    cfg_iocb();
    cfg_t0();
    
    
/*------------------------------------------------------------------------------
                              LOOP PRINCIPAL
------------------------------------------------------------------------------*/
    while(1){  //loop principal   
        decim();
    }
    
    return;
}
/*------------------------------------------------------------------------------
                                 FUNCIONES
------------------------------------------------------------------------------*/
int decim(int num, int num0, int num1, int num2){
   
    num2 = num / 100;
    num = num - (num2*100);
    num1 = num /10;
    num = num - (num1*10);
    num0 = num / 1;
  
    return num2;
    return num1;
    return num0;
}


/*------------------------------------------------------------------------------
                              CONFIG GENERAL
------------------------------------------------------------------------------*/
void cfg_io(){
    ANSEL = 0x00;   //Seteo de inputs como digitales
    ANSELH = 0X00;
    
    TRISB = 0x03; // Pines RB0 y RB1 como inputs
    TRISC = 0x00; // PORTC Y PORTA como salidas
    TRISA = 0X00;

  
    OPTION_REGbits.nRBPU =  0 ; // se habilita el pull up interno en PORTB
    WPUB = 0x03;  //  Pull ups para los pines RB0 y RB1
    
    PORTB = 0x00; // CLEAR de los puertos
    PORTC = 0x00;
    PORTA = 0x00;
   
    
    //return;
}
void cfg_clk(){
    OSCCONbits.IRCF2 = 0; // IRCF = 011 (500kHz) 
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 1;
    OSCCONbits.SCS = 1; //Reloj interno habilitado
    
    return;
}
void cfg_inte(){  
    INTCONbits.GIE = 1; // Habilitar interrupciones globales
    INTCONbits.T0IE = 1; // Habilitar interrupción de t0
    INTCONbits.RBIE = 1; // Habilitar interrupción de B
    INTCONbits.RBIF = 0; // Clear en bandera de B
    INTCONbits.T0IF = 0; // Clear en bandera de t0
    
    return;
}  
void cfg_iocb(){
    IOCB = 0X03 ;        // Habilitar PORTC 0 y 1 para interrupción
    INTCONbits.RBIF = 0; // Clear de la bandera B
    
    return;
    
}
void cfg_t0(){
    OPTION_REGbits.T0CS = 0;
    OPTION_REGbits.PSA = 0;
    OPTION_REGbits.PS2 = 1; // PS 110 = 128
    OPTION_REGbits.PS1 = 1;
    OPTION_REGbits.PS0 = 0;
    
    TMR0 = 250; // N de t0 para 5ms
    INTCONbits.T0IF = 0;
            
    return;
}