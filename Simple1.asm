	#include p18f87k22.inc

	extern	UART_Setup, UART_Transmit_Message  ; external UART subroutines
	extern  LCD_Setup, LCD_Write_Message, LCD_clear, LCD_Send_Byte_D	    ; external LCD subroutines
	extern  KeyInput
	extern  Row_Setup
	extern	Column_Setup
	extern	LCD_delay_ms
	extern	Timer_Setup
	extern	interrupt_timer
	extern	kb_settests
	
acs0	udata_acs   ; reserve data space in access ram
counter	    res 1   ; reserve one byte for a counter variable
delay_count res 1   ; reserve one byte for counter in the delay routine
kb_ascii    res 3   ;reserve 3 bytes for ascii character?
kb_ascii_1    res 3   ;reserve 3 bytes for ascii character?
    
   ; constant    kb_enter1=0x0d	;set as ascii for enter for check later
    
tables	udata	0x400    ; reserve data anywhere in RAM (here at 0x400)
	
myArray res 0x90    ; reserve 128 bytes for message data

rst	code	0    ; reset vector
	goto	setup

pdata	code    ; a section of programme memory for storing data
	; ******* myTable, data in programme memory, and its length *****
myTable data	    "Res_Cu\n"	; message, plus carriage return
	constant    myTable_l=.7	; length of data
		
myB	data	    "B"	; message, plus carriage return
	;would've used this for inputting duolingo style questions
	constant    myLength=.1	; length of data

main	code
	; ******* Programme FLASH read Setup Code ***********************
setup	bcf	EECON1, CFGS	; point to Flash program memory  
	bsf	EECON1, EEPGD 	; access Flash program memory
	call	kb_settests	;set tests to 0x01
	call	LCD_Setup	; setup LCD
	call	Timer_Setup
	goto	start
	
	; ******* Main programme ****************************************
start 	lfsr	FSR0, myArray	; Load FSR0 with address in RAM	
	movlw	upper(myB)	; address of data in PM
	movwf	TBLPTRU		; load upper bits to TBLPTRU
	movlw	high(myB)	; address of data in PM
	movwf	TBLPTRH		; load high byte to TBLPTRH
	movlw	low(myB)	; address of data in PM
	movwf	TBLPTRL		; load low byte to TBLPTRL
	movlw	myLength	; bytes to read
	movwf 	counter		; our counter register
loop 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter		; count down to zero
	bra	loop		; keep going until finished
	
	call	LCD_clear
	movlw	.40		;delay to let LCD reset
	call	LCD_delay_ms	
	movlw	myLength	; output message to LCD (leave out "\n")
	lfsr	FSR2, myArray
	call	LCD_Write_Message
	
	goto	$

	; a delay subroutine if you need one, times around loop in delay_count
delay	decfsz	delay_count	; decrement until zero
	bra delay
	return

	end
