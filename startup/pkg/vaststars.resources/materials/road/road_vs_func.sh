#include "common/transform.sh"
#include "common/common.sh"
#include "road.sh"

vec4 CUSTOM_VS_POSITION(VSInput vsinput, inout Varyings varyings, out mat4 worldmat)
{
	worldmat = (mat4)0;
	return transform_road(vsinput, varyings);
}

void CUSTOM_VS(mat4 worldmat, in VSInput vsinput, inout Varyings varyings)
{
	uint color 			= floatBitsToUint(vsinput.data0.z);
	varyings.texcoord0  = vsinput.texcoord0;
	varyings.color0		= vec4(uvec4(color, color>>8, color>>16, color>>24)&0xff) / 255.0;
	varyings.posWS.w	= mul(u_view, varyings.posWS).z;
}