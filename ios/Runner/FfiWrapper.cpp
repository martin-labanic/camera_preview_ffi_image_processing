#include <stdint.h>
#include <string.h>
#include <chrono>

extern "C" {
	__attribute__((visibility("default"))) __attribute__((used))
	double ffiProcessImage(unsigned char *data, int width, int height, int scanLine) { // Placed in the runner project instead of the plugin because there is a 3rd party static library that I use to process image data.
		auto start = std::chrono::high_resolution_clock::now();
		// Image processing code; not needed to demonstrate the performance issues I'm seeing.
		std::chrono::duration<double> elapsedSeconds = std::chrono::high_resolution_clock::now()-start;
		return elapsedSeconds.count();
	}
}
