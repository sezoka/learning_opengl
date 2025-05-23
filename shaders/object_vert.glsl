#version 330 core
layout (location = 0) in vec3 a_pos;
layout (location = 1) in vec3 a_normal;
layout (location = 2) in vec2 a_uv;

out vec3 v_normal;
out vec3 v_world_pos;
out vec3 v_pos;
out vec2 v_uv;

uniform mat4 transform;
uniform mat4 model;
uniform mat3 u_normal;

void main()
{
    gl_Position = transform * vec4(a_pos, 1.0);
    v_normal = u_normal * a_normal;
    v_world_pos = vec3(model * vec4(a_pos, 1.0));
    v_uv = a_uv;
}
