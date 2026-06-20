#version 120

varying vec3 viewDir;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    viewDir = normalize((gl_ModelViewMatrix * gl_Vertex).xyz);
}
