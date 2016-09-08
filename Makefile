CC=gcc
CFLAGS=-O3 -Wall -Wno-unused-function -Wno-pointer-sign \
       -flto -flto-partition=none -Isecp256k1 -Isecp256k1/include
LDFLAGS=$(CFLAGS)
LDLIBS=-lm -lgmp

OBJS=vanitygen.o base58.o rmd160.o sha256.o

ifeq ($(shell uname -m),x86_64)
  CFLAGS := -march=native $(CFLAGS)
  OBJS += sha256/sha256-avx-asm.o sha256/sha256-avx2-asm.o sha256/sha256-ssse3-asm.o sha256/sha256-ni-asm.o
else ifeq ($(shell uname -m),i686)
  CFLAGS := -march=native $(CFLAGS)
endif


all: vanitygen

install: all
	cp --remove-destination -p vanitygen /usr/local/bin/

clean:
	rm -f vanitygen *.o sha256/*.o

distclean: clean
	$(MAKE) -C secp256k1 distclean

sha256/sha256-%-asm.o: sha256/sha256-%-asm.S sha256/sha256-%-stub.S
	$(CC) -c $< -o $@ >/dev/null 2>/dev/null || $(CC) -c $(subst asm,stub,$<) -o $@

vanitygen: $(OBJS)

$(OBJS): Makefile *.h secp256k1/src/libsecp256k1-config.h secp256k1/src/ecmult_static_context.h

secp256k1/src/libsecp256k1-config.h:
	(cd secp256k1;./autogen.sh;./configure)

secp256k1/src/ecmult_static_context.h:
	$(MAKE) -C secp256k1 src/ecmult_static_context.h
