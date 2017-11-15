#pragma once
#include "Experiment.h"


class DirectX12;
class PointCloud : public Experiment
{
public:
	explicit PointCloud(const DirectX12& dx12);
	virtual void Initialize() override;
	virtual void Update(double frameTime, float frameDeltaTime) override;
	virtual void Draw() const override;

private:
	const DirectX12& m_Dx12;

	ID3D12PipelineState* m_Pso;
	ID3D12RootSignature* m_Rs;

	static constexpr uint32_t k_PointCount = 100000;
	ID3D12Resource* m_PointVb;
	void* m_PointVbCpuAddr;
	D3D12_VERTEX_BUFFER_VIEW m_PointVbView;
	std::vector<XMFLOAT2A> m_Points;

	ID3D12Resource* m_RootCb[2];
	void* m_RootCbCpuAddr[2];
	D3D12_GPU_VIRTUAL_ADDRESS m_RootCbGpuAddr[2];

	void CreateBuffers();
};

inline PointCloud::PointCloud(const DirectX12& dx12) : m_Dx12(dx12)
{
}
