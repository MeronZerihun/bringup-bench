define HELP_TEXT
Please choose one of the following target
  run-tests      - clean, build, and test all benchmarks in all target modes (NA,DO,ENC)
  all-clean      - clean all benchmark directories

Within individual directories, the following Makefile targets are also available:
  clean          - delete all generated files
  build          - build the binary
  test           - run the standard test on the binary

Note that benchmark builds must be parameterized with the build MODE, such as:
  TARGET=host       - build in NATIVE mode, non-data-oblivious build without encryption
  TARGET=standalone - build in DATA-OBLIVIOUS ENCRYPTED mode, data-oblivious build with encrpytion

Example benchmark builds:
  make TARGET=host clean build test
  make TARGET=standalone build
  make TARGET=host clean
endef

export HELP_TEXT

error:
	@echo "$$HELP_TEXT"

#
# END of user-modifiable variables
#
BMARKS = ackermann anagram banner boyer-moore-search bubble-sort c-interp checkers cipher dhrystone distinctness donut fft-int flood-fill frac-calc hanoi heapsort kepler life longdiv lz-compress mandelbrot mersenne natlog nr-solver parrondo pascal pi-calc quine rho-factor shortest-path sieve skeleton spelt2num strange totient

OPT_CFLAGS = -O0 -g

ifeq ($(TARGET), host)
TARGET_CC = gcc
TARGET_CFLAGS = -DTARGET_HOST
TARGET_LIBS =
TARGET_SIM =
TARGET_DIFF = diff
TARGET_EXE = $(PROG).host
TARGET_CLEAN =
TARGET_BMARKS = $(BMARKS)
else ifeq ($(TARGET), standalone)
TARGET_CC = gcc
TARGET_CFLAGS = -DTARGET_SA
TARGET_LIBS =
TARGET_SIM =
TARGET_DIFF = diff
TARGET_EXE = $(PROG).sa
TARGET_CLEAN =
TARGET_BMARKS = $(BMARKS)
else ifeq ($(TARGET), simple)
TARGET_CC = riscv32-unknown-elf-gcc
TARGET_CFLAGS = -DTARGET_SIMPLE -march=rv32imc -mabi=ilp32 -static -mcmodel=medany -Wall -g -Os -fvisibility=hidden -nostdlib -nostartfiles -ffreestanding  -MMD
TARGET_LIBS = -lgcc
TARGET_SIM = ../target/simple_sim.sh ../../Snowflake-IoT/ibex/build/lowrisc_ibex_ibex_simple_system_0/sim-verilator/Vibex_simple_system
TARGET_DIFF = mv ibex_simple_system.log FOO; diff
TARGET_EXE = $(PROG).elf
TARGET_CLEAN = *.d ibex_simple_system_pcount.csv
TARGET_BMARKS = banner bubble-sort cipher dhrystone fft-int flood-fill hanoi heapsort kepler life longdiv mandelbrot mersenne natlog nr-solver parrondo pascal shortest-path sieve skeleton strange totient
else
# default is an error
$(error No build TARGET defined, e.g., make TARGET=host ...)
endif

CFLAGS = -Wall $(OPT_CFLAGS) -Wno-strict-aliasing $(TARGET_CFLAGS) $(LOCAL_CFLAGS)
OBJS = $(LOCAL_OBJS) ../common/libmin.o ../common/libtarg.o
LIBS = $(LOCAL_LIBS) $(TARGET_LIBS)

build: $(TARGET_EXE)

%.o: %.c
	$(TARGET_CC) $(CFLAGS) -I../common/ -o $(notdir $@) -c $<

$(TARGET_EXE): $(OBJS)
ifeq ($(TARGET), host)
	$(TARGET_CC) $(CFLAGS) -o $@ $(notdir $^) $(LIBS)
else ifeq ($(TARGET), standalone)
	$(TARGET_CC) $(CFLAGS) -o $@ $(notdir $^) $(LIBS)
else ifeq ($(TARGET), simple)
	$(TARGET_CC) $(CFLAGS) -T ../target/simple-map.ld $(notdir $^) ../target/simple-crt0.S -o $@ $(LIBS)
else
	$(error MODE is not defined (add: TARGET={host|sa}).)
endif

clean:
	rm -f $(PROG).host $(PROG).sa $(PROG).elf *.o core mem.out *.log FOO $(LOCAL_CLEAN) $(TARGET_CLEAN)


#
# top-level Makefile interfaces
#

run-tests:
	@for _BMARK in $(TARGET_BMARKS) ; do \
	  for _TARGET in host standalone ; do \
	    cd $$_BMARK ; \
	    echo "--------------------------------" ; \
	    echo "Running "$$_BMARK" in TARGET="$$_TARGET ; \
	    echo "--------------------------------" ; \
	    $(MAKE) TARGET=$$TARGET clean build test || exit 1; \
	    cd .. ; \
	  done \
	done

clean-all all-clean: clean
	@for _BMARK in $(BMARKS) ; do \
	  for _TARGET in host standalone ; do \
	    cd $$_BMARK ; \
	    echo "--------------------------------" ; \
	    echo "Cleaning "$$_BMARK" in TARGET="$$_TARGET ; \
	    echo "--------------------------------" ; \
	    $(MAKE) TARGET=$$TARGET clean ; \
	    cd .. ; \
	  done \
	done

