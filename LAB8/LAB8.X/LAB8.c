//File: LAB8
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
                       Directivas del preprocesador
------------------------------------------------------------------------------*/
#define _XTAL_FREQ 4000000

/*------------------------------------------------------------------------------
                       DECLARACIONES Y VARIABLES
------------------------------------------------------------------------------*/
void cfg_io();
void cfg_clk();
void cfg_inte();
void cfg_adc();
void cfg_t0();
void int_t0();
void int_adc();

char tab7seg[10]={0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x67};
unsigned char num;
unsigned char num0 = 0;
unsigned char num1 = 0;
unsigned char num2 = 0;
unsigned char cont;
unsigned char udisp = 0;
unsigned char ddisp = 0;
unsigned char cdisp = 0;
void decim();



/*------------------------------------------------------------------------------
                              INTERRUPCIONES
------------------------------------------------------------------------------*/
void __interrupt() isr(void){

    if (INTCONbits.T0IF){     //Revisión bandera TIMER0
        int_t0();
    }
    if (PIR1bits.ADIF){       //Revisión bandera ADC
        int_adc();
    }
}
void int_t0(){                //Interrupción TIMER0
    PORTA = 0X00;             //Clear del puertof 
    if (cont == 0X00){        //Primer ciclo display 7seg unidades
        PORTA = udisp;
        PORTB = 0x06;         //Enable del display 7seg unidades
        cont++;               //Incrementar variable de ciclo
    }
    else if (cont == 0X01){   //Segundo ciclo display 7seg decenas
        PORTA = ddisp;
        PORTB = 0x05;         //Enable del display 7seg decenas
        cont++;               //Incrementar variable de ciclo
    }
    else if (cont == 0X02){   //Tercer ciclo display 7seg centenas
        PORTA = cdisp;    
        PORTB = 0x03;         //Enable del display de centenas
        cont = 0x00;          //Clear variable de ciclo
    }
 
    
    TMR0 = 254;               //N para el TIMER0 
    INTCONbits.T0IF = 0;      //Clear la bandera de TIMER0
    
}
void int_adc(){               //Interrupción ADC
    if(ADCON0bits.CHS == 5){  //Primer ciclo de ADC (ADRESH A PUERTO)
        PORTC = ADRESH;
        }   
    else{                     //Segundo ciclo de ADC (ADRESH A PUERTO)
        PORTD = ADRESH;  
        }   
    PIR1bits.ADIF = 0;        //Clear de bandera ADC
    
}
/*------------------------------------------------------------------------------
                                    MAIN
------------------------------------------------------------------------------*/
void main () {                //Configuración de PIC en general
    cfg_io();                 
    cfg_clk();         
    cfg_inte();
    cfg_adc();
    cfg_t0();   
    ADCON0bits.GO = 1;        // Inicio externo del loop del ADC
/*------------------------------------------------------------------------------
                              LOOP PRINCIPAL
------------------------------------------------------------------------------*/
    while(1){                 //Loop principal   
        decim();              //Call para conversión a decimal
        
        if(ADCON0bits.GO == 0){
            if(ADCON0bits.CHS == 6){  //Cambio constante de canal para input
                ADCON0bits.CHS = 5; 
            }
                
            else{
                ADCON0bits.CHS = 6;
            }
              
            __delay_us(50);           //Delay para no traslapar conversiones
            ADCON0bits.GO = 1;
         }        
    }
}
/*------------------------------------------------------------------------------
                                 FUNCIONES
------------------------------------------------------------------------------*/
void decim(void){                    //Función para bionaro -> decimal
    num = PORTD;
    num2 = (num / 100);
    num = (num - (num2*100));
    num1 = (num /10);
    num = num - (num1*10);
    num0 = num;
    
    udisp = tab7seg[num0];
    ddisp = tab7seg[num1];
    cdisp = tab7seg[num2];          
}










/*------------------------------------------------------------------------------
                              CONFIG GENERAL
------------------------------------------------------------------------------*/
void cfg_io(){      //Configuraciónd entradas y salidas
    ANSELH = 0x00;  
    ANSEL = 0x60;   //Se habilitan RE0 y RE1 como analógicas
    
    TRISB = 0x00;   //Salidas
    TRISC = 0x00;   // 
    TRISA = 0X00;
    TRISD = 0X00;
    TRISE = 0x03;   //Entradas RE0 y RE1

    
    PORTB = 0x00;   // CLEAR de los puertos
    PORTC = 0x00;
    PORTA = 0x00;
    PORTD = 0X00;
   
}
void cfg_clk(){           //Configuración de reloj
    OSCCONbits.IRCF2 = 1; //IRCF = 100 (1MHz) 
    OSCCONbits.IRCF1 = 0;
    OSCCONbits.IRCF0 = 0;
    OSCCONbits.SCS = 1;   //Reloj interno habilitado
    
}
void cfg_inte(){         //Configuración interrupciones
    INTCONbits.GIE = 1;  //Enable Interrupciones globales
    INTCONbits.T0IE = 1; //Enable nterrupción de t0
    INTCONbits.PEIE = 1; //Enable interrupciones perifericas
    PIE1bits.ADIE = 1;   //Enable interrupcion del ADC
    PIR1bits.ADIF = 0;   //Clear bandera del ADC
    INTCONbits.T0IF = 0; //Clear en bandera de t0
    
}  
void cfg_adc() {         //Configuración AD
    ADCON1bits.ADFM = 0;    //Justificar a la izquierda
    ADCON1bits.VCFG0 = 0;   //Voltaje de referencia Vss y Vdd
    ADCON1bits.VCFG1 = 0;   
    
    ADCON0bits.ADCS0 = 0;   //ADC clock Fosc/2 para 1Mhz
    ADCON0bits.ADCS1 = 0;   
    ADCON0bits.CHS = 5;     //Canal 5 selecionado para inicar
    __delay_us(100);        //Delay más largo para tiempo necesario de conver.
    ADCON0bits.ADON = 1;    //Encender módulo ADC
    
}
void cfg_t0(){               //Configuración TIMER0
    OPTION_REGbits.T0CS = 0; //Selección reloj interno
    OPTION_REGbits.PSA = 0;  //Prescaler en TIMER0
    OPTION_REGbits.PS2 = 1;  //PS 111 = 256
    OPTION_REGbits.PS1 = 1;
    OPTION_REGbits.PS0 = 1;
    
    TMR0 = 254;             //N de t0 para 5ms
    INTCONbits.T0IF = 0;    //Clear de la bandera TIMER0 
           
}
