#version 330

/*
 -> Automatically come from raylib:
 Vertex attributes:
 vertexPosition vertexTexCoord vertexNormal vertexColor vertexTangent
 
 Uniforms:
 mvp matModel matView matProjection colDiffuse texture0/1/2
*/

in vec3 vertexPosition;
in mat4 instanceTransform;
in vec4 instanceColor;

uniform mat4 mvp;

out vec4 fragColor;

void main() {
    fragColor = instanceColor;
    gl_Position = mvp * instanceTransform * vec4(vertexPosition, 1.0);
}
