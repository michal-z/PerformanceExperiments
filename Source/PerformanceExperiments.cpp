#include "Pch.h"
#include "PointCloud.h"
#include "DirectX12.h"
#include "Library.h"

//#define USE_PIX 1
#include "pix3.h"
#if defined(USE_PIX)
#pragma comment(lib, "WinPixEventRuntime.lib")
#endif

void* operator new[](size_t size, const char * /*name*/, int /*flags*/, unsigned /*debugFlags*/,
					 const char * /*file*/, int /*line*/)
{
	return malloc(size);
}

void* operator new[](size_t size, size_t alignment, size_t alignmentOffset, const char * /*name*/, int /*flags*/,
					 unsigned /*debugFlags*/, const char * /*file*/, int /*line*/)
{
	return _aligned_offset_malloc(size, alignment, alignmentOffset);
}

static void UpdateFrameTime(HWND window, const char *windowText, double &o_Time, float &o_DeltaTime)
{
	static double s_LastTime = -1.0;
	static double s_LastFpsTime = 0.0;
	static unsigned s_FrameCount = 0;

	if (s_LastTime < 0.0)
	{
		s_LastTime = Lib::GetTime();
		s_LastFpsTime = s_LastTime;
	}

	o_Time = Lib::GetTime();
	o_DeltaTime = (float)(o_Time - s_LastTime);
	s_LastTime = o_Time;

	if ((o_Time - s_LastFpsTime) >= 1.0)
	{
		const double fps = s_FrameCount / (o_Time - s_LastFpsTime);
		const double ms = (1.0 / fps) * 1000.0;
		char text[256];
		snprintf(text, sizeof(text), "[%.1f fps  %.3f ms] %s", fps, ms, windowText);
		SetWindowText(window, text);
		s_LastFpsTime = o_Time;
		s_FrameCount = 0;
	}
	s_FrameCount++;
}

static LRESULT CALLBACK ProcessWindowMessage(HWND window, UINT message, WPARAM wparam, LPARAM lparam)
{
	switch (message)
	{
	case WM_KEYDOWN:
		if (wparam == VK_ESCAPE)
		{
			PostQuitMessage(0);
			return 0;
		}
		break;
	case WM_DESTROY:
		PostQuitMessage(0);
		return 0;
	}
	return DefWindowProc(window, message, wparam, lparam);
}

static HWND MakeWindow(const char *name, uint32_t resolutionX, uint32_t resolutionY)
{
	WNDCLASS winclass = {};
	winclass.lpfnWndProc = ProcessWindowMessage;
	winclass.hInstance = GetModuleHandle(nullptr);
	winclass.hCursor = LoadCursor(nullptr, IDC_ARROW);
	winclass.lpszClassName = name;
	if (!RegisterClass(&winclass))
		assert(0);

	RECT rect = {0, 0, (int32_t)resolutionX, (int32_t)resolutionY};
	if (!AdjustWindowRect(&rect, WS_OVERLAPPED | WS_SYSMENU | WS_CAPTION | WS_MINIMIZEBOX, 0))
		assert(0);

	HWND window = CreateWindowEx(0, name, name, WS_OVERLAPPED | WS_SYSMENU | WS_CAPTION | WS_MINIMIZEBOX | WS_VISIBLE,
								 CW_USEDEFAULT, CW_USEDEFAULT,
								 rect.right - rect.left, rect.bottom - rect.top,
								 NULL, NULL, NULL, 0);
	assert(window);
	return window;
}

static constexpr char* k_Name = "Performance Experiments";
static constexpr uint32_t k_Resolution[2] = { 1280, 720 };

int CALLBACK WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{
	SetProcessDPIAware();
	HWND window = MakeWindow(k_Name, k_Resolution[0], k_Resolution[1]);

	DirectX12 dx12;
	if (!dx12.Initialize(window))
	{
		// TODO: Add messageBox
		return 1;
	}

	Experiment* experiment = new PointCloud(dx12);
	experiment->Initialize();

	MSG message = {};
	for (;;)
	{
		if (PeekMessage(&message, 0, 0, 0, PM_REMOVE))
		{
			TranslateMessage(&message);
			DispatchMessage(&message);
			if (message.message == WM_QUIT)
				break;
		}
		else
		{
			double frameTime;
			float frameDeltaTime;
			UpdateFrameTime(window, k_Name, frameTime, frameDeltaTime);
			experiment->Update(frameTime, frameDeltaTime);
			experiment->Draw();
			dx12.Present();
		}
	}

	delete experiment;
	return 0;
}
