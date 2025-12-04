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
make init
```

Compile:
```bash
make
```

Flash to STM32F4 (using ST-Link):
```bash
make flash
```

Clean build artifacts:
```bash
make clean
```
