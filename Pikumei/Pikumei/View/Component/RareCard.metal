//
//  RareCard.metal
//  Pikumei
//
//  Created by hayata  on 2026/02/18.
//

// RareCard.metal
#include <metal_stdlib>
using namespace metal;

// 1. 光が左上から右下に走る効果
half4 getRareBaseColor(float2 position, float2 size, half4 original, float time) {
    float2 uv = position / size;
    float diagCoord = (uv.x + uv.y) * 0.5;
    
    // 5秒周期のうち最初の1.5秒だけグリントを出し、残りは休止
    constexpr float cycle = 5.0;
    constexpr float activeTime = 1.5;
    float phase = fmod(time, cycle);
    float t = clamp(phase / activeTime, 0.0, 1.0);

    float glintPos = 1.0 - exp(-4.0 * t) * cos(5.0 * t);
    constexpr float width = 0.15;

    // 休止期間中は強度を0にする
    float active = step(phase, activeTime);
    float intensity = smoothstep(glintPos - width, glintPos, diagCoord) * (1.0 - smoothstep(glintPos, glintPos + width, diagCoord)) * active;
    
    half3 glinted = original.rgb + half3(1.0) * half(intensity) * 0.15;
    return half4(glinted, original.a);
}

// 2. 傾きで光る効果
half4 getMotionLightEffectColor(float2 position, float2 size, half4 baseColor, float2 acceleration) {
    float2 uv = (position / size) * 2.0 - 1.0;
    uv.y = -uv.y;
    
    half3 horizontalLight = uv.x * acceleration.x * -1 * 0.2;
    half3 verticalLight = uv.y * acceleration.y * -1 * 0.2;
    
    half3 finalRgb = max(horizontalLight + verticalLight + baseColor.rgb, baseColor.rgb);
    return half4(finalRgb, baseColor.a);
}

// 3. メインの呼び出し関数
[[ stitchable ]] half4 rareCard(float2 position, half4 color, float2 size, float2 acceleration, float time) {
    half4 baseColor = getRareBaseColor(position, size, color, time);
    return getMotionLightEffectColor(position, size, baseColor, acceleration);
}
