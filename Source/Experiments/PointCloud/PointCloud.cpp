#include "Pch.h"
#include "PointCloud.h"
#include <random>
#include "EASTL/random.h"
#include "DirectX12.h"
#include "Library.h"


void PointCloud::Initialize()
{
	m_Dx12.GetCmdList()->Close();

	eastl::vector<uint8_t> csoVs = Lib::LoadFile("Assets/Shaders/PointCloudVS.cso");
	eastl::vector<uint8_t> csoPs = Lib::LoadFile("Assets/Shaders/PointCloudPS.cso");

	D3D12_INPUT_ELEMENT_DESC inputElements[] =
	{
		{ "POSITION", 0, DXGI_FORMAT_R32G32_FLOAT, 0, 0, D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 }
	};

	D3D12_GRAPHICS_PIPELINE_STATE_DESC psoDesc = {};
	psoDesc.InputLayout = { inputElements, (uint32_t)eastl::size(inputElements) };
	psoDesc.VS = { csoVs.data(), csoVs.size() };
	psoDesc.PS = { csoPs.data(), csoPs.size() };
	psoDesc.RasterizerState.FillMode = D3D12_FILL_MODE_SOLID;
	psoDesc.RasterizerState.CullMode = D3D12_CULL_MODE_NONE;
	psoDesc.BlendState.RenderTarget[0].RenderTargetWriteMask = D3D12_COLOR_WRITE_ENABLE_ALL;
	psoDesc.SampleMask = 0xffffffff;
	psoDesc.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_POINT;
	psoDesc.NumRenderTargets = 1;
	psoDesc.RTVFormats[0] = DXGI_FORMAT_R8G8B8A8_UNORM;
	psoDesc.SampleDesc.Count = 1;

	VHR(m_Dx12.GetDevice()->CreateGraphicsPipelineState(&psoDesc, IID_PPV_ARGS(&m_Pso)));
	VHR(m_Dx12.GetDevice()->CreateRootSignature(0, csoVs.data(), csoVs.size(), IID_PPV_ARGS(&m_Rs)));

	CreateBuffers();
}

void PointCloud::Update(double frameTime, float frameDeltaTime)
{
	static double frameTime0 = frameTime;
	const float time = (float)(frameTime - frameTime0);

	const uint32_t frameIdx = m_Dx12.GetFrameIndex();

	XMFLOAT4X4A* ptr = (XMFLOAT4X4A*)m_RootCbCpuAddr[frameIdx];

	float sinV, cosV;
	XMScalarSinCos(&sinV, &cosV, time);

	XMMATRIX objectToProj =
		//XMMatrixLookAtLH(XMVectorSet(3.0f * cosV, 0.0f, 3.0f * sinV, 1.0f), XMVectorZero(), XMVectorSet(0.0f, 1.0f, 0.0f, 0.0)) *
		XMMatrixLookAtLH(XMVectorSet(0.0f, 0.0f, -50.0f, 1.0f), XMVectorZero(), XMVectorSet(0.0f, 1.0f, 0.0f, 0.0)) *
		XMMatrixPerspectiveFovLH(XM_PIDIV4, 1.777f, 1.0f, 100.0f);

	XMStoreFloat4x4A(ptr, objectToProj);
}

__itt_domain* domain = __itt_domain_create("Example.Domain.Global");
__itt_string_handle* handle_createthread = __itt_string_handle_create("CreateThread");

void PointCloud::Draw() const
{
	const uint32_t frameIdx = m_Dx12.GetFrameIndex();

	__itt_task_begin(domain, __itt_null, __itt_null, handle_createthread);

	ID3D12CommandAllocator* cmdAlloc = m_Dx12.GetCmdAllocator();
	cmdAlloc->Reset();

	ID3D12GraphicsCommandList* cmdList = m_Dx12.GetCmdList();

	cmdList->Reset(cmdAlloc, nullptr);
	cmdList->RSSetViewports(1, &m_Dx12.GetViewport());
	cmdList->RSSetScissorRects(1, &m_Dx12.GetScissorRect());

	D3D12_RESOURCE_BARRIER barrier = {};
	barrier.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
	barrier.Transition.pResource = m_Dx12.GetBackBuffer();
	barrier.Transition.StateBefore = D3D12_RESOURCE_STATE_PRESENT;
	barrier.Transition.StateAfter = D3D12_RESOURCE_STATE_RENDER_TARGET;
	cmdList->ResourceBarrier(1, &barrier);

	D3D12_CPU_DESCRIPTOR_HANDLE backBufferHandle = m_Dx12.GetBackBufferHandle();
	D3D12_CPU_DESCRIPTOR_HANDLE depthBufferHandle = m_Dx12.GetDepthBufferHandle();

	cmdList->OMSetRenderTargets(1, &backBufferHandle, 0, &depthBufferHandle);

	cmdList->ClearRenderTargetView(backBufferHandle, XMVECTORF32{ 0.0f, 0.2f, 0.4f, 1.0f }, 0, nullptr);
	cmdList->ClearDepthStencilView(depthBufferHandle, D3D12_CLEAR_FLAG_DEPTH, 1.0f, 0, 0, nullptr);

	cmdList->IASetVertexBuffers(0, 1, &m_PointVbView);
	cmdList->SetPipelineState(m_Pso);

	cmdList->SetGraphicsRootSignature(m_Rs);
	cmdList->IASetPrimitiveTopology(D3D_PRIMITIVE_TOPOLOGY_POINTLIST);

	const XMFLOAT2A* __restrict ptr = m_Points.data();
	for (uint32_t pointIdx = 0; pointIdx < k_PointCount; ++pointIdx)
	{
		cmdList->SetGraphicsRoot32BitConstants(0, 2, &ptr[pointIdx], 0);
		cmdList->DrawInstanced(1, 1, 0, 0);
	}

	barrier.Transition.StateBefore = D3D12_RESOURCE_STATE_RENDER_TARGET;
	barrier.Transition.StateAfter = D3D12_RESOURCE_STATE_PRESENT;
	cmdList->ResourceBarrier(1, &barrier);

	cmdList->Close();

	__itt_task_end(domain);


	m_Dx12.GetCmdQueue()->ExecuteCommandLists(1, (ID3D12CommandList**)&cmdList);
}

void PointCloud::CreateBuffers()
{
	ID3D12Device* device = m_Dx12.GetDevice();

	{	// vertex buffer
		auto vbDesc = CD3DX12_RESOURCE_DESC::Buffer(1 * sizeof(XMFLOAT2A));
		VHR(device->CreateCommittedResource(
			&CD3DX12_HEAP_PROPERTIES(D3D12_HEAP_TYPE_UPLOAD),
			D3D12_HEAP_FLAG_NONE, &vbDesc, D3D12_RESOURCE_STATE_GENERIC_READ,
			nullptr, IID_PPV_ARGS(&m_PointVb)));

		m_PointVbView.BufferLocation = m_PointVb->GetGPUVirtualAddress();
		m_PointVbView.StrideInBytes = sizeof(XMFLOAT2A);
		m_PointVbView.SizeInBytes = 1 * m_PointVbView.StrideInBytes;
		
		VHR(m_PointVb->Map(0, &CD3DX12_RANGE(0, 0), &m_PointVbCpuAddr));
		*(XMFLOAT2A*)m_PointVbCpuAddr = XMFLOAT2A(0.0f, 0.0f);

		std::mt19937 randEngine;
		std::uniform_real_distribution<float> randDis(-0.7f, 0.7f);

		m_Points.resize(k_PointCount);
		XMFLOAT2A* __restrict ptr = m_Points.data();
		for (uint32_t pointIdx = 0; pointIdx < k_PointCount; ++pointIdx)
		{
			*ptr++ = XMFLOAT2A(randDis(randEngine), randDis(randEngine));
		}
	}

	// constant buffer
	for (uint32_t frameIdx = 0; frameIdx < 2; ++frameIdx)
	{
		auto cbDesc = CD3DX12_RESOURCE_DESC::Buffer(64 * 1024);
		VHR(device->CreateCommittedResource(
			&CD3DX12_HEAP_PROPERTIES(D3D12_HEAP_TYPE_UPLOAD), D3D12_HEAP_FLAG_NONE, &cbDesc, D3D12_RESOURCE_STATE_GENERIC_READ,
			nullptr, IID_PPV_ARGS(&m_RootCb[frameIdx])));

		VHR(m_RootCb[frameIdx]->Map(0, &CD3DX12_RANGE(0, 0), &m_RootCbCpuAddr[frameIdx]));
		
		m_RootCbGpuAddr[frameIdx] = m_RootCb[frameIdx]->GetGPUVirtualAddress();
	}
}
