package sgl

import "core:os/os2"
import "core:strings"
import "core:log"
import stbi "vendor:stb/image"
import "core:image"
import "core:fmt"
import "base:runtime"
import "core:slice"

Image :: struct {
    data:     []u8,
    width:    i32,
    height:   i32,
    channels: i32,
    format:   ImageFormat,
}

ImageFormat :: enum {
    R8,
    RGB8,
    RGBA8,
}

getFormatFromChannels :: proc(channels: i32) -> ImageFormat {
    switch channels {
    case 1:
        return .R8
    case 3:
        return .RGB8
    case 4:
        return .RGBA8
    }
    panic("unhandled")
}

@(require_results)
loadImage :: proc(ally: Allocator, img_path: string, flip := true) -> Image {
    img_bytes, ok := readEntireFile(
        tempAlly(),
        img_path,
    )
    assert(ok)

    width, height, channels: i32

    stbi.set_flip_vertically_on_load(flip ? 1 : 0)
    img := stbi.load_from_memory(
        raw_data(img_bytes),
        i32(len(img_bytes)),
        &width,
        &height,
        &channels,
        0,
    )
    stbi.set_flip_vertically_on_load(0)
    if img == nil {
        log.errorf("image '%s' didn't loaded by stbi. reason: '%s'", img_path, stbi.failure_reason())
        assert(img != nil)
    }
    defer stbi.image_free(img)

    return {
        data = slice.clone(img[0:width * height * channels], allocator=ally),
        width = width,
        height = height,
        channels = channels,
        format = getFormatFromChannels(channels),
    }
}

deleteImage :: proc(img: ^Image) {
    delete(img.data)
    img^ = {}
}

@(require_results)
readEntireFile :: proc(ally: Allocator, path: string) -> ([]byte, bool) {
    file_bytes, err := os2.read_entire_file_from_path(path, allocator = ally)
    if err != nil {
        log.errorf("failed to read file '%s', error: '%v'", path, err)
        return {}, false
    }
    return file_bytes, true
}
