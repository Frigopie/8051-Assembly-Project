ORG 0
					JMP INICIO
					
					ORG 3h
					JMP INT_0
					
					ORG 23h
					JMP INT_P_S
					
					ORG 40h
INICIO:				
                
                    MOV R1,  #00H
                    
				     
					CLR TR1
					
					
					MOV TMOD, #20h						;Timer en modo 2
					MOV TCON, #1h
					MOV TH1,  #206						;Progaramamos el timer a 9600 baudios
					MOV TL1,  #206
				
					MOV SCON, #11001000b				;Modo 1
					MOV PCON, #10000000h						;SMOD=0
					MOV TCON, #00000001b				;La habilitación de la interrupción 0 será por flanco
					MOV IE, #10010001b					;Habilitamos la interupción cero y el puerto serie
					MOV	IP,	#00010000b					;Priorizamos el puerto serie
					
					
					
FIN:		
           
            JNB P1.0,NoP0	
             MOV R1,#00H
NoP0:	    JNB P1.1,NoP1
             MOV R1,#01H
NoP1:        JMP FIN

					
					ORG 80h
//////////////////////////////
INT_P_S:			
                    CLR TI
					CLR A								
					MOV A, R1				
					MOV SBUF, A	
                    					
					RETI				
////////////////////////////////////					
INT_0:				
                    SETB TR1
					MOV A,R1
					MOV SBUF,A
                    
					MOV R2,#01H				
												
					RETI				
/////////////////////////////////////////////
END