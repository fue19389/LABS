//File: LAB9
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
#pragma config PWRTE = ON      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF       // RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = ON      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
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
                       Directivas del preprocesador
------------------------------------------------------------------------------*/
#define _XTAL_FREQ 8000000

/*------------------------------------------------------------------------------
                       DECLARACIONES Y VARIABLES
------------------------------------------------------------------------------*/
void cfg_io();
void cfg_clk();
void cfg_inte();
void cfg_adc();
void cfg_t0();
void cfg_pwm();
void int_pwm();


/*------------------------------------------------------------------------------
                              INTERRUPCIONES
------------------------------------------------------------------------------*/
void __interrupt() isr(void){

    if (PIR1bits.ADIF){       //Revisión bandera ADC
        int_pwm();
    }
}

void int_pwm(){               //Interrupción ADC
    if(ADCON0bits.CHS == 0){  //Primer ciclo de ADC (ADRESH A CCP1)
        CCPR1L = ADRESH;
        }   
    else{                     //Segundo ciclo de ADC (ADRESH A CCP2)
        CCPR2L = ADRESH;  
        }   
    PIR1bits.ADIF = 0;        //Clear de bandera ADC
    
}
/*------------------------------------------------------------------------------
                                    MAIN
------------------------------------------------------------------------------*/
void main () {                //Configuración de PIC en general
    cfg_io();                 
    cfg_clk();         
    cfg_adc();
    cfg_pwm();
    cfg_inte();
    ADCON0bits.GO = 1;        // Inicio externo del loop del ADC
/*------------------------------------------------------------------------------
                              LOOP PRINCIPAL
------------------------------------------------------------------------------*/
    while(1){                 //Loop principal   
        
        if(ADCON0bits.GO == 0){
            if(ADCON0bits.CHS == 1){  //Cambio constante de canal para input
                ADCON0bits.CHS = 0; 
            }
                
            else{
                ADCON0bits.CHS = 1;
            }
              
            __delay_us(50);           //Delay para no traslapar conversiones
            ADCON0bits.GO = 1;
         }        
    }
}



/*------------------------------------------------------------------------------
                              CONFIG GENERAL
------------------------------------------------------------------------------*/
void cfg_io(){      //Configuraciónd entradas y salidas
    ANSELH = 0x00;  
    ANSEL = 0x03;   //Se habilitan RA0 y RA1 como analógicas
    
    TRISB = 0x00;   //Salidas
    TRISC = 0x00;   
    TRISA = 0Xff;   // Entradas RA0 y RA1
    TRISD = 0X00;
    TRISE = 0x00;   

   
}
void cfg_clk(){           //Configuración de reloj
    OSCCONbits.IRCF2 = 1; //IRCF = 111 (8MHz) 
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 1;
    OSCCONbits.SCS = 1;   //Reloj interno habilitado
    
}
void cfg_inte(){         //Configuración interrupciones
    INTCONbits.GIE = 1;  //Enable Interrupciones globales
    INTCONbits.PEIE = 1; //Enable interrupciones perifericas
    PIE1bits.ADIE = 1;   //Enable interrupcion del ADC
    PIR1bits.ADIF = 0;   //Clear bandera del ADC
    
}  
void cfg_adc() {         //Configuración AD
    ADCON1bits.ADFM = 0;    //Justificar a la izquierda
    ADCON1bits.VCFG0 = 0;   //Voltaje de referencia Vss y Vdd
    ADCON1bits.VCFG1 = 0;   
    
    ADCON0bits.ADCS0 = 0;   //ADC clock Fosc/32 para 8Mhz
    ADCON0bits.ADCS1 = 1;   
    ADCON0bits.CHS = 0;     //Canal 0 selecionado para inicar
    __delay_us(50);        //Delay más largo para tiempo necesario de conver.
    ADCON0bits.ADON = 1;    //Encender módulo ADC
    
}
           
void cfg_pwm(){                 // Configuración PWM
    TRISCbits.TRISC1 = 1;       // Seteo de salidas como entradas (xd)
    TRISCbits.TRISC2 = 1; 
    PR2 = 249;                  // N para el TIMER2
    CCP1CONbits.P1M = 0;        // Salida normal, con PORTA modulado
    CCP1CONbits.CCP1M = 0b1100; // Selección de modo PWM
    CCP2CONbits.CCP2M = 0b1100;
    
    CCPR1L = 0x0f ;             // Valores iniciales para CCPx
    CCPR2L = 0x0f ;
    CCP1CONbits.DC1B = 0;       // Modo PWM para LSbs
    CCP2CONbits.DC2B0 = 0;
    CCP2CONbits.DC2B1 = 0;
    
    PIR1bits.TMR2IF = 0;        // Clear bandera TMR2
    T2CONbits.T2CKPS = 0b11;    // Prescaler del TMR2
    T2CONbits.TMR2ON = 1;       // Encendido TMR2
    
    while(PIR1bits.TMR2IF == 0); // Espera hasta que se encienda la bandera
    PIR1bits.TMR2IF = 0;        // Clear bandera
    TRISCbits.TRISC2 = 0;       // Seteo de salidas como tal, para funcionar
    TRISCbits.TRISC1 = 0;
    
    
}
