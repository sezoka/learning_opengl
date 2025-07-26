#version 330 core
out vec4 FragColor;

in vec3 TexCoords;

uniform samplerCube skybox;

void main()
{    
    // float v = int(skybox) == 0;
    // FragColor = vec4(TexCoords, 1);
    FragColor = texture(skybox, TexCoords);
}
