#pragma language glsl3

// skyShader.glsl
#ifdef VERTEX
vec4 position(mat4 transform, vec4 vertex)
{
    // Apenas passa a posição do vértice adiante
    return transform * vertex;
}
#endif

#ifdef PIXEL
// Cores do gradiente (em RGB normalizado)
const vec3 topColor    = vec3(0.161, 0.678, 1.0);   // #29adff
const vec3 bottomColor = vec3(0.114, 0.169, 0.325); // #1d2b53

// Matriz de Bayer 4x4 para dithering
const float bayer4x4[16] = float[](
    0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0,
    12.0/16.0, 4.0/16.0, 14.0/16.0, 6.0/16.0,
    3.0/16.0, 11.0/16.0, 1.0/16.0,  9.0/16.0,
    15.0/16.0, 7.0/16.0, 13.0/16.0, 5.0/16.0
);

vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 screenCoord)
{
    // screenCoord.y varia de 0 (topo) até love.graphics.getHeight() (fundo)
    // Invertemos para que 0 seja o topo e 1 o fundo
    float t = 0.75 - screenCoord.y / love_ScreenSize.y;

    // Interpolação linear entre as duas cores
    vec3 skyColor = mix(topColor, bottomColor, t);

    // Calcula o threshold de dithering baseado na posição do pixel (em coordenadas de tela)
    int x = int(mod(screenCoord.x, 4.0));
    int y = int(mod(screenCoord.y, 4.0));
    float threshold = bayer4x4[y * 4 + x];

    // Aplica dithering: compara o componente vermelho (ou qualquer um) com o threshold
    // Usamos a luminância aproximada para decidir se o pixel será "aceso" ou "apagado"
    float luma = dot(skyColor, vec3(0.299, 0.587, 0.114));
    float value = step(threshold, luma);

    // Quantiza a cor para apenas dois níveis: topColor ou bottomColor
    vec3 finalColor = mix(bottomColor, topColor, value);

    return vec4(finalColor, 1.0);
}
#endif