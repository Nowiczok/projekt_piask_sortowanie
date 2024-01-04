# tool macros
CC := icc
CFLAGS := -qopenmp -Ofast -std=c11 -I../utils
RM := rm -rf
BINARY_NAME := app

SOURCES := main.c ../utils/my_timers.c

.PHONY: build
build: $(SOURCES)
	$(CC) $(CFLAGS) $(SOURCES) -o build/$(BINARY_NAME)

.PHONY: clean
clean:
	$(RM) ./build/$(BINARY_NAME)

.PHONY: run
run:
	build/$(BINARY_NAME)

.PHONY: all
all: clean build run