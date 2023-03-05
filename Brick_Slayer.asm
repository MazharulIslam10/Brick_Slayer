[org 0x0100]
	jmp main
score: dw 0
batposition: dw 3914
ballposition: dw 3760
clrscr:
	pusha				; this function clears the screen
	push es
	mov ax,0xb800
	mov es,ax
	mov di,0
	mov ax,0x0720
	mov cx,2000
	cld
	rep stosw

	pop es
	popa
	ret

;print string 
;passed parameters: x,y,attribute,offset_of_string,length
printstr: 
	push bp				; this function takes parameters for string printing
	mov bp, sp
	push es
	push ax
	push cx
	push si
	push di

	;copying video memory starting adress to es
	mov ax, 0xb800
	mov es, ax

	;calculate the location from x and y cordiantes and move to di
	mov al, 80
	mul byte [bp+10]
	add ax, [bp+12]
	shl ax, 1
	mov di,ax

	;move the string address to si, length to cx, and attribyte to ah
	mov si, [bp+6]
	mov cx, [bp+4]
	mov ah, [bp+8]

	;moving the string's character one by one to al and then copying whole ax to the video memory
	nextchar: 
		mov al, [si]
		mov [es:di], ax
		add di, 2
		add si, 1
		loop nextchar
	pop di
	pop si
	pop cx
	pop ax
	pop es
	pop bp
	ret 10

;creates a pause effect
sleep:
	push cx				; this function creates a delay so that the game doesnot end suddenly
	mov cx, 0x30
	delay: 
	push cx
	mov cx,0xBBB
	delay2:
	nop
	loop delay2
	pop cx
	loop delay
	pop cx
	ret

drawbat: 
	pusha			; this draws the bat from 7 dashes - at the desired location
	push es

	push 0xb800
	pop es

	mov ax,0x0BB2
	mov cx,7
	mov di,[batposition]
	rep stosw

	pop es
	popa
	ret

movebat:
	;parameter(1 to move right to for left)
	push bp
	mov bp,sp
	pusha

	cmp word[bp+4],1
	jne mbi1
	cmp word[batposition],3984	; this checks if the bat is in the bound from right
	je mbend
	call clearbat
	add word[batposition],2
	call drawbat

	mbi1:
	cmp word[bp+4],2
	jne mbend
	cmp word[batposition],3842	; this checks if the bat is in the bound from left
	je mbend
	call clearbat
	sub word[batposition],2
	call drawbat

	mbend:
	popa
	pop bp
	ret 2

clearbat: 
	pusha
	push es

	push 0xb800
	pop es

	mov ax,0x0720			; this clears the bat from screen
	mov cx,7
	mov di,[batposition]
	rep stosw
	
	pop es
	popa
	ret


keyboard:
	pusha
	in al,0x60		; this checks if a key is pressed from keyboard

	;left
	cmp al,75		; this checks if left arrow key is pressed
	jne kbi1
	push 2
	call movebat	; moves bat in left position
	jmp kbend

	;right
	kbi1:
	cmp al,77		; this checks if right arrow key is pressed
	jne kbend
	push 1
	call movebat	; moves bat in right position
	jmp kbend

	
	nomatch:
	popa				; no match of key pressed
	jmp far [cs:oldkb]

	kbend:
	mov al, 0x20
	out 0x20, al
	popa
	iret

scoreStr: db'Score:'
printscore:				; this prints the string Score only
	push 34
	push 1
	push 0x75
	push scoreStr
	push 6
	call printstr

	push 48
	push 1				; this prints the numerical score
	push word[score]
	call printnumber

	ret

;print number at x,y position
printnumber:;parameters(x,y,num)
	push bp
	mov bp, sp			; this function is taken from book for number printing
	push es
	push ax
	push bx
	push cx
	push dx
	push di
	mov ax, 0xb800
	mov es, ax
	mov ax, [bp+4]
	mov bx, 10
	mov cx, 0
	numnextdigit: 
		mov dx, 0
		div bx
		add dl, 0x30
		push dx
		inc cx
		cmp ax, 0
		jnz numnextdigit

	mov al,80
	mul byte[bp+6]
	add ax,[bp+8]
	shl ax,1
	mov di, ax
	numnextpos:
		pop dx
		mov dh, 0x75
		mov [es:di], dx
		add di, 2
		loop numnextpos
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop es
	pop bp
	ret 6

;draw a rectangle on the screen
textrect:   ;parameters(y1,x1,y2,x2,att)
		push bp
		mov bp,sp		; this creates a rectangular border
		push ax
        push bx
		push cx
		push es
		push di
		push dx

		mov al,80
		mul byte[bp+12]
		add ax,[bp+10]
		shl ax,1
		mov di,ax

        ;y comp
        mov dx,[bp+8]
        sub dx,[bp+12]

        ;x comp
        mov bx,[bp+6]
        sub bx,[bp+10]

		mov ax,0xb800
		mov es,ax
		

		mov cx,0
		mov ax,[bp+4]
		lr1:	mov [es:di],ax		; these are the four lines of rectangle
				add di,2			; lr1 , lr2 , lr3 , lr4
				inc cx
				cmp cx,bx
				jne lr1

		mov cx,0
		sub di,2
	
		lr2:	mov [es:di],ax
				mov [es:di+2],ax 
				add di,160
				inc cx
				cmp cx,dx
				jne lr2

		mov cx,0
		sub di,160
		lr3:	mov [es:di],ax
				sub di,2
				inc cx
				cmp cx,bx
				jne lr3

		mov cx,0
		add di,2

		lr4:	mov [es:di],ax
				mov [es:di-2],ax 
				sub di,160
				inc cx
				cmp cx,dx
				jne lr4

		pop dx
		pop di
		pop es
		pop cx
        pop bx
		pop ax
		pop bp
		ret 10

;designing the screen to display when the game ends
endstr: db 'Congratulations on your achievement'
endscreen:
	pusha			; this prints this message after game is over
	push es
	push 0xb800
	pop es
	mov ax,0x720
	mov cx,2000
	rep stosw

	push 5
	push 5
	push 21
	push 74
	push 0x3020
	call textrect		; drawing rectangle

	push 35
	push 10
	push 0x02
	push scoreStr		; printing score string
	push 6
	call printstr

	push 21
	push 18
	push 0x8D
	push endstr			; printing this string
	push 35
	call printstr

	push 42
	push 10
	push word[score]
	call printnumber	; printing score
	
	pop es
	popa
	ret

startstr1: db 'You have to break the bricks on top'
startstr2: db 'Use left and right arrow keys to move'
startstr3: db 'Press ESCAPE to continue'
welcome:
	pusha
	push es
	push 0xb800
	pop es
	mov ax,0x720
	mov cx,2000
	rep stosw

	push 5
	push 5
	push 21
	push 74
	push 0x3020
	call textrect

	push 21
	push 7
	push 0x0D
	push startstr1		; printing first string on the start of game
	push 35
	call printstr

	push 20
	push 8
	push 0x0D
	push startstr2		; printing second string on the start of game
	push 37
	call printstr

	push 26
	push 15
	push 0x8C
	push startstr3		; printing third string on the start of game
	push 23
	call printstr

	pop es
	popa
	ret

;restoring the old interrupts
unhook:
	push ax
	push es				; this function unhooks all the interrupts so that keyboard works normally

	mov ax,0
	mov es, ax

	mov ax, [oldkb]
	mov word[es:9*4], ax
	mov ax,[oldkb+2]
	mov word[es:9*4+2],ax
	
	pop es
	pop ax
	ret

drawborders:
	pusha
	push es			; this draws border of the game inside dosbox

	push 0xb800
	pop es

	mov di,0
	mov cx,80
	mov ax,0x7520
	rep stosw

	mov di,160
	mov cx,80
	mov ax,0x7520
	rep stosw

	mov di,160
	mov cx,24
	dbl1:
		mov word[es:di],0x7520
		add di,160
		dec cx
		jnz dbl1

	mov di,318
	mov cx,24
	dbl2:
		mov word[es:di],0x7520
		add di,160
		dec cx
		jnz dbl2
	pop es
	popa
	ret

movlen1: dw 158
movlen2: dw 162
movcase: db 1
movballc1:
	pusha					; this function controls the movement of the ball
	push es

	push 0xb800
	pop es


	mov di,word[ballposition]
	sub di,[movlen1]

	cmp word[es:di],0x720
	jne reflect1
	call clearball
	mov word[ballposition],di
	call drawball
	jmp mbc1end

	reflect1:
	cmp word[es:di+160],0x0720		; if the ball doesnot find space, move in the next direction 
	jne mbc1ri1
	mov byte[movcase],2
	jmp mbc1end

	mbc1ri1:
	cmp word[es:di-2],0x0720
	jne mbc1end
	mov byte[movcase],3
	
	mbc1end:
	pop es
	popa
	ret

movballc2:
	pusha					; second case of ball movement
	push es

	push 0xb800
	pop es


	mov di,word[ballposition]
	add di,[movlen2]

	cmp word[es:di],0x720
	jne reflect2
	call clearball
	mov word[ballposition],di
	call drawball
	jmp mbc2end
	
	reflect2:
	cmp word[es:di-160],0x0720
	jne mbc2ri1
	mov byte[movcase],1
	jmp mbc2end

	mbc2ri1:
	cmp word[es:di-2],0x0720
	jne mbc2end
	mov byte[movcase],4

	mbc2end:
	pop es
	popa
	ret

movballc3:
	pusha
	push es					; third case of ball movement

	push 0xb800
	pop es


	mov di,word[ballposition]
	sub di,[movlen2]

	cmp word[es:di],0x720
	jne reflect3
	call clearball
	mov word[ballposition],di
	call drawball
	jmp mbc3end
	
	reflect3:
	cmp word[es:di+160],0x0720
	jne mbc3ri1
	mov byte[movcase],4
	jmp mbc3end

	mbc3ri1:
	cmp word[es:di+2],0x0720
	jne mbc3end
	mov byte[movcase],1

	mbc3end:
	pop es
	popa
	ret

movballc4:
	pusha					; fourth case of ball movement
	push es

	push 0xb800
	pop es


	mov di,word[ballposition]
	add di,[movlen1]

	cmp word[es:di],0x720
	jne reflect4
	call clearball
	mov word[ballposition],di
	call drawball
	jmp mbc4end
	
	reflect4:
	cmp word[es:di-160],0x0720
	jne mbc4ri1
	mov byte[movcase],3
	jmp mbc4end

	mbc4ri1:
	cmp word[es:di+2],0x0720
	jne mbc4end
	mov byte[movcase],2
	
	mbc4end:
	pop es
	popa
	ret

movball:
	cmp byte[movcase],1			; the movement of ball is controlled by four cases only
	jne mbli1					; this function is like switch case of C++ which deals with
	call movballc1				; the movement of ball

	mbli1:
	cmp byte[movcase],2
	jne mbli2
	call movballc2

	
	mbli2:
	cmp byte[movcase],3
	jne mbli3
	call movballc3

	mbli3:
	cmp byte[movcase],4
	jne mbli4
	call movballc4

	mbli4:
	ret

drawball:
	pusha
	push es
	
	push 0xb800
	pop es

	mov di,[ballposition]		; this draws the ball at the desired location
	mov word[es:di],0x076F

	pop es
	popa
	ret

clearball:
	pusha
	push es
	
	push 0xb800
	pop es
	mov di,[ballposition]		; this clears the ball from screen
	mov word[es:di],0x720
	pop es
	popa
	ret

drawbricks:
	pusha
	push es

	push 0xb800
	pop es

	mov ax,0x0C16			; this draws the two lines of bricks from dashes -
	mov di,482
	mov cx,78
	rep stosw

	mov di,642
	mov cx,78
	rep stosw

	pop es
	popa
	ret

removebricks:
	pusha
	push es

	push 0xb800
	pop es
	mov di,[ballposition]	
	cmp word[es:di-160],0x0C16		; this checks if the ball position is similar with brick
	jne rmbrend						

	add word[score],10				; increment score by 10
	mov word[es:di-160],0x0720		; if position is similar, print space at that location
	call printscore

	rmbrend:
	pop es
	popa
	ret

chkgameover:
	push bp
	mov bp,sp
	push ax
	cmp word[ballposition],3840		; this checks if the ball falls below this location
	ja outofrange					; then end the game

	inrange:
	mov word[bp+4],1				; if not, continue the game
	jmp cgoend						; stores 1 in return value

	outofrange:
	mov word[bp+4],0				; stores 0 in return value
	jmp cgoend

	cgoend:
	pop ax
	pop bp
	ret

oldkb: dd 0
main:					; main function of the game
	call welcome
	mls1:
		mov ah,0
		int 16h
		cmp al,27
		jne mls1

	;saving old interrupt address to restore at the end of the program
	mov ax,0
	mov es, ax
	mov ax, [es:9*4]
	mov [oldkb], ax
	mov ax, [es:9*4+2]
	mov [oldkb+2], ax

	;hook new interrupt for keyboard
	cli
	mov word [es:9*4], keyboard
	mov [es:9*4+2], cs
	sti

	call clrscr				; simply calling these functions
	call drawborders
	call drawbricks
	call printscore
	call drawbat
	call drawball

	mls2:
		call removebricks
		call sleep
		call movball
		push 0				; creating space because chkgameover function returns a value
		call chkgameover
		pop ax
		cmp ax,0
		je mend
		jmp mls2

	mend:
	call endscreen
	call unhook
	mov ax,0x4c00	
	int 0x21
	