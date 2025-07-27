package sgl

import "core:c"
import "core:log"
import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

_initGL :: proc(width, height: u32) -> bool {
    gl.load_up_to(OPENGL_MAJOR_VER, OPENGL_MINOR_VER, sdl.gl_set_proc_address)

    _updateViewportSize_GL(width, height)
    gl_enableDepthTest()
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    enableFaceCulling_gl()
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

enableFaceCulling_gl :: proc() {
    gl.Enable(gl.CULL_FACE)
}

disableFaceCulling_gl :: proc() {
    gl.Disable(gl.CULL_FACE)
}

gl_enableDepthTest :: proc() {
    gl.Enable(gl.DEPTH_TEST)
}

gl_disableDepthTest :: proc() {
    gl.Disable(gl.DEPTH_TEST)
}

bindVAO_gl :: proc(vao: GL_VaoId) {
    gl.BindVertexArray(u32(vao))
}

GL_VaoId :: distinct u32
makeVAO_gl :: proc() -> GL_VaoId {
    vao : u32
    gl.GenVertexArrays(1, &vao)
    return GL_VaoId(vao)
}

GL_BufferId :: distinct u32
makeBuffer_gl :: proc() -> GL_BufferId {
    buff : u32
    gl.GenBuffers(1, &buff)
    return GL_BufferId(buff)
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

setVBOData_gl :: proc(vbo: GL_BufferId, data: []$T, usage: GL_BufferUsageKind) {
    gl.BindBuffer(gl.ARRAY_BUFFER, u32(vbo));
    gl.BufferData(gl.ARRAY_BUFFER, len(data) * size_of(T), raw_data(data), u32(usage));
}

setEBOData_gl :: proc(ebo: GL_BufferId, indices: []$T, usage: GL_BufferUsageKind) {
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, u32(ebo));
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices) * size_of(T), raw_data(indices), u32(usage));
}

_updateViewportSize_GL :: proc(width, height: u32) {
    gl.Viewport(0, 0, i32(width), i32(height))
}

gl_clearBackground :: proc(r, g, b, a: f32) {
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
    m.ebo = makeBuffer_gl()
    m.vbo = makeBuffer_gl()
    m.vao = makeVAO_gl()

    bindVAO_gl(m.vao); defer bindVAO_gl(0)

    setVBOData_gl(m.vbo, m.vertices, .StaticDraw)

    setEBOData_gl(m.ebo, m.indices, .StaticDraw)
    // gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, m.ebo)
    // gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(m.indices) * size_of(m.indices[0]), &m.indices[0], gl.STATIC_DRAW)

    // position
    setVertexAttribute_gl(f32, 0, 3, size_of(Vertex), 0)
    // normal
    setVertexAttribute_gl(f32, 1, 3, size_of(Vertex), offset_of(Vertex, normal))
    // uv
    setVertexAttribute_gl(f32, 2, 2, size_of(Vertex), offset_of(Vertex, uv))
}

gl_drawMesh :: proc(m: Mesh) {
    bindVAO_gl(m.vao); defer bindVAO_gl(0)
    drawTrianglesWithIndices_gl(m.vao, len(m.indices))
}

drawTrianglesWithIndices_gl :: proc(vao: GL_VaoId, indices_len: int) {
    bindVAO_gl(vao); defer bindVAO_gl(0)
    gl.DrawElements(gl.TRIANGLES, i32(indices_len), gl.UNSIGNED_INT, nil)
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

_odinTypeToGLType :: proc(T: typeid) -> u32 {
    switch T {
    case f32:
        return gl.FLOAT
    case:
        log.error("unhandled type")
        panic("unhandled")
    }
    return 0
}

setVertexAttribute_gl :: proc(
    $T: typeid,
    attrib_id: u32,
    length: i32,
    stride: i32,
    start: uintptr,
    normalize := false
) {
    gl.EnableVertexAttribArray(attrib_id)  
    gl.VertexAttribPointer(
        attrib_id,
        length,
        _odinTypeToGLType(T),
        normalize ? gl.TRUE : gl.FALSE,
        stride,
        start,
    );
}
