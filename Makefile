# arch = {riscv32, riscv64, x86_64, aarch64}
# mode = {debug, release}
arch ?= riscv32
mode ?= debug
out_dir ?= build/$(arch)
out_img ?= build/$(arch).img

rust_src_dir := rust/src/bin
rust_bin_path := rust/target/$(arch)-rcore/$(mode)
rust_bins := $(patsubst $(rust_src_dir)/%.rs, $(rust_bin_path)/%, $(wildcard $(rust_src_dir)/*.rs))
ucore_bin_path := ucore/build/$(arch)
biscuit_bin_path := biscuit/build/$(arch)
busybox := $(out_dir)/busybox

rust_build_args := --target targets/$(arch)-rcore.json
cmake_build_args := -DARCH=$(arch)

ifeq ($(mode), release)
rust_build_args += --release
cmake_build_args += -DCMAKE_BUILD_TYPE=Release
endif


.PHONY: all clean build rust ucore biscuit bin

all: build

rust:
	@echo Building rust programs
	@cd rust && cargo xbuild $(rust_build_args)
	@rm -rf $(out_dir)/rust && mkdir -p $(out_dir)/rust
	@cp $(rust_bins) $(out_dir)/rust

ucore:
ifneq ($(arch), x86_64)
	@echo Building ucore programs
	@mkdir -p ucore/build
	@cd ucore/build && cmake $(cmake_build_args) .. && make
	@rm -rf $(out_dir)/ucore && mkdir -p $(out_dir)/ucore
	@cp $(ucore_bin_path)/* $(out_dir)/ucore
endif

biscuit:
ifeq ($(arch), $(filter $(arch), x86_64 aarch64))
	@echo Building biscuit programs
	@mkdir -p biscuit/build
	@cd biscuit/build && cmake $(cmake_build_args) .. && make
	@rm -rf $(out_dir)/biscuit && mkdir -p $(out_dir)/biscuit
	@cp $(biscuit_bin_path)/* $(out_dir)/biscuit
endif

$(busybox):
	wget https://busybox.net/downloads/binaries/1.21.1/busybox-x86_64 -O $(busybox)

build: rust ucore biscuit $(busybox)

sfsimg: $(out_img)

$(out_img): build mksfs
	@mksfs zip $(out_dir) $@

mksfs:
ifeq ($(shell which mksfs),)
	@cargo install --git https://github.com/wangrunji0408/SimpleFileSystem-Rust --features="std"
endif

clean:
	@cd rust && cargo clean
	@rm -rf biscuit/build ucore/build
	@rm -rf $(out_dir)
