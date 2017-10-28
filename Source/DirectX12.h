#pragma once

#define VHR(hr) if (FAILED(hr)) { assert(0); }
#define SAFE_RELEASE(obj) if ((obj)) { (obj)->Release(); (obj) = nullptr; }

class DirectX12
{
public:
	~DirectX12();
	bool Initialize(HWND window);
	void Present() const;
	void Flush() const;

	ID3D12Device* GetDevice() const;
	ID3D12CommandAllocator* GetCmdAllocator() const;
	ID3D12CommandQueue* GetCmdQueue() const;
	ID3D12GraphicsCommandList* GetCmdList() const;
	ID3D12Resource* GetBackBuffer() const;
	D3D12_CPU_DESCRIPTOR_HANDLE GetBackBufferHandle() const;
	D3D12_CPU_DESCRIPTOR_HANDLE GetDepthBufferHandle() const;
	const D3D12_VIEWPORT& GetViewport() const;
	const D3D12_RECT& GetScissorRect() const;
	uint32_t GetFrameIndex() const;

private:
	mutable uint32_t m_BackBufferIndex = 0;
	mutable uint32_t m_FrameIndex = 0;

	uint32_t m_DescriptorSize;
	uint32_t m_DescriptorSizeRtv;
	D3D12_CPU_DESCRIPTOR_HANDLE m_SwapBuffersHeapStart;
	D3D12_CPU_DESCRIPTOR_HANDLE m_DepthBufferHeapStart;

	ID3D12Device* m_Device = nullptr;
	ID3D12CommandQueue* m_CmdQueue = nullptr;
	ID3D12CommandAllocator* m_CmdAlloc[2] = {};
	ID3D12GraphicsCommandList* m_CmdList = nullptr;

	IDXGIFactory4* m_Factory = nullptr;
	IDXGISwapChain3* m_SwapChain = nullptr;
	ID3D12DescriptorHeap* m_SwapBuffersHeap = nullptr;
	ID3D12DescriptorHeap* m_DepthBufferHeap = nullptr;
	ID3D12Resource* m_SwapBuffers[4] = {};
	ID3D12Resource*	m_DepthBuffer = nullptr;

	mutable uint64_t m_CpuCompletedFrames = 0;
	ID3D12Fence* m_FrameFence = nullptr;
	HANDLE m_FrameFenceEvent = nullptr;

	D3D12_VIEWPORT m_Viewport;
	D3D12_RECT m_ScissorRect;
};

inline ID3D12Device* DirectX12::GetDevice() const
{
	return m_Device;
}

inline ID3D12CommandAllocator* DirectX12::GetCmdAllocator() const
{
	return m_CmdAlloc[m_FrameIndex];
}

inline ID3D12CommandQueue* DirectX12::GetCmdQueue() const
{
	return m_CmdQueue;
}

inline ID3D12GraphicsCommandList* DirectX12::GetCmdList() const
{
	return m_CmdList;
}

inline ID3D12Resource* DirectX12::GetBackBuffer() const
{
	return m_SwapBuffers[m_BackBufferIndex];
}

inline D3D12_CPU_DESCRIPTOR_HANDLE DirectX12::GetBackBufferHandle() const
{
	D3D12_CPU_DESCRIPTOR_HANDLE h = m_SwapBuffersHeapStart;
	h.ptr += m_BackBufferIndex * m_DescriptorSizeRtv;
	return h;
}

inline D3D12_CPU_DESCRIPTOR_HANDLE DirectX12::GetDepthBufferHandle() const
{
	return m_DepthBufferHeapStart;
}

inline const D3D12_VIEWPORT& DirectX12::GetViewport() const
{
	return m_Viewport;
}

inline const D3D12_RECT& DirectX12::GetScissorRect() const
{
	return m_ScissorRect;
}

inline uint32_t DirectX12::GetFrameIndex() const
{
	return m_FrameIndex;
}
