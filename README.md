# Single Cycle CPU with 2-way Set associative Cache
**All logic circuits are Flip-Flops**
## Architecture Overview
### Brief version
![Block Diagram](https://i.imgur.com/Hstt7CH.png)
### Detail version ([More Detail](https://github.com/RobertChienShiba/Single-cycle-CPU/tree/main/spec.pdf))
![Block Diagram](https://i.imgur.com/blGHlCl.png)
## Support Instruction
- [x] add, sub, and, xor
- [x] mul(**multi-cycle bitwise operation**)
- [x] addi, slli, srai, slti
- [x] beq, bge, bne, blt
- [x] lw, sw
- [x] auipc
- [x] jal, jalr
- [x] ecall(system call for end of program)
## Memory
- Size: 16KB
- Data Width: 32 bits
### Read(Delay 10 cycles)
![MemRead](https://i.imgur.com/0H3mF2Z.png)
### Write(Delay 5 cycles)
![MemWrite](https://i.imgur.com/cwDwx4w.png)
## Cache
- Size: 256 Bytes(0.25KB)
- Data Width: 128 bits
- Associative: 2-way
- Replacement policy: LRU
- Write hit policy: write back
- Write miss policy: write allocate
- Address Segmentation: 25 bits for tag, 3 bits for index, 4 bits for offset 
### Finite State Machine Schematic Diagram
![FSM](https://i.imgur.com/hTZwIqj.png)
### Data Transportation
![Data Transport](https://i.imgur.com/KxBzh11.png)
## Performance(the execution cycle number of each instruction set)
- I0: leaf program 
([Python](https://github.com/RobertChienShiba/Single-cycle-CPU/tree/main/03_Python/I0_leaf_gen.py)) ([Assembly](https://github.com/RobertChienShiba/Single-cycle-CPU/tree/main/02_Assembly/I0_leaf.s))
- I1: Factorial 
([Python](https://github.com/RobertChienShiba/Single-cycle-CPU/tree/main/03_Python/I1_fact_gen.py)) ([Assembly](https://github.com/RobertChienShiba/Single-cycle-CPU/tree/main/02_Assembly/I1_fact.s))
- I2: Recursive relation function 
([Python](https://github.com/RobertChienShiba/Single-cycle-CPU/tree/main/03_Python/I2_hw1_gen.py)) 
([Assembly](https://github.com/RobertChienShiba/Single-cycle-CPU/tree/main/02_Assembly/I2_hw1.s))
- I3: Bubble sort 
([Python](https://github.com/RobertChienShiba/Single-cycle-CPU/tree/main/03_Python/I3_sort_gen.py)) 
([Assembly](https://github.com/RobertChienShiba/Single-cycle-CPU/tree/main/02_Assembly/I3_sort.s))

**Consider finally store data back to memory**

**cycle time: 10ns / cycle**
| Instruction Set      | Without Cache | Direct Mapped | 2-way Set Associative | Speed up |
| ----------- | ----------- | ----------- | ----------- | ----------- |
| I0 | 78 | 76 | 76 | 1.02 |
| I1 | 463 | 367 | 367 | 1.26 |
| I2 | 437 | 375 | 375 | 1.16 |
| I3 | 1359 | 455 | 440 | 3.08 |