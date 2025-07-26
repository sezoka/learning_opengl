package sgl

import gl "vendor:OpenGL"
import "core:strings"
import "core:fmt"

Texture2D :: struct {
    id: u32,
    format: ImageFormat,
    name: cstring,
}

enableTexture2D :: proc(tex: Texture2D, unit: u32) {
    gl.ActiveTexture(gl.TEXTURE0 + unit)  // HINT: currently_modifying_texture_idx = gl.TEXTURE0 + unit;
    gl.BindTexture(gl.TEXTURE_2D, tex.id) //       textures[currently_modifying_texture_idx].id = tex.id;
}

disableTexture2D :: proc(tex: Texture2D, unit: u32) {
    gl.ActiveTexture(gl.TEXTURE0 + unit)
    gl.BindTexture(gl.TEXTURE_2D, 0)    
}

enableCubeMap :: proc(cum: CubeMap, unit: u32) {
    gl.ActiveTexture(gl.TEXTURE0 + unit)
    gl.BindTexture(gl.TEXTURE_CUBE_MAP, cum.id)
}

disableCubeMap :: proc(cum: CubeMap, unit: u32) {
    gl.ActiveTexture(gl.TEXTURE0 + unit)
    gl.BindTexture(gl.TEXTURE_CUBE_MAP, 0)
}

_myImgFormatToGLImgFormat :: proc(imf: ImageFormat) -> i32 {
    switch (imf) {
    case .R8:
        return gl.RED
    case .RGB8:
        return gl.RGB
    case .RGBA8:
        return gl.RGBA
    }
    unreachable()
    return 0;
}

makeTexture2D :: proc(img: Image, name: cstring) -> (tex: Texture2D) {
    gl.GenTextures(1, &tex.id)
    enableTexture2D(tex, 0)

    setImageData_gl(gl.TEXTURE_2D, img)

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST_MIPMAP_LINEAR);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.GenerateMipmap(gl.TEXTURE_2D);

    tex.format = tex.format
    tex.name = name
    return tex
}

// images: right, left, top, bottom, back, front
makeCubeMap :: proc(images: []Image) -> (tex: CubeMap) {
    assert(len(images) == 6)

    gl.GenTextures(1, &tex.id)
    // enableCubeMap(tex, 0)
    gl.BindTexture(gl.TEXTURE_CUBE_MAP, tex.id)

    for img, i in images {
        setImageData_gl(u32(gl.TEXTURE_CUBE_MAP_POSITIVE_X + i), img)
    }

    gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, gl.NEAREST_MIPMAP_LINEAR);
    gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.TexParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_EDGE);  
    gl.GenerateMipmap(gl.TEXTURE_CUBE_MAP);

    return tex
}

loadTexture2D :: proc(path: string, name: cstring) -> Texture2D {
    img := loadImage(tempAlly(), path)
    return makeTexture2D(img, name)
}

loadCubeMap :: proc(paths: []string) -> CubeMap {
    assert(len(paths) == 6)
    imgs : [6]Image
    for path, i in paths {
        imgs[i] = loadImage(tempAlly(), path, flip=false)
    }
    return makeCubeMap(imgs[:])
}

CubeMap :: struct {
    id: u32,
}
