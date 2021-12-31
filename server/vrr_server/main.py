import socket
import asyncio
import ffmpeg
from PIL import ImageGrab
from PIL.Image import _getencoder
from dataclasses import dataclass
import numpy as np


class OpCode:
    HELLO = 1


def send(conn, opcode):
    conn.send(f"{opcode:04d}".encode("utf-8"))


@dataclass
class StreamContext:
    process: str
    width: int
    height: int
    tick: int = 0


# TODO find proper width and height of monitors separately
async def setup_frame_sending(width, height):
    ffmpeg_cmdline = (
        f"ffmpeg -video_size 1366x768 -framerate 60 -f x11grab -i :0.0 -c:v libx264 -preset ultrafast -tune zerolatency -f rtsp -rtsp_transport udp rtsp://localhost:8554/live.sdp",
    )
    print("ffmpeg cmd", ffmpeg_cmdline)

    # ffmpeg_cmdline = (
    #     ffmpeg.input(
    #         "pipe:", format="png", s=f"{width}x{height}", r=10, pix_fmt="rgb8"
    #     )
    #     .output("pipe:", format="mjpeg", pix_fmt="yuvj420p")
    #     .compile()
    # )

    process = await asyncio.create_subprocess_shell(
        " ".join(ffmpeg_cmdline),
        # stderr=asyncio.subprocess.PIPE,
        stdout=asyncio.subprocess.PIPE,
        stdin=asyncio.subprocess.PIPE,
    )

    return StreamContext(
        process,
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
    # sock = socket.create_server(("", 9696), reuse_port=True)
    # print("waiting for client")
    # conn, address = sock.accept()
    # print("connected", address)
    # send(conn, OpCode.HELLO)

    # img = ImageGrab.grab()
    # width, height = img.width, img.height
    ctx = await setup_frame_sending(-1, -1)
    try:
        out, err = await ctx.process.communicate()
        print(out, err)
    finally:
        await ctx.process.kill()


def main():
    asyncio.run(amain())


if __name__ == "__main__":
    main()
