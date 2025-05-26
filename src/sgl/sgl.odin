package sgl

import sdl "vendor:sdl3"
import "core:log"
import "core:fmt"
import "core:os"
import "core:strings"
import "base:runtime"

OPENGL_MAJOR_VER :: 4
OPENGL_MINOR_VER :: 4

Backend :: enum {
    Software,
    OpenGL,
}

Context :: struct {
    sdl: SDLStuff,
    is_running: bool,
    prev_frame_time_ms: u64,
    dt: f32,
    mouse: Mouse,
    backend: Backend,
    target_fps: int,
}

SDLStuff :: struct {
    win: ^sdl.Window,
    keys: [1024]bool,
    mouse_btn_mask: u32,

    glcontext: ^sdl.GLContextState,

    renderer: ^sdl.Renderer,
}

Mouse :: struct {
    x_delta: f32,
    y_delta: f32,
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
        _initGL(width, height)
    case .Software:
        c.sdl.renderer = sdl.CreateRenderer(c.sdl.win, nil)
    }

    enableRelativeMouseMode(c)
    c.is_running = true
    c.prev_frame_time_ms = getTimeMs()
    c.dt = 0.016
    c.backend = options.backend
    c.target_fps = options.target_fps
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

    _pollEvents(c)
    _updateKeysState(c)
    _updateMouseState(c)

    _clearZBuffer(c^)
}

_updateMouseState :: proc(c: ^Context) {
    c.mouse.buttons = sdl.GetRelativeMouseState(&c.mouse.x_delta, &c.mouse.y_delta)
}

setWindowResizable :: proc(c: Context, on: bool) {
    sdl.SetWindowResizable(c.sdl.win, on)
}

getDelta :: proc(c: Context) -> f32 {
    return c.dt
}

getScreenSize :: proc(c: Context) -> (u32, u32) {
    width, height: i32
    sdl.GetWindowSize(c.sdl.win, &width, &height)
    return u32(width), u32(height)
}

getScreenWidth :: proc(c: Context) -> u32 {
    width, _ := getScreenSize(c)
    return u32(width)
}

getScreenHeight :: proc(c: Context) -> u32 {
    _, height := getScreenSize(c)
    return u32(height)
}

clearScreen :: proc(c: Context, r, g, b, a: f32) {
    switch c.backend {
    case .OpenGL: 
        _clearScreen_GL(r, g, b, a)
    case .Software:
        sdl.SetRenderDrawColor(c.sdl.renderer, u8(r * 255), u8(g * 255), u8(b * 255), u8(a * 255));
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

_updateKeysState :: proc(c: ^Context) {
    num_keys: i32
    keys := sdl.GetKeyboardState(&num_keys);
    copy(c.sdl.keys[:], keys[0:num_keys])
}

isButtonDown :: proc(c: Context, btn: sdl.Scancode) -> bool {
    return c.sdl.keys[btn]
}

_pollEvents :: proc(c: ^Context) {
    ev: sdl.Event
    for sdl.PollEvent(&ev) {
        #partial switch ev.type {
        case .QUIT:
            c.is_running = false
        case .WINDOW_RESIZED:
            width := ev.window.data1
            height := ev.window.data2
            _updateViewportSize(u32(width), u32(height))
        }
    }
}

enableWireframeMode :: proc() {
    _enableWireframeMode_GL()
}

disableWireframeMode :: proc() {
    _disableWireframeMode_GL()
}

_updateViewportSize :: proc(width, height: u32) {
    _updateViewportSize_GL(width, height)
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
    c.keys = {}

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

getMouseDeltaX :: proc(c: Context) -> f32 {
    return c.mouse.x_delta
}

getMouseDeltaY :: proc(c: Context) -> f32 {
    return c.mouse.y_delta
}

enableRelativeMouseMode :: proc(c: Context) {
    setRelativeMouseMode(c, true)
}

disableRelativeMouseMode :: proc(c: Context)  {
    setRelativeMouseMode(c, false)
}

setRelativeMouseMode :: proc(c: Context, on: bool) {
    if !sdl.SetWindowRelativeMouseMode(c.sdl.win, on) {
        log.errorf("sdl: SetWindowRelativeMouseMode returned false: %s", sdl.GetError())
    }
}

randomF32 :: proc() -> f32 {
    return sdl.randf()
}
