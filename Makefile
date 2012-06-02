.SUFFIXES:  # delete default rules

# Put local customisations into `mk/build.mk`.
-include mk/build.mk

# DIST must be an absolute directory
ifeq ($(DIST),)
DIST := $(shell pwd)/dist
endif

HC ?= ghc
HC_PKG ?= ghc-pkg
CC ?= gcc
CCC ?= g++

ifeq "$(strip $(PerformanceBuild))" "Yes"
EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DNDEBUG
endif

ifeq "$(strip $(SelfCheck))" "Yes"
EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DLC_SELF_CHECK_MODE
endif

ifeq "$(strip $(DisableJit))" "Yes"
EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DLC_HAS_JIT=0
endif

ifneq ($(DebugLevel),)
EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DLC_DEBUG_LEVEL=$(DebugLevel)
endif

ifeq "$(strip $(DisableAsm))" "Yes"
EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DLC_HAS_ASM_BACKEND=0
endif

ifeq "$(shell uname)" "Darwin"
EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DNEEDS_UNDERSCORE
EXTRA_LDFLAGS := $(EXTRA_LDFLAGS) -Wl,-no_pie
endif

HSBUILDDIR = $(DIST)/build
LCC = $(HSBUILDDIR)/lcc/lcc
CABAL ?= cabal

DEPDIR = $(DIST)/.deps
DEPDIRS = $(DEPDIR) $(DEPDIR)/rts

.PHONY: all
all: interp compiler/Opcodes.h $(LCC) lcc

.PHONY: boot
boot:
	mkdir -p $(HSBUILDDIR)
	mkdir -p $(DEPDIR)/rts
	mkdir -p $(DEPDIR)/rts/codegen
	mkdir -p $(DEPDIR)/vm
	mkdir -p $(DEPDIR)/utils
	test -f mk/build.mk || touch mk/build.mk

INCLUDES = -Iincludes -Irts -Irts/codegen
CFLAGS = -Wall -g $(EXTRA_CFLAGS)

df = $(DEPDIR)/$(*D)/$(*F)

#SRCS := $(wildcard rts/*.c)
SRCS = rts/Bytecode.c rts/Capability.c rts/ClosureFlags.c \
       rts/FileUtils.c rts/HashTable.c rts/InterpThreaded.c \
       rts/Loader.c rts/MiscClosures.c rts/PrintClosure.c \
       rts/Thread.c rts/StorageManager.c \
       rts/Main.c \
       rts/Record.c rts/PrintIR.c rts/OptimiseIR.c \
       rts/Snapshot.c rts/HeapInfo.c rts/Bitset.c \
       rts/InterpIR.c rts/Stats.c \
       rts/codegen/MCode.c rts/codegen/InterpAsm.c \
       rts/codegen/AsmCodeGen.c \
       rts/GC.c rts/ShadowHeap.c \
	rts/Jit.c

UTILSRCS = utils/genopcodes.c

echo:
	@echo "SRCS = $(SRCS)"
#SRCS = rts/Loader.c rts/HashTable.c

#
# === GoogleTest =======================================================
#

GTEST_VERSION=1.6.0
UNZIP=unzip
AT=@
GTEST_DEFS=-DGTEST_HAS_PTHREAD=0
GTEST_DIR=utils/gtest-$(GTEST_VERSION)
GTEST_A=$(GTEST_DIR)/libgtest.a

$(GTEST_DIR): $(GTEST_DIR).zip
	cd `dirname $(GTEST_DIR)` && $(UNZIP) `basename $<`

${GTEST_DIR}/src/gtest-all.cc: ${GTEST_DIR} 

$(GTEST_DIR)/src/gtest-all.o: ${GTEST_DIR}/src/gtest-all.cc 
	@echo "Compiling googletest framework"
	$(CCC) -I${GTEST_DIR}/include -I${GTEST_DIR} $(GTEST_DEFS) -c $< -o $@

$(GTEST_A): $(GTEST_DIR)/src/gtest-all.o
	ar -rv $@ $<

# ======================================================================

interp: $(SRCS:.c=.o)
	@echo "LINK $(EXTRA_LDFLAGS) $^ => $@"
	@$(CC) $(EXTRA_LDFLAGS) -o $@ $^

lcc: $(LCC)
	ln -fs $(LCC) $@

vm/unittest.o: $(GTEST_A)

# Building a C file automatically generates dependencies as a side
# effect.  This only works with `gcc'.
#
# The dependency file for `rts/Foo.c' lives at `.deps/rts/Foo.c'.
#
%.o: %.c mk/build.mk
	@echo "CC $(CFLAGS) $< => $@"
	@$(CC) -c $(INCLUDES) -MD -MF $(patsubst %.c,$(DEPDIR)/%.d,$<) $(CFLAGS) -o $@ $<
	@cp $(df).d $(df).P; \
	    sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
	        -e '/^$$/ d' -e 's/$$/ :/' < $(df).d >> $(df).P; \
	rm -f $(df).d

%.o: %.cc mk/build.mk
	@echo "C++ $(CFLAGS) $< => $@"
	@$(CCC) -c $(INCLUDES) -I$(GTEST_DIR)/include $(GTEST_DEFS) \
	        -MD -MF $(patsubst %.cc,$(DEPDIR)/%.d,$<) $(CFLAGS) -o $@ $<
	@cp $(df).d $(df).P; \
	    sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
	        -e '/^$$/ d' -e 's/$$/ :/' < $(df).d >> $(df).P; \
	rm -f $(df).d

VM_SRCS = vm/thread.cc vm/capability.cc vm/memorymanager.cc

unittest: vm/unittest.o $(GTEST_A) $(VM_SRCS:.cc=.o)
	@echo "LINK $^ => $@"
	@$(CCC) -o $@ $^

.PHONY: test
test: unittest
	@./unittest 2> /dev/null # ignore debug output

utils/genopcodes: utils/genopcodes.o
	@echo "LINK $^ => $@"
	@$(CC) -o $@ $^

utils/print_config: utils/print_config.o
	@echo "LINK $^ => $@"
	@$(CC) -o $@ $^

compiler/Opcodes.h: utils/genopcodes
	./$< > $@

HSDEPFILE = compiler/.depend

HSFLAGS = -hide-all-packages \
          -package ghc -package base -package filepath -package process -package directory -package containers \
          -package ghc-paths -package cmdargs -package mtl -package blaze-builder -package vector \
          -package utf8-string -package bytestring -package array -package ansi-wl-pprint -package binary \
          -package uniplate -package hoopl -package value-supply \
          -package graph-serialize -package temporary \
          -icompiler \
          -odir $(HSBUILDDIR) -hidir $(HSBUILDDIR)

$(HSDEPFILE):
	$(HC) -M $(HSFLAGS) compiler/Main.hs -dep-makefile $(HSDEPFILE)

# include $(HSDEPFILE)

%.hi: %.o
	@:

%.o: %.hs
	$(HC) -c $< $(HSFLAGS)

HSSRCS := $(shell find compiler -name '*.hs')

# FIXME: We let the compiler depend on the source files not the .o
# files.  This actually doesn't always work.  Fortunately,
#
#    make clean && make boot && make
#
# is pretty quick.

# .PHONY:

$(DIST)/setup-config: lambdachine.cabal
	$(CABAL) configure --with-compiler=$(HC) --with-hc-pkg=$(HC_PKG)

$(LCC): $(HSSRCS) compiler/Opcodes.h $(DIST)/setup-config
	@mkdir -p $(HSBUILDDIR)
	$(CABAL) build

.PHONY: clean-interp
clean-interp:
	rm -f $(SRCS:%.c=%.o) utils/*.o interp

.PHONY: clean
clean:
	rm -f $(SRCS:%.c=%.o) utils/*.o interp compiler/.depend \
		compiler/lcc lcc $(DIST)/setup-config vm/*.o
	rm -rf $(HSBUILDDIR)
	$(MAKE) -C tests clean

.PHONY: install-deps
install-deps:
	$(CABAL) install --only-dependencies --with-compiler=$(HC) \
	  --with-hc-pkg=$(HC_PKG)
# find compiler -name "*.hi" -delete

# Rules for building built-in packages

LCCFLAGS = --dump-bytecode --dump-core-binds

tests/ghc-prim/%.lcbc: tests/ghc-prim/%.hs
	cd tests/ghc-prim && \
	$(LCC) $(LCCFLAGS) --package-name=ghc-prim $(patsubst tests/ghc-prim/%, %, $<)

tests/integer-gmp/%.lcbc: tests/integer-gmp/%.hs
	cd tests/integer-gmp && \
	$(LCC) $(LCCFLAGS) --package-name=integer-gmp $(patsubst tests/integer-gmp/%, %, $<)

tests/base/%.lcbc: tests/base/%.hs
	cd tests/base && \
	$(LCC) $(LCCFLAGS) --package-name=base $(patsubst tests/base/%, %, $<)
#	@echo "@ = $@, < = $<"

PRIM_MODULES_ghc-prim = GHC/Bool GHC/Types GHC/Ordering GHC/Tuple
PRIM_MODULES_integer-gmp = GHC/Integer/Type GHC/Integer
PRIM_MODULES_base = GHC/Base GHC/Classes GHC/Num GHC/List \
	Control/Exception/Base

PRIM_MODULES = \
	$(patsubst %,tests/ghc-prim/%.lcbc,$(PRIM_MODULES_ghc-prim)) \
	$(patsubst %,tests/integer-gmp/%.lcbc,$(PRIM_MODULES_integer-gmp)) \
	$(patsubst %,tests/base/%.lcbc,$(PRIM_MODULES_base))

.PHONY: check
TESTS ?= .
check: $(PRIM_MODULES)
	@ $(MAKE) -C tests check TESTS=$(TESTS) LITARGS=$(LITARGS)

.PHONY: bench
bench: $(PRIM_MODULES)
	$(MAKE) -C tests check TESTS=Bench LITARGS=$(LITARGS)

pr:
	@echo $(PRIM_MODULES)

clean-bytecode:
	rm -f $(PRIM_MODULES)
	$(MAKE) -C tests clean

.PHONY: gtest
gtest: $(GTEST_A)

-include $(SRCS:%.c=$(DEPDIR)/%.P)
-include $(UTILSRCS:%.c=$(DEPDIR)/%.P)

