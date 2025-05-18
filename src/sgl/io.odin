package sgl

import os "core:os/os2"
import "core:strings"
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
loadImage :: proc(img_path: string, flip := true, allocator := context.allocator) -> Image {
    img_bytes, err := os.read_entire_file_from_path(
        img_path,
        tempAlly(),
    )
    assert(err == nil)

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
    assert(img != nil)
    defer stbi.image_free(img)

    fmt.println(channels)

    return {
        data = slice.clone(img[0:width * height * channels]),
        width = width,
        height = height,
        channels = channels,
        format = getFormatFromChannels(channels),
    }
}

deleteImage :: proc(img: ^Image) {
    delete(img.data)
    img.data = nil
}
