#version 330 core

out vec4 FragColor;
  
in vec3 v_normal;
in vec3 v_world_pos;

// uniform sampler2D texture1;
// uniform sampler2D texture2;

struct Material {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
};

struct Light {
    vec3 position;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

uniform vec3 object_color;
uniform vec3 u_view_pos;
uniform Material U_MATERIAL;
uniform Light U_LIGHT;

void main()
{
    // ambient
    vec3 ambient_color = U_LIGHT.ambient * U_MATERIAL.ambient;

    // diffuse
    vec3 norm = normalize(v_normal);
    vec3 light_dir = normalize(U_LIGHT.position - v_world_pos);
    float diffuse_intensity = max(0, dot(light_dir, norm));
    vec3 diffuse = U_LIGHT.diffuse * (diffuse_intensity * U_MATERIAL.diffuse);

    // specular
    vec3 view_dir = normalize(u_view_pos - v_world_pos);
    vec3 reflect_dir = reflect(-light_dir, norm);
    float specular_intensity = pow(max(0, dot(view_dir, reflect_dir)), U_MATERIAL.shininess);
    vec3 specular = U_LIGHT.specular * (specular_intensity * U_MATERIAL.specular);

    vec3 result = ambient_color + diffuse + specular;
    FragColor =  vec4(result, 1);
}
