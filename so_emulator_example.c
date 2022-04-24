#include <stdio.h>
#include <stdint.h>
#include <assert.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <pthread.h>

#define MEM_SIZE 256

typedef struct __attribute__((packed)) {
  uint8_t A, D, X, Y, PC;
  uint8_t unused; // Wypełniacz, aby struktura zajmowała 8 bajtów.
  bool    C, Z;
} cpu_state_t;

cpu_state_t so_emul(uint16_t* code, uint8_t* data, size_t steps, size_t cores);

uint16_t code_mov[MEM_SIZE] = {
  0x4000 + 0x100 * 0 + 1,           // MOVI A, 1
  0x4000 + 0x100 * 1 + 3,           // MOVI D, 3
  0x4000 + 0x100 * 2 + 0x11,        // MOVI X, 0x11
  0x4000 + 0x100 * 3 + 0x21,        // MOVI Y, 0x21
  0x0000 + 0x100 * 4 + 0x0800 * 0,  // MOV  [X], A
  0x0000 + 0x100 * 5 + 0x0800 * 1,  // MOV  [Y], D
  0x4000 + 0x100 * 6 + 0x07,        // MOVI [X + D], 0x07
  0x0004 + 0x100 * 1 + 0x0800 * 0,  // ADD  D, A
  0x4000 + 0x100 * 6 + 0x08,        // MOVI [X + D], 0x08
  0x0000 + 0x100 * 7 + 0x0800 * 6,  // MOV  [Y + D], [X + D]
  0x0000                            // MOV  A, A; czyli NOP
};

uint8_t data[MEM_SIZE];

static void dump_cpu_state(size_t core, cpu_state_t cpu_state, uint8_t const *data) {
  printf("core %zu: A = %02" PRIx8 ", D = %02" PRIx8 ", X = %02" PRIx8 ", Y = %02"
         PRIx8 ", PC = %02" PRIx8 ", C = %hhu, Z = %hhu, [X] = %02" PRIx8 ", [Y] = %02"
         PRIx8 ", [X + D] = %02" PRIx8 ", [Y + D] = %02" PRIx8 "\n",
         core, cpu_state.A, cpu_state.D, cpu_state.X, cpu_state.Y, cpu_state.PC,
         cpu_state.C, cpu_state.Z, data[cpu_state.X], data[cpu_state.Y],
         data[(cpu_state.X + cpu_state.D) & 0xFF], data[(cpu_state.Y + cpu_state.D) & 0xFF]);
}

int main() {
//	size_t steps = 4;
	printf("before\n");
//	cpu_state_t res = so_emul(code, data, steps);
//	printf("after\n");
//	printf("RES: %ld\n", res);
	dump_cpu_state(0, so_emul(code_mov, data, 4, 0), data);

	return 0;
}
