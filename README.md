# 4bit opcode 8bit data cpu

This cpu reads the program stored in memory and executes its instructions. In the present 
configuration it uses 4 bits for each operation code and 8 bits for storing data.

## The following are the operations paired with their corresponding opcodes

 1) 0000 XXXXXXXX  : ACC keeps its value, no write to M[], PC increments by 1
 2) 0001 XXX AAAAA : Load ACC M[AA]
 3) 0010 XXX AAAAA : Add  ACC M[AA]
 4) 0011 XXX AAAAA : Subtract  ACC M[AA]
 5) 0100 XXX AAAAA : Logic AND ACC M[AA]
 6) 0101 XXX AAAAA : Logic OR  ACC M[AA]
 7) 0110 XXX AAAAA : Logic XOR ACC M[AA]
 8) 0111 XXXXXXXX  : Logic NOT ACC
 9) 1000 XXXXXXXX  : Right shift ACC
10) 1001 XXXXXXXX  : Left shift  ACC
11) 1010 VVVVVVVV  : Load immediate ACC VV
12) 1011 VVVVVVVV  : Add immediate  ACC VV
13) 1100 XXX AAAAA : Store ACC M[AA]
14) 1101 XXXX VVVV : Jump on zero ACC PC<--PC+VV
15) 1110 XXXX VVVV : Jump on negative ACC PC<--PC+VV
16) 1111 XXXXXXXX  : Jump unconditional PC<--ACC

Where AA signifies an address value, VV a signed numeric value and XX a value not taken into consideration.
The Accumulator(ACC) register is used for the majority of the operations, with the Program Counter(PC)
enabling control flow and Memory(M[]) holding the program and any data we wish to store.

## Below is the basic block diagram of the cpu and memory

![Block diagram CPU](https://user-images.githubusercontent.com/87810236/215602274-c56973eb-c4b5-4f65-a20c-86d7ddcb4602.jpg)

The "CentralPU_rtl.pdf" contains the RTL design created with Intel's Quartus Prime. 
