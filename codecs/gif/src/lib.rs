use wasm_bindgen::prelude::*;
use wasm_bindgen::Clamped;

// Custom ImageData bindings to allow construction with
// a JS-owned copy of the data.
#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(typescript_type = ImageData)]
    pub type ImageData;

    #[wasm_bindgen(constructor)]
    fn new_with_owned_u8_clamped_array_and_sh(
        data: Clamped<Vec<u8>>,
        sw: u16,
        sh: u16,
    ) -> ImageData;

    #[wasm_bindgen(method, getter, js_name = data)]
    fn data(this: &ImageData) -> Clamped<Vec<u8>>;

    #[wasm_bindgen(method, getter)]
    fn width(this: &ImageData) -> u16;

    #[wasm_bindgen(method, getter)]
    fn height(this: &ImageData) -> u16;
}

#[wasm_bindgen]
pub fn encode(data: Clamped<Vec<u8>>, width: u16, height: u16) -> Vec<u8> {
    let mut buffer = Vec::new();

    {
        let global_palette = &[]; // only one frame, don't need global palette
        let mut encoder = gif::Encoder::new(&mut buffer, width, height, global_palette).unwrap();
        let mut data_copy = data.to_vec();
        let frame = gif::Frame::from_rgba(width, height, &mut data_copy);
        encoder.write_frame(&frame).unwrap_throw();
        encoder.into_inner().unwrap_throw();
    }

    buffer
}

#[wasm_bindgen]
pub fn decode(data: &[u8]) -> ImageData {
    let mut options = gif::DecodeOptions::new();
    options.set_color_output(gif::ColorOutput::RGBA);
    let decoder = options.read_info(&*data);
    let mut reader = decoder.unwrap();

    println!("DATA: {:?}", data);
    let mut buf = vec![0; reader.width() as usize * reader.height() as usize * 4];
    let frame = reader.read_next_frame().unwrap().unwrap();
    // frame.buffer is a Cow<'_, [u8]>
    buf.copy_from_slice(&frame.buffer);
    println!("BUF: {:?}", buf);

    ImageData::new_with_owned_u8_clamped_array_and_sh(
        wasm_bindgen::Clamped(buf),
        reader.width(),
        reader.height(),
    )
}
