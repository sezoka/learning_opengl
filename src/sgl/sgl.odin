package sgl

import sdl "vendor:sdl3"
import "core:log"
import "core:os"
import "core:strings"
import "base:runtime"

OPENGL_MAJOR_VER :: 4
OPENGL_MINOR_VER :: 4

Context :: struct {
    sdl: SDLStuff,
    is_running: bool,
}

SDLStuff :: struct {
    win: ^sdl.Window,
    glcontext: ^sdl.GLContextState,
    keys: [1024]bool,
}

@(require_results)
init :: proc(width, height: u32, title: string) -> Context {
    ctx : Context
    ctx.is_running = true
    _initSDL(&ctx.sdl, width, height, title)
    _initGL(width, height)
    return ctx
}

deinit :: proc(ctx: ^Context) {
    _deinitSDL(ctx)
}

makeLogger :: proc() -> runtime.Logger {
    return log.create_console_logger()
}

finishFrame :: proc(ctx: ^Context) {
    // end of current frame
    _swapWindow(ctx)

    // start of new frame
    _pollEvents(ctx)
    _updateKeysState(ctx)

    _clearZBuffer()
    free_all(tempAlly())
}

getScreenSize :: proc(ctx: ^Context) -> (u32, u32) {
    width, height: i32
    sdl.GetWindowSize(ctx.sdl.win, &width, &height)
    return u32(width), u32(height)
}

getScreenWidth :: proc(ctx: ^Context) -> u32 {
    width, _ := getScreenSize(ctx)
    return u32(width)
}

getScreenHeight :: proc(ctx: ^Context) -> u32 {
    _, height := getScreenSize(ctx)
    return u32(height)
}

clearScreen :: proc(r, g, b, a: f32) {
    _clearScreenGL(r, g, b, a)
}

_clearZBuffer :: proc() {
    _clearZBufferGL()
}

_swapWindow :: proc(ctx: ^Context) {
    sdl.GL_SwapWindow(ctx.sdl.win)
}

_updateKeysState :: proc(ctx: ^Context) {
    num_keys: i32
    keys := sdl.GetKeyboardState(&num_keys);
    copy(ctx.sdl.keys[:], keys[0:num_keys])
}

_pollEvents :: proc(ctx: ^Context) {
    ev: sdl.Event
    for sdl.PollEvent(&ev) {
        #partial switch ev.type {
        case .QUIT:
            ctx.is_running = false
        case .WINDOW_RESIZED:
            width := ev.window.data1
            height := ev.window.data2
            _updateViewportSize(u32(width), u32(height))
        }
    }
}

enableWireframeMode :: proc() {
    _enableWireframeModeGL()
}

disableWireframeMode :: proc() {
    _disableWireframeModeGL()
}

_updateViewportSize :: proc(width, height: u32) {
    _updateViewportSizeGL(width, height)
}

isWindowShouldClose :: proc(ctx: Context) -> bool {
    return !ctx.is_running
}

_changeDirectoryToExePath :: proc() {
    os.set_current_directory(readExePath())
}

_initSDL :: proc(ctx: ^SDLStuff, width, height: u32, title: string) -> bool {
    if !sdl.Init({.VIDEO}) {
        log.error("Couldn't initialize SDL", sdl.GetError())
        return false
    }
    ctx.keys = {}

    sdl.GL_SetAttribute(sdl.GL_CONTEXT_MAJOR_VERSION, OPENGL_MAJOR_VER);
    sdl.GL_SetAttribute(sdl.GL_CONTEXT_MINOR_VERSION, OPENGL_MINOR_VER);
    sdl.GL_SetAttribute(sdl.GL_CONTEXT_PROFILE_MASK, i32(sdl.GL_CONTEXT_PROFILE_CORE));

    title_cstring := strings.clone_to_cstring(title); defer delete(title_cstring)
    ctx.win = sdl.CreateWindow(title_cstring, i32(width), i32(height), {.OPENGL})
    if ctx.win == nil {
        log.error("SDL Window was not created. SDL error:", sdl.GetError())
        return false
    }

    ctx.glcontext = sdl.GL_CreateContext(ctx.win);
    if ctx.glcontext == nil {
        log.error("GL context was not created. SDL error:", sdl.GetError())
        return false
    }
    sdl.GL_MakeCurrent(ctx.win, ctx.glcontext)

    sdl.GL_SetSwapInterval(1)

    return true
}

_deinitSDL :: proc(ctx: ^Context) {
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
