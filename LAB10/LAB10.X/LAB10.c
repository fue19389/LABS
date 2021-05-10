//File: LAB10
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
#define _XTAL_FREQ 1000000

/*------------------------------------------------------------------------------
                       DECLARACIONES Y VARIABLES
------------------------------------------------------------------------------*/
char menu[96]={0x42,0x54,0x52,0x4F,0x50,0x20,0x72,0x61,0x69,0x62,0x6D,0x61,0x43,
0x20,0x29,0x33,0x28,0x0D,0x41,0x54,0x52,0x4F,0x50,0x20,0x72,0x61,0x69,0x62,0x6D,
0x61,0x43,0x20,0x29,0x32,0x28,0x0D,0x73,0x65,0x72,0x65,0x74,0x63,0x61,0x72,0x61,
0x63,0x20,0x65,0x64,0x20,0x61,0x6E,0x65,0x64,0x61,0x63,0x20,0x72,0x61,0x67,0x65,
0x6C,0x70,0x73,0x65,0x44,0x20,0x29,0x31,0x28,0x0D,0x72,0x61,0x74,0x75,0x63,0x65,
0x6A,0x65,0x20,0x61,0x65,0x73,0x65,0x64,0x20,0x6E,0x6F,0x69,0x63,0x63,0x61,0x20,
0x65,0x75,0x51}; 

char cadena[21]={0x44,0x58,0x20,0x6F,0x64,0x6E,0x75,0x6D,0x20,0x61,0x6C,0x6F,
0x48,0x0D,0x3A,0x61,0x6E,0x65,0x64,0x61,0x43};   //Cadena OP1

char pa[15]={0x3A,0x6F,0x76,0x65,0x75,0x6E,0x20,0x72,0x65,0x74,0x63,0x61,0x72,
0x61,0x43};   // Menú de PORTA

char pb[15]={0x3A,0x6F,0x76,0x65,0x75,0x6E,0x20,0x72,0x65,0x74,0x63,0x61,0x72,
0x61,0x43};   // Display PORTB


char bmenu = 1;      // Bandera menú
char op1 = 0;        // Bandera espera dato PORTA
char op2 = 0;        // Bandera espera dato PORTB
char crctr = 96;     // Puntero para menú 
char crctr1 = 21;    // Puntero para display de cadena
char crctr2 = 15;    // Puntero para display de PORTA
char crctr3 = 15;    // Puntero para display de PORTB


void setup(void);
/*------------------------------------------------------------------------------
                              INTERRUPCIONES
------------------------------------------------------------------------------*/
void __interrupt() isr(void){

    if (PIR1bits.RCIF){                      //Revisión bandera recepción

        TXREG = 12;                          //Clear consola
        
/*INTERRUPCIÓN DE OPCIÓN 2*/        
        if (RCREG == 51){                    // Si presiona 3 en ASCII
            while(crctr3 > 0){               // Loop de cadena
                crctr3 = crctr3-1;           // Cambiar posición de cadena
                TXREG = pb[crctr3];          // Display en virtual terminal
                __delay_ms(1);               // Delay para transmitir datos
            }
            
            TXREG = 0x0D;                    // Realizar enter
            
            op2 = 1;                         // Set bandera caracter
            
            while (op2 == 1){                // Loop para caracter
                if (RCREG != 51){            // Esperar un nuevo dato
                    PORTB = RCREG;           // Envío a PORTB
                    __delay_ms(1500);        // Delay para transmitir
                    op2 = 0;                 // Clear bandera caracter
                }            
            }
            crctr3 = 15;                     // Restauración puntero
        }
        
/*INTERRUPCIÓN DE OPCIÓN 1*/        
        if (RCREG == 50){                    // Si presiona 2 en ASCII
            while(crctr2 > 0){               // Loop cadena
                crctr2 = crctr2-1;           // Cambio posición de cadena
                TXREG = pa[crctr2];     // Display en virtual terminal
                __delay_ms(1);               // Delay para transmitir
            }
            
            TXREG = 0x0D;                    // Realizar Enter
            
            op1 = 1;                         // Set bandera caracter
            
            while (op1 == 1){                // Loop para caracter
                if (RCREG != 50){            // Esperar un nuevo dato
                    PORTA = RCREG;           // Envío a PORTA
                    __delay_ms(1500);        // Delay para transmitir
                    op1 = 0;                 // Clear bandera caracter
                }
            }
            crctr2 = 15;                     // Restauración puntero
        }
        
/*INTERRUPCIÓN DE CADENA NORMAL*/        
        if (RCREG == 49){                    // Si presiona 1 en ASCII
            while(crctr1 > 0){               // Ciclo para menú de PORTB
                crctr1 = crctr1-1;           // Cambiar posición de cadena
                TXREG = cadena[crctr1];      // Display en virtual terminal
                __delay_ms(1);               // Delay para transmitir
            }
            __delay_ms(3000);                // Delay para visualización
            crctr1 = 21;                     // Restauración puntero
        }    
        bmenu = 1;                           // Set para regresar a menú
        
    }
}

/*------------------------------------------------------------------------------
                                    MAIN
------------------------------------------------------------------------------*/
void main (){                            // Configuración de PIC en general
    setup();                 

/*------------------------------------------------------------------------------
                              LOOP PRINCIPAL
------------------------------------------------------------------------------*/
    while(1){                            // Loop principal   
                                         // Delay 
        
        if(PIR1bits.TXIF){               // Bandera TXREG envío
            
            if (bmenu == 1){             // Revisión de bandera para menú
                TXREG = 12;              // Clear consola
                while (crctr > 0){       // Loop de cadena
                    crctr = crctr - 1;   // Cambiar posición de cadena
                    TXREG = menu[crctr]; // Display virtual terminal
                    __delay_ms(1);       // Delay para transmitir
                }
                crctr = 96;              // Restauración del puntero  
                bmenu = 0;               // Clear de bandera menú
            }            
        }        
    }
}


/*------------------------------------------------------------------------------
                              CONFIG GENERAL
------------------------------------------------------------------------------*/
void setup(){      //Configuración de entradas y salidas
    ANSELH = 0x00;  
    ANSEL = 0x00;   //Digitales
    
    TRISA = 0;
    PORTA = 0x00;
    TRISD = 0;   //Salidas
    PORTD = 0x00;
    TRISB = 0;   //Salidas
    PORTB = 0x00;
   

    //Configuración de reloj
    OSCCONbits.IRCF = 0b100; //IRCF = 100 (1MHz) 
    OSCCONbits.SCS = 1;   //Reloj interno habilitado
    
    //Config TX Y RX
    TXSTAbits.SYNC = 0;
    TXSTAbits.BRGH = 1;
    
    BAUDCTLbits.BRG16 = 1;
    
    SPBRG = 25;
    SPBRGH = 0;
    
    RCSTAbits.SPEN = 1;
    RCSTAbits.RX9 = 0;
    RCSTAbits.CREN = 1;
    
    TXSTAbits.TXEN = 1;
            
    
    //Configuración interrupciones
    INTCONbits.GIE = 1;  //Enable Interrupciones globales
    INTCONbits.PEIE = 1; //Enable interrupciones perifericas
    PIE1bits.RCIE = 1;   //Enable interrupcion del UART
    //PIR1bits.RCIF = 0;   //No se puede escribir, es solo lectura
    
}
           

