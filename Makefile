CODE = src/*.lua
DATA = assets/*.png assets/*.ttf assets/*.mp3

mps.love: $(CODE) $(DATA)
	mkdir -p _build
	rm -f build/*
	cp $(CODE) _build
	cp $(DATA) _build
	cd _build && zip ../mps.love *
