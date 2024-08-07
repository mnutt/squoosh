ENVIRONMENT = worker

# OUT_JS = enc/webp_enc.js enc/webp_enc_simd.js dec/webp_dec.js 
OUT_JS = enc/webp_enc.js dec/webp_dec.js 
OUT_WASM := $(OUT_JS:.js=.wasm)

.PHONY: all clean

all: $(OUT_JS)

# Define dependencies for all variations of build artifacts.
$(filter enc/%,$(OUT_JS)): enc/webp_enc.o
$(filter dec/%,$(OUT_JS)): dec/webp_dec.o
# enc/webp_enc.js dec/webp_dec.js: $(CODEC_BASELINE_BUILD_DIR)/libwebp.a
# enc/webp_enc_simd.js: $(CODEC_SIMD_BUILD_DIR)/libwebp.a

LIBWEBP_FLAGS = -I${WEBP}/include -L${WEBP}/lib -lwebp

$(OUT_JS):
	$(LD) \
		-O3 \
		-flto \
		-std=c++17 \
		-s FILESYSTEM=0 \
		-s PTHREAD_POOL_SIZE=navigator.hardwareConcurrency \
		-s ALLOW_MEMORY_GROWTH=1 \
		-s TEXTDECODER=2 \
		-s NODEJS_CATCH_EXIT=0 -s NODEJS_CATCH_REJECTION=0 \
		$(LIBWEBP_FLAGS) \
		$(LDFLAGS) \
		-lembind \
		-s ENVIRONMENT=$(ENVIRONMENT) \
		-s EXPORT_ES6=1 \
		-o $@ \
		$+

%.o: %.cpp 
	$(CXX) -c \
		-O3 \
		-flto \
		-std=c++17 \
		-s FILESYSTEM=0 \
		-s PTHREAD_POOL_SIZE=navigator.hardwareConcurrency \
		-s ALLOW_MEMORY_GROWTH=1 \
		-s TEXTDECODER=2 \
		-s NODEJS_CATCH_EXIT=0 -s NODEJS_CATCH_REJECTION=0 \
		$(LIBWEBP_FLAGS) \
		$(CXXFLAGS) \
		-o $@ \
		$<

