# vrr

vr (screen) repeater

takes your screen and repeats it into vr

everything is Work In Progress status, and is tailored for my machine (hardcoded `h264_vaapi`,
for example. could have codec compatibility code in the future /shrug)

is not planned to be a full app, be distributed on stores, etc. its for me.

its not even ready for build. i'm leaving the build instructions for myself,
if i forget.

## architecture

- your machine runs two pieces of code
  - vrr server (TODO: rename to agent? streamer?)
  - https://github.com/aler9/rtsp-simple-server
- your headset (which can be still your machine) runs the vrr client
  - a lovr app that uses https://github.com/lun-4/lovr-rtsp to connect to your machine

## setup (server-side)

TODO actually make urls configurable. this doesn't work

- python 3.10
- https://python-poetry.org/
- https://github.com/aler9/rtsp-simple-server

```sh
git clone ...
cd vrr/server
poetry install
poetry run src/main.py
```

## setup (client-side)

BROKEN BUILD AHEAD: NEEDS MORE CARE (like how to fetch the quest 2 3d models,
or getting penlight into this repo. all is cursed, will not work on anything).

- https://ziglang.org
- https://github.com/lun-4/lovr-rtsp

### linux x86

```sh
cd vrr/client
# build and copy rtsp.so to this folder, as directed in the lovr-rtsp README
path/to/lovr .
```

### quest 2

(will not work on any machine other than mine. do not attempt. will not provide
support to others attempting to do so at the moment. maybe in the future)

```sh
# on the build process for quest (https://lovr.org/docs/Compiling),
# set the path to this folder in the relevant cmake command. build your apk
# while also following lovr-rtsp's process, and you'll be done.
cd vrr/client
```
