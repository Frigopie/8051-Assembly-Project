// Nuevo Proyecto//
// EQUS DE PUERTOS//
LUZ equ P1.0
BUZZ equ P1.1
	
	//
	//AQUI APUNTO REGISTROS PARA ACORDARME//
	//R1 y R2, R3 para la luz que parpadea
	// R4 es booleano para ver si ha habido transmision o no
	// R5 es el seguir contado, 256 valores
	// R6, para que cuando se haya entrado en la interrupcion, se altere
    // R7, el registro donde se va a guardar la xor
	
// Inicio tras el reset
		ORG 00H	
		JMP INICIORESET
// iNTERRUPCION 0 LA DEL P0.1

       ORG 0003H
	   JMP INT_0 
	  
// INTERRUPCION 1 PARA ACTIVAR TIMER
     
	  ORG 0013H
	  JMP INT_1		  

// INTERRUPCION TIMER 0, contador
       ORG 000BH
       JMP INT_T0
 	   
		 
// INTERRUPCION SERIE, 
     ORG 0023H
      JMP INT_SERIE		 
		 


      
	   

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	 
	// INICIO
	;---------;
org 100H



INICIORESET:

        CLR TI
		CLR RI
		MOV IP, #0
		MOV SCON,#0
		CLR TR1
		CLR TR0
		MOV TH1,#0
		MOV TL1,#0
       			 
         MOV R4,#0 
         MOV R5, #255 
		 Mov R7, #0
		 mov r6, #0
		 MOV R1, #0
		 MOV R2, #0
		 MOV r3, #0
		 MOV R0, #0
        
		
		CLR BUZZ    		 
   
INICIO: SETB LUZ
JMP ESTADOLUZ  // Como hay 2 funciones que pasan por condicones iniciales (LCD y mismas interrupciones)      
LUZAPAGADA: CLR LUZ
	   	 
ESTADOLUZ:        // Aqui estara la luz encendida o no en funcion de si ha ocurrido transmision o no
        
		MOV IE,   #10000001b  // Activada solo la interrupcion de pulsador
        MOV TCON, #00000101b // Activada por flanco la IE0 // Borra las flags al volve
		MOV TMOD, #00010110b // Timer 1: software, modo temporizador 16b
		                    //  Timer 0: a pulso, modo contador, autorecarga cada 100pulsos
        MOV  TH0, #156        // 256-156= 100+
		MOV	 TL0, #157 // POR QUE NOS COMEMOS 1 solo al principio
   
 
CALL LCD_PRINCIPIO

	 MOV DPTR, #7000h
	 MOV 60H,DPL
	 MOV 61H,DPH
	 

BUCLE: 

CJNE R6,#0,SEPULSAP1
JMP BUCLE
    
SEPULSAP1:

CALL LCD_APAGAR



CJNE R4,#0, TRANSMISION  

PARPADEO:      CPL  LUZ    ;Rutina de tiempo que enciende y apaga LUZ
    MOV R1,#4
S1: MOV R2, #250  // Es  para
S2: MOV R3, #250
S3: DJNZ R3, S3
    DJNZ R2, S2
    DJNZ R1, S1
	
	CJNE R4,#0, LUZAPAGADA
	
	JMP PARPADEO
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////-

INT_0:  
	   
			MOV R6,#01h  //, para que cuando salga de la interrupcion, vaya al parpadeo
        CJNE R4,#0,SALIRINT0
        MOV IE, #10000110b // Apagamos el INT 0 para que no vuelva a entrar, y solo activamos INT 1 , y el timer 0 (contador), para cuando llegue el pulso
        MOV IP, #00000100b // EXT 1 que tenga PRIORIDAD frente a el contador.
   
        	
SALIRINT0: RETI

///////////////////////////////////////////////////////////////////

INT_1:  // Aqui llega el primer flanco de del dato, activandonos el temporizador de 60ms
       
	   MOV TCON, #01010101b ; // Nos activa el temporizador1 por software, y nos detecta por flanco
       MOV IE, #10000010b     ; Nos activamos las interrupciones T1 y T0, pero las externas las quitamos
	   
RETI
		
////- INTERRUPCION MODO CONTADOR // CUANDO LLEGA A 100

INT_T0:          // Esta interrupcion ocurre cuando hay 100 pulsos
    
	   MOV 70H,DPL 
	   MOV 71H,DPH  // Posicion del lcd
	  
	  MOV DPL,60h       // 7000h
	  MOV DPH,61h
     
	  MOV A,TL1
	  MOVX @DPTR, A 
	  INC DPTR
	  MOV A,TH1
	  MOVX @DPTR,A
	  INC DPTR
	

	  MOV 60H,DPL
	  MOV 61H,DPH
	  
	  MOV TL1,#18h //0 el tiempo que ha pasado en esta interrupcion
	  MOV TH1,#0
	  
 	  
	  
	  DJNZ R5,SEGUIRCONTANDO
      
	  MOV R4,#1         // Asi ocurrira transmision
	  MOV R6,#0
	 
	
SEGUIRCONTANDO:	
        
		MOV DPL,70h
	    MOV DPH,71h

		RETI
 
	 		

 
 //////     ////////////////////////  TRANSMISION                    //////////////////////////////////        ///////

TRANSMISION:
      
  	  // uart, modo 3 11 bits: bit de start= 0, 9 bits por maquina, 8 de dato, 9 a eleccion, en nuestro caso = 1, y otro bit más -> 2 bit de stop TB8=1
		
  	MOV PCON, #10000000B //ENCENDIENDO EL smod, PROBRADO CON SMOD SETB
    MOV TH1,  #206 // Baud RATE 1250 //206
   	MOV TL1, #206
	MOV SCON, #11101000b //////transmision en modo 3 con un bit 1 como noveno bit ( dos bit de stop)) 
	
 //CALL LCD_APAGAR	

    MOV DPTR, #7000h // EL LCD NOS HA PODIDO PISAR 
		
	MOV R2,#1
	MOV R1,#255 
	  MOV TCON , #01H	
      MOV TMOD,#00100000B // MODO AUTORECARGA TIMER 1

      MOV IE,#10010000B
	
	SETB TR1
	
	 CLR A								;Borramos el acumulador
     MOVX A, @DPTR					;Copiamos el DPTR al acumulador
	 INC DPTR
	 MOV SBUF, A							;Copiamos en el SBUF el acumulador (
		     

BUCLET: CJNE R1,#0,BUCLET
        CJNE R2,#0,CARGA_R1



  MOV R0,#5H
 CALL LCD_PRINCIPIO
   JMP RECEPCION
         
	//////	 
CARGA_R1:
        MOV R1,#255 
        JMP BUCLET		

///////////////////////////////////////////////////////////////////7
/////////////////interrupcion////////////////////
INT_SERIE:
     
	 CLR TI
	 CLR A
	 
	 DJNZ R1,RETISERIE
	 DJNZ R2,RETISERIE
 
    MOV A,R7  // No hace este dato, he comprobado con un mov R7,A
	MOV SBUF,A

	CLR TR1
      RETI


RETISERIE:  
     
     MOVX A,@DPTR
     INC DPTR
	 MOV SBUF,A
	 XRL A,R7
     MOV R7,A	 
 
		  RETI



///////////////////////////////////////////////////////////////////////
	 
//////////////////////////// RECEPCION + BUZZER ////////////////////////
		
RECEPCION:

      CLR RI
MOV TMOD,#00100000b
MOV TH1, #206
MOV TL1, #206
MOV SCON,#11010100b  /// Recepcion
MOV PCON,#10000000b
MOV	IE, #0
	SETB TR1
	         		;Habilitamos la recepción EN MODO 1 SIN BIT
	MOV PCON, #80h					;SMOD=0
				;Cargamos el puntero



COMPRUEBA_RI: JNB RI,COMPRUEBA_RI


MOV A,SBUF
CLR RI
CLR TR1

CJNE A,#00H, PITAR
JMP INICIORESET 


PITAR:

// PARA QUE SE PUEDA LEER EL MENSAJE DE 00H, ESTO ES MUY INNECESARIO



  MOV R0,#4H
 CALL LCD_PRINCIPIO

MOV TMOD, #00000001B

VOLVER: SETB BUZZ
        CALL FRECUENCIA
        CLR BUZZ
        CALL FRECUENCIA
        JMP VOLVER

FRECUENCIA: MOV TH0,#0FFH        // 65536- 250 cada uno = 65286
            MOV TL0,#006H         // FF06= 65286
            SETB TR0
           
			 
RECARGA:    JNB TF0,RECARGA       // Se queda dando vueltas hasta ver la flag
            CLR TR0
            CLR TF0
            
			SETB BUZZ
				RET                 //  Volvera a la linea original del programa grande donde mirara si hay reset
      
	  /////////////////////////////////////LCD INICIO MAS FUNCIONES////////////////////////////////
	//////
	
LCD_PRINCIPIO: 
	CALL RETARDO
	MOV A,#30H  // 03-> Funcion set con 8bits de dato, 1 linea y fuente normal
	CALL INST_RET
	MOV A,#30H
	CALL INST_RET
	MOV A,#30H
	CALL INST_BUF
	MOV A,#30H
	CALL INST_BUF
	MOV A,#08H     //CLEAR AGAIN
	CALL INST_BUF
	MOV A,#01H        //CLEAR
	CALL INST_BUF
	MOV A,#06H
	CALL INST_BUF
	MOV A,#0FH      // ON, VISIBLE Y PARPADEA
	CALL INST_BUF       /// A PARTIR DE AQUI ESCRIBIMO COSA

  CJNE R0,#0, SEGUNDOMENS
    
	MOV  DPTR, #030H //donde esta nuestro DB
    MOV R1,#19
	JMP TEXTO

SEGUNDOMENS:
CJNE R0,#04H,AQUI
JMP TERCERMENS

AQUI:MOV DPTR, #2500h
MOV R1, #13
JMP TEXTO

TERCERMENS:
MOV R1,#14
MOV DPTR,#2600H

TEXTO:    
		CLR A
		MOVC A, @ A+DPTR
		INC DPTR
		CALL ESC_DATO
       
        DJNZ R1,TEXTO //18 datos
	
	    
		
			RET		
         
///////////////////////////fUNCIONES LCD////

RETARDO: // 20MS


 MOV R2,#250
T_2: MOV R3, #250
T_1:DJNZ R3,T_1
    DJNZ R2,T_2
	
		RET	

INST_RET: 
    MOV DPTR,#4000H
    MOVX @DPTR,A
    CALL RETARDO	
		RET

INST_BUF: 
    MOV DPTR, #4000H
	MOVX @DPTR,A	
 CALL CHECK_BUF
		RET

ESC_DATO:
    
	MOV R2,DPL
	MOV R3,DPH
 	MOV DPTR,#4001H
	MOVX @DPTR,A
	CALL CHECK_BUF
	MOV DPL,R2
	MOV DPH,R3
	RET
       
  
CHECK_BUF:
MOV DPTR, #4002H
F1: MOVX A,@DPTR
   JB ACC.7, F1
	RET
///////////////////
LCD_APAGAR:

	
	CALL INST_BUF
	MOV A,#01H        //CLEAR
	CALL INST_BUF
	MOV A,#06H
	CALL INST_BUF
	MOV A,#0FH      // ON, VISIBLE Y PARPADEA
	
		 RET
 ////////////////////////////////LCD COMO MEMORIA EXTERNA RECORDAR QUE ESTA EN 000010000000... de memoria////////////////////////////////

ORG 030H
			DB 'Pulse el boton 1' //16 letras
ORG 2500H
            DB 'Esperando 00H' 	//13 letras				

ORG 2600H
	        DB 'Alarma Bip-Bip' //14 letras
END