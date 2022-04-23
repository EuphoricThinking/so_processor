#include <stdio.h>

int so_emul();

int main() {
	printf("before\n");
	int res = so_emul();
	printf("after\n");
	printf("RES: %d\n", res);

	return 0;
}
