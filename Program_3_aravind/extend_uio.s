@******************************************************
@ name: extend_uio.s
@
@ description: program to read 3 digits from stdin,
@ validates it, and render to stdout.
@
@******************************************************
.global main 						@entry point
.text							@code area

main:
	ldr r1, =prompt					@prompt character
	mov r2, #30					@Length of prompt message
	mov r0, #1					@Stdio
	mov r7, #4					@write system call
	svc 0						@execute system call

	@Prepare registers for number storage
	mov r4, #0					@clear the register
	mov r5, #0 					@digit counter
input_loop:
	ldr r1, =inbuff 				@set pointer to input buffer
	mov r2, #1 					@read one char
	mov r0, #0					@read from stdio
	mov r7, #3					@read system call
	svc 0 						@execute system call

	@Validate if input is a number (0-9)
	ldrb r3, [r1] 					@load input character
	cmp r3, #10					@check for newline
	beq process_number				@if newline, process input
	cmp r3, #'0'					@check if char is 0
	blt invalid_input				@if char is less than 0, it is invalid
	cmp r3, #'9'					@check if char is greater than 9
	bgt invalid_input				@if char is greater than 9, it is invalid

	@Convert valid character to integer to process it
	sub r3, r3, #'0' 				@convert char to integer
	mov r6, #10					@create multiplier (x10)
	mul r4, r4, r6					@multiply current digit by multiplier (Shift left in decimal)
	add r4, r4, r3					@append digit to final number
	add r5, r5, #1					@increment digit counter

	@limit input to 3 digits
	cmp r5, #3
	bge process_number 				@if 3 digits entered, process input

	@Continue receiving input
	b input_loop

invalid_input:
	@Output error for invalid input
	ldr r1, =error_msg				@error message for invalid input
	mov r2, #32 					@length of error message
	mov r0, #1 					@stdio
	mov r7, #4					@write system call
	svc  0						@execute system call

	@Reset Registers
	mov r4, #0					@reset stored number
	mov r5, #0					@reset digit counter

	@Flush input buffer
	ldr r1, =inbuff					@point to buffer
	mov r2, #4 					@read remaining characters
	mov r0, #0					@stdin
	mov r7, #3					@read system call
	svc 0 						@discard input

	@Prompt for re-entry
	b input_loop

process_number:
	ldr r1, =bin_output				@binary output message
	mov r2, #24					@length of output message
	mov r0, #1					@stdout
	mov r7, #4					@write system call
	svc 0 						@execute system call

	@Convert the decimal to binary
	mov r6, r4					@copy decimal value
	ldr r1, =binbuff				@buffer for binary string
	mov r2, #0					@string index

binary_loop:
	and r3, r6, #1					@least significant bit
	add r3, r3, #'0'				@convert to char
	strb r3, [r1, r2]				@store bit in buffer
	lsr r6, r6, #1					@shift right
	add r2, r2, #1					@increment the index
	cmp r6, #0					@check if there is more to convert
	bne binary_loop					@if yes, continue loop

	@terminate safely
	mov r3, #0
	strb r3, [r1,r2]

	@Reverse binary string for correct display
	mov r6, #0
	sub r2, r2, #1					@adjust index

reverse_loop:
	cmp r6, r2
	bge print_binary				@if done, print output
	ldrb r3, [r1, r6]				@load first char
	ldrb r7, [r1, r2]				@load last char
	strb r7, [r1, r6]				@swap char
	strb r3, [r1, r2]
	add r6, r6, #1
	sub r2, r2, #1
	b reverse_loop

print_binary:
	ldr r1,=binbuff					@load binary buffer
	mov r2, #10					@set max length
	mov r0, #1					@stdout
	mov r7, #4					@write system call
	svc 0 						@execute system call

exit_program:
	mov r7, #1					@exit system call, return 0
	mov r0, #0					@successful execution
	svc 0


.data 							@data follows
inbuff: .space 4					@buffer for input
binbuff: .space 12					@buffer for output
prompt: .ascii	"\nEnter a base 10 digit (0-9): " 	@prompt message
error_msg: .ascii "\nInvaild Input. Try Again (0-9):" 	@error message
bin_output: .ascii "\nBinary represenation: " 		@binary output message

@ fix executable stack warning
.section .note.GNU-stack ,"", %progbits
