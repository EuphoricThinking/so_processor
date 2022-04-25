gcc -DCORES=1 -c -Wall -Wextra -std=c17 -O2 -o so_emulator_example.o so_emulator_example.c # -DCORES=1
nasm -DCORES=1 -f elf64 -w+all -w+error -o so_emulator.o so_emulator.asm # -DCORES=1
gcc -pthread -o so_emulator_example so_emulator_example.o so_emulator.o
./so_emulator_example 61 18
#rm *.o
