#!/bin/zsh
ffmpeg -i 60.mov -vf "fps=10, scale=1280:-2" 10__.mp4
ffmpeg -i 10__.mp4 -filter_complex "[0:v] palettegen" palette.png
ffmpeg -i 10__.mp4 -i palette.png -filter_complex "[0:v][1:v] paletteuse" Presentation.gif
rm -f 10__.mp4
rm -f palette.png