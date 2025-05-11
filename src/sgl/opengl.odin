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
