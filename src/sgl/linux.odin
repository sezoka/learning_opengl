#+build linux

package sgl

import "core:sys/linux"
import "core:path/filepath"

@(require_results)
readExePath :: proc() -> string {
    path := make([]u8, 2048, tempAlly());
    len, err := linux.readlink("/proc/self/exe", path[:])
    assert(err == nil)
    return string(path[0:len])
}

@(require_results)
readExeDir :: proc() -> string {
    return filepath.dir(readExePath(), tempAlly())
}


