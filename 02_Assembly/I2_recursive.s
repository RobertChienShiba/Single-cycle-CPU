.data
    n: .word 10
    
.text
.globl __start

FUNCTION:
    # Todo: Define your own function in HW1
    addi sp, sp, -8     # Althrough this simulator only simulate 32-bit registers, here i still consider the registers as 64-bit
    sw   x1, 4(sp)      # Push x1(i.e., return addr.) into stack (should be SD as 64-bit)
    sw   x10, 0(sp)     # Push x10(i.e., current n) into stack (should be SD as 64-bit)
    addi x5, x10, -2    # Read with next inst. \
    bge  x5, x0, L1     # Test if n is greater than or equal to 2
    addi x10, x0, 2     # n is less than 2, so x10 is used for return the value 1 
    addi sp, sp, 8      # Because x1 and x10 are not change, pop stack without storing
    jalr x0, 0(x1)      # return
L1:
    srai x10, x10, 1    # x10/2 
    jal  x1, FUNCTION   # call the function again (recursive)
    slli x6, x10, 2     # x10*4 store in x6, because x10 will used to restore n
    add  x6, x6, x10    # store x10*5 in x6
    lw   x10, 0(sp)     # pop from stack
    lw   x1, 4(sp)      # 
    addi sp, sp, 8      # 
    slli x7, x10, 1     # store 2*n in x7
    add  x7, x7, x10    # store 3*n in x7
    slli x10, x7, 1     # store 6*n in x10
    add  x10, x10, x6   # add 6*n with x6
    addi x10, x10, 4	# add 4 with x10 => 5T(n/2) + 6n + 4
    jalr x0, 0(x1)      # return

# Do NOT modify this part!!!
__start:
    la   t0, n
    lw   x10, 0(t0)
    jal  x1,FUNCTION
    la   t0, n
    sw   x10, 4(t0)
    addi a0,x0,10
    ecall