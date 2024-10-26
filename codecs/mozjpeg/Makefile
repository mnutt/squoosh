CODEC_URL = https://github.com/mozilla/mozjpeg/archive/v4.1.1.tar.gz
CODEC_DIR = node_modules/mozjpeg
CODEC_BUILD_ROOT := $(CODEC_DIR)/build
ENVIRONMENT = worker
SOURCE_DATE_EPOCH = 0

OUT_JS := enc/mozjpeg_enc.js enc/mozjpeg_node_enc.js dec/mozjpeg_node_dec.js
OUT_WASM := $(OUT_JS:.js=.wasm)

.PHONY: all clean

all: $(OUT_JS)

# Define dependencies for all variations of build artifacts.
$(filter enc/%,$(OUT_JS)): enc/mozjpeg_enc.cpp
$(filter dec/%,$(OUT_JS)): dec/mozjpeg_dec.cpp
enc/mozjpeg_node_enc.js dec/mozjpeg_node_dec.js: ENVIRONMENT = node
$(OUT_JS): $(CODEC_BUILD_ROOT)/libjpeg.a $(CODEC_BUILD_ROOT)/rdswitch.o

enc/mozjpeg_enc.cpp: $(CODEC_BUILD_ROOT)/libjpeg.a
dec/mozjpeg_dec.cpp: $(CODEC_BUILD_ROOT)/libjpeg.a

$(OUT_JS):
	$(CXX) \
		$(CXXFLAGS) \
		$(LDFLAGS) \
		-I $(CODEC_DIR) \
		-I $(CODEC_BUILD_ROOT) \
		--bind \
		-s ENVIRONMENT=$(ENVIRONMENT) \
		-s EXPORT_ES6=1 \
		-o $@ \
		$+

%/libjpeg.a: %/Makefile
	$(MAKE) -C $(<D)

# libjpeg doesn't include rdswitch by default so we yoink it from cjpeg-static.
$(CODEC_BUILD_ROOT)/rdswitch.o: $(CODEC_BUILD_ROOT)/libjpeg.a
	cp $(CODEC_BUILD_ROOT)/CMakeFiles/cjpeg-static.dir/rdswitch.c.o $@

%/Makefile: $(CODEC_DIR)/CMakeLists.txt
	emcmake cmake \
		$(CMAKE_FLAGS) \
		-DENABLE_SHARED=0 \
		-DPNG_SUPPORTED=0 \
		-DWITH_TURBOJPEG=0 \
		-DWITH_SIMD=0 \
		-DWITH_ARITH_ENC=0 \
		-DWITH_ARITH_DEC=0 \
		-B $(CODEC_BUILD_ROOT) \
		$(<D)

$(CODEC_DIR)/CMakeLists.txt:
	mkdir -p $(CODEC_DIR)
	curl -sL $(CODEC_URL) | tar xz --strip 1 -C $(CODEC_DIR)

clean:
	$(RM) $(OUT_JS) $(OUT_WASM)
	$(MAKE) -C $(CODEC_DIR) clean
