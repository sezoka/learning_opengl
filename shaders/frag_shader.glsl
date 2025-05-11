#version 330 core
out vec4 FragColor;
  
in vec2 TexCoord;

// uniform sampler2D texture1;
// uniform sampler2D texture2;

uniform vec3 light_color;
uniform vec3 object_color;

void main()
{
    // FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), 0.2);
    FragColor = vec4(light_color * object_color, 1.0);
}
