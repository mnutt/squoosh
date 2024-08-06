ENVIRONMENT = worker

OUT_JS := enc/mozjpeg_enc.js 
OUT_WASM := $(OUT_JS:.js=.wasm)

.PHONY: all clean

all: $(OUT_JS)

# Define dependencies for all variations of build artifacts.
$(filter enc/%,$(OUT_JS)): enc/mozjpeg_enc.cpp
$(filter dec/%,$(OUT_JS)): dec/mozjpeg_dec.cpp

%.js:
	$(CXX) \
		-I ${MOZJPEG}/include \
		${CXXFLAGS} \
		${LDFLAGS} \
		--bind \
		-s ENVIRONMENT=$(ENVIRONMENT) \
		-s EXPORT_ES6=1 \
		-o $@ \
		-ljpeg \
		$+
