# stm32f4xx_template
STM32 template with CMSIS and HAL libraries.

Template is ready-to-use with STM32F4 series chips and contains example code for Black Pill (STM32F401CC).

## Requirements
- arm-none-eabi-gcc
- GNU Make
- st-link tools (st-flash)

## Getting started

Clone the repository:
```bash
git clone https://github.com/madjichan/stm32f4xx_template.git
cd stm32f4xx_template
```

Initialize project structure:
```bash
make init CHIP_NAME=<your chip name>
```

Create target:
```bash
nano .targets/<your target name>.mk
```

and add needed arguments in target file. For example:
```make
CHIP_NAME := STM32F401CCU6
LD_SCRIPT_PATH := stm32f401ccu6.ld
TARGET_SRCS := src/main.c src/init_stub.c src/syscalls.c
```

Compile:
```bash
make TARGET=<target name>
```

Flash to STM32F4 (using ST-Link):
```bash
make flash TARGET=<target name>
```

Clean build artifacts:
```bash
make clean
```
