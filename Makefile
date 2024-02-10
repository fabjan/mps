CODE = src/*.lua
VENDORED = src/vendor/*.lua
DATA = assets/*.png assets/*.ttf assets/*.mp3

mps.love: $(CODE) $(DATA) $(VENDORED)
	rm -rf _build/*
	mkdir -p _build/vendor
	cp $(CODE) _build
	cp $(VENDORED) _build/vendor
	cp $(DATA) _build
	cd _build && zip -r ../mps.love *
