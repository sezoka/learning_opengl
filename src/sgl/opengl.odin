package sgl

import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

_initGL :: proc(width, height: u32) -> bool {
    gl.load_up_to(OPENGL_MAJOR_VER, OPENGL_MINOR_VER, sdl.gl_set_proc_address)

    gl.Viewport(0, 0, i32(width), i32(height));
    gl.Enable(gl.BLEND);
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    gl.Enable(gl.DEPTH_TEST);  

    return true
}

_updateViewportSizeGL :: proc(width, height: u32) {
    gl.Viewport(0, 0, i32(width), i32(height));
}

_clearScreenGL :: proc(r, g, b, a: f32) {
    gl.ClearColor(r, g, b, a);
    gl.Clear(gl.COLOR_BUFFER_BIT);
}

_enableWireframeModeGL :: proc() {
    gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
}

_disableWireframeModeGL :: proc() {
    gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
}

_clearZBufferGL :: proc() {
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

_enableVSyncGL :: proc() {
    sdl.GL_SetSwapInterval(1)
}

_disableVSyncGL :: proc() {
    sdl.GL_SetSwapInterval(0)
}

_initMeshGL :: proc(m: ^Mesh) {
    gl.GenVertexArrays(1, &m.vao)
    gl.GenBuffers(1, &m.vbo)
    gl.GenBuffers(1, &m.ebo)

    gl.BindVertexArray(m.vao); defer gl.BindVertexArray(0)

    gl.BindBuffer(gl.ARRAY_BUFFER, m.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(m.vertices) * size_of(m.vertices[0]), &m.vertices[0], gl.STATIC_DRAW)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, m.ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(m.indices) * size_of(m.indices[0]), &m.indices[0], gl.STATIC_DRAW)

    // position
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), 0)
    // normal
    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, normal))
    // uv
    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, uv))
}

_drawMeshGL :: proc(m: Mesh) {
    gl.BindVertexArray(m.vao); defer gl.BindVertexArray(0)
    gl.DrawElements(gl.TRIANGLES, i32(len(m.indices)), gl.UNSIGNED_INT, nil)
}
