# tool macros
CC := gcc # FILL: the compiler
CFLAGS := -fopenmp -Ofast -std=c11
RM := rm -rf
BINARY_NAME := app

SOURCES := main.c

.PHONY: build
build: $(SOURCES)
	$(CC) $(CFLAGS) $(SOURCES) -o build/$(BINARY_NAME)

.PHONY: clean
clean:
	$(RM) $(BINARY_NAME)

.PHONY: run
run:
	./$(BINARY_NAME)

.PHONY: all
all: clean build run