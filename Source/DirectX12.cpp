#include "Pch.h"
#include "DirectX12.h"


#define ENABLE_DEBUG_LAYER 1

DirectX12::~DirectX12()
{
	if (m_FrameFence && m_CmdQueue)
		Flush();
	if (m_FrameFenceEvent)
		CloseHandle(m_FrameFenceEvent);
	SAFE_RELEASE(m_FrameFence);
	for (uint32_t i = 0; i < 4; ++i)
		SAFE_RELEASE(m_SwapBuffers[i]);
	SAFE_RELEASE(m_DepthBuffer);
	SAFE_RELEASE(m_SwapBuffersHeap);
	SAFE_RELEASE(m_DepthBufferHeap);
	SAFE_RELEASE(m_SwapChain);
	SAFE_RELEASE(m_Factory);
	SAFE_RELEASE(m_CmdList);
	for (uint32_t i = 0; i < 2; ++i)
		SAFE_RELEASE(m_CmdAlloc[i]);
	SAFE_RELEASE(m_CmdQueue);
	SAFE_RELEASE(m_Device);
}

bool DirectX12::Initialize(HWND window)
{
	assert(m_Device == nullptr);
	assert(window != nullptr);

	VHR(CreateDXGIFactory1(IID_PPV_ARGS(&m_Factory)));

#if ENABLE_DEBUG_LAYER == 1
	ID3D12Debug* dbg = nullptr;
	D3D12GetDebugInterface(IID_PPV_ARGS(&dbg));
	if (dbg)
	{
		dbg->EnableDebugLayer();
		dbg->Release();
	}
#endif
	if (FAILED(D3D12CreateDevice(nullptr, D3D_FEATURE_LEVEL_12_0, IID_PPV_ARGS(&m_Device))))
	{
		return false;
	}

	D3D12_COMMAND_QUEUE_DESC cmdQueueDesc = {};
	cmdQueueDesc.Flags = D3D12_COMMAND_QUEUE_FLAG_NONE;
	cmdQueueDesc.Priority = D3D12_COMMAND_QUEUE_PRIORITY_NORMAL;
	cmdQueueDesc.Type = D3D12_COMMAND_LIST_TYPE_DIRECT;
	VHR(m_Device->CreateCommandQueue(&cmdQueueDesc, IID_PPV_ARGS(&m_CmdQueue)));

	DXGI_SWAP_CHAIN_DESC swapChainDesc = {};
	swapChainDesc.BufferCount = 4;
	swapChainDesc.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
	swapChainDesc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
	swapChainDesc.OutputWindow = window;
	swapChainDesc.SampleDesc.Count = 1;
	swapChainDesc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL;
	swapChainDesc.Windowed = 1;

	IDXGISwapChain* tempSwapChain;
	VHR(m_Factory->CreateSwapChain(m_CmdQueue, &swapChainDesc, &tempSwapChain));
	VHR(tempSwapChain->QueryInterface(IID_PPV_ARGS(&m_SwapChain)));
	SAFE_RELEASE(tempSwapChain);

	for (uint32_t i = 0; i < 2; ++i)
	{
		VHR(m_Device->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, IID_PPV_ARGS(&m_CmdAlloc[i])));
	}

	GetClientRect(window, &m_ScissorRect);
	m_Viewport = CD3DX12_VIEWPORT(0.0f, 0.0f, (float)m_ScissorRect.right, (float)m_ScissorRect.bottom);

	m_DescriptorSize = m_Device->GetDescriptorHandleIncrementSize(D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV);
	m_DescriptorSizeRtv = m_Device->GetDescriptorHandleIncrementSize(D3D12_DESCRIPTOR_HEAP_TYPE_RTV);

	{	// swap buffers
		D3D12_DESCRIPTOR_HEAP_DESC heapDesc = {};
		heapDesc.NumDescriptors = 4;
		heapDesc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_RTV;
		heapDesc.Flags = D3D12_DESCRIPTOR_HEAP_FLAG_NONE;
		VHR(m_Device->CreateDescriptorHeap(&heapDesc, IID_PPV_ARGS(&m_SwapBuffersHeap)));
		m_SwapBuffersHeapStart = m_SwapBuffersHeap->GetCPUDescriptorHandleForHeapStart();

		CD3DX12_CPU_DESCRIPTOR_HANDLE handle(m_SwapBuffersHeapStart);

		for (uint32_t i = 0; i < 4; ++i)
		{
			VHR(m_SwapChain->GetBuffer(i, IID_PPV_ARGS(&m_SwapBuffers[i])));

			m_Device->CreateRenderTargetView(m_SwapBuffers[i], nullptr, handle);
			handle.Offset(m_DescriptorSizeRtv);
		}
	}
	{	// depth buffer
		D3D12_DESCRIPTOR_HEAP_DESC heapDesc = {};
		heapDesc.NumDescriptors = 1;
		heapDesc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_DSV;
		heapDesc.Flags = D3D12_DESCRIPTOR_HEAP_FLAG_NONE;
		VHR(m_Device->CreateDescriptorHeap(&heapDesc, IID_PPV_ARGS(&m_DepthBufferHeap)));
		m_DepthBufferHeapStart = m_DepthBufferHeap->GetCPUDescriptorHandleForHeapStart();

		// TODO: set proper width and height
		CD3DX12_RESOURCE_DESC imageDesc = CD3DX12_RESOURCE_DESC::Tex2D(DXGI_FORMAT_D32_FLOAT, 1280, 720);
		imageDesc.Flags = D3D12_RESOURCE_FLAG_ALLOW_DEPTH_STENCIL;
		VHR(m_Device->CreateCommittedResource(&CD3DX12_HEAP_PROPERTIES(D3D12_HEAP_TYPE_DEFAULT), D3D12_HEAP_FLAG_NONE,
											  &imageDesc, D3D12_RESOURCE_STATE_DEPTH_WRITE,
											  &CD3DX12_CLEAR_VALUE(DXGI_FORMAT_D32_FLOAT, 1.0f, 0), IID_PPV_ARGS(&m_DepthBuffer)));

		D3D12_DEPTH_STENCIL_VIEW_DESC viewDesc = {};
		viewDesc.Format = DXGI_FORMAT_D32_FLOAT;
		viewDesc.ViewDimension = D3D12_DSV_DIMENSION_TEXTURE2D;
		viewDesc.Flags = D3D12_DSV_FLAG_NONE;
		m_Device->CreateDepthStencilView(m_DepthBuffer, &viewDesc, m_DepthBufferHeapStart);
	}
	VHR(m_Device->CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&m_FrameFence)));

	m_FrameFenceEvent = CreateEventEx(nullptr, nullptr, 0, EVENT_ALL_ACCESS);
	assert(m_FrameFenceEvent);

	VHR(m_Device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, m_CmdAlloc[0], nullptr, IID_PPV_ARGS(&m_CmdList)));

	return true;
}

void DirectX12::Present() const
{
	assert(m_SwapChain && m_CmdQueue);

	m_SwapChain->Present(0, 0);
	m_CmdQueue->Signal(m_FrameFence, ++m_CpuCompletedFrames);

	const uint64_t gpuCompletedFrames = m_FrameFence->GetCompletedValue();

	if ((m_CpuCompletedFrames - gpuCompletedFrames) >= 2)
	{
		m_FrameFence->SetEventOnCompletion(gpuCompletedFrames + 1, m_FrameFenceEvent);
		WaitForSingleObject(m_FrameFenceEvent, INFINITE);
	}

	m_BackBufferIndex = m_SwapChain->GetCurrentBackBufferIndex();
	m_FrameIndex = !m_FrameIndex;
}

void DirectX12::Flush() const
{
	assert(m_FrameFence && m_CmdQueue);
	m_CmdQueue->Signal(m_FrameFence, ++m_CpuCompletedFrames);
	m_FrameFence->SetEventOnCompletion(m_CpuCompletedFrames, m_FrameFenceEvent);
	WaitForSingleObject(m_FrameFenceEvent, INFINITE);
}
