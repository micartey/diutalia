#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(binding = 1) uniform sampler2D source;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 screenSize;
    // imageSize is a GLSL intrinsic; that name breaks OpenGL uniform lookup.
    vec2 imageDimensions;
    float fillMode;
    vec4 fillColor;
    float isSolid;
    vec4 solidColor;
    float density;
    float dropletSize;
    float refraction;
    float time;
    float dropletLifetime;
    float hitWindowPercentage;
    float backgroundRain;
    float glassStrength;
    float windowTime;
    float backgroundTime;
} ubuf;

vec3 hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    q += dot(q, q.yxz + 33.33);
    return fract((q.xxy + q.yzz) * q.zyx);
}

vec3 wallpaper(vec2 uv) {
    if (ubuf.isSolid > 0.5)
        return ubuf.solidColor.rgb;
    vec2 size = ubuf.imageDimensions;
    vec2 screen = ubuf.screenSize;
    if (ubuf.fillMode < 0.5) {
        uv = (uv * screen - (screen - size) * 0.5) / size;
    } else if (ubuf.fillMode < 2.5) {
        float scale = ubuf.fillMode < 1.5 ? max(screen.x / size.x, screen.y / size.y)
                                           : min(screen.x / size.x, screen.y / size.y);
        uv = (uv * screen - (screen - size * scale) * 0.5) / (size * scale);
    } else if (ubuf.fillMode > 3.5) {
        return texture(source, fract(uv * screen / size)).rgb;
    }
    if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0))))
        return ubuf.fillColor.rgb;
    return texture(source, uv).rgb;
}

// Each cell gets a new impact each lifetime, with independent timing and hit chance.
vec4 bead(vec2 pixel, float cellSize, float seed, float moving, float neighbor) {
    vec2 grid = pixel / cellSize;
    vec2 cell = floor(grid) + vec2(0.0, neighbor);
    vec3 clock = hash(cell + seed);
    float layerTime = moving > 0.5 ? ubuf.windowTime : ubuf.time;
    float tick = layerTime / (max(0.4, ubuf.dropletLifetime) * (0.7 + clock.x * 0.6)) + clock.y;
    float phase = fract(tick);
    vec3 random = hash(cell + seed + floor(tick) * vec2(19.17, 7.83));
    float present = step(random.z, ubuf.density / (ubuf.density + 0.6));
    present *= step(hash(cell + seed + floor(tick) * 31.7 + 137.0).x, ubuf.hitWindowPercentage);
    if (ubuf.hitWindowPercentage <= 0.0)
        present = 0.0;
    vec2 center = cell + 0.3 + random.xy * 0.4;
    center.y += moving * (phase * phase - 0.3) * 1.1;
    float life = smoothstep(0.0, 0.045, phase) * (1.0 - smoothstep(0.58, 1.0, phase));
    float radius = (0.055 + pow(random.z, 2.0) * 0.065) * cellSize;
    radius *= 0.8 + 0.2 * smoothstep(0.0, 0.12, phase);
    vec2 local = (pixel - center * cellSize) / max(radius, 0.5);
    float distance = length(local);
    float coverage = (1.0 - smoothstep(0.92, 1.02, distance)) * present * life;
    return vec4(local, radius, coverage);
}

float rain(vec2 pixel, vec2 cellSize, float seed, float velocity) {
    vec2 falling = pixel - vec2(0.12, 1.0) * ubuf.backgroundTime * velocity;
    vec2 cell = floor(falling / cellSize);
    vec3 random = hash(cell + seed);
    vec2 local = falling - (cell + 0.2 + random.xy * 0.6) * cellSize;
    float length = 12.0 + random.y * 28.0;
    float crossSection = abs(local.x - local.y * 0.12);
    float streak = 1.0 - smoothstep(0.3, 1.3, crossSection);
    streak *= 1.0 - smoothstep(length * 0.25, length, abs(local.y));
    streak *= step(random.z, ubuf.density / (ubuf.density + 0.6));
    return streak * (0.25 + random.x * 0.55);
}

float rainfall(vec2 pixel) {
    float amount = rain(pixel, vec2(43.0, 113.0), 211.0, 760.0);
    amount += rain(pixel, vec2(71.0, 173.0), 359.0, 1100.0) * 0.6;
    return clamp(amount * ubuf.backgroundRain * 0.5, 0.0, 0.65);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 pixel = uv * ubuf.screenSize;
    float scale = max(0.4, ubuf.dropletSize);
    vec4 drop = bead(pixel, 34.0 * scale, 17.0, 0.0, 0.0);
    vec4 medium = bead(pixel, 60.0 * scale, 53.0, 0.0, 0.0);
    if (medium.w > drop.w)
        drop = medium;
    for (int i = -1; i <= 1; ++i) {
        vec4 sliding = bead(pixel, 90.0 * scale, 97.0, 1.0, float(i));
        if (sliding.w > drop.w)
            drop = sliding;
    }

    float rainAlpha = rainfall(pixel);
    if (drop.w <= 0.0) {
        fragColor = vec4(vec3(0.78, 0.85, 0.92) * rainAlpha, rainAlpha) * ubuf.qt_Opacity;
        return;
    }

    vec2 local = drop.xy;
    float distance = length(local);
    float dome = sqrt(max(0.0, 1.0 - min(1.0, distance * distance)));
    vec3 normal = normalize(vec3(local * 0.85, dome + 0.12));
    // Clear centers, strong edge lensing, and a faint chromatic fringe suggest liquid glass.
    float rim = smoothstep(0.55, 0.97, distance);
    vec2 offset = normal.xy * (drop.z * 2.2 + 8.0) * ubuf.refraction * (0.15 + rim * 0.85)
                  * (1.0 + ubuf.glassStrength * 0.2) / ubuf.screenSize;
    vec2 fringe = normal.xy * rim * ubuf.refraction * (0.65 + ubuf.glassStrength * 0.65) / ubuf.screenSize;
    vec3 color = vec3(wallpaper(uv - offset - fringe).r,
                      wallpaper(uv - offset).g,
                      wallpaper(uv - offset + fringe).b);
    if (ubuf.backgroundRain > 0.0)
        color = mix(color, vec3(0.78, 0.85, 0.92), rainfall(pixel - offset * ubuf.screenSize));
    float topShade = smoothstep(0.05, 0.8, -normal.y) * rim;
    color *= 1.0 - 0.16 * topShade;
    color *= 1.0 - 0.07 * rim;

    float bottomLight = pow(max(0.0, dot(normal, normalize(vec3(-0.25, 0.75, 0.35)))), 14.0);
    float glint = pow(max(0.0, dot(normal, normalize(vec3(-0.4, -0.5, 0.75)))), 65.0);
    float edge = smoothstep(0.83, 0.94, distance) * (1.0 - smoothstep(0.96, 1.02, distance));
    float edgeLight = edge * (0.18 + 0.4 * max(0.0, -normal.x * 0.6 - normal.y * 0.8));
    // Colored environment reflections wrap around the lens; white ribbons sit above them.
    vec3 purple = vec3(0.67, 0.30, 1.0);
    vec3 blue = vec3(0.16, 0.52, 1.0);
    vec3 white = vec3(0.96, 0.99, 1.0);
    float purpleReflection = pow(max(0.0, dot(normal, normalize(vec3(-0.7, -0.2, 0.65)))), 5.0);
    float blueReflection = pow(max(0.0, dot(normal, normalize(vec3(0.55, 0.45, 0.7)))), 4.0);
    float hue = clamp(0.5 + normal.x * 0.45 + normal.y * 0.25 + sin(distance * 9.0) * 0.12, 0.0, 1.0);
    vec3 prism = mix(purple, blue, hue);
    float fresnel = pow(1.0 - max(0.0, normal.z), 2.0);
    float prismReflection = edge * 0.9 + fresnel * 0.25;
    float reflectedWeight = purpleReflection + blueReflection + prismReflection;
    vec3 reflectedColor = (purple * purpleReflection + blue * blueReflection + prism * prismReflection)
                          / max(0.001, reflectedWeight);
    float tintAmount = min(0.48, reflectedWeight * ubuf.glassStrength * 0.18);
    color = mix(color, reflectedColor, tintAmount);
    // Bounded mixing preserves wallpaper detail instead of clipping additive light to white.
    float whiteAmount = min(0.98, (glint * 0.7 + bottomLight * 0.09 + edgeLight * 0.12)
                                  * (1.0 + ubuf.glassStrength * 0.3));
    color = mix(color, white, whiteAmount);

    float alpha = drop.w;
    vec3 combined = clamp(color, 0.0, 1.0) * alpha + vec3(0.78, 0.85, 0.92) * rainAlpha * (1.0 - alpha);
    float combinedAlpha = alpha + rainAlpha * (1.0 - alpha);
    fragColor = vec4(combined, combinedAlpha) * ubuf.qt_Opacity;
}
