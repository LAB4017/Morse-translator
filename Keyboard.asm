    #include p18f87k22.inc
    
    global Column_Setup
    global Row_Setup
    global KeyInput
    global Timer_Setup
    global interrupt_timer
    extern LCD_Send_Byte_D
    global kb_settests
   
acs0    udata_acs   ; named variables in access ram
kb_cnt_l   res 1   ; reserve 1 byte for variable LCD_cnt_l    
kb_cnt_ms  res 1   ; reserve 1 byte for ms counter
kb_cnt_h   res 1   ; reserve 1 byte for variable LCD_cnt_h
kb_tmp	   res 1   ; reserve 1 byte for temporary use
kb_counter res 1   ; reserve 1 byte for counting through message

kb_key	   res 1   ; reserve 1 byte for key output ie whats pressed
kb_col	   res 1   ; res 1 byte for which col
kb_row	   res 1   ; res 1 byte for which row
kb_chnib   res 1   ;res 1 byte for checking if key pushed
kb_temp	   res 1   ;res 1 for temp storing ascii character
kb_temp1   res 1   ;res 1 for temp storing when translating
	   
kb_prtin   res 1   ;res 1 for PORTE input when checking

kb_ascii   res 1    ;res1 for 1st input

kb_key1	   res 1    ;res 1 for 1st key
kb_key2	   res 1    ;res 1 for 2nd key
kb_key3	   res 1    ;res 1 for 3rd key
kb_key4	   res 1    ;res 1 for 4th key
kb_key5	   res 1    ;res 1 for 5th key
kb_key6	   res 1    ;res 1 for 6th key

kb_test1    res 1    ;res 1 for 1st test
kb_test2    res 1    ;res 1 for 2nd test
kb_test3    res 1    ;res 1 for 3rd test
kb_test4    res 1    ;res 1 for 4th test
kb_test5    res 1    ;res 1 for 5th test
kb_test6    res 1    ;res 1 for 6th test
    
kb_check1   res 1    ;res 1 for 1st test, this is the test if translation has happened
kb_check2   res 1    ;res 1 for 2nd test
kb_check3   res 1    ;res 1 for 3rd test
kb_check4   res 1    ;res 1 for 4th test
kb_check5   res 1    ;res 1 for 5th test
kb_check6   res 1    ;res 1 for 6th test
	   
	constant    kb_nokey=0x00   ;0 for checking if nothing pushed
  
Keyboard    code

kb_settests	;set test values for checking if keys have been written to (test) and translated (check)
    movlw   0x01
    movwf   kb_test1	    ;start with kb_test1 with value 0x01
    movwf   kb_check1
    movwf   kb_check2
    movwf   kb_check3
    movwf   kb_check4
    movwf   kb_check5
    movwf   kb_check6
    movlw   0x02
    movwf   kb_test2	    ;start with kb_test1 with value 0x01
    movlw   0x03
    movwf   kb_test3
    movlw   0x04
    movwf   kb_test4
    movlw   0x05
    movwf   kb_test5
    movlw   0x06
    movwf   kb_test6
    return
    
KeyInput	;checks keypad and outputs the ascii into W
    call    Scan    ;returns which row and col in kb_row and kb_col
    call    Key_convert
    movf    kb_key  ;move the binary literal from look up table (and W right now) into kb_key
    return
    
Column_Setup
    banksel PADCFG1
    bsf	    PADCFG1, REPU, BANKED
    clrf    LATE
    
    movlw   0x0F    ;set all cols high
    movwf   TRISE
    movlw   .10
    call    kb_delay_x4us
    return 
    
Row_Setup
    banksel PADCFG1
    bsf	    PADCFG1, REPU, BANKED
    clrf    LATE
    
    movlw   0xF0    ;set all rows high
    movwf   TRISE
    movlw   .10
    call    kb_delay_x4us
    return 
    
Key_convert		;converts key to ascii and stores back in kb_key
    call    Convert
    movwf   kb_key  
    return
    
Scan
    clrf    kb_key	;as should be first time calling scan, make key clear to be written    
    call    Column_Setup	;set all cols high
    
    call    Scan_kb_col
    movff   kb_key, kb_col	;get which column, store in kb_col 
    clrf    kb_key	;clear kb_key again
    
    call    Row_Setup	;set all rows high
    call    Scan_kb_row	;get which row
    movff   kb_key, kb_row  ;get which row, store in kb_row
    clrf    kb_key
    return
    
Scan_kb_col    
    btfss   PORTE, 0	;test col1 if in col1 wont skip and will return to where called
    return
    incf    kb_key	;if not in col1 add 1 to kb_key -- maybe in col2
    btfss   PORTE, 1
    return
    incf    kb_key
    btfss   PORTE, 2
    return
    incf    kb_key
    btfss   PORTE, 3
    return
   
    clrf    kb_key  ;if nothing pressed reset kb_key and check again
    goto    Scan_kb_col	; if no key pressed check again
    return

Scan_kb_row    
   
    btfss   PORTE, 4	;test col1 if in col1 wont skip and will return to where called
    return
    incf    kb_key	;if not in col1 add 1 to kb_key -- maybe in col2
    btfss   PORTE, 5
    return
    incf    kb_key
    btfss   PORTE, 6
    return
    incf    kb_key
    btfss   PORTE, 7
    return
    clrf    kb_key	;clear kb_key and check again
    goto    Scan_kb_row	; if no key pressed check again
    return
    
Check_kb	;routine that checks if key is pushed during interupt routine   
    call    Row_Setup		;set rows high
    movff   PORTE,  kb_chnib	;move the output of PORTE to some f
    swapf   kb_chnib, W		;as we checked rows this is the high nibble, swap to make it low to use it, store result in W
    andlw   0x0f		;take only lower nibble, just incase 1 of cols high, result put in W
    movwf   kb_prtin		;move W to f
    movlw   0x0f
    cpfseq  kb_prtin		;compare lower nibble with number 0x0f (00001111)
    bra	    Check_kb_1		;if key pushed go to what key is
    movlw   0x00		;if key not pushed clear W return
    return			;if same no key pressed return to whatever were doing
Check_kb_1    
    movlw   .20		;if not same add delay to avoid debouncing, 20ms atm
    call    kb_delay_ms
    call    KeyInput		;finds key
    return
    
LUT code    0x1000  ;move far away to prevent overflow
Convert		    ;converts kb_col and kb_row to an ascii character
    clrf    PCLATU  ;make sure PCL is writable
    movlw   0x10
    movwf   PCLATH
    rlncf   kb_col, W  ;move 0-3 to W, corresponding to key from bottom left to top right
    addwf   PCL, F  ;move 0-3 lines depending on kb_col
    bra    Col1_lookup
    bra    Col2_lookup
    bra    Col3_lookup
    bra    Col4_lookup
    return
    

Col1_lookup
    rlncf   kb_row, W  ;move which row to W (0-3)
    addwf   PCL, F  ;move that many lines in code
    retlw   b'110001'	    ;1
    retlw   b'110100'	    ;4 ascii 
    retlw   b'110111'	    ;7 ascii 
    retlw   b'101110'	    ;binary for dot ascii 
    

Col2_lookup    
    rlncf   kb_row, W  ;move which row to W (0-3)
    addwf   PCL, F  ;move that many lines in code
    retlw   b'110010'	    ;2 
    retlw   b'110101'	    ;5
    retlw   b'111000'	    ;8 
    retlw   b'110000'	    ;binary for 0 ascii 
    

Col3_lookup     
    rlncf   kb_row, W  ;move which row to W (0-3)
    addwf   PCL, F  ;move that many lines in code
    retlw   b'110011'	    ;3 retlw  
    retlw   b'110110'	    ;6 retlw  
    retlw   b'111001'	    ;9 ascii
    retlw   b'101101'	    ;dash ascii
    

Col4_lookup     
    rlncf   kb_row, W  ;move which row to W (0-3)
    addwf   PCL, F  ;move that many lines in code
    retlw   b'11011'	    ;esc for now 
    retlw   b'1101'	    ;carriage return
    retlw   b'100000'	    ;space ascii
    retlw   b'1000'	    ;backspace ascii
    
kb_delay_ms		    ; delay given in ms in W
	movwf	kb_cnt_ms
kblp2	movlw	.250	    ; 1 ms delay
	call	kb_delay_x4us	
	decfsz	kb_cnt_ms
	bra	kblp2
	return
    
kb_delay_x4us		    ; delay given in chunks of 4 microsecond in W
	movwf	kb_cnt_l   ; now need to multiply by 16
	swapf   kb_cnt_l,F ; swap nibbles
	movlw	0x0f	    
	andwf	kb_cnt_l,W ; move low nibble to W
	movwf	kb_cnt_h   ; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	kb_cnt_l,F ; keep high nibble in LCD_cnt_l
	call	kb_delay
	return

kb_delay			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
kblp1	decf 	kb_cnt_l,F	; no carry when 0x00 -> 0xff
	subwfb 	kb_cnt_h,F	; no carry when 0x00 -> 0xff
	bc 	kblp1		; carry, then loop again
	return			; carry reset so return
	
Timer_Setup		    ;this enables the clock to start running to constantly interrupt
	movlw	b'10000111'	; Set timer0 to 16-bit, Fosc/4/256
	movwf	T0CON		; = 62.5KHz clock rate, approx 1sec rollover
	bsf	INTCON,TMR0IE	; Enable timer0 interrupt
	bsf	INTCON,GIE	; Enable all interrupts
	return
	
g	code	0x08
interrupt_timer	
	btfss	INTCON, TMR0IF	;cehck if interrupt flag enbaled, skip is set
	retfie	FAST		; if not set return
	nop			;nop for debugging
	call	Check_kb	;if set check, returns key in W
	cpfslt	kb_nokey	;dont write if no key pushed
	bcf	INTCON, TMR0IF	;clear so dont interupt again
	cpfslt	kb_nokey
	retfie	FAST
	
	movwf	kb_temp		;store key temporarily
	call	LCD_Send_Byte_D	;write key to LCD
	movf	kb_temp
	
	tstfsz	kb_test1	;test if value in key1 by checking if value in test1
	call	key1
	
	tstfsz	kb_test2    ;test if we have written to key1 by checking if test2 is zero
	call	key2
	tstfsz	kb_check2   ;test if key2 was enter/morse was translated, if translated skip and bra to rst
	bra	key3write
	bra	interrupt_timer_rst
	
key3write	;used to wrtite to 3rd key variable
	tstfsz	kb_test3
	call	key3
	tstfsz	kb_check3
	bra	key4write
	bra	interrupt_timer_rst
	
key4write
	tstfsz	kb_test4
	call	key4
	tstfsz	kb_check4
	bra	key5write
	bra	interrupt_timer_rst
	
key5write
	tstfsz	kb_test5
	call	key5
	tstfsz	kb_check5
	bra	key6write
	bra	interrupt_timer_rst
	
key6write
	;tstfsz	kb_test6
	;call	key6

interrupt_timer_rst
	bcf	INTCON, TMR0IF	;clear so dont interupt again
	retfie
	


key1	   ;function to move temp key to kb_key1 and decrement kb_test1 so we dont write to key1 after the first loop
	decf	kb_test1	;if key1 is clear, dec (changed to inc as test1 started at 0xff for some reason) test1 to zero so we dont write to key1 next time
	movff	kb_temp, kb_key1
	return

key2	
	decf	kb_test2	
	movff	kb_temp, kb_key2
	movlw	0x0d
	cpfseq	kb_temp
	return
	call	Translate
	call	WriteTranslation
	decf	kb_check2	;check to not translate again if already translated once
	return
	
key3	
	decf	kb_test3	
	movff	kb_temp, kb_key3
	movlw	0x0d
	cpfseq	kb_temp
	return
	call	Translate
	call	WriteTranslation
	decf	kb_check3
	return

key4	
	decf	kb_test4	
	movff	kb_temp, kb_key4
	movlw	0x0d
	cpfseq	kb_temp
	return
	call	Translate
	call	WriteTranslation
	decf	kb_check4
	return
	
key5	
	decf	kb_test5	
	movff	kb_temp, kb_key5
	movlw	0x0d
	cpfseq	kb_temp
	return
	call	Translate
	call	WriteTranslation
	decf	kb_check5
	return
	
key6	
	decf	kb_test6	
	movff	kb_temp, kb_key6
	movlw	0x0d
	cpfseq	kb_temp
	return
	call	Translate
	call	WriteTranslation
	decf	kb_check6
	return
	
WriteTranslation   
	call	LCD_Send_Byte_D
	return
	
binaryto16  ;function to compare keys to dot,dash,enter to aid in translation
;1conv
;	cpfseq	ascii_1			    ;compare with ascii for 1, if not same skip to next if same go to next line
;	bra	1conv
;	retlw	0x00	    ;return with zero for look up table
;2conv
;	cpfseq	ascii_2
;	bra	2conv
;	retlw	0x01	;return with 1 for look up table
dotconv	    ;if key is a dot return with 0x00 in W
	movlw	b'101110'   ;move ascii for dot into W
	cpfseq	kb_temp1
	bra	dashconv   
	retlw	0x00
dashconv    ;if key is dash return with 0x01 in W
	movlw	b'101101'
	cpfseq	kb_temp1
	bra	entconv
	retlw	0x01
entconv	    ;if key is enter return with 0x02 in W
	movlw	b'1101'
	cpfseq	kb_temp1
	return
	retlw	0x02
	
Translate   ;translates after enter key pressed
	clrf	kb_temp1	;clear temp variable
	movff	kb_key1, kb_temp1   ;move key 1 to temp var
	call	binaryto16	;convert key to dot dash or enter, return this to W as 0,1 or 2
	movwf	kb_key1	    ;move W to key 1
	
	clrf	kb_temp1
	movff	kb_key2, kb_temp1
	call	binaryto16
	movwf	kb_key2
	
	clrf	kb_temp1
	movff	kb_key3, kb_temp1
	call	binaryto16
	movwf	kb_key3
	
	clrf	kb_temp1
	movff	kb_key4, kb_temp1
	call	binaryto16
	movwf	kb_key4
	
	clrf	kb_temp1
	movff	kb_key5, kb_temp1
	call	binaryto16
	movwf	kb_key5
	
	clrf	kb_temp1
	movff	kb_key6, kb_temp1
	call	binaryto16
	movwf	kb_key6
	
	call	tablemrs
	return
	
z	code 0x3000
tablemrs	;lookup table for mrs to eng, dot is 0x00 dash is 0x1, return is 0x2
	clrf    PCLATU  ;make sure PCL is writable
	movlw   0x30
	movwf   PCLATH
	rlncf   kb_key1, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dot
	bra	dash
	retlw	b'100001'   ;if enter on first letter return with !, just to throw up error
	
dot ;first input is dot table
	rlncf   kb_key2, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dotdot
	bra	dotdash
	retlw	b'1000101'	;ascii for E
dash	;look up table after 1 dash
	rlncf   kb_key2, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dashdot
	bra	dashdash
	retlw	b'1010100'	;ascii for T
	;2 morse inputs +enter	
dotdot	;look up table after 2 dots
	rlncf   kb_key3, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dotdotdot
	bra	dotdotdash
	retlw	b'1001001'	;ascii for I
dotdash	;look up table after dot dash
	rlncf   kb_key3, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dotdashdot
	bra	dotdashdash
	retlw	b'1000001'	;ascii for A	
dashdot
	rlncf   kb_key3, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dashdotdot
	bra	dashdotdash
	retlw	b'1001110'	;ascii for N
dashdash
	rlncf   kb_key3, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dashdashdot
	bra	dashdashdash
	retlw	b'1001101'	;ascii for M	
	;3 morse inupts +enter
dotdotdot
	rlncf   kb_key4, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dotdotdotdot
	bra	dotdotdotdash
	retlw	b'1010011'	;ascii for S
dotdotdash
	rlncf   kb_key4, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dotdotdashdot
	bra	dotdotdashdash
	retlw	b'1010101'	;ascii for U
dotdashdot
	rlncf   kb_key4, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dotdashdotdot
	retlw	b'100001'   ;ascii for !
	retlw	b'1010010'	;ascii for R
dotdashdash
	rlncf   kb_key4, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dotdashdashdot
	bra	dotdashdashdash
	retlw	b'1010111'	;ascii for W
dashdotdot
	rlncf   kb_key4, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dashdotdotdot
	bra	dashdotdotdash
	retlw	b'1000100'	;ascii for D
dashdotdash
	rlncf   kb_key4, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dashdotdashdot
	bra	dashdotdashdash
	retlw	b'1001011'	;ascii for K
dashdashdot
	rlncf   kb_key4, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dashdashdotdot
	bra	dashdashdotdash
	retlw	b'1000111'	;ascii for G
dashdashdash
	rlncf   kb_key4, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dashdashdashdot
	bra	dashdashdashdash
	retlw	b'1001111'	;ascii for O
	;4 morse input + enter
dotdotdotdot	
	rlncf   kb_key5, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dotdotdotdotdot
	bra	dotdotdotdotdash
	retlw	b'1001000'	;ascii for H	
dotdotdotdash
	rlncf   kb_key5, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dotdotdotdashdot
	bra	dotdotdotdashdash
	retlw	b'1010110'	;ascii for V	
dotdotdashdot
	rlncf   kb_key5, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	retlw	b'100001'	;ascii for ! as no mrs after
	retlw	b'100001'
	retlw	b'1000110'	;ascii for F	
dotdotdashdash
	rlncf   kb_key5, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dotdotdashdashdot
	bra	dotdotdashdashdash
	retlw	b'100001'	;ascii for !
dotdashdotdot
	rlncf   kb_key5, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dotdashdotdotdot
	bra	dotdashdotdotdash
	retlw	b'1001100'	;ascii for L
dotdashdashdot
	rlncf   kb_key5, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	retlw	b'100001'
	retlw	b'100001'
	retlw	b'1010000'	;ascii for P
dotdashdashdash
	rlncf   kb_key5, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dotdashdashdashdot
	bra	dotdashdashdashdash
	retlw	b'1001010'	;ascii for J
	
dashdotdotdot 
	rlncf   kb_key5, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dashdotdotdotdot
	bra	dashdotdotdotdash
	retlw	b'1000010'	;ascii for B
dashdotdotdash
	rlncf   kb_key5, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dashdotdotdashdot
	bra	dashdotdotdashdash
	retlw	b'1011000'	;ascii for X
dashdotdashdot
	rlncf   kb_key5, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dashdotdashdotdot
	bra	dashdotdashdotdash
	retlw	b'1000011'	;ascii for C
dashdotdashdash
	rlncf   kb_key5, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dashdotdashdashdot
	bra	dashdotdashdashdash
	retlw	b'1011001'	;ascii for Y
dashdashdotdot
	rlncf   kb_key5, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dashdashdotdotdot
	bra	dashdashdotdotdash
	retlw	b'1011010'	;ascii for Z
dashdashdotdash
	rlncf   kb_key5, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dashdashdotdashdot
	bra	dashdashdotdashdash
	retlw	b'1010001'	;ascii for Q
dashdashdashdot
	rlncf   kb_key5, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dashdashdashdotdot
	bra	dashdashdashdotdash
	retlw	b'100001'	;ascii for !
dashdashdashdash
	rlncf   kb_key5, W  ;move 0,1 or 2 to W, corresponding to dot dash enter
	addwf	PCL, F
	bra	dashdashdashdashdot
	bra	dashdashdashdashdash
	retlw	b'111111'	;ascii for !
	;5 morse +enter
	
;rest of potential inputs below
dotdotdotdotdot
dotdotdotdotdash
dotdotdotdashdot
dotdotdotdashdash
dotdotdashdotdot
dotdotdashdotdash
dotdashdotdotdot
dotdashdotdotdash
dotdotdashdashdot
dotdotdashdashdash
dotdotdashdashdot
dotdotdashdashdash
dotdashdotdashdot
dotdashdotdashdash
dotdashdashdashdot
dotdashdashdashdash

dashdotdotdotdot
dashdotdotdotdash
dashdotdotdashdot
dashdotdotdashdash
dashdotdashdotdot
dashdotdashdotdash
dashdotdashdashdot
dashdotdashdashdash
dashdashdotdotdot
dashdashdotdotdash
dashdashdotdashdot
dashdashdotdashdash
dashdashdashdotdot
dashdashdashdotdash
dashdashdashdashdot
dashdashdashdashdash


    END