#include "stm32f4xx.h"


int main(void) {
    RCC->AHB1ENR |= RCC_AHB1ENR_GPIOCEN;
    GPIOC->MODER |= (1U << (13 * 2));

    while (1) {
        GPIOC->ODR ^= (1U << 13);
        for (volatile int i = 0; i < 500000; i++);
    }
}

