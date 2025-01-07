




run: cachesim.cpp
	g++ cachesim.cpp -o cachesim -std=c++20
	./cachesim $(ITRACE)

cachesim: cachesim.cpp
	echo g++ cachesim.cpp -o cachesim -std=c++20
	./cachesim $(ITRACE) -DNUM_BLOCKS=32
