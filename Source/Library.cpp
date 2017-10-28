#include "Pch.h"
#include "Library.h"


eastl::vector<uint8_t> Lib::LoadFile(const char* fileName)
{
	FILE *file = fopen(fileName, "rb");
	assert(file);
	fseek(file, 0, SEEK_END);
	long size = ftell(file);
	assert(size != -1);
	eastl::vector<uint8_t> content(size);
	fseek(file, 0, SEEK_SET);
	fread(&content[0], 1, content.size(), file);
	fclose(file);
	return content;
}

double Lib::GetTime()
{
	LARGE_INTEGER frequency, counter;
	QueryPerformanceCounter(&counter);
	QueryPerformanceFrequency(&frequency);
	return counter.QuadPart / (double)frequency.QuadPart;
}
