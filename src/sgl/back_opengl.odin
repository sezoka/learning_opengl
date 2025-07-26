package sgl

import "core:c"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

_initGL :: proc(ctx: ^Context, width, height: u32) -> bool {
    gl.load_up_to(OPENGL_MAJOR_VER, OPENGL_MINOR_VER, sdl.gl_set_proc_address)

    _updateViewportSize_GL(width, height)
    gl_enableDepthTest()
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    gl_enableFaceCulling()
    _disableVSync_GL()

    // {
    //     ctx.gl.rect_vbo = gl_makeBuffer()
    //     ctx.gl.rect_ebo = gl_makeBuffer()
    //     ctx.gl.rect_vao = gl_makeVAO()
    //     gl_bindVAO(ctx.gl.rect_vao); defer gl_bindVAO(0)
    //
    //     gl_setVBOData(ctx.gl.rect_vbo, _gl_rect_vertices[:], .StaticDraw)
    //     gl_setEBOData(ctx.gl.rect_ebo, _gl_rect_indices[:], .StaticDraw)
    // }

    return true
}

_gl_rect_vertices := [?]f32 {
     0.5,  0.5, 0.0,  // top right
     0.5, -0.5, 0.0,  // bottom right
    -0.5, -0.5, 0.0,  // bottom let
    -0.5,  0.5, 0.0   // top let 
}

_gl_rect_indices := [?]i32 {
    0, 1, 3,  // first Triangle
    1, 2, 3   // second Triangle
}

GLType :: enum(c.int) {
    byte = gl.BYTE,
    ubyte = gl.UNSIGNED_BYTE,
    short = gl.SHORT,
    ushort = gl.UNSIGNED_SHORT,
    int = gl.INT,
    uint = gl.UNSIGNED_INT
}

// gl_defineVertexAttribute :: proc(idx: u32, gl_type: GLType, stride: c.uint) {
//     gl_type : u32 = 0
//     assert(0 < idx)
// }

gl_enableFaceCulling :: proc() {
    gl.Enable(gl.CULL_FACE)
}

gl_disableFaceCulling :: proc() {
    gl.Disable(gl.CULL_FACE)
}

gl_enableDepthTest :: proc() {
    gl.Enable(gl.DEPTH_TEST)
}

gl_disableDepthTest :: proc() {
    gl.Disable(gl.DEPTH_TEST)
}

gl_bindVAO :: proc(vao: u32) {
    gl.BindVertexArray(vao)
}

gl_makeVAO :: proc() -> u32 {
    vao : u32
    gl.GenVertexArrays(1, &vao)
    return vao
}

gl_makeBuffer :: proc() -> u32 {
    buff : u32
    gl.GenBuffers(1, &buff)
    return buff
}

GL_BufferUsageKind :: enum(u32) {
    StaticDraw = gl.STATIC_DRAW,
    StaticRead = gl.STATIC_READ,
    StaticCopy = gl.STATIC_COPY,
    DynamicDraw = gl.DYNAMIC_DRAW,
    DynamicDead = gl.DYNAMIC_READ,
    DynamicCopy = gl.DYNAMIC_COPY,
    StreamDraw = gl.STREAM_DRAW,
    StreamRead = gl.STREAM_READ,
    StreamCopy = gl.STREAM_COPY,
}

gl_setVBOData :: proc(vbo: u32, data: []$T, usage: GL_BufferUsageKind) {
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.BufferData(gl.ARRAY_BUFFER, len(data) * size_of(T), raw_data(data), u32(usage));
}

gl_setEBOData :: proc(ebo: u32, indices: []$T, usage: GL_BufferUsageKind) {
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices) * size_of(T), raw_data(indices), u32(usage));
}

_updateViewportSize_GL :: proc(width, height: u32) {
    gl.Viewport(0, 0, i32(width), i32(height))
}

_clearScreen_GL :: proc(r, g, b, a: f32) {
    gl.ClearColor(r, g, b, a);
    gl.Clear(gl.COLOR_BUFFER_BIT)
}

_enableWireframeMode_GL :: proc() {
    gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
}

_disableWireframeMode_GL :: proc() {
    gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
}

_clearZBuffer_GL :: proc() {
    gl.Clear(gl.DEPTH_BUFFER_BIT)
}

_enableVSync_GL :: proc() {
    sdl.GL_SetSwapInterval(1)
}

_disableVSync_GL :: proc() {
    sdl.GL_SetSwapInterval(0)
}

_initMesh_GL :: proc(m: ^Mesh) {
    gl.GenVertexArrays(1, &m.vao)
    gl.GenBuffers(1, &m.vbo)
    gl.GenBuffers(1, &m.ebo)

    gl.BindVertexArray(m.vao); defer gl.BindVertexArray(0)

    gl_setVBOData(m.vbo, m.vertices, .StaticDraw)

    gl_setEBOData(m.ebo, m.indices, .StaticDraw)
    // gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, m.ebo)
    // gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(m.indices) * size_of(m.indices[0]), &m.indices[0], gl.STATIC_DRAW)

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

_drawMesh_GL :: proc(m: Mesh) {
    gl.BindVertexArray(m.vao); defer gl.BindVertexArray(0)
    gl.DrawElements(gl.TRIANGLES, i32(len(m.indices)), gl.UNSIGNED_INT, nil)
}

setImageData_gl :: proc(target: u32, img: Image) {
    gl.TexImage2D(
        target,
        0,
        _myImgFormatToGLImgFormat(img.format),
        img.width,
        img.height,
        0,
        u32(_myImgFormatToGLImgFormat(img.format)),
        gl.UNSIGNED_BYTE,
        raw_data(img.data)
    );
} 
