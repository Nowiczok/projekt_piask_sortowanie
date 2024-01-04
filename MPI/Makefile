# tool macros
CC := mpicc
CFLAGS := -Ofast -std=c11 -I../utils
RM := rm -rf
BINARY_NAME := app

SOURCES := main.c ../utils/utils.c ../utils/my_timers.c

.PHONY: build
build: $(SOURCES)
	$(CC) $(CFLAGS) $(SOURCES) -o build/$(BINARY_NAME)

.PHONY: clean
clean:
	$(RM) $(BINARY_NAME)

.PHONY: run
run:
	mpiexec -np 4 ./build/$(BINARY_NAME)

.PHONY: all
all: clean build run