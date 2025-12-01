#include "stm32f4xx.h"


int main(void) {
    RCC->AHB1ENR |= RCC_AHB1ENR_GPIOAEN;
    GPIOA->MODER |= (1U << (5 * 2));

    while (1) {
        GPIOA->ODR ^= (1U << 5);
        for (volatile int i = 0; i < 500000; i++);
    }
}

