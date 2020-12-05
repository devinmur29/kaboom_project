#!/usr/bin/python

import math
import os
import wave

AUDIO_PATH = "./sounds/"
GRAPHICS_PATH = "./images/"
OUTPUT_FILE = "./packed.hex"

BLOCK_SIZE = 512

audio_assets = []
graphics_assets = []
packed_asset_filenames = []

# pack graphics assets here

for file in os.listdir(AUDIO_PATH):
    try:
        with wave.open(AUDIO_PATH + file, 'rb') as sound:
            packed_asset_filenames.append(file)

            if sound.getparams()[:3] != (1, 1, 44100):
                raise Exception("audio must be mono, 8-bit signed, 44.1kHz")
            
            # read entire file
            sound_bytes = sound.readframes(sound.getnframes())

            audio_assets.append(sound_bytes)

    except wave.Error:
        continue

# TOC format: (4 bytes of START, 4 bytes of END; both must be BLOCK_SIZE aligned)
# graphics TOC goes in 0x000-0x0FF
# audio TOC goes in 0x100-0x1FF

# data starts at 1024 bytes past beginning of file, just because it's easier and allows for extensions
DATA_START_ADDRESS = 1024

graphics_toc = []
audio_toc = []

with open(OUTPUT_FILE, 'wb') as f:
    head_addr = DATA_START_ADDRESS

    def write_with_padding(data):
        bytes_required = math.ceil(len(data) / 512) * 512

        f.write(data)
        f.write(bytes([0]) * (bytes_required - len(data)))

        return bytes_required

    f.seek(DATA_START_ADDRESS)

    # write graphics here

    for asset in audio_assets:
        bytes_written = write_with_padding(asset)

        audio_toc.append((head_addr, head_addr + bytes_written))
        head_addr += bytes_written

    f.seek(0)

    # write graphics here

    # audio starts in the middle of the first block
    f.seek(256)

    for start, end in audio_toc:
        f.write(start.to_bytes(4, 'little'))
        f.write(end.to_bytes(4, 'little'))

print(f'packed {len(packed_asset_filenames)} files!')
print(*packed_asset_filenames, sep="\n")