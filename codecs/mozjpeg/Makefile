ENVIRONMENT = worker

OUT_JS := enc/mozjpeg_enc.js 
OUT_WASM := $(OUT_JS:.js=.wasm)

.PHONY: all clean

all: $(OUT_JS)

$(filter enc/%,$(OUT_JS)): enc/mozjpeg_enc.cpp

%.js:
	$(CXX) \
		-O3 \
		-flto \
		-s FILESYSTEM=0 \
		-s PTHREAD_POOL_SIZE=navigator.hardwareConcurrency \
		-s ALLOW_MEMORY_GROWTH=1 \
		-s TEXTDECODER=2 \
		-s NODEJS_CATCH_EXIT=0 -s NODEJS_CATCH_REJECTION=0 \
		-s ENVIRONMENT=$(ENVIRONMENT) \
		-s EXPORT_ES6=1 \
		-lembind \
		${CXXFLAGS} \
		${LDFLAGS} \
		-o $@ \
		-I ${MOZJPEG}/include \
		-L ${MOZJPEG}/lib \
		-ljpeg \
		${MOZJPEG}/lib/rdswitch.o \
		$+
