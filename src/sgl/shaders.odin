package sgl

import os "core:os/os2"
import gl "vendor:OpenGL"
import "core:log"
import "core:math/linalg"
import "core:strings"
import "core:c"

Shader :: struct {
    id: u32,
}

useShader :: proc(s: Shader) {
    gl.UseProgram(s.id)
}

loadShaderFromFile :: proc(vert_path, frag_path: string) -> Shader {
    vert, vert_read_ok := readEntireFile(tempAlly(), vert_path)
    assert(vert_read_ok)
    fragment, frag_read_ok := readEntireFile(tempAlly(), frag_path)
    assert(frag_read_ok)
    shader, ok := compileShaderProgram(string(vert), string(fragment))
    assert(ok)
    return shader
}

compileShaderProgram :: proc(vert_src: string, frag_src: string) -> (s: Shader, ok: bool) {
    vert_cstring := strings.clone_to_cstring(vert_src); defer delete(vert_cstring)
    vert_shader := gl.CreateShader(gl.VERTEX_SHADER)
    gl.ShaderSource(vert_shader, 1, &vert_cstring, nil);
    gl.CompileShader(vert_shader);
    if !checkCompileErrors(vert_shader, .Vertex) {
        return {}, false
    }

    frag_cstring := strings.clone_to_cstring(frag_src); defer delete(frag_cstring)
    frag_shader := gl.CreateShader(gl.FRAGMENT_SHADER); 
    gl.ShaderSource(frag_shader, 1, &frag_cstring, nil);
    gl.CompileShader(frag_shader);
    if !checkCompileErrors(frag_shader, .Fragment) {
        return {}, false
    }

    s.id = gl.CreateProgram()
    gl.AttachShader(s.id, vert_shader)
    gl.AttachShader(s.id, frag_shader)
    gl.LinkProgram(s.id)
    if !checkCompileErrors(s.id, .Program) {
        return {}, false
    }
    gl.DeleteShader(vert_shader)
    gl.DeleteShader(frag_shader)
    return s, true
}

@(require_results)
checkCompileErrors :: proc(obj: u32, type: enum { Fragment, Vertex, Program }) -> bool {
    LOG_SIZE :: 2048
    success: i32
    info_log: [LOG_SIZE]u8
    info_log_len: i32

    if type != .Program {
        gl.GetShaderiv(obj, gl.COMPILE_STATUS, &success)
        if success == 0 {
            gl.GetShaderInfoLog(obj, LOG_SIZE, &info_log_len, raw_data(&info_log))
            log.errorf("shader: compile-time error: type: %v\n%s", type, info_log[0:info_log_len])
            return false
        }
    } else {
        gl.GetProgramiv(obj, gl.LINK_STATUS, &success);
        if success == 0 {
            gl.GetProgramInfoLog(obj, LOG_SIZE, &info_log_len, raw_data(&info_log));
            log.errorf("shader: link-time error: type: %v\n%s", type, info_log[0:info_log_len])
            return false
        }
    }

    return true
}

setUniformVec4 :: proc(s: Shader, name: cstring, v: Vec4) {
    gl.Uniform4f(gl.GetUniformLocation(s.id, name), v.x, v.y, v.z, v.w)
}

setUniformVec3 :: proc(s: Shader, name: cstring, v: Vec3) {
    gl.Uniform3f(gl.GetUniformLocation(s.id, name), v.x, v.y, v.z)
}

setUniformInt :: proc(s: Shader, name: cstring, v: c.int) {
    gl.Uniform1i(gl.GetUniformLocation(s.id, name), v)
}

setUniformUInt :: proc(s: Shader, name: cstring, v: c.uint) {
    gl.Uniform1ui(gl.GetUniformLocation(s.id, name), v)
}

setUniformFloat :: proc(s: Shader, name: cstring, v: c.float) {
    gl.Uniform1f(gl.GetUniformLocation(s.id, name), v)
}

setUniformMat4 :: proc(s: Shader, name: cstring, v: Mat4) {
    mat_arr := linalg.matrix_flatten(v)
    gl.UniformMatrix4fv(gl.GetUniformLocation(s.id, name), 1, gl.FALSE, raw_data(mat_arr[:]))
}

setUniformMat3 :: proc(s: Shader, name: cstring, v: Mat3) {
    mat_arr := linalg.matrix_flatten(v)
    gl.UniformMatrix3fv(gl.GetUniformLocation(s.id, name), 1, gl.FALSE, raw_data(mat_arr[:]))
}

setUniformTexture2D :: proc(s: Shader, name: cstring, tex: Texture2D, unit: u32) {
    enableTexture2D(tex, unit)
    setUniformInt(s, name, i32(unit))
}

//
// void Shader::SetFloat(const char *name, float value, bool useShader)
// {
//     if (useShader)
//         this->Use();
//     glUniform1f(glGetUniformLocation(this->ID, name), value);
// }
// void Shader::SetVector2f(const char *name, float x, float y, bool useShader)
// {
//     if (useShader)
//         this->Use();
//     glUniform2f(glGetUniformLocation(this->ID, name), x, y);
// }
// void Shader::SetVector2f(const char *name, const glm::vec2 &value, bool useShader)
// {
//     if (useShader)
//         this->Use();
//     glUniform2f(glGetUniformLocation(this->ID, name), value.x, value.y);
// }
// void Shader::SetVector3f(const char *name, float x, float y, float z, bool useShader)
// {
//     if (useShader)
//         this->Use();
//     glUniform3f(glGetUniformLocation(this->ID, name), x, y, z);
// }
// void Shader::SetVector3f(const char *name, const glm::vec3 &value, bool useShader)
// {
//     if (useShader)
//         this->Use();
//     glUniform3f(glGetUniformLocation(this->ID, name), value.x, value.y, value.z);
// }
// void Shader::SetVector4f(const char *name, const glm::vec4 &value, bool useShader)
// {
//     if (useShader)
//         this->Use();
//     glUniform4f(glGetUniformLocation(this->ID, name), value.x, value.y, value.z, value.w);
// }
// void Shader::SetMatrix4(const char *name, const glm::mat4 &matrix, bool useShader)
// {
//     if (useShader)
//         this->Use();
//     glUniformMatrix4fv(glGetUniformLocation(this->ID, name), 1, false, glm::value_ptr(matrix));
// }
//
//
