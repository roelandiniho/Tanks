	processor 6502
	include "vcs.h"
	include "macro.h"	
;------------------------------------------------
	SEG.U variables
	ORG $80
PlayerMvTurn ds 1
P0Y ds 1
P0X ds 1
P1Y ds 1
P1X ds 1
P0Angle ds 1
P1Angle ds 1
P0Hp ds 1
P1Hp ds 1
Misile0Shot ds 1
Misile1Shot ds 1
M0X ds 1
M1X ds 1
M0Y ds 1
M1Y ds 1
M0vx ds 1
M0vy ds 1
M1vx ds 1
M1vy ds 1
FramesSinceM0Shot ds 1
FramesSinceM1Shot ds 1
FramesSinceAP0 ds 1
FramesSinceAP1 ds 1
	SEG
	ORG $027F
;------------------------------------------------
	SEG code 
	ORG $F000
	; reset code from the tutorial http://www.randomterrain.com/atari-2600-memories-tutorial-andrew-davie-12.html
	;   by andrew davies and adapted by Duane Alan Hahn
Reset
	ldx #0		; load number 0 into register x
	txa		; transfer register x to the accumulator
Clear  dex		; decrement x (1st call wraps around to $FF)
	txs		; transfer x to stack pointer
	pha		; push accumulator onto the stack ; on first call stack pointer gets initialized
	bne Clear		; branch if the zero flag is 0.( in this case branch isn't taken until the A=X=0
;------------------------------------------------
	;initialize colours
	lda #$0F	; load hex number 00 into acumulator (colour-lum code from NTFS http://www.qotile.net/minidig/docs/tia_color.html)
	sta COLUPF	  ; store accumulator into COLUPF of TIA: set the playfield colour
	lda #$00
	sta COLUBK
	lda #$42	; load hex number 42 into accumulator
	sta COLUP0	; store accumulator into colup0 of tia: set player one colour
	lda #$98	; load hex number 98 into accumulator
	sta COLUP1	; set player two colout to $98
	lda #%00000001	; load binary number 0000 0001 into accumulator
	sta CTRLPF	  ; store accumulator into ctrlpf: reflect playfield -- playfiel sprite will be mirrored
	lda #$00		; clear PF 
	sta PF0		 ;
	sta PF1		 ;
	sta PF2		 ;
;------------------------------------------------
	; initialize static variables
	;TODO: find correct values for variables depending on the playfield
MisileSize = #$10   ;*
PlayerStartY = #80  ;*
Player0StartX = #20 ;*
Player1StartX = #140;*
PlayerStartHP = #3  ;*
MisileMoveA0X = #3	;*
MisileMoveA0XP1 = #$FD  ;
MisileMoveA30X = #2	;*
MisileMoveA30XP1 = #$FE ;
MisileMoveA45X = #2 ;*
MisileMoveA45XP1 = #$FE ;
MisileMoveA30y = #$FF	;*
MisileMoveA45y = #$FE	;*
gravity = #1	;*
GFrames = #5	;  
;------------------------------------------------
	;initialize player 1 and 2 position
	; started with code from https://atariage.com/2600/programming/2600_101/05joy.html 
	;				  which was then modified
	lda PlayerStartY	; load dec number into accumulator
	sta P0Y		; store accumulator in reg P0Y RAM address assigned by DASM compiler*
	sta P1Y		 ; store accumulator in reg P1Y RAM address*
	lda MisileSize		; load hex number into acc, misile size
	sta NUSIZ0  	; store hex into NUSIZ0, set player one misile number size
	sta NUSIZ1	  ; store hex into NUSIZ1, set player two misile number size
	lda Player0StartX   ;
	sta P0X		 ;*
	lda Player1StartX   ;
	sta P1X		 ;*
	lda PlayerStartHP   ;
	sta P1Hp		;*
	sta P0Hp		;*
	;initialize player 1 and 2 angle
	lda #1		  ;
	sta P0Angle	 ;*
	sta P1Angle	 ;*
	;start with p0
	lda #$00		;
	sta PlayerMvTurn	;*
	sta Misile0Shot	 ;
	sta Misile1Shot	 ;
	sta FramesSinceAP0
	sta FramesSinceAP1
;------------------------------------------------
;   runtime game logic and frame drawing:
StartOfFrame
	;3 vsync lines
	lda #2		  ; load accumulator
	sta VSYNC	   	; store accumulator in vsync reg (set vsync)
	sta WSYNC	   	; wait til start next line
	sta WSYNC 	   	; wait til start next line
	sta WSYNC	   	; wait til start next line
	lda #0		  ; load accumulator
	sta VSYNC 	   	; clear vsync
	;37 vblank lines
	sta WSYNC
	lda #0		  ; 2
	sta VBLANK	  ; 3 minCycl=5
;------------------------------------------------
; Main Computations; check down, up, left, right
; Not effecient code, so made movement change alternate on frame PlayerMvTurn(0,1)
; make sure to improve to true 60 fps if time over
; started with code from https://atariage.com/2600/programming/2600_101/05joy.html which was then modified
;NOP's are empty time... try to avoid them?
;branches when taken use 3 clocks, but only by not taking them does the max increase so 2 is fine. Also the amount of branches
;isn't enough to catch op to the maxCycl value so as long as wsync happen before 73rd clock in a line a wsync will catch both up.
;------------------------------------------------
;Collisions
	;players   
	bit CXP0FB	  ; 3 minCycl=8
	bpl noP0Collision  ; 2 minCycl=10 
	dec P0Y		 ; 5 minCycl=10 maxCycl=15
	jmp endP0PFCollision   ; 5 minCycl=10 maxCycl=20
noP0Collision	  
	inc P0Y		 ; 5 minCycl=15 maxCycl=25
	nop		 ; 2 
	nop		 ; 2
	nop		 ; 2
	nop		 ; 2
	nop		 ; 2 minCycl=25 maxCycl=25
endP0PFCollision
	bit CXP1FB	  ; 3 minCycl=28 maxCycl=28
	bpl noP1Collision  ; 2 mincycl=30 maxCycl=30
	dec P1Y		 ; 5 minCycl=30 maxCycl=35
	jmp endP1PFCollision   ; 5 minCycl=30 maxCycl=40
noP1Collision
	inc P1Y		 ; 5 minCycl=30 maxCycl=40
	nop		 ; 2 
	nop		 ; 2
	nop		 ; 2
	nop		 ; 2
	nop		 ; 2 minCycl=40 maxCycl=40
endP1PFCollision
	bit CXPPMM	  ; 3 minCycl=43 maxCycl=43
	bpl noP0P1Collision; 2 minCycl=45 maxCycl=45
	dec P0X		 ; 5 minCycl=45 maxCycl=50
	inc P1X		 ; 5 minCycl=45 maxCycl=55
noP0P1Collision
	sta WSYNC	   ; 3 minCycl=1.1 maxCycl=1.1
	;minCycl=45 maxCycl=55
	;Misiles
	;M0 P1
	bit CXM0P	   ; 3 minCycl=1.3 maxCycl=1.3
	bpl NoM0P1collision; 2 minCycl=1.5 maxCycl=1.5
	lda #$00		; 2 minCycl=1.5 maxCycl=1.7
	sta Misile0Shot	 ; 3 minCycl=1.5 maxCycl=1.10
	lda #$02		; 2 minCycl=1.5 maxCycl=1.12
	sta RESMP0	  ; 3 minCycl=1.5 maxCycl=1.15
	dec P1Hp		; 5 minCycl=1.5 maxCycl=1.20
NoM0P1collision
	;M0 PF
	bit CXM0FB	  ; 3 minCycl=1.8 maxCycl=1.23
	bpl NoM0PFcollision; 2 minCycl=1.10 maxCycl=1.25
	lda #$02		; 2 minCycl=1.10 maxCycl=1.27
	sta RESMP0	  ; 3 minCycl=1.10 maxCycl=1.30
	lda #$00		; 2 minCycl=1.10 maxCycl=1.32
	sta Misile0Shot	 ; 3 minCycl=1.10 maxCycl=1.35
NoM0PFcollision
	;M0 M1
	bit CXPPMM	  ; 3 minCycl=1.13 maxCycl=1.35
	bvc NoM0M1collisions   ; 2 minCycl=1.15 maxCycl=1.37
	lda #$02		; 2 minCycl=1.15 maxCycl=1.39
	sta RESMP0	  ; 3 minCycl=1.15 maxCycl=1.42
	sta RESMP1	  ; 3 minCycl=1.15 maxCycl=1.45
	lda #$00		; 2 minCycl=1.15 maxCycl=1.47
	sta Misile0Shot	 ; 3 minCycl=1.15 maxCycl=1.50
	sta Misile1Shot	 ; 3 minCycl=1.15 maxCycl=1.53
NoM0M1collisions
	sta WSYNC	   ; 3 minCycl=2.1 maxCycl=2.1
	;M1 P0
	bit CXM1P	   ; 3 minCycl=2.4 maxCycl=2.4
	bpl NoM1P0collisions   ; 2 minCycl=2.6 maxCycl=2.6
	lda #$00		; 2 minCycl=2.6 maxCycl=2.8
	sta Misile1Shot	 ; 3 minCycl=2.6 maxCycl=2.11
	lda #$02		; 2 minCycl=2.6 maxCycl=2.13
	sta RESMP1	  ; 3 minCycl=2.6 maxCycl=2.16
	dec P0Hp		; 5 minCycl=2.6 maxCycl=2.21
NoM1P0collisions
	;M1 PF
	bit CXM1FB	  ; 3 minCycl=2.9 maxCycl=2.24
	bpl NoM1PFcollisions   ; 2 minCycl=2.11 maxCycl=2.26
	lda #$00		; 2 minCycl=2.11 maxCycl=2.28
	sta Misile1Shot	 ; 3 minCycl=2.11 maxCycl=2.31
	lda #$02		; 2 minCycl=2.11 maxCycl=2.33
	sta RESMP1	  ; 3 minCycl=2.11 maxCycl=2.36
NoM1PFcollisions
	sta WSYNC	   ; 3 minCycl=3.1 maxCycl=3.1
; change Player turn: artificial 30 fps, can be removed, we'll see
	lda #0		  ; 2 minCycl=3.3 maxCycl=3.3
	cmp PlayerMvTurn	; 3 minCycl=3.6 maxCycl=3.6
	beq inbetween	; 2 minCycl=3.8 maxCycl=3.8
	dec PlayerMvTurn	; 5 minCycl=3.13 maxCycl=3.13
;------------------------------------------------	
;Movement code (joystick plus automated missiles)
;   Player0Turn 
	; change angle Down?
	lda FramesSinceAP0  ; 3 min max + 3
	cmp #0		  ; 3 +6
	beq changeAngleP0	
	cmp #5
	beq changeAngleP0  ; +8
	inc FramesSinceAP0  ; +13
	jmp Player1TurnEnd
changeAngleP0
	lda #0
	sta FramesSinceAP0  
	lda #%00010000	  ; 2 minCycl=3.15 maxCycl=3.15
	bit SWCHA	   ; 3 minCycl=3.18 maxCycl=3.18
	bne DNLowerAangleP0; 2 minCycl=3.20 maxCycl=3.20
	lda #0		  ; 2 minCycl=3.20 maxCycl=3.22
	CMP P1Angle	 ; 3 minCycl=3.20 maxCycl=3.25
	beq DNLowerAangleP0; 2 minCycl=3.20 maxCycl=3.27
	dec P0Angle	 ; 5 minCycl=3.20 maxCycl=3.32 deltaminmax = 10
	lda #1		  ; 2 maxCycl+2
	sta FramesSinceAP0  ; 3 maxCycle+5
DNLowerAangleP0		
	sta WSYNC	   ; 4.1
	; change angle Up?
	lda #%00100000	  ; 2 minCycl=3.22 maxCycl=3.34
	bit SWCHA	   ; 3 minCycl=3.25 maxCycl=3.37
	bne DNIncAngleP0   ; 2 minCycl=3.27 maxCycl=3.39
	lda #2		  ; 2 minCycl=3.27 maxCycl=3.41
	CMP P0Angle	 ; 3 minCycl=3.27 maxCycl=3.44
	beq DNIncAngleP0   ; 2 mincycl=3.27 maxCycl=3.46
	inc P0Angle	 ; 5 minCycl=3.27 maxCycl=3.51 deltaminmax = 20
	lda #1		  ; 2 maxCycl+7
	sta FramesSinceAP0  ; 3 maxCycle+10
	jmp endinbetween
DNIncAngleP0	
inbetween
    jmp Player1Turn
endinbetween
	sta WSYNC	   ; 3 minCycl=4.1 maxCycl=4.1 + 1 line
	; Right?
	lda #%10000000		; 2 minCycl=4.3 maxCycl=4.3
	bit SWCHA	   ; 3 minCycl=4.6 maxCycl=4.6
	bne DoNotMoveRightP0   ; 2 minCycl=4.8 maxCycl=4.8
	lda #151		; 2 minCycl=4.8 maxCycl=4.10
	cmp P0X		 ; 3 mincycl=4.8 maxCycl=4.13
	beq DoNotMoveRightP0	; 2 minCycl=4.8 maxCycl=4.15
	inc P0X		 ; 5 minCycl=4.8 maxCycl=4.20 deltaminmax=7
DoNotMoveRightP0	   
	; Left?
	lda #%01000000		; 2 minCycl=4.10 maxCycl=4.22
	bit SWCHA	   ; 3 minCycl=4.13 maxCycl=4.25
	bne DoNotMoveLeftP0; 2 minCycl=4.15 maxCycl=4.27
	lda #1		  ; 2 minCycl=4.15 maxCycl=4.29
	cmp P0X		 ; 3 minCycl=4.15 maxCycl=4.32
	beq DoNotMoveLeftP0; 2 minCycl=4.15 maxCycl=4.34
	dec P0X		 ; 5 minCycl=4.15 maxCycl=4.39 deltaminmax=14
DoNotMoveLeftP0	
	sta WSYNC	   ; 3 minCycl=5.1 maxCycl=5.1
	;M0
	lda #$00		; 2 minCycl=5.3 maxCycl=5.3
	cmp Misile0Shot	 ; 3 minCycl=5.6 maxCycl=5.6
	beq M0MoveEnd	  ; 2 minCycl=5.8 maxCycl=5.8
	;xMov
	lda M0X		 ; 2 minCycl=5.8 maxCycl=5.10
	adc M0vx		; 3 minCycl=5.8 maxCycl=5.13
	sta M0X		 ; 3 minCycl=5.8 maxCycl=5.16
	;xMov
	lda M0Y		 ; 2 minCycl=5.8 maxCycl=5.18
	adc M0vy		; 3 minCycl=5.8 maxCycl=5.21
	sta M0Y		 ; 3 minCycl=5.8 maxCycl=5.24
	;maybe change y speed
	lda GFrames	 ; 3 minCycl=5.8 maxCycl=5.27
	cmp FramesSinceM0Shot   ; 3 minCycl=5.8 maxCycl=5.30
	bne M0MoveEnd	  ; 2 minCycl=5.8 maxCycl=5.32
	inc M0vy		; 5 minCycl=5.8 maxCycl=5.37
	lda #$00		; 2 minCycl=5.8 maxCycl=5.39
	sta FramesSinceM0Shot   ; 3 minCycl=5.8 maxCycl=5.42
M0MoveEnd
	jmp Player1TurnEnd ; 5 minCycl=5.12 maxCycl=5.47 als verwijdert verander door een sta WSYNC
;------------------------------------------------
;Player one
Player1Turn	;
	inc PlayerMvTurn	; 5 minCycl=3.13 maxCycl=3.13
	
	lda FramesSinceAP1  ; 3 min max + 3
	cmp #0		  ; 3 +6
	beq changeAngleP1	
	cmp #5
	beq changeAngleP1  ; +8
	inc FramesSinceAP1  ; +13
	jmp Player1TurnEnd
changeAngleP1
	lda #0
	sta FramesSinceAP0
	; Down?
	lda #%00000001	  ;
	bit SWCHA	   ;
	bne DNLowerAngleP1 ;
	lda #0		  ;
	CMP P1Angle	 ;
	beq DNLowerAngleP1 ;
	dec P1Angle	 ;
	lda #1		  ; 2 maxCycl+2
	sta FramesSinceAP1  ; 3 maxCycle+5
DNLowerAngleP1	 ;
	sta WSYNC	   ; 4.1
	; Up?
	lda #%00000010	  ;
	bit SWCHA	   ;
	bne DNIncAngleP1   ;
	lda #2		  ;
	CMP P1Angle	 ;
	beq DNIncAngleP1   ;
	inc P1Angle	 ;
	lda #1		  ; 2 maxCycl+2
	sta FramesSinceAP1  ; 3 maxCycle+5
DNIncAngleP1   
	sta WSYNC	   ; 5 minCycl=4.1 maxCycl=4.1
	; Left?	 
	lda #%00000100	  ;
	bit SWCHA	   ;
	bne DoNotMoveLeftP1;
	lda #1		  ;
	cmp P1X		 ;
	beq DoNotMoveLeftP1	;
	dec P1X		 ;
DoNotMoveLeftP1	;
	; Right?
	lda #%00001000	  ;
	bit SWCHA	   ;
	bne DoNotMoveRightP1;
	lda #151		;
	cmp P1X		 ;
	beq DoNotMoveRightP1	;
	inc P1X		 ;
DoNotMoveRightP1	   
	sta WSYNC	   ; 3 minCycl=5.1 maxCycl=5.1
	;M1
	lda #$00		;
	cmp Misile1Shot	 ;
	beq Player1TurnEnd ;
	;xMov
	lda M1X		 ;
	adc M1vx		;
	sta M1X		 ;
	;xMov  
	lda M1Y		 ;
	adc M1vy		;
	sta M1Y		 ;
	;maybe change y speed
	lda GFrames	 ;
	cmp FramesSinceM1Shot   ;
	bne Player1TurnEnd ;
	inc M1vy		;
	lda #$00		;
	sta FramesSinceM0Shot   ;
Player1TurnEnd
	sta WSYNC	   ; 3 minCycl=6.1 maxCycl=6.1
;------------------------------------------------
	; Button input
	;button P0
	lda INPT4	   ; 3 minCycl=6.4 maxCycl=6.4
	bmi Button0NotPressed  ; 2 minCycl=6.6 maxCycl=6.6
	lda #$00		; 2 minCycl=6.6 maxCycl=6.8
	cmp Misile0Shot	 ; 3 minCycl=6.6 maxCycl=6.11
	bne Button0NotPressed  ; 2 minCycl=6.6 maxCycl=6.12
	lda #$0F		; 2 minCycl=6.6 maxCycl=6.14
	sta Misile0Shot	 ; 3 minCycl=6.6 maxCycl=6.17
	lda #$00		; 2 minCycl=6.6 maxCycl=6.19
	sta RESMP0	  ; 3 minCycl=6.6 maxCycl=6.22
	lda P0Angle	 ; 3 minCycl=6.6 maxCycl=6.25
	cmp #0		  ; 2 minCycl=6.6 maxCycl=6.27
	bne P0ANot0	; 2 minCycl=6.6 maxCycl=6.29
	lda #$00		; 2 minCycl=6.6 maxCycl=6.31
	sta M0vy		; 3 minCycl=6.6 maxCycl=6.34
	lda MisileMoveA0X   ; 3 minCycl=6.6 maxCycl=6.37
	sta M0vx		; 3 minCycl=6.6 maxCycl=6.40
	jmp Button0NotPressed  ; 5 minCycl=6.6 maxCycl=6.45
P0ANot0
	lda P0Angle	 ; 3 minCycl=6.6 maxCycl=6.32
	cmp #1		  ; 2 minCycl=6.6 maxCycl=6.34
	bne P0ANot30	   ; 2 minCycl=6.6 maxCycl=6.36
	lda MisileMoveA30y  ; 3 minCycl=6.6 maxCycl=6.39
	sta M0vy		; 3 minCycl=6.6 maxCycl=6.42
	lda MisileMoveA30X  ; 3 minCycl=6.6 maxCycl=6.45
	sta M0vx		; 3 minCycl=6.6 maxCycl=6.48
	jmp Button0NotPressed  ; 5 minCycl=6.6 maxCycl=6.53
P0ANot30
	lda P0Angle	 ; 3 minCycl=6.6 maxCycl=6.39
	cmp #2		  ; 2 minCycl=6.6 maxCycl=6.41
	bne Button0NotPressed  ; 2 minCycl=6.6 maxCycl=6.43
	lda MisileMoveA45y  ; 3 minCycl=6.6 maxCycl=6.46
	sta M0vy		; 3 minCycl=6.6 maxCycl=6.49
	lda MisileMoveA45X  ; 3 minCycl=6.6 maxCycl=6.52
	sta M0vx		; 3 minCycl=6.6 maxCycl=6.55
Button0NotPressed   
	sta WSYNC	   ; 3 minCycl=7.1 maxCycl=7.1
	;button P1
	lda INPT5	   ;
	bmi Button1NotPressed  ;
	lda #$00		;
	cmp Misile1Shot	 ;
	bne Button1NotPressed  ;
	lda #$0F		;
	sta Misile1Shot	 ;
	lda #$00		;
	sta RESMP1	  ;
	lda P1Angle	 ;
	cmp #0		  ;
	bne P1ANot0	;
	lda #$00		;
	sta M1vy		;
	lda MisileMoveA0XP1 ;
	sta M1vx		;
	jmp Button1NotPressed  ;
P1ANot0		
	lda P1Angle	 ;
	cmp #1		  ;
	bne P1ANot30	   ;
	lda MisileMoveA30y  ;
	sta M1vy		;
	lda MisileMoveA30XP1;
	sta M1vx		;
	jmp Button1NotPressed  ; 
P1ANot30	   
	lda P1Angle	 ;
	cmp #2		  ;
	bne Button1NotPressed  ;
	lda MisileMoveA45y  ;
	sta M1vy		;
	lda MisileMoveA45XP1;
	sta M1vx		;
Button1NotPressed	  
	sta WSYNC	   ;3 minCycl=8.1 maxCycl=8.1 #added two more wsyncs to make things work out right
;------------------------------------------------
; prepping values for screendrawing
	lda #%00000000
	sta PF0
	sta PF1
	sta PF2
;------------------------------------------------
	ldx #10
	stx CXCLR   ; clears collisions of the previous frame. 
VerticalBlank   
	sta WSYNC   ;
	inx	 ;
	cpx #37	 ;
	bne VerticalBlank;
;------------------------------------------------
; FrameDrawing space:
	; 68 hblank
	ldx #192  ; line #
.kernel
	sta WSYNC
	;sprite drawing from http://atariage.com/forums/topic/75982-skipdraw-and-graphics/?p=928232: improve
	
	;insert drawing code for player and missile at right time
	;write to GRP0 and GRP1 on the exact TIA clock you want to start the player 
	;on the next line

	;playfield drawing
	cpx #40
	bne .wait
	lda #%11111111
	sta PF0
	sta PF1
	sta PF2
.wait
	dex
	bne .kernel
	sta WSYNC
;------------------------------------------------
	;eof code from http://www.randomterrain.com/atari-2600-memories-tutorial-andrew-davie-13.html
	lda #%01000010
	sta VBLANK	   ; end of screen - enter blanking
; 30 scanlines of overscan...
	ldx #0
Overscan sta WSYNC
	inx
	cpx #30
	bne Overscan
	jmp StartOfFrame
	;sprites
	include "PlayField.asm"
	include "TANK0.asm"
	include "TANK30.asm"
	include "TANK45.asm"
	ORG $FFFA

InterruptVectors
	word Reset	   ; NMI
	word Reset	   ; RESET
	word Reset	   ; IRQ
END
	
	