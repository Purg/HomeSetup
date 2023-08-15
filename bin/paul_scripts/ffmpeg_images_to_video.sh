#!/bin/bash
#
# If nothing else, a record of FFMPEG use that adequately converts a glob of
# image files into an MP4 video
#

INPUT_GLOB="$1"
OUTPUT_FILEPATH="$2"

ffmpeg \
  -threads 4 \
  -framerate 30 \
  -pattern_type glob \
  -i "${INPUT_GLOB}" \
  -c:v h264_nvenc \
  -rc:v vbr_hq \
  -rc-lookahead:v 32 \
  -b:v 4M \
  -maxrate:v 5M \
  -bufsize:v 8M \
  -coder:v cabac \
  -f mp4 \
  "${OUTPUT_FILEPATH}"
