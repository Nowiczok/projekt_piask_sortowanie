# tool macros
CC := nvcc
CFLAGS := 
RM := rm -rf
BINARY_NAME := app

SOURCES := main.cu

.PHONY: build
build: $(SOURCES)
	$(CC) $(CFLAGS) $(SOURCES) -o build/$(BINARY_NAME)

.PHONY: clean
clean:
	$(RM) $(BINARY_NAME)

.PHONY: run
run:
	./build/$(BINARY_NAME)

.PHONY: all
all: clean build run