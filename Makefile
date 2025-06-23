# ============================================================================
# VARIABLES (Think of these as settings you can change)
# ============================================================================

# CC = which compiler to use
CC = gcc

# CFLAGS = compiler flags (options)
# -Wall: show all warnings
# -Wextra: show extra warnings  
# -std=c99: use C99 standard
# -g: include debug information
# CFLAGS = -Wall -Wextra -std=c99 -g
CFLAGS = -std=c99 -g

# Directory where source files live
SRCDIR = src

# Name of the final program
TARGET = clox

# ============================================================================
# FILE LISTS (What files to compile)
# ============================================================================

# Find all .c files in src directory
SOURCES = $(wildcard $(SRCDIR)/*.c)

# Remove test.c from main program (if it exists)
MAIN_SOURCES = $(filter-out $(SRCDIR)/test.c, $(SOURCES))

# For tests: all .c files except main.c, plus test.c
TEST_SOURCES = $(filter-out $(SRCDIR)/main.c, $(SOURCES))

# ============================================================================
# TARGETS (Commands you can run)
# ============================================================================

# .PHONY means these aren't real files, just command names
.PHONY: all clean test run help

# DEFAULT TARGET: runs when you just type "make"
all: $(TARGET)

# BUILD MAIN PROGRAM
# This says: "clox depends on all the MAIN_SOURCES files"
# If any .c or .h file changes, rebuild clox
$(TARGET): $(MAIN_SOURCES)
	$(CC) $(CFLAGS) -o $@ $^

# RUN THE PROGRAM
# This depends on $(TARGET), so it builds first if needed
run: $(TARGET)
	./$(TARGET)

# CLEAN UP (remove built files)
clean:
	rm -f $(TARGET) test_clox *.o $(SRCDIR)/*.o

# BUILD AND RUN TESTS (if you create test.c later)
test: test_clox
	./test_clox

# Build test executable (only if test.c exists)
test_clox: $(TEST_SOURCES)
	$(CC) $(CFLAGS) -o $@ $^

# HELP - show available commands
help:
	@echo "Available commands:"
	@echo "  make        - Build the main program"
	@echo "  make run    - Build and run the program"  
	@echo "  make test   - Build and run tests"
	@echo "  make clean  - Remove built files"
	@echo "  make help   - Show this help"
