#version 330

/*
 -> Automatically come from raylib:
 Vertex attributes:
 vertexPosition vertexTexCoord vertexNormal vertexColor vertexTangent
 
 Uniforms:
 mvp matModel matView matProjection colDiffuse texture0/1/2
*/

in vec4 fragColor;
uniform vec4 colDiffuse;
out vec4 finalColor;

void main() {
    finalColor = fragColor * colDiffuse;
}
