
// the number of volume samples to take
#define SAMPLE_COUNT 32

// spacing between samples
#define SAMPLE_PERIOD .6

uniform sampler2D _NoiseTex;
float noise( in float3 x )
{
	float3 p = floor( x );
	float3 f = frac( x );
	f = f*f*(3.0 - 2.0*f);

	float2 uv2 = (p.xy + float2(37.0, 17.0)*p.z) + f.xy;
	float2 rg = tex2Dlod( _NoiseTex, float4((uv2 + 0.5) / 256.0, 0.0, 0.0) ).yx;
	return lerp( rg.x, rg.y, f.z );
}

float4 map( in float3 p )
{
	float d = .1 + .8 * sin( 0.6*p.z )*sin( 0.5*p.x ) - p.y; // was 0.1

	float3 q = p;
	float f;
	f = 0.5000*noise( q ); q = q*2.02;
	f += 0.2500*noise( q ); q = q*2.03;
	f += 0.1250*noise( q ); q = q*2.01;
	f += 0.0625*noise( q );
	d += 2.75 * f;

	d = clamp( d, 0.0, 1.0 );

	float4 res = (float4)d;

	float3 col = 1.15 * float3(1.0, 0.95, 0.8);
	col += float3(1., 0., 0.) * exp2( res.x*10. - 10. );
	res.xyz = lerp( col, float3(0.7, 0.7, 0.7), res.x );

	return res;
}

float4 VolumeSampleColor( in float3 pos )
{
	float maxExtent = max( max( abs( pos.x ), abs( pos.y ) ), abs( pos.z ) );
	float feather = SAMPLE_PERIOD*1.5;
	float R = 5.;
	float dens = 1. - smoothstep( R - feather, R, maxExtent );
	// cut floor

	float sphereR = 3.5;
	float sr = length( pos );
	if( sr < sphereR + feather*.5 )
		dens *= saturate( (sr - (sphereR-.5*feather)) / feather );

	//dens *= noise( pos - float3(.1,.5,.1)* _Time.w );

	float col = .15 * dens;
	float a = dens * .1;

	return float4((float3)col, a);
}

float3 skyColor( float3 ro, float3 rd )
{
	return (float3)0.;
}

float4 postProcessing( in float3 col, in float2 screenPosNorm )
{
	col = saturate( col );

	// gamma correction
	col = pow( col, (float3).45 );

	float2 q = screenPosNorm;
	col *= pow( 16.0*q.x*q.y*(1.0 - q.x)*(1.0 - q.y), 0.12 ); // Vignette

	//screenPosNorm.x *= _ScreenParams.x / _ScreenParams.y;
	//screenPosNorm *= _ScreenParams.y / 256.;
	//col *= lerp( tex2Dlod( _NoiseTex, 2. * float4(screenPosNorm, 0.0, 0.0) ).x, 1., .7 );

	return float4(col, 1.0);
}
