#include <bgfx_shader.sh>
#include "common/transform.sh"
#include "common/common.sh"
#include "common/default_inputs_structure.sh"

void CUSTOM_VS_FUNC(in VSInput vs_input, inout VSOutput vs_output)
{
	mat4 wm = get_world_matrix(vs_input);
	highp vec4 posWS = transform_pos(wm, vs_input.pos, vs_output.clip_pos);

	vs_output.uv0 = vec4(vs_input.uv0.xy, 0, 0);
	vs_output.user0 = vec4(vs_input.user0.zw, 0, 0);
    vs_output.user1 = vec4(vs_input.user0.xy, 0, 0);
	vs_output.normal	= mul(wm, mediump vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	vs_output.tangent	= mul(wm, mediump vec4(1.0, 0.0, 0.0, 0.0)).xyz;
	vs_output.world_pos = posWS;
	vs_output.world_pos.w = mul(u_view, vs_output.world_pos).z;
}