#version 120

varying vec2 texCoord;
varying vec4 vertexColor;
varying vec3 viewDir;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vertexColor = gl_Color;
    viewDir = normalize((gl_ModelViewMatrix * gl_Vertex).xyz);
}
