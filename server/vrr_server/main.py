import socket
import asyncio
import ffmpeg
from dataclasses import dataclass
from typing import List, Any


class OpCode:
    HELLO = 1


def send(conn, opcode):
    conn.send(f"{opcode:04d}".encode("utf-8"))


@dataclass
class StreamContext:
    processes: List[Any]
    width: int
    height: int
    tick: int = 0


# TODO find proper width and height of monitors separately
async def setup_frame_sending(width, height):
    # ffmpeg_params = "-vaapi_device /dev/dri/renderD128 -vf 'format=nv12,hwupload' -c:v h264_vaapi -rc_mode CQP -qp 20 -pix_fmt yuv444p10le -preset fast -tune zerolatency -crf 18 -minrate 100M -maxrate 200M -bufsize 200M"
    ffmpeg_params = "-vaapi_device /dev/dri/renderD128 -vf 'format=nv12,hwupload' -c:v h264_vaapi -rc_mode CQP -qp 30 -coder cabac"
    # ffmpeg_params = "-vaapi_device /dev/dri/renderD128 -vf 'format=nv12,hwupload' -c:v h264_vaapi -tune zerolatency -preset medium -profile main -coder cabac"
    ffmpeg_cmdlines = (
        f"ffmpeg -video_size 1366x768 -framerate 30 -f x11grab -i :0.0 {ffmpeg_params} -f rtsp -rtsp_transport udp rtsp://localhost:8554/screen_1.sdp",
        # f"ffmpeg -video_size 1080x1920 -framerate 30 -f x11grab -i :0.0+1366,0 {ffmpeg_params} -f rtsp -rtsp_transport udp rtsp://localhost:8554/screen_2.sdp",
    )

    print("ffmpeg cmd", ffmpeg_cmdlines)

    processes = []

    for cmdline in ffmpeg_cmdlines:
        processes.append(await asyncio.create_subprocess_shell(cmdline))

    return StreamContext(processes, width, height)


async def amain():
    ctx = await setup_frame_sending(-1, -1)
    try:
        tasks = []
        for proc in ctx.processes:
            tasks.append(asyncio.create_task(proc.wait()))
        await asyncio.wait(tasks)
    finally:
        for proc in ctx.processes:
            await proc.kill()


def main():
    asyncio.run(amain())


if __name__ == "__main__":
    main()
