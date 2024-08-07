ENVIRONMENT = worker

OUT_JS := enc/mozjpeg_enc.js 
OUT_WASM := $(OUT_JS:.js=.wasm)

.PHONY: all clean

all: $(OUT_JS)

$(filter enc/%,$(OUT_JS)): enc/mozjpeg_enc.cpp

%.js:
	$(CXX) \
		-I ${MOZJPEG}/include \
		-L ${MOZJPEG}/lib \
		${CXXFLAGS} \
		${LDFLAGS} \
		--bind \
		-s ENVIRONMENT=$(ENVIRONMENT) \
		-s EXPORT_ES6=1 \
		-o $@ \
		-ljpeg \
		${MOZJPEG}/lib/rdswitch.o \
		$+
