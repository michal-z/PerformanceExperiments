#define RootSig \
	"RootFlags(ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT)," \
	"RootConstants(b0, num32BitConstants = 2)"

	//"CBV(b0, visibility = SHADER_VISIBILITY_VERTEX)"

/*
struct RootConstants
{
	float4x4 objectToProjMatrix;
};
ConstantBuffer<RootConstants> cbv_Root : register(b0);
*/
struct Float2
{
	float x, y;
};
ConstantBuffer<Float2> cbv_Positions : register(b0);

[RootSignature(RootSig)]
float4 main(float2 position : POSITION) : SV_POSITION
{
	//return mul(float4(position, 1.0f), cbv_Root.objectToProjMatrix);
	return float4(cbv_Positions.x, cbv_Positions.y, 0.0f, 1.0f);
}
