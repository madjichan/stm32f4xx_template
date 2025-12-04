TARGET := test_lab

PROJ_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

CHIP_NAME ?= STM32F401CCU6
CHIP_REGEX := STM32([FGLHW])([0-9])([0-9]+)([FGKTSCRVZI])([468BCDEFGHI])([PHUTY])([67])
CHIP_LOWER := $(shell echo $(CHIP_NAME) | tr A-Z a-z)

CHIP_PREFIX := $(shell echo $(CHIP_NAME) | sed -E 's/$(CHIP_REGEX)/STM32\1\2\3x\5/')
STARTUP_FILENAME := $(shell echo $(CHIP_NAME) | sed -E 's/$(CHIP_REGEX)/stm32\1\2\3x\5/' | tr A-Z a-z)
CHIP_SERIES := $(shell echo $(CHIP_NAME) | sed -E 's/$(CHIP_REGEX)/stm32\1\2xx/' | tr A-Z a-z)
CHIP_SERIES_UC := $(shell echo $(CHIP_NAME) | sed -E 's/$(CHIP_REGEX)/STM32\1\2xx/')

REPO_NAME := $(shell echo $(CHIP_NAME) | sed -E 's/$(CHIP_REGEX)/STM32Cube\1\2/')
REPO_PATH := .repo/$(REPO_NAME)

CHIPSRC_INCLUDE := $(CHIP_SERIES).h
CHIPSRC_SYSTEM := system_$(CHIP_SERIES).c
CHIPSRC_STARTUP := startup_$(STARTUP_FILENAME).s

CMSIS_PREFIX := Drivers/CMSIS
HAL_PREFIX := Drivers/$(CHIP_SERIES_UC)_HAL_Driver
HAL_SRC_DIR := $(realpath $(REPO_PATH)/$(HAL_PREFIX)/Src)
HAL_INC_DIR := $(realpath $(REPO_PATH)/$(HAL_PREFIX)/Inc)

CMSIS_CORE_INC = $(wildcard $(REPO_PATH)/$(CMSIS_PREFIX)/Core/Include/*)
CMSIS_DEVICE_INC = $(wildcard $(REPO_PATH)/$(CMSIS_PREFIX)/Device/ST/$(CHIP_SERIES_UC)/Include/*)
HAL_SRC_FILES = $(filter-out %_template.c,$(patsubst $(HAL_SRC_DIR)/%,%,$(wildcard $(HAL_SRC_DIR)/*.c $(HAL_SRC_DIR)/**/*.c)))
HAL_INC_FILES = $(filter-out %_template.h,$(patsubst $(HAL_INC_DIR)/%,%,$(wildcard $(HAL_INC_DIR)/*.h $(HAL_INC_DIR)/**/*.h)))

CC := arm-none-eabi-gcc
OBJCOPY := arm-none-eabi-objcopy

CFLAGS := -mcpu=cortex-m4 -mthumb -O2 -Wall \
		 -D$(CHIP_PREFIX) \
		 -DUSE_HAL_DRIVER \
		 -I./include/CMSIS/$(CHIP_NAME) \
		 -I./include/HAL/$(CHIP_NAME) \
		 -I./include

LDFLAGS := -T $(TARGET).ld -nostartfiles -lc -lgcc

ASRCS := src/CMSIS/$(CHIP_NAME)/$(CHIPSRC_STARTUP)

SRCS := src/CMSIS/$(CHIP_NAME)/$(CHIPSRC_SYSTEM) \
	    $(wildcard src/HAL/$(CHIP_NAME)/*.c) \
		src/init_stub.c \
	    src/syscalls.c \
		src/main.c

AOBJS = $(addprefix .build/,$(ASRCS:.s=.o))
OBJS = $(addprefix .build/,$(SRCS:.c=.o))
DEPS = $(OBJS:.o=.d)

all: $(TARGET).bin

init:
	git -C $(REPO_PATH) pull 2> /dev/null || git clone --recursive --depth=1 https://github.com/STMicroelectronics/$(REPO_NAME).git $(REPO_PATH)
	$(MAKE) init-rec

init-rec:
	mkdir -p src/ src/CMSIS/$(CHIP_NAME)/ src/HAL/$(CHIP_NAME)/
	mkdir -p include/ include/CMSIS/$(CHIP_NAME)/ include/HAL/$(CHIP_NAME)/
	cp -r $(REPO_PATH)/$(CMSIS_PREFIX)/Device/ST/$(CHIP_SERIES_UC)/Source/Templates/gcc/$(CHIPSRC_STARTUP) ./src/CMSIS/$(CHIP_NAME)/
	cp -r $(REPO_PATH)/$(CMSIS_PREFIX)/Device/ST/$(CHIP_SERIES_UC)/Source/Templates/$(CHIPSRC_SYSTEM) ./src/CMSIS/$(CHIP_NAME)/
	cp -r $(REPO_PATH)/$(CMSIS_PREFIX)/Device/ST/$(CHIP_SERIES_UC)/Include/$(CHIPSRC_INCLUDE) ./include/CMSIS/$(CHIP_NAME)/
	cp -r $(CMSIS_CORE_INC) ./include/CMSIS/$(CHIP_NAME)/
	cp -r $(CMSIS_DEVICE_INC) ./include/CMSIS/$(CHIP_NAME)/
	cp -r $(REPO_PATH)/$(HAL_PREFIX)/Inc/$(CHIP_SERIES)_hal_conf_template.h ./include/HAL/$(CHIP_NAME)/$(CHIP_SERIES)_hal_conf.h
	cd $(HAL_SRC_DIR); cp -r --parents $(HAL_SRC_FILES) $(PROJ_DIR)/src/HAL/$(CHIP_NAME)/
	cd $(HAL_INC_DIR); cp -r --parents $(HAL_INC_FILES) $(PROJ_DIR)/include/HAL/$(CHIP_NAME)/

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $^ $@

$(TARGET).elf: $(OBJS) $(AOBJS)
	$(CC) $^ -o $@ $(LDFLAGS) $(CFLAGS)

$(AOBJS): .build/%.o: %.s
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJS): .build/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

$(DEPS): .build/%.d: %.c
	@mkdir -p $(@D)
	$(CC) -E $(CFLAGS) $< -MM -MT $(@:.d=.o) > $@

clean:
	rm -rf *.elf *.bin .build/

clean-repo:
	rm -rf $(REPO_PATH)

flash: $(TARGET).bin
	st-flash write $^ 0x08000000

NODEPS = clone init init-rec clean clean-repo
.PHONY: all clone init init-rec clean clean-repo flash

ifeq (0, $(words $(findstring $(MAKECMDGOALS), $(NODEPS))))
include $(DEPS)
endif
