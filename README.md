# Matrix-operation-using-ARM-Assembly

## Overview

This project implements a 3x3 matrix calculator for the LPC2148 microcontroller using ARM assembly language. It performs matrix addition, subtraction, and multiplication through a UART-based user interface.

## Features

- Full 3x3 matrix operations (addition, subtraction, multiplication)
- Interactive UART interface (9600 baud, 8N1)
- Integer arithmetic with negative number support
- Clean, optimized ARM assembly implementation
- Support for LPC2148 microcontroller

## How It Works

### Hardware Architecture

The calculator runs on an LPC2148 microcontroller with:
- ARM7TDMI-S 32-bit RISC core
- 32KB on-chip static RAM
- 512KB on-chip flash memory
- UART interface for user interaction

### Key Registers Used

- `R8`: Base address of Matrix A
- `R9`: Base address of Matrix B
- `R10`: Base address of Result Matrix
- Other registers (`R0-R7`) handle temporary calculations and UART operations

### Memory Layout

The program stores matrices in the Data RAM area:
- Each matrix occupies 36 bytes (9 elements × 4 bytes per integer)
- Elements are stored in row-major order

### Matrix Operations Implementation

#### Addition/Subtraction
```
For each element (i,j) in matrices A and B:
    C[i,j] = A[i,j] ± B[i,j]
```

#### Multiplication
```
For each element (i,j) in result matrix C:
    C[i,j] = 0
    For k from 0 to 2:
        C[i,j] += A[i,k] * B[k,j]
```

### UART Communication

The program configures UART0 at 9600 baud to:
- Display prompts and results
- Accept matrix input values
- Accept operation selection (+, -, *)

## Repository Contents

- matrix.asm: Main assembly source code

## Usage

To install the development environment and tools, refer to [INSTALLATION.md](INSTALLATION.md).

For detailed usage instructions, see [GUIDE.md](GUIDE.md).

## Quick Example

1. Connect to the LPC2148 via serial terminal (9600 baud, 8N1)
2. Input the first 3x3 matrix when prompted
3. Input the second 3x3 matrix
4. Choose an operation (+, -, *)
5. View the result matrix

## Acknowledgments

- ARM Limited for the ARM architecture
- NXP Semiconductors for the LPC2148 microcontroller
