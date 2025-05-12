#version 330 core

out vec4 FragColor;
  
in vec3 v_normal;
in vec3 v_world_pos;

// uniform sampler2D texture1;
// uniform sampler2D texture2;

uniform vec3 light_color;
uniform vec3 light_pos;
uniform vec3 object_color;
uniform vec3 u_view_pos;

void main()
{
    float ambient_strength = 0.1;
    vec3 ambient_color = light_color * ambient_strength;

    vec3 norm = normalize(v_normal);
    vec3 light_dir = normalize(light_pos - v_world_pos);
    float diffuse_intensity = max(0, dot(light_dir, norm));
    vec3 diffuse = diffuse_intensity * light_color;

    float specular_strength = 0.5;
    vec3 view_dir = normalize(u_view_pos - v_world_pos);
    vec3 reflect_dir = reflect(-light_dir, norm);
    float specular_intensity = pow(max(0, dot(view_dir, reflect_dir)), 250);
    vec3 specular = specular_strength * specular_intensity * light_color;

    vec3 result = (ambient_color + diffuse + specular) * object_color;
    FragColor = vec4(result, 1);
    // FragColor = vec4(light_color * object_color, 1.0);
    // FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), 0.2);
}
