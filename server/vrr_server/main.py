import socket
import asyncio
import ffmpeg
from PIL import ImageGrab
from PIL.Image import _getencoder
from dataclasses import dataclass
from typing import List, Any
import numpy as np


class OpCode:
    HELLO = 1


def send(conn, opcode):
    conn.send(f"{opcode:04d}".encode("utf-8"))


@dataclass
class StreamContext:
    process: List[Any]
    width: int
    height: int
    tick: int = 0


# TODO find proper width and height of monitors separately
async def setup_frame_sending(width, height):
    ffmpeg_cmdlines = (
        f"ffmpeg -video_size 1366x768 -framerate 45 -f x11grab -i :0.0 -c:v libx264 -preset fast -tune zerolatency -b:v 15M -maxrate 15M -bufsize 10M -crf 18 -f rtsp -rtsp_transport udp rtsp://localhost:8554/screen_1.sdp",
        f"ffmpeg -video_size 1080x1920 -framerate 45 -f x11grab -i :0.0+1366,0 -c:v libx264 -preset fast -tune zerolatency -b:v 15M -maxrate 15M -bufsize 10M -crf 18 -f rtsp -rtsp_transport udp rtsp://localhost:8554/screen_2.sdp",
    )
    print("ffmpeg cmd", ffmpeg_cmdlines)

    processes = []

    for cmdline in ffmpeg_cmdlines:
        processes.append(
            await asyncio.create_subprocess_shell(
                cmdline,
            )
        )

    return StreamContext(
        processes,
        width,
        height,
    )


def write_bytes_to_file(fd, image):
    e = _getencoder(image.mode, encoder_name="raw", args=image.mode)
    e.setimage(image.im)
    l, s, d = e.encode(image.width * image.height * 4)
    fd.write(d)
    if s < 0:
        raise RuntimeError(f"encoder error {s} in tobytes")


async def capture_frame(ctx) -> bytes:
    img = ImageGrab.grab()
    print("tick", img.mode, ctx.tick)
    write_bytes_to_file(ctx.process.stdin, img)
    await ctx.process.stdin.drain()

    # read the full h264 thing we want
    out_bytes = b""
    while True:
        print("read...")
        chunk = await ctx.process.stdout.read(4096)
        print("chunk", chunk)
        if not chunk:
            break
        out_bytes += chunk

    return out_bytes


async def amain():
    ctx = await setup_frame_sending(-1, -1)
    try:
        coros = []
        for proc in ctx.processes:
            coros.append(proc.wait())
        await asyncio.wait(coros)
    finally:
        for proc in ctx.processes:
            await proc.kill()


def main():
    asyncio.run(amain())


if __name__ == "__main__":
    main()
