.data
    a: .word 7
    b: .word -10
    c: .word -4
    d: .word 8
    e: .word 98765
    f: .word 123456
.text
.globl __start

leaf:
    add x5, x10, x11
    add x6, x12, x13
    sub x20, x5, x6
    mul x21, x10, x13
    mul x22, x14, x15
    srai x23, x11, 2
    addi x10, x5, 0
    addi x11, x6, 0
    addi x12, x20, 0
    addi x13, x21, 0
    addi x14, x22, 0
    addi x15, x23, 0
    jalr x0, 0(x1)
    
__start:
    la t0, a
    lw x10, 0(t0)
    la t0, b
    lw x11, 0(t0)
    la t0, c
    lw x12, 0(t0)
    la t0, d
    lw x13, 0(t0)
    la t0, e
    lw x14, 0(t0)
    la t0, f
    lw x15, 0(t0)
    jal x1, leaf
    la t0, f
    sw x10, 4(t0)
    sw x11, 8(t0)
    sw x12,12(t0)
    sw x13,16(t0)
    sw x14,20(t0)
    sw x15,24(t0)
    addi a0, x0, 10
    ecall