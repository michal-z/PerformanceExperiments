#define RootSig \
    "RootFlags(ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT), " \
    "CBV(b0, visibility = SHADER_VISIBILITY_VERTEX)"

struct RootConstants
{
	float4x4 objectToProjMatrix;
};
ConstantBuffer<RootConstants> cbv_Root : register(b0);

[RootSignature(RootSig)]
float4 main(float3 position : POSITION) : SV_POSITION
{
	return mul(float4(position, 1.0f), cbv_Root.objectToProjMatrix);
}
