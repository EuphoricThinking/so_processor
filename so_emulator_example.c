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

cpu_state_t so_emul(uint16_t const *code, uint8_t *data, size_t steps, size_t core);

uint8_t data[MEM_SIZE];

static const uint16_t code_mov[MEM_SIZE] = {
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

static const uint16_t code_mul[MEM_SIZE] = {
//  0x4000 + 0x100 * 2 + 1,           // MOVI X, 1
//  0x4000 + 0x100 * 3 + 0,           // MOVI Y, 0
//  0x0000 + 0x100 * 0 + 0x0800 * 5,  // MOV  A, [Y]
//  0x4000 + 0x100 * 5 + 0,           // MOVI [Y], 0
//  0x4000 + 0x100 * 1 + 8,           // MOVI D, 8
  0x7001 + 0x100 * 4,               // RCR  [X]
  0xC200 + 2,                       // JNC  +2
  0x8000,                           // CLC
  0x0006 + 0x100 * 5 + 0x0800 * 0,  // ADC  [Y], A
  0x7001 + 0x100 * 5,               // RCR  [Y]
  0x7001 + 0x100 * 4,               // RCR  [X]
  0x6000 + 0x100 * 1 + 255,         // ADDI D, -1
  0xC400 + (uint8_t)-7,             // JNZ  -7
  0xC000                            // MOV  A, A; czyli NOP
};

static void dump_memory(uint8_t const *memory) {
  for (unsigned i = 0; i < MEM_SIZE; ++i) {
    printf("%02" PRIx8, memory[i]);
    unsigned r = i & 0xf;
    if (r == 7)
      printf("  ");
    else if (r == 15)
      printf("\n");
    else
      printf(" ");
  }
}

static void dump_cpu_state(size_t core, cpu_state_t cpu_state, uint8_t const *data) {
  printf("core %zu: A = %02" PRIx8 ", D = %02" PRIx8 ", X = %02" PRIx8 ", Y = %02"
         PRIx8 ", PC = %02" PRIx8 ", C = %hhu, Z = %hhu, [X] = %02" PRIx8 ", [Y] = %02"
         PRIx8 ", [X + D] = %02" PRIx8 ", [Y + D] = %02" PRIx8 "\n",
         core, cpu_state.A, cpu_state.D, cpu_state.X, cpu_state.Y, cpu_state.PC,
         cpu_state.C, cpu_state.Z, data[cpu_state.X], data[cpu_state.Y],
         data[(cpu_state.X + cpu_state.D) & 0xFF], data[(cpu_state.Y + cpu_state.D) & 0xFF]);
}


static void single_core_mul_test(uint8_t a, uint8_t b) {
  cpu_state_t cpu_state;

  data[0] = a;
  data[1] = b;
  dump_memory(data);

  // Kod można wykonywać krokowo.
  dump_cpu_state(0, cpu_state = so_emul(code_mul, data, 0, 0), data);
  while (cpu_state.PC != 13) {
    dump_cpu_state(0, cpu_state = so_emul(code_mul, data, 1, 0), data);
  }

  dump_memory(data);
}

int main() {
//	size_t steps = 4;
	printf("before\n");
//	cpu_state_t res = so_emul(code, data, steps);
//	printf("after\n");
//	printf("RES: %ld\n", res);
//	dump_cpu_state(0, so_emul(code_mov, data, 4, 0), data);
//	printf("seven\n");
//	dump_cpu_state(0, so_emul(code_mov, data, 10, 0), data);
//  dump_memory(data);
	single_core_mul_test(61, 18);

	return 0;
}
