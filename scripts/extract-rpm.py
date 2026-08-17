#!/usr/bin/env python3
"""
extract-rpm.py — 极简 rpm payload 提取器（纯 Python 标准库，无 rpm/cpio 依赖）。

用法:
    python3 extract-rpm.py <package.rpm> <destdir>

原理:
    RPM 文件布局 = 96 字节 lead + signature header + main header + payload。
    payload 是 (gzip|xz 压缩的) newc(cpio) 归档，此处直接解析并落盘，
    保留文件权限与符号链接。不需要目标架构的 rpm 二进制，也不需要
    rpm2cpio/bsdtar 等宿主工具。

支持:
    - payload 压缩: gzip(.rpm 常见)、xz(lzma)、以及未压缩
    - cpio 格式: newc (070701 / 070702)
"""

import os
import struct
import sys
import zlib

LEAD_SIZE = 96
_CPIO_HEADER = struct.Struct(
    "6s8s8s8s8s8s8s8s8s8s8s8s8s8s"  # magic ino mode uid gid nlink mtime
)  # filesize devmajor devminor rdevmajor rdevminor namesize check
# 实际 14 个字段
_CPIO_HEADER = struct.Struct(
    "6s8s8s8s8s8s8s8s8s8s8s8s8s8s"
)


def _align4(n: int) -> int:
    return (n + 3) & ~3


def _header_end(data: bytes, offset: int) -> int:
    """解析一个 header（magic+reserved+nindex+hsize+index+data），返回其主体结束偏移。"""
    if data[offset : offset + 4] not in (b"\x8e\xad\xe8\x01", b"\x8e\xad\xe8\x00"):
        raise SystemExit(f"不是有效的 rpm header magic @{offset}: {data[offset:offset+4]!r}")
    nindex, hsize = struct.unpack(">II", data[offset + 8 : offset + 16])
    return offset + 16 + nindex * 16 + hsize


def _scan_magic(data: bytes, start: int, magics, max_off: int = 16) -> int:
    """在 start 之后 max_off 字节内寻找任一 magic（容忍 header 尾部 8 字节对齐填充）。"""
    end = min(len(data), start + max_off)
    for off in range(0, end - start):
        for m in magics:
            if data[start + off : start + off + len(m)] == m:
                return start + off
    raise SystemExit(f"无法在偏移 {start} 附近找到 {magics!r}")


def _read_payload(rpm_path: str) -> bytes:
    with open(rpm_path, "rb") as f:
        data = f.read()

    sig_body_end = _header_end(data, LEAD_SIZE)
    sig_end = _scan_magic(data, sig_body_end, (b"\x8e\xad\xe8\x01",))  # -> main header
    main_body_end = _header_end(data, sig_end)
    pos = _scan_magic(
        data, main_body_end, (b"\x1f\x8b", b"\xfd7zXZ\x00", b"070701")
    )  # -> payload
    payload = data[pos:]

    if payload[:2] == b"\x1f\x8b":
        return zlib.decompress(payload, 16 + zlib.MAX_WBITS)
    if payload[:6] == b"\xfd7zXZ\x00":
        import lzma

        return lzma.decompress(payload)
    return payload


def _mode_to_type(mode_hex: str) -> int:
    return int(mode_hex, 16) & 0o170000


def _extract_cpio_newc(data: bytes, dest: str) -> None:
    off = 0
    n = len(data)
    count = 0
    while off + 110 <= n:
        magic = data[off : off + 6]
        if magic not in (b"070701", b"070702"):
            raise SystemExit(f"cpio magic 异常 @{off}: {magic!r}")
        fields = _CPIO_HEADER.unpack_from(data, off)
        hdr_vals = [int(x, 16) for x in fields[1:]]
        (
            ino,
            mode,
            uid,
            gid,
            nlink,
            mtime,
            filesize,
            devmajor,
            devminor,
            rdevmajor,
            rdevminor,
            namesize,
            check,
        ) = hdr_vals

        name = data[off + 110 : off + 110 + namesize - 1].decode("utf-8", "replace")
        data_off = off + _align4(110 + namesize)
        content = data[data_off : data_off + filesize]

        if name == "TRAILER!!!":
            break

        path = os.path.join(dest, name.lstrip("./"))
        ftype = mode & 0o170000

        if ftype == 0o040000:  # dir
            os.makedirs(path, exist_ok=True)
            os.chmod(path, mode & 0o7777)
        elif ftype == 0o120000:  # symlink
            os.makedirs(os.path.dirname(path), exist_ok=True)
            target = content.decode("utf-8", "replace")
            try:
                os.symlink(target, path)
            except FileExistsError:
                os.unlink(path)
                os.symlink(target, path)
        elif ftype == 0o100000:  # regular file
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "wb") as fh:
                fh.write(content)
            os.chmod(path, mode & 0o7777)
        elif ftype == 0o020000:  # char device
            os.makedirs(os.path.dirname(path), exist_ok=True)
        else:
            os.makedirs(os.path.dirname(path), exist_ok=True)

        count += 1
        off = data_off + _align4(filesize)

    print(f"[extract-rpm] 解包完成: {count} 个条目 -> {dest}")


def main() -> None:
    if len(sys.argv) != 3:
        print(__doc__)
        raise SystemExit("用法: extract-rpm.py <package.rpm> <destdir>")
    rpm_path, dest = sys.argv[1], sys.argv[2]
    os.makedirs(dest, exist_ok=True)
    data = _read_payload(rpm_path)
    _extract_cpio_newc(data, dest)


if __name__ == "__main__":
    main()