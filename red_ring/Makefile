run:
	wasmtime run --invoke answer red_ring.wat

serve: build
	python3 -m http.server 8000
	
build:
	wat2wasm red_ring.wat
