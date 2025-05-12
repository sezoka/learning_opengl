#version 330 core
out vec4 FragColor;
  
in vec2 TexCoord;

uniform vec3 light_color;

void main()
{
    FragColor = vec4(light_color, 1);
}
