#include <stdio.h>
#include <stdint.h>

#define MEM_SIZE 256

uint64_t so_emul(uint16_t* code, uint8_t* data, size_t steps);

uint16_t code[MEM_SIZE] = {
  0x0004,
  0x4000 + 0x100 * 2 + 1,           // MOVI X, 1
  0x4000 + 0x100 * 3 + 0,           // MOVI Y, 0
  0x0000 + 0x100 * 0 + 0x0800 * 5
};  // MOV  A, [Y]

uint8_t data[MEM_SIZE];

int main() {
	size_t steps = 1;
	printf("before\n");
	uint64_t res = so_emul(code, data, steps);
	printf("after\n");
	printf("RES: %ld\n", res);

	return 0;
}
