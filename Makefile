BUILDROOT ?= buildroot
JOBS      ?= $(shell nproc 2>/dev/null || echo 4)
VERSION   ?= 1.0

.PHONY: all help build build-glibc config config-glibc apply dist lint clean mrproper

all: build

help:
	@printf '%s\n' \
		'DoelzaberiOS targets:' \
		'  build      build the musl live ISO and the installer disk image' \
		'  build-glibc  the same images with a glibc toolchain' \
		'  config     apply and configure only (no long build)' \
		'  config-glibc  the same for the glibc variant' \
		'  apply      copy board/, configs/ and package/ into $(BUILDROOT)' \
		'  dist       collect the images into release/ with SHA256SUMS' \
		'  lint       run the static checks over this repository' \
		'  clean      delete $(BUILDROOT)/output' \
		'  mrproper   delete the $(BUILDROOT) checkout' \
		'' \
		'Variables: BUILDROOT=$(BUILDROOT) JOBS=$(JOBS) VERSION=$(VERSION)'

build:
	./build.sh -b "$(BUILDROOT)" -j "$(JOBS)" -l musl

build-glibc:
	./build.sh -b "$(BUILDROOT)" -j "$(JOBS)" -l glibc

config:
	./build.sh -b "$(BUILDROOT)" -j "$(JOBS)" -l musl -n

config-glibc:
	./build.sh -b "$(BUILDROOT)" -j "$(JOBS)" -l glibc -n

apply:
	./scripts/apply-to-buildroot.sh "$(BUILDROOT)"

dist:
	./scripts/make-release.sh "$(BUILDROOT)" "$(VERSION)"

lint:
	./scripts/lint.sh

clean:
	./build.sh -b "$(BUILDROOT)" -j "$(JOBS)" -c -n

mrproper:
	rm -rf -- "$(BUILDROOT)"
