TARGET = $(notdir $(shell pwd))

SUBDIR = src

# unittest
TESTDIR    = test
TESTTARGET = $(addsuffix Test, $(TARGET))

CC = g++

CFLAGS  = -g3 -Wall -Iinc -lstdc++ -Isrc
LDFLAGS =

SRCS  = $(wildcard $(addsuffix /*.cpp, $(SUBDIR)))
SRCS += $(wildcard $(addsuffix /*.c,   $(SUBDIR)))
DEPS := $(patsubst %.c, %.deps, $(patsubst %.cpp, %.deps, $(SRCS)))
OBJS := $(patsubst %.c, %.o,    $(patsubst %.cpp, %.o,    $(SRCS)))

# unittest
TESTSRCS := $(SRCS)
TESTSRCS := $(filter-out %/Main.cpp, $(TESTSRCS))
TESTSRCS := $(filter-out %/Main.c,   $(TESTSRCS))
TESTSRCS += $(wildcard $(addsuffix /*.cpp, $(TESTDIR)))
TESTSRCS += $(wildcard $(addsuffix /*.c,   $(TESTDIR)))
TESTDEPS := $(patsubst %.c, %.deps, $(patsubst %.cpp, %.deps, $(TESTSRCS)))
TESTOBJS := $(patsubst %.c, %.o,    $(patsubst %.cpp, %.o,    $(TESTSRCS)))

ifeq ("$(SRCS)", " ")
exit:
endif

# fake target
.PHONY: all run clean coverage release debug echo test exit

all: $(TARGET)

run: $(TARGET)
	./$(TARGET) in.txt

clean:
	rm -rf $(TARGET)
	rm -rf $(OBJS)
	rm -rf $(DEPS)

test: CFLAGS += -UNDEBUG
test: LDFLAGS += -lgtest -lpthread
test: $(TESTTARGET)
	# @rm -rf test.png
	# ./$(TESTTARGET) 2> test.dot && dot -Tpng test.dot -o test.png && display test.png
	./$(TESTTARGET) in.txt 2> test.dot

coverage: CFLAGS  += --coverage
coverage: LDFLAGS += --coverage
coverage: all

release: CFLAGS += -O2
release: all

ifneq ("$(MAKECMDGOALS)", "clean")
include $(DEPS)
endif
ifeq ("$(MAKECMDGOALS)", "test")
include $(TESTDEPS)
endif

# real target
echo:
	@echo $(SRCS)
	@echo $(DEPS)
	@echo $(OBJS)

$(TARGET): $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS)

$(TESTTARGET): $(TESTOBJS)
	$(CC) -o $@ $^ $(LDFLAGS)

%.deps: %.cpp
	@set -e ; \
	$(CC) $(CFLAGS) -MM $< > $@; \
	sed -E -i "s,(.*):,$(dir $@)\1:,g" $@;

%.deps: %.c
	@set -e ; \
	$(CC) $(CFLAGS) -MM $< > $@; \
	sed -E -i "s,(.*):,$(dir $@)\1:,g" $@;

%.o: %.cpp
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

