#version 330 core

out vec4 FragColor;
  
in vec3 v_normal;
in vec3 v_world_pos;
in vec2 v_uv;

// uniform sampler2D texture1;
// uniform sampler2D texture2;

struct Material {
    sampler2D diffuse;
    sampler2D specular;
    float shininess;
};

struct Light {
    vec3 position;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

struct SpotLight {
    vec3 position;
    vec3 direction;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float cut_off;
    float outer_cut_off;
    float constant;
    float linear;
    float quadratic;
};

struct DirLight {
    vec3 direction;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

struct PointLight {
    vec3 position;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float constant;
    float linear;
    float quadratic;
};

#define POINT_LIGHTS_NUM 4

uniform vec3 object_color;
uniform vec3 u_view_pos;
uniform Material U_MATERIAL;
uniform SpotLight U_LIGHT;
uniform PointLight U_POINT_LIGHTS[POINT_LIGHTS_NUM];

vec3 directionalLight(DirLight light, Material material, vec3 world_pos, vec3 view_pos, vec3 normal, vec2 uv) {
    // ambient
    vec3 ambient_color = light.ambient * vec3(texture(material.diffuse, uv));

    // diffuse
    vec3 norm = normalize(normal);
    vec3 light_dir = normalize(-light.direction);
    float diffuse_intensity = max(0, dot(light_dir, norm));
    vec3 diffuse = light.diffuse * (diffuse_intensity * vec3(texture(material.diffuse, uv)));

    // specular
    vec3 view_dir = normalize(view_pos - world_pos);
    vec3 reflect_dir = reflect(-light_dir, norm);
    float specular_intensity = pow(max(0, dot(view_dir, reflect_dir)), material.shininess);
    vec3 specular = light.specular * (specular_intensity * vec3(texture(material.specular, uv)));

    vec3 result = ambient_color + diffuse + specular;
    return result;
}

vec3 defaultLight(Light light, Material material, vec3 world_pos, vec3 view_pos, vec3 normal, vec2 uv) {
    // ambient
    vec3 ambient_color = light.ambient * vec3(texture(material.diffuse, uv));

    // diffuse
    vec3 norm = normalize(normal);
    vec3 light_dir = normalize(light.position - world_pos);
    float diffuse_intensity = max(0, dot(light_dir, norm));
    vec3 diffuse = light.diffuse * (diffuse_intensity * vec3(texture(material.diffuse, uv)));

    // specular
    vec3 view_dir = normalize(u_view_pos - world_pos);
    vec3 reflect_dir = reflect(-light_dir, norm);
    float specular_intensity = pow(max(0, dot(view_dir, reflect_dir)), material.shininess);
    vec3 specular = light.specular * (specular_intensity * vec3(texture(material.specular, uv)));

    return ambient_color + diffuse + specular;
}

vec3 spotLight(SpotLight light, Material material, vec3 world_pos, vec3 camera_pos, vec3 normal, vec2 uv) {
    // ambient
    vec3 ambient = light.ambient * vec3(texture(material.diffuse, uv));

    // diffuse
    vec3 light_dir = normalize(light.position - world_pos);
    vec3 norm = normalize(normal);
    float diffuse_intensity = max(0, dot(light_dir, norm));
    vec3 diffuse = light.diffuse * (diffuse_intensity * vec3(texture(material.diffuse, uv)));

    // specular
    vec3 view_dir = normalize(camera_pos - world_pos);
    vec3 reflect_dir = reflect(-light_dir, norm);
    float specular_intensity = pow(max(0, dot(view_dir, reflect_dir)), material.shininess);
    vec3 specular = light.specular * (specular_intensity * vec3(texture(material.specular, uv)));

    float distance = length(light.position - world_pos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));

    // spotlight
    float theta = dot(light_dir, normalize(-light.direction));
    float epsilon = light.cut_off - light.outer_cut_off;
    float intensity = clamp((theta - light.outer_cut_off) / epsilon, 0.0, 1.0);  

    diffuse *= attenuation;
    specular *= attenuation;

    diffuse *= intensity;
    specular *= intensity;

    return ambient + diffuse + specular;
}

vec3 pointLight(PointLight light, Material material, vec3 world_pos, vec3 camera_pos, vec3 normal, vec2 uv) {
    // ambient
    vec3 ambient = light.ambient * vec3(texture(material.diffuse, uv));

    // diffuse
    vec3 norm = normalize(normal);
    vec3 light_dir = normalize(light.position - world_pos);
    float diffuse_intensity = max(0, dot(light_dir, norm));
    vec3 diffuse = light.diffuse * (diffuse_intensity * vec3(texture(material.diffuse, uv)));

    // specular
    vec3 view_dir = normalize(camera_pos - world_pos);
    vec3 reflect_dir = reflect(-light_dir, norm);
    float specular_intensity = pow(max(0, dot(view_dir, reflect_dir)), material.shininess);
    vec3 specular = light.specular * (specular_intensity * vec3(texture(material.specular, uv)));

    float distance = length(light.position - world_pos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));

    ambient *= attenuation;
    diffuse *= attenuation;
    specular *= attenuation;

    return ambient + diffuse + specular;
}

void main()
{
    // FragColor = defaultLight(U_LIGHT, U_MATERIAL, v_world_pos, u_view_pos, v_normal, v_uv);
    vec3 point_lights;
    for (int i = 0; i < POINT_LIGHTS_NUM; i += 1) {
        point_lights += pointLight(U_POINT_LIGHTS[i], U_MATERIAL, v_world_pos, u_view_pos, v_normal, v_uv);
    }
    FragColor = vec4(spotLight(U_LIGHT, U_MATERIAL, v_world_pos, u_view_pos, v_normal, v_uv) + point_lights, 1);
// vec4 spotLight(SpotLight light, Material material, vec3 world_pos, vec3 camera_pos, vec3 normal, vec2 uv) {
    // directionalLight(light, material, v_world_pos, u_view_pos, v_normal, v_uv);
}
