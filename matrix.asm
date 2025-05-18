; 3x3 Matrix Calculator for LPC2148
; Operations: Addition, Subtraction, Multiplication
; User inputs both matrices and selects operation via UART

        AREA    RESET, CODE, READONLY
        ENTRY
        
; LPC2148 Register Definitions
PINSEL0         EQU     0xE002C000      ; Pin Function Select Register 0
U0RBR           EQU     0xE000C000      ; UART0 Receiver Buffer Register
U0THR           EQU     0xE000C000      ; UART0 Transmitter Holding Register
U0DLL           EQU     0xE000C000      ; UART0 Divisor Latch LSB
U0DLM           EQU     0xE000C004      ; UART0 Divisor Latch MSB
U0FCR           EQU     0xE000C008      ; UART0 FIFO Control Register
U0LCR           EQU     0xE000C00C      ; UART0 Line Control Register
U0LSR           EQU     0xE000C014      ; UART0 Line Status Register
U0LSR_RDR       EQU     0x01            ; UART0 LSR Receive Data Ready bit
U0LSR_THRE      EQU     0x20            ; UART0 LSR Transmit Holding Register Empty

; Vector Table
        LDR     PC, Reset_Addr
Reset_Addr      DCD     START

START
        ; Initialize UART0 for communication (9600 baud, 8N1)
        BL      init_uart
        
        ; Allocate memory for matrices
        LDR     R8, =MatrixA        ; Matrix A base address
        LDR     R9, =MatrixB        ; Matrix B base address
        LDR     R10, =ResultMatrix  ; Result matrix base address
        
        ; Input Matrix A
        LDR     R0, =msg_inputA
        BL      print_string
        MOV     R0, R8
        MOV     R1, #9              ; 9 elements
        BL      input_matrix
        
        ; Input Matrix B
        LDR     R0, =msg_inputB
        BL      print_string
        MOV     R0, R9
        MOV     R1, #9              ; 9 elements
        BL      input_matrix
        
        ; Input operation
        LDR     R0, =msg_operation
        BL      print_string
        BL      get_char
        MOV     R7, R0              ; Save operation in R7
        
        ; Echo operation character
        BL      put_char
        
        ; Print newline
        MOV     R0, #13             ; CR
        BL      put_char
        MOV     R0, #10             ; LF
        BL      put_char
        
        ; Check operation and branch to appropriate function
        CMP     R7, #'+'
        BEQ     do_addition
        CMP     R7, #'-'
        BEQ     do_subtraction
        CMP     R7, #'*'
        BEQ     do_multiplication
        
        ; Invalid operation - show error message
        LDR     R0, =msg_invalid
        BL      print_string
        B       program_end
        
do_addition
        LDR     R0, =msg_add
        BL      print_string
        BL      matrix_add
        B       show_result
        
do_subtraction
        LDR     R0, =msg_sub
        BL      print_string
        BL      matrix_subtract
        B       show_result
        
do_multiplication
        LDR     R0, =msg_mul
        BL      print_string
        BL      matrix_multiply
        B       show_result
        
show_result
        LDR     R0, =msg_result
        BL      print_string
        MOV     R0, R10
        BL      print_matrix
        
program_end
        B       program_end          ; Infinite loop at end of program

;-----------------------------------------
; Initialize UART0 (9600 baud, 8N1)
;-----------------------------------------
init_uart
        PUSH    {R0-R2, LR}
        
        ; Configure P0.0 and P0.1 for UART0
        LDR     R0, =PINSEL0
        LDR     R1, [R0]
        BIC     R1, R1, #0xF         ; Clear bits 0-3
        ORR     R1, R1, #0x5         ; Set P0.0=TXD0, P0.1=RXD0
        STR     R1, [R0]
        
        ; Set DLAB=1 to access divisor latches
        LDR     R0, =U0LCR
        MOV     R1, #0x83            ; 8N1 + DLAB=1
        STR     R1, [R0]
        
        ; Set baud rate to 9600 (PCLK=12MHz)
        ; Divisor = PCLK/(16*9600) = 12000000/(16*9600) = 78.125 ≈ 78 = 0x4E
        LDR     R0, =U0DLL
        MOV     R1, #0x4E            ; LSB of divisor
        STR     R1, [R0]
        
        LDR     R0, =U0DLM
        MOV     R1, #0x00            ; MSB of divisor
        STR     R1, [R0]
        
        ; Enable FIFO and reset RX/TX FIFOs
        LDR     R0, =U0FCR
        MOV     R1, #0x07            ; Enable and reset FIFOs
        STR     R1, [R0]
        
        ; Set DLAB=0 to access regular registers
        LDR     R0, =U0LCR
        MOV     R1, #0x03            ; 8N1 + DLAB=0
        STR     R1, [R0]
        
        POP     {R0-R2, PC}

;-----------------------------------------
; Get character from UART (blocking)
;-----------------------------------------
get_char
        PUSH    {R1-R2, LR}
        
wait_rx_ready
        LDR     R1, =U0LSR
        LDR     R2, [R1]
        TST     R2, #U0LSR_RDR       ; Test if data ready
        BEQ     wait_rx_ready        ; If not, keep waiting
        
        ; Data is ready, read it
        LDR     R1, =U0RBR
        LDRB    R0, [R1]             ; Load received byte into R0
        
        POP     {R1-R2, PC}

;-----------------------------------------
; Send character via UART
;-----------------------------------------
put_char
        PUSH    {R0-R2, LR}
        
wait_tx_ready
        LDR     R1, =U0LSR
        LDR     R2, [R1]
        TST     R2, #U0LSR_THRE      ; Test if transmitter ready
        BEQ     wait_tx_ready        ; If not, keep waiting
        
        ; Transmitter ready, send character
        LDR     R1, =U0THR
        STRB    R0, [R1]             ; Send byte from R0
        
        POP     {R0-R2, PC}

;-----------------------------------------
; Print null-terminated string
; Input: R0 = pointer to string
;-----------------------------------------
print_string
        PUSH    {R0-R2, LR}
        MOV     R2, R0               ; Save string pointer
        
print_loop
        LDRB    R0, [R2], #1         ; Load byte and increment pointer
        CMP     R0, #0               ; Check if null terminator
        BEQ     print_done           ; If null, we're done
        BL      put_char             ; Otherwise print the character
        B       print_loop           ; Continue with next character
        
print_done
        POP     {R0-R2, PC}

;-----------------------------------------
; Input a number from UART
; Output: R0 = number
;-----------------------------------------
input_number
        PUSH    {R1-R4, LR}
        
        MOV     R4, #0               ; Initialize result
        MOV     R3, #0               ; Flag for negative number
        
        ; Wait for first character
        BL      get_char
        
        ; Check if it's a minus sign
        CMP     R0, #'-'
        BNE     not_negative
        
        ; It's negative, set flag and get next char
        MOV     R3, #1
        BL      put_char             ; Echo the minus
        BL      get_char
        
not_negative
        ; Process digits
input_loop
        ; Check if it's a digit
        CMP     R0, #'0'
        BLT     input_done
        CMP     R0, #'9'
        BGT     input_done
        
        ; Echo the digit
        BL      put_char
        
        ; Update result: R4 = R4 * 10 + (digit - '0')
        SUB     R0, R0, #'0'         ; Convert ASCII to number
        MOV     R1, R4, LSL #3       ; R1 = R4 * 8
        ADD     R1, R1, R4, LSL #1   ; R1 = R4 * 8 + R4 * 2 = R4 * 10
        ADD     R4, R1, R0           ; R4 = R4 * 10 + digit
        
        ; Get next character
        BL      get_char
        B       input_loop
        
input_done
        ; Check if we need to negate the result
        CMP     R3, #1
        BNE     input_positive
        RSB     R4, R4, #0           ; Negate: R4 = 0 - R4
        
input_positive
        ; Return the result
        MOV     R0, R4
        
        ; Print newline if not called during matrix input
        CMP     R0, #13              ; Check if it's CR
        BEQ     skip_newline
        CMP     R0, #10              ; Check if it's LF
        BEQ     skip_newline
        
        ; Print newline
        PUSH    {R0}
        MOV     R0, #13             ; CR
        BL      put_char
        MOV     R0, #10             ; LF
        BL      put_char
        POP     {R0}
        
skip_newline
        POP     {R1-R4, PC}

;-----------------------------------------
; Input a matrix from UART
; Input: R0 = matrix address, R1 = number of elements
;-----------------------------------------
input_matrix
        PUSH    {R0-R7, LR}
        
        MOV     R4, R0               ; Matrix pointer
        MOV     R5, R1               ; Element counter
        MOV     R6, #0               ; Row counter
        MOV     R7, #0               ; Column counter
        
input_matrix_loop
        ; Print prompt with element position
        LDR     R0, =msg_element
        BL      print_string
        
        ; Print row and column
        MOV     R0, R6
        ADD     R0, R0, #1           ; Display as 1-based
        BL      print_number
        MOV     R0, #','
        BL      put_char
        MOV     R0, R7
        ADD     R0, R0, #1           ; Display as 1-based
        BL      print_number
        MOV     R0, #':'
        BL      put_char
        MOV     R0, #' '
        BL      put_char
        
        ; Get input number
        BL      input_number
        STR     R0, [R4], #4         ; Store number and increment pointer
        
        ; Update column counter
        ADD     R7, R7, #1
        CMP     R7, #3               ; Check if end of row
        BNE     not_end_of_row
        
        ; End of row reached
        MOV     R7, #0               ; Reset column counter
        ADD     R6, R6, #1           ; Increment row counter
        
not_end_of_row
        ; Decrement element counter
        SUBS    R5, R5, #1
        BNE     input_matrix_loop
        
        POP     {R0-R7, PC}

;-----------------------------------------
; Print a number
; Input: R0 = number to print
;-----------------------------------------
print_number
        PUSH    {R0-R7, LR}
        
        MOV     R4, R0               ; Save number
        
        ; Check if negative
        CMP     R4, #0
        BGE     positive_number
        
        ; Print minus sign
        MOV     R0, #'-'
        BL      put_char
        
        ; Make number positive
        RSB     R4, R4, #0           ; R4 = 0 - R4
        
positive_number
        ; Count digits and build them on the stack
        MOV     R5, #0               ; Digit counter
        
digit_loop
        ; Divide by 10: R4 / 10 -> R0, R4 % 10 -> R1
        MOV     R0, R4               ; Dividend
        MOV     R1, #10              ; Divisor
        BL      divide               ; R0 = quotient, R1 = remainder
        
        ; Push remainder (digit) to stack
        ADD     R1, R1, #'0'         ; Convert to ASCII
        PUSH    {R1}                 ; Store on stack
        ADD     R5, R5, #1           ; Increment digit counter
        
        ; Check if more division needed
        MOV     R4, R0               ; Update number with quotient
        CMP     R4, #0               ; Check if we're done
        BNE     digit_loop
        
        ; Pop and print digits in reverse order
print_digits
        POP     {R0}                 ; Get digit from stack
        BL      put_char             ; Print it
        SUBS    R5, R5, #1           ; Decrement counter
        BNE     print_digits         ; Continue until all digits printed
        
        POP     {R0-R7, PC}

;-----------------------------------------
; Division: R0 / R1 -> R0 remainder R1
; Input: R0 = dividend, R1 = divisor
; Output: R0 = quotient, R1 = remainder
;-----------------------------------------
divide
        PUSH    {R2-R4, LR}
        
        MOV     R4, #0               ; Initialize quotient
        
        ; Check for division by zero
        CMP     R1, #0
        BEQ     divide_by_zero
        
        ; Check if dividend is less than divisor
        CMP     R0, R1
        BLT     division_done
        
division_loop
        MOV     R2, R1               ; R2 = divisor
        MOV     R3, #1               ; R3 = current bit in quotient
        
        ; Left shift divisor until just before it exceeds dividend
shift_loop
        LSL     R2, R2, #1           ; R2 = R2 << 1
        CMP     R2, R0
        BGT     shift_done           ; If R2 > R0, we've gone too far
        
        LSL     R3, R3, #1           ; R3 = R3 << 1
        B       shift_loop
        
shift_done
        ; Shift back once (we went one too far)
        LSR     R2, R2, #1           ; R2 = R2 >> 1
        LSR     R3, R3, #1           ; R3 = R3 >> 1
        
        ; Subtract and add to quotient
        ADD     R4, R4, R3           ; Add bit to quotient
        SUB     R0, R0, R2           ; Subtract from dividend
        
        ; Check if we need to continue
        CMP     R0, R1
        BGE     division_loop
        
division_done
        MOV     R1, R0               ; Set remainder
        MOV     R0, R4               ; Set quotient
        
divide_by_zero
        POP     {R2-R4, PC}

;-----------------------------------------
; Print a matrix
; Input: R0 = matrix address
;-----------------------------------------
print_matrix
        PUSH    {R0-R7, LR}
        
        MOV     R4, R0               ; Matrix pointer
        MOV     R5, #3               ; Row counter
        
print_matrix_row
        MOV     R6, #3               ; Column counter
        
print_matrix_col
        ; Print element
        LDR     R0, [R4], #4         ; Load element and increment pointer
        BL      print_number
        
        ; Print space or newline
        SUBS    R6, R6, #1           ; Decrement column counter
        BEQ     end_of_row
        
        ; Not end of row, print space
        MOV     R0, #' '
        BL      put_char
        B       print_matrix_col
        
end_of_row
        ; Print newline
        MOV     R0, #13             ; CR
        BL      put_char
        MOV     R0, #10             ; LF
        BL      put_char
        
        ; Check if more rows
        SUBS    R5, R5, #1
        BNE     print_matrix_row
        
        POP     {R0-R7, PC}

;-----------------------------------------
; Matrix Addition: C = A + B
;-----------------------------------------
matrix_add
        PUSH    {R0-R7, LR}
        
        MOV     R0, R8               ; Matrix A pointer
        MOV     R1, R9               ; Matrix B pointer
        MOV     R2, R10              ; Result matrix pointer
        MOV     R3, #9               ; 3x3 matrix has 9 elements
        
add_loop
        LDR     R4, [R0], #4         ; Load element from matrix A
        LDR     R5, [R1], #4         ; Load element from matrix B
        ADD     R6, R4, R5           ; Add elements
        STR     R6, [R2], #4         ; Store result in matrix C
        SUBS    R3, R3, #1           ; Decrement counter
        BNE     add_loop             ; Continue until all elements processed
        
        POP     {R0-R7, PC}

;-----------------------------------------
; Matrix Subtraction: C = A - B
;-----------------------------------------
matrix_subtract
        PUSH    {R0-R7, LR}
        
        MOV     R0, R8               ; Matrix A pointer
        MOV     R1, R9               ; Matrix B pointer
        MOV     R2, R10              ; Result matrix pointer
        MOV     R3, #9               ; 3x3 matrix has 9 elements
        
subtract_loop
        LDR     R4, [R0], #4         ; Load element from matrix A
        LDR     R5, [R1], #4         ; Load element from matrix B
        SUB     R6, R4, R5           ; Subtract elements
        STR     R6, [R2], #4         ; Store result in matrix C
        SUBS    R3, R3, #1           ; Decrement counter
        BNE     subtract_loop        ; Continue until all elements processed
        
        POP     {R0-R7, PC}

;-----------------------------------------
; Matrix Multiplication: C = A * B
;-----------------------------------------
matrix_multiply
        PUSH    {R0-R12, LR}
        
        ; For each element C[i,j] = Σ A[i,k] * B[k,j] for k=0..2
        MOV     R0, #0               ; i = 0 (row counter)
        
row_loop
        ; Loop for each column j of matrix B
        MOV     R1, #0               ; j = 0 (column counter)
        
col_loop
        MOV     R7, #0               ; Accumulator for dot product
        
        ; Compute dot product for element C[i,j]
        MOV     R2, #0               ; k = 0
        
dot_product_loop
        ; Calculate indices for A[i,k] and B[k,j]
        MOV     R3, R0, LSL #1       ; R3 = 2*i
        ADD     R3, R3, R0           ; R3 = 3*i (row offset for A)
        ADD     R3, R3, R2           ; R3 = 3*i + k (index for A[i,k])
        
        MOV     R4, R2, LSL #1       ; R4 = 2*k
        ADD     R4, R4, R2           ; R4 = 3*k (row offset for B)
        ADD     R4, R4, R1           ; R4 = 3*k + j (index for B[k,j])
        
        ; Load A[i,k] and B[k,j]
        LDR     R5, [R8, R3, LSL #2] ; R5 = A[i,k]
        LDR     R6, [R9, R4, LSL #2] ; R6 = B[k,j]
        
        ; Accumulate dot product
        MUL     R11, R5, R6          ; R11 = A[i,k] * B[k,j]
        ADD     R7, R7, R11          ; R7 += A[i,k] * B[k,j]
        
        ; Move to next element in the dot product
        ADD     R2, R2, #1           ; k++
        CMP     R2, #3               ; Compare k with 3
        BLT     dot_product_loop     ; If k < 3, continue dot product
        
        ; Store the result C[i,j]
        MOV     R3, R0, LSL #1       ; R3 = 2*i
        ADD     R3, R3, R0           ; R3 = 3*i (row offset for C)
        ADD     R3, R3, R1           ; R3 = 3*i + j (index for C[i,j])
        STR     R7, [R10, R3, LSL #2]; C[i,j] = accumulated value
        
        ; Move to next column
        ADD     R1, R1, #1           ; j++
        CMP     R1, #3               ; Compare j with 3
        BLT     col_loop             ; If j < 3, continue to next column
        
        ; Move to next row
        ADD     R0, R0, #1           ; i++
        CMP     R0, #3               ; Compare i with 3
        BLT     row_loop             ; If i < 3, continue to next row
        
        POP     {R0-R12, PC}

; Data section for messages
msg_inputA      DCB "Enter Matrix A (3x3):", 13, 10, 0
msg_inputB      DCB "Enter Matrix B (3x3):", 13, 10, 0
msg_operation   DCB "Enter operation (+, -, *): ", 0
msg_element     DCB "Element [", 0
msg_invalid     DCB "Invalid operation!", 13, 10, 0
msg_add         DCB "Performing Addition:", 13, 10, 0
msg_sub         DCB "Performing Subtraction:", 13, 10, 0
msg_mul         DCB "Performing Multiplication:", 13, 10, 0
msg_result      DCB "Result Matrix:", 13, 10, 0

        AREA    MatrixData, DATA, READWRITE
MatrixA         SPACE 36             ; 9 words (4 bytes each)
MatrixB         SPACE 36             ; 9 words
ResultMatrix    SPACE 36             ; 9 words

        END