package sgl

import gl "vendor:OpenGL"

Texture2D :: struct {
    id: u32,
    format: ImageFormat,
    name: cstring,
}

bindTexture2D :: proc(tex: Texture2D, unit: u32) {
    gl.ActiveTexture(gl.TEXTURE0 + unit)
    gl.BindTexture(gl.TEXTURE_2D, tex.id)
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
    bindTexture2D(tex, 0)
    gl.TexImage2D(
        gl.TEXTURE_2D,
        0,
        _myImgFormatToGLImgFormat(img.format),
        img.width,
        img.height,
        0,
        u32(_myImgFormatToGLImgFormat(img.format)),
        gl.UNSIGNED_BYTE,
        raw_data(img.data)
    );

    min_texture_filter :: gl.NEAREST_MIPMAP_LINEAR
    mag_texture_filter :: gl.NEAREST

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, min_texture_filter);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, mag_texture_filter);
    gl.GenerateMipmap(gl.TEXTURE_2D);

    tex.format = tex.format
    tex.name = name
    return tex
}

loadTexture2D :: proc(path: string, name: cstring) -> Texture2D {
    img := loadImage(path); defer deleteImage(&img)
    return makeTexture2D(img, name)
}
