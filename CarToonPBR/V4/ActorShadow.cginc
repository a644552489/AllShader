#ifndef __ACTOR_SHADOW_CGINC__
#define __ACTOR_SHADOW_CGINC__

#include "UnityCG.cginc"

struct Attributes
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
};

struct Varyings
{
	V2F_SHADOW_CASTER;
};

Varyings vert(Attributes v)
{
	Varyings o;
	TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
	return o;
}

half4 frag(Varyings input) : SV_Target
{
	SHADOW_CASTER_FRAGMENT(input);
}

#endif
