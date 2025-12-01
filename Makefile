TARGET := test_lab

PROJ_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

CHIP_NAME := STM32F401xC
STARTUP_FILENAME := stm32f401xc
CHIP_SERIES := stm32f4xx

CHIPSRC_INCLUDE := $(CHIP_SERIES).h
CHIPSRC_SYSTEM := system_$(CHIP_SERIES).c
CHIPSRC_STARTUP := startup_$(STARTUP_FILENAME).s

CMSIS_PREFIX := Drivers/CMSIS
HAL_PREFIX := Drivers/STM32F4xx_HAL_Driver
HAL_SRC_DIR := $(realpath .repo/$(HAL_PREFIX)/Src)
HAL_INC_DIR := $(realpath .repo/$(HAL_PREFIX)/Inc)

CC := arm-none-eabi-gcc
OBJCOPY := arm-none-eabi-objcopy

CFLAGS := -mcpu=cortex-m4 -mthumb -O2 -Wall \
		 -D$(CHIP_NAME) \
		 -DUSE_HAL_DRIVER \
		 -I./include/CMSIS \
		 -I./include/HAL \
		 -I./include

LDFLAGS := -T $(TARGET).ld -nostartfiles -lc -lgcc

SRCS = src/CMSIS/$(CHIPSRC_STARTUP) \
	    src/CMSIS/$(CHIPSRC_SYSTEM) \
	    $(wildcard src/HAL/*.c) \
		src/init_stub.c \
	    src/syscalls.c \
		src/main.c

all: $(TARGET).bin

clone:
	git -C .repo/ pull || git clone --recursive --depth=1 https://github.com/STMicroelectronics/STM32CubeF4.git .repo/

init:
	mkdir -p src/ src/CMSIS src/HAL
	mkdir -p include/ include/CMSIS include/HAL
	cp -r .repo/$(CMSIS_PREFIX)/Device/ST/STM32F4xx/Source/Templates/gcc/$(CHIPSRC_STARTUP) ./src/CMSIS/
	cp -r .repo/$(CMSIS_PREFIX)/Device/ST/STM32F4xx/Source/Templates/$(CHIPSRC_SYSTEM) ./src/CMSIS/
	cp -r .repo/$(CMSIS_PREFIX)/Device/ST/STM32F4xx/Include/$(CHIPSRC_INCLUDE) ./include/CMSIS/
	cp -r $(wildcard .repo/$(CMSIS_PREFIX)/Core/Include/*) ./include/CMSIS/
	cp -r $(wildcard .repo/$(CMSIS_PREFIX)/Device/ST/STM32F4xx/Include/*) ./include/CMSIS/
	cp -r .repo/$(HAL_PREFIX)/Inc/stm32f4xx_hal_conf_template.h ./include/HAL/stm32f4xx_hal_conf.h
	cd $(HAL_SRC_DIR); cp -r --parents $(filter-out %_template.c,$(patsubst $(HAL_SRC_DIR)/%,%,$(wildcard $(HAL_SRC_DIR)/*.c $(HAL_SRC_DIR)/**/*.c))) $(PROJ_DIR)/src/HAL/
	cd $(HAL_INC_DIR); cp -r --parents $(filter-out %_template.h,$(patsubst $(HAL_INC_DIR)/%,%,$(wildcard $(HAL_INC_DIR)/*.h $(HAL_INC_DIR)/**/*.h))) $(PROJ_DIR)/include/HAL/

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $^ $@

$(TARGET).elf: $(SRCS)
	$(CC) $(CFLAGS) $(SRCS) $(LDFLAGS) -o $@

clean:
	rm -f *.elf *.bin

flash: $(TARGET).bin
	st-flash write $^ 0x08000000

.PHONY: all init clean flash clone
