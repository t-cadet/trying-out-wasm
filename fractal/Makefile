build:
	wat2wasm fractal.wat
serve:
	python3 -m http.server 8000
base64:
	wat2wasm fractal.wat;
	wasm-opt fractal.wasm -all -O4 -o - | base64 -w0 > fractal.wasm.b64

