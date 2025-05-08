package sgl

import os "core:os/os2"
import gl "vendor:OpenGL"
import "core:log"
import "core:strings"

Shader :: struct {
    id: u32,
}

useShader :: proc(s: Shader) {
    gl.UseProgram(s.id)
}

loadShaderFromFile :: proc(vert_path, frag_path: string) -> Shader {
    vert, vert_err := os.read_entire_file_from_path(vert_path, tempAlly())
    assert(vert_err == nil)
    fragment, frag_err := os.read_entire_file_from_path(frag_path, tempAlly())
    assert(frag_err == nil)
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

    // if geometry shader source code is given, also compile geometry shader
    // if (geometrySource != nil)
    // {
    //     gShader = glCreateShader(gl.GEOMETRY_SHADER);
    //     gl.ShaderSource(gShader, 1, &geometrySource, nil);
    //     gl.CompileShader(gShader);
    //     checkCompileErrors(gShader, "GEOMETRY");
    // }

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

//
// void Shader::SetFloat(const char *name, float value, bool useShader)
// {
//     if (useShader)
//         this->Use();
//     glUniform1f(glGetUniformLocation(this->ID, name), value);
// }
// void Shader::SetInteger(const char *name, int value, bool useShader)
// {
//     if (useShader)
//         this->Use();
//     glUniform1i(glGetUniformLocation(this->ID, name), value);
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
// void Shader::SetVector4f(const char *name, float x, float y, float z, float w, bool useShader)
// {
//     if (useShader)
//         this->Use();
//     glUniform4f(glGetUniformLocation(this->ID, name), x, y, z, w);
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
