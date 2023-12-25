.data
    n: .word 10
    
.text
.globl __start


# Todo: Define your own function in HW1
# You should store the output into x10
FUNCTION:
    addi sp, sp, -4
    sw  x1, 0(sp)
    jal x1, fact
    lw  x1, 0(sp)
    addi a0, t0, 0
    jalr x0, 0(x1)

fact:
    addi sp, sp, -8 # save return address and n on stack
    sw x1, 4(sp)
    sw a0, 0(sp)
    addi t1, a0, -1
    bne t1, x0, L1 # check recursive function base case
    addi t0, x0, 2 # T(1)
    addi sp, sp, 8 # pop stack
    jalr x0, 0(x1) # jump to caller interrupt address
    
L1:
    srli a0, a0, 1 # floor(n / 2)
    jal x1, fact # recursive function
    addi t4, t0, 0
    addi t2, x0, 5 
    mul t4, t4, t2 # 5T(floor(n / 2))
    lw a0, 0(sp) # restore n from stack
    lw x1, 4(sp) # restore return address
    addi sp, sp, 8 # pop stack
    addi t3, x0, 6 
    mul t5, a0, t3 # 6n
    addi t5, t5, 4 # 6n + 4
    add t0, t4, t5 # 5T(floor(n / 2)) + 6n + 4
    jalr x0, 0(x1) # jump to caller interrupt address
    
# Do NOT modify this part!!!
__start:
    la   t0, n
    lw   x10, 0(t0)
    jal  x1,FUNCTION
    la   t0, n
    sw   x10, 4(t0)
    addi a0,x0,10
    ecall