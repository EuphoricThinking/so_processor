#include <stdio.h>
#include <stdint.h>

int so_emul(uint16_t* code);
uint16_t code[5] = {
  0x4000 + 0x100 * 2 + 1,           // MOVI X, 1
  0x4000 + 0x100 * 3 + 0,           // MOVI Y, 0
  0x0000 + 0x100 * 0 + 0x0800 * 5};  // MOV  A, [Y]

int main() {
	printf("before\n");
	int res = so_emul(code);
	printf("after\n");
	printf("RES: %d\n", res);

	return 0;
}
