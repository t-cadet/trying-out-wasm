run:
	wasmtime run --invoke answer minimal_module.wat

serve: build
	python3 -m http.server 8000
	
build:
	wat2wasm minimal_module.wat
