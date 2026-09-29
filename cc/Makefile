CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c99
LIBS = -lm

OBJS = main.o rrd.o rrd_algorithms.o

TARGET = rrdespike

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS) $(LIBS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)
