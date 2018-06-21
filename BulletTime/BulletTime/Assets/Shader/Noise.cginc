#ifndef NOSIC
#define NOSIC

//根據Perlin noise需要得到單位晶格每個頂點的"偽隨機"梯度向量
//3D的晶格是立方體
void PerlinHash3D(float3 gridcell,
	out float4 lowz_hash_0,
	out float4 lowz_hash_1,
	out float4 lowz_hash_2,
	out float4 highz_hash_0,
	out float4 highz_hash_1,
	out float4 highz_hash_2)
{
	const float2 OFFSET = float2(50.0, 161.0);
	const float DOMAIN = 69.0;
	const float3 SOMELARGEFLOATS = float3(635.298681, 682.357502, 668.926525);
	const float3 ZINC = float3(48.500388, 65.294118, 63.934599);
	gridcell.xyz = gridcell.xyz - floor(gridcell.xyz * (1.0 / DOMAIN)) * DOMAIN;
	float3 gridcell_inc1 = step(gridcell, float3(DOMAIN - 1.5, DOMAIN - 1.5, DOMAIN - 1.5)) * (gridcell + 1.0);
	float4 P = float4(gridcell.xy, gridcell_inc1.xy) + OFFSET.xyxy;
	P *= P;
	P = P.xzxz * P.yyww;
	float3 lowz_mod = float3(1.0 / (SOMELARGEFLOATS.xyz + gridcell.zzz * ZINC.xyz));
	float3 highz_mod = float3(1.0 / (SOMELARGEFLOATS.xyz + gridcell_inc1.zzz * ZINC.xyz));
	lowz_hash_0 = frac(P * lowz_mod.xxxx);
	highz_hash_0 = frac(P * highz_mod.xxxx);
	lowz_hash_1 = frac(P * lowz_mod.yyyy);
	highz_hash_1 = frac(P * highz_mod.yyyy);
	lowz_hash_2 = frac(P * lowz_mod.zzzz);
	highz_hash_2 = frac(P * highz_mod.zzzz);
}

//平滑函式	
float3 EaseCurve_C2(float3 x) { return x * x * x * (x * (x * 6.0 - 15.0) + 10.0); }

float Perlin3D(float3 P)
{
	//Pi表示在哪個正方體裡面，Pi是正方體原點
	float3 Pi = floor(P);
	//Pf表示P在正方體Pi裡面的位置，表示Pi(0,0,0)到P的向量
	float3 Pf = P - Pi;
	//這裡以單位1切為一個晶體，Pf_min1表示Pi(0,0,0)到P的向量
	float3 Pf_min1 = Pf - 1.0;

	//取得正方體各個頂點的梯度
	float4 hashx0, hashy0, hashz0, hashx1, hashy1, hashz1;
	PerlinHash3D(Pi, hashx0, hashy0, hashz0, hashx1, hashy1, hashz1);

	float4 grad_x0 = hashx0 - 0.49999;
	float4 grad_y0 = hashy0 - 0.49999;
	float4 grad_z0 = hashz0 - 0.49999;
	float4 grad_x1 = hashx1 - 0.49999;
	float4 grad_y1 = hashy1 - 0.49999;
	float4 grad_z1 = hashz1 - 0.49999;
	//grad_results_0 = dot(a,b) / |b| = |a|Cos() = [-sqrt(3) ~ sqrt(3)]
	//a是頂點到點的向量
	//計算各頂點到P的向量與梯度點積
	float4 grad_results_0 =
		rsqrt(grad_x0 * grad_x0 + grad_y0 * grad_y0 + grad_z0 * grad_z0)
		* (float2(Pf.x, Pf_min1.x).xyxy * grad_x0
			+ float2(Pf.y, Pf_min1.y).xxyy * grad_y0
			+ Pf.zzzz * grad_z0);
	float4 grad_results_1 =
		rsqrt(grad_x1 * grad_x1 + grad_y1 * grad_y1 + grad_z1 * grad_z1)
		* (float2(Pf.x, Pf_min1.x).xyxy * grad_x1
			+ float2(Pf.y, Pf_min1.y).xxyy * grad_y1
			+ Pf_min1.zzzz * grad_z1);

	//Perlin緩和曲線
	// Pf = 0~1 ,所以blend也在 0~1
	float3 blend = EaseCurve_C2(Pf);
	float4 res0 = lerp(grad_results_0, grad_results_1, blend.z);
	float2 res1 = lerp(res0.xy, res0.zw, blend.y);
	float final = lerp(res1.x, res1.y, blend.x);
	//final 最後是 [-sqrt(3) ~ sqrt(3)]
	final = (final * rsqrt(3) + 1)/2;
	return final;
}

float PerlinNormal(float3 p, int octaves, float3 offset, float frequency, float amplitude, float lacunarity, float persistence)
{
	float sum = 0;
	//將多張Noise合併
	for (int i = 0; i < octaves; i++)
	{
		float h = 0;
		h = Perlin3D((p + offset) * frequency);
		sum += h*amplitude;
		frequency *= lacunarity;
		amplitude *= persistence;
	}
	return sum / octaves;
}

#endif