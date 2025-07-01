package sgl

import sdl "vendor:sdl3"
import "core:log"
import "core:fmt"
import "core:os"
import "core:strings"
import "base:runtime"
import sarr "core:container/small_array"

OPENGL_MAJOR_VER :: 4
OPENGL_MINOR_VER :: 4

Backend :: enum {
    Software,
    OpenGL,
}

OpenGLStuff :: struct {
    rect_ebo: u32,
    rect_vbo: u32,
    rect_vao: u32,
}

Context :: struct {
    sdl: SDLStuff,
    gl: OpenGLStuff,

    is_running: bool,
    prev_frame_time_ms: u64,
    dt: f32,
    mouse: Mouse,
    window: Window,
    backend: Backend,
    target_fps: int,
}

Window :: struct {
    width, height: u32,
}

SDLStuff :: struct {
    win: ^sdl.Window,
    scancodes: [1024]bool,
    scancodes_prev: [1024]bool,
    keys_clicked_at_same_frame: sarr.Small_Array(32, u32),
    mouse_btn_mask: u32,

    glcontext: ^sdl.GLContextState,

    renderer: ^sdl.Renderer,
}

Mouse :: struct {
    x, y: f32,
    x_delta, y_delta: f32,
    // new_x_delta, new_y_delta: f32,
    buttons: sdl.MouseButtonFlags,
}

MouseBtn :: enum {
    Left,
    Middle,
    Right,
    X1,
    X2,
}

InitOptions :: struct {
    backend: Backend,
    target_fps: int,
}

DEFAULT_INIT_OPTIONS : InitOptions : {
    backend = .OpenGL,
    target_fps = 60,
}

@(require_results)
init :: proc(width, height: u32, title: string, options := DEFAULT_INIT_OPTIONS) -> Context {
    c : Context
    _initSDL(&c.sdl, width, height, title)

    switch options.backend {
    case .OpenGL:
        _initGL(&c, width, height)
    case .Software:
        c.sdl.renderer = sdl.CreateRenderer(c.sdl.win, nil)
    }

    setRelativeMouseMode(c, true)

    c.is_running = true
    c.prev_frame_time_ms = getTimeMs()
    c.dt = 0.016
    c.backend = options.backend
    c.target_fps = options.target_fps
    c.mouse = {}
    c.window = {width, height}
    return c
}

deinit :: proc(c: ^Context) {
    _deinitSDL(c)
}

makeLogger :: proc() -> runtime.Logger {
    return log.create_console_logger()
}

finishFrame :: proc(c: ^Context) {
    // end of current frame
    _swapWindow(c)
    free_all(tempAlly())

    // start of new frame
    curr_time_ms := getTimeMs()
    frame_delta_ms := curr_time_ms - c.prev_frame_time_ms
    sleep_time := (1000 / f32(c.target_fps)) - f32(frame_delta_ms)
    if 0 < sleep_time {
        sdl.Delay(u32(sleep_time))
    }
    curr_time_ms = getTimeMs()
    c.dt = f32(curr_time_ms - c.prev_frame_time_ms) / 1000
    c.prev_frame_time_ms = curr_time_ms
    c.mouse = {}

    _pollEvents(c)
    _updateMouseState(c)

    _clearZBuffer(c^)
}

_updateMouseState :: proc(c: ^Context) {
    c.mouse.buttons = sdl.GetRelativeMouseState(&c.mouse.x_delta, &c.mouse.y_delta)
    c.mouse.x = clamp(c.mouse.x + c.mouse.x_delta, 0, f32(c.window.width))
    c.mouse.y = clamp(c.mouse.y + c.mouse.y_delta, 0, f32(c.window.height))
}

setWindowResizable :: proc(c: Context, on: bool) {
    sdl.SetWindowResizable(c.sdl.win, on)
}

getDelta :: proc(c: Context) -> f32 {
    return c.dt
}

getWindowSize :: proc(c: Context) -> (u32, u32) {
    return c.window.width, c.window.height
}

getScreenWidth :: proc(c: Context) -> u32 {
    return c.window.width
}

getScreenHeight :: proc(c: Context) -> u32 {
    return c.window.height
}

clearScreen :: proc(c: Context, color: Color) {
    switch c.backend {
    case .OpenGL: 
        _clearScreen_GL(color.r, color.g, color.b, color.a)
    case .Software:
        _setSDLColor(c, color)
        sdl.RenderClear(c.sdl.renderer)
    }
}

_clearZBuffer :: proc(c: Context) {
    switch c.backend {
    case .OpenGL:
        _clearZBuffer_GL()
    case .Software:
    }
}

_swapWindow :: proc(c: ^Context) {
    switch c.backend {
    case .OpenGL: 
        sdl.GL_SwapWindow(c.sdl.win)
    case .Software:
        sdl.RenderPresent(c.sdl.renderer)
    }
}

isKeyDown :: proc(c: Context, btn: sdl.Scancode) -> bool {
    return c.sdl.scancodes[btn]
}

_pollEvents :: proc(c: ^Context) {
    for scancode in sarr.slice(&c.sdl.keys_clicked_at_same_frame) {
        c.sdl.scancodes[scancode] = false
    }
    sarr.clear(&c.sdl.keys_clicked_at_same_frame)
    c.sdl.scancodes_prev = c.sdl.scancodes

    ev: sdl.Event
    for sdl.PollEvent(&ev) {
        #partial switch ev.type {
        case .QUIT:
            c.is_running = false
        case .WINDOW_RESIZED:
            width := ev.window.data1
            height := ev.window.data2
            _updateViewportSize(c, u32(width), u32(height))
        case .KEY_DOWN:
            c.sdl.scancodes[u32(ev.key.scancode)] = true
        case .KEY_UP:
            prev := c.sdl.scancodes_prev[u32(ev.key.scancode)]
            new := c.sdl.scancodes[u32(ev.key.scancode)]
            if new {
                if prev {
                    c.sdl.scancodes[u32(ev.key.scancode)] = false
                } else {
                    sarr.push(&c.sdl.keys_clicked_at_same_frame, u32(ev.key.scancode))
                    // pressed and released at the same frame
                }
            }
        case:
            // fmt.println(ev.type)
        }
    }
}

enableWireframeMode :: proc() {
    _enableWireframeMode_GL()
}

disableWireframeMode :: proc() {
    _disableWireframeMode_GL()
}

_updateViewportSize :: proc(c: ^Context, width, height: u32) {
    c.window.width = width
    c.window.height = height
    switch c.backend {
    case .OpenGL:
        _updateViewportSize_GL(width, height)
    case .Software:
    }
}

isWindowShouldClose :: proc(c: Context) -> bool {
    return !c.is_running
}

_changeDirectoryToExePath :: proc() {
    os.set_current_directory(readExePath())
}

_initSDL :: proc(c: ^SDLStuff, width, height: u32, title: string) -> bool {
    if !sdl.Init({.VIDEO}) {
        log.error("Couldn't initialize SDL", sdl.GetError())
        return false
    }
    c.scancodes = {}

    sdl.GL_SetAttribute(sdl.GL_CONTEXT_MAJOR_VERSION, OPENGL_MAJOR_VER);
    sdl.GL_SetAttribute(sdl.GL_CONTEXT_MINOR_VERSION, OPENGL_MINOR_VER);
    sdl.GL_SetAttribute(sdl.GL_CONTEXT_PROFILE_MASK, i32(sdl.GL_CONTEXT_PROFILE_CORE));

    title_cstring := strings.clone_to_cstring(title); defer delete(title_cstring)
    c.win = sdl.CreateWindow(title_cstring, i32(width), i32(height), {.OPENGL})
    if c.win == nil {
        log.error("SDL Window was not created. SDL error:", sdl.GetError())
        return false
    }

    c.glcontext = sdl.GL_CreateContext(c.win);
    if c.glcontext == nil {
        log.error("GL context was not created. SDL error:", sdl.GetError())
        return false
    }
    sdl.GL_MakeCurrent(c.win, c.glcontext)
    // enableVSync()

    return true
}

enableVSync :: proc() {
    _enableVSync_GL()
}

disableVSync :: proc() {
    _disableVSync_GL()
}

_deinitSDL :: proc(c: ^Context) {
    sdl.Quit()
}

tempAlly :: proc() -> runtime.Allocator {
    return context.temp_allocator
}

ally :: proc() -> runtime.Allocator {
    return context.allocator
}

getTimeMs :: proc() -> u64 {
    return sdl.GetTicks();
}

getTime :: proc() -> f64 {
    return f64(getTimeMs()) / 1000;
}

unreachable :: proc() {
    panic("unreachable")
}

getMousePos :: proc(c: Context) -> Vec2 {
    return {c.mouse.x, c.mouse.y}
}

getMouseDeltaX :: proc(c: Context) -> f32 {
    return c.mouse.x_delta
}

getMouseDeltaY :: proc(c: Context) -> f32 {
    return c.mouse.y_delta
}

setRelativeMouseMode :: proc(c: Context, on: bool) {
    if !sdl.SetWindowRelativeMouseMode(c.sdl.win, on) {
        log.errorf("sdl: SetWindowRelativeMouseMode returned false: %s", sdl.GetError())
    }
}

setMouseGrabMode :: proc(c: Context, on: bool) {
    if !sdl.SetWindowMouseGrab(c.sdl.win, on) {
        log.errorf("sdl: SetWIndowMouseGrab returned false: %s", sdl.GetError())
    }
}

randomF32 :: proc() -> f32 {
    return sdl.randf()
}

Color :: [4]f32

drawLine :: proc(c: Context, a: Vec2, b: Vec2, color: Color) {
    assert(c.backend == .Software)
    _setSDLColor(c, color)
    sdl.RenderLine(c.sdl.renderer, a.x, a.y, b.x, b.y)
}

Rect :: struct {
    x, y, w, h: f32,
}

drawRect :: proc(c: Context, rect: Rect, color: Color) {
    assert(c.backend == .Software)
    frect : sdl.FRect = {rect.x, rect.y, rect.w, rect.h}
    _setSDLColor(c, color)
    sdl.RenderRect(c.sdl.renderer, &frect);
}

_setSDLColor :: proc(c: Context, color: Color) {
    sdl.SetRenderDrawColor(c.sdl.renderer, u8(color.r * 255), u8(color.g * 255), u8(color.b * 255), u8(color.a * 255));
}
