#include <stdint.h>
#include <string.h>
#include <chrono>

extern "C" {
	__attribute__((visibility("default"))) __attribute__((used))
	double ffiProcessImage(unsigned char *data, int width, int height, int scanLine) {
		auto start = std::chrono::high_resolution_clock::now();
		// Image processing code; not needed to demonstrate the performance issues I'm seeing.
		std::chrono::duration<double> elapsedSeconds = std::chrono::high_resolution_clock::now()-start;
		return elapsedSeconds.count();
	}
}
