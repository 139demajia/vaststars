#ifndef __ROAD_SH__
#define __ROAD_SH__

vec3 blend(vec3 texture1, float a1, float d1, vec3 texture2, float a2, float d2){
    float depth = 0.2;
    float ma = max(d1 + a1, d2 + a2) - depth;

    float b1 = max(d1  + a1 - ma, 0);
    float b2 = max(d2  + a2 - ma, 0);

    return (texture1.rgb * b1 + texture2.rgb * b2) / (b1 + b2);
}


vec3 calc_road_basecolor(vec3 road_basecolor, float road_type)
{
    vec3 stop_color   = vec3(255.0/255,  37.0/255,  37.0/255);
    vec3 choose_color = vec3(228.0/255, 228.0/255, 228.0/255);
    if(road_type == 1){
        return road_basecolor.rgb;
    }
    else if (road_type == 2){
        return vec3((stop_color.r+road_basecolor.r)*0.5, (stop_color.g+road_basecolor.g)*0.5, (stop_color.b+road_basecolor.b)*0.5);
    }
    else{
        return vec3((choose_color.r+road_basecolor.r)*0.5, (choose_color.g+road_basecolor.g)*0.5, (choose_color.b+road_basecolor.b)*0.5);
    }  
}

vec3 calc_mark_basecolor(float mark_type)
{
    if(mark_type == 1){
        return vec3(0.71484, 0, 0);
    }
    else{
        return vec3(1, 1, 1);
    }
}

material_info road_material_info_init(vec3 gnormal, vec3 normal, vec4 posWS, vec4 basecolor, vec4 fragcoord, vec4 metallic, vec4 roughness)
{
    material_info mi  = (material_info)0;
    mi.basecolor         = basecolor;
    mi.posWS             = posWS.xyz;
    mi.distanceVS        = posWS.w;
    mi.V                 = normalize(u_eyepos.xyz - posWS.xyz);
    mi.gN                = gnormal;  //geomtery normal
    mi.N                 = normal;

    mi.perceptual_roughness  = roughness;
    mi.metallic              = metallic;
    mi.occlusion         = 1.0;

    mi.screen_uv         = calc_normalize_fragcoord(fragcoord.xy);
    return mi;
}

#endif //
