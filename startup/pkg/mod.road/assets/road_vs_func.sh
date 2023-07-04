#include <bgfx_shader.sh>
#include "common/transform.sh"
#include "common/common.sh"
#include "common/default_inputs_structure.sh"

void CUSTOM_VS_FUNC(in VSInput vs_input, inout VSOutput vs_output)
{
    float road_type  = vs_input.idata2.x;
    float road_shape = vs_input.idata2.y;
    float mark_type  = vs_input.idata2.z;
    float mark_shape = vs_input.idata2.w;
    
    float road_texcoord_r = vs_input.idata1.x;
    float mark_texcoord_r = vs_input.idata1.y;

#ifdef DRAW_INDIRECT
	mediump mat4 wm = get_indirect_world_matrix(vs_input.idata0, vs_input.idata1, vs_input.idata2, u_draw_indirect_type);
#else
	mediump mat4 wm = get_world_matrix(vs_input);
#endif //DRAW_INDIRECT
	highp vec4 posWS = transformWS(wm, mediump vec4(vs_input.pos, 1.0));
	vs_output.clip_pos = mul(u_viewProj, posWS);
	vs_output.uv0	    = get_rotated_texcoord(road_texcoord_r, vs_input.uv0).xy;
	vs_output.user0		= vec4(road_type, road_shape, mark_type, mark_shape);
    vs_output.user1     = vec4(get_rotated_texcoord(mark_texcoord_r, vs_input.user0.xy).xy, 0, 0);
	vs_output.normal	= mul(wm, mediump vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	vs_output.tangent	= mul(wm, mediump vec4(1.0, 0.0, 0.0, 0.0)).xyz;
	vs_output.world_pos = posWS;
	vs_output.world_pos.w = mul(u_view, vs_output.world_pos).z;
}