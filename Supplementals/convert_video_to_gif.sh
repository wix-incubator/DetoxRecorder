#!/bin/zsh
ffmpeg -i 60.mov -vf "fps=10, scale=1280:-2" 10__.mov
ffmpeg -i 10__.mov -filter_complex "[0:v] palettegen" palette.png
ffmpeg -i 10__.mov -i palette.png -filter_complex "[0:v][1:v] paletteuse" Presentation.gif
rm -f 10__.mov
rm -f palette.png

ffmpeg -i Green.mov -filter_complex "[0:v] palettegen" palette.png
ffmpeg -i Green.mov -i palette.png -filter_complex "[0:v][1:v] paletteuse" Green.gif
rm -f Green.mov
rm -f palette.png

ffmpeg -i Orange.mov -filter_complex "[0:v] palettegen" palette.png
ffmpeg -i Orange.mov -i palette.png -filter_complex "[0:v][1:v] paletteuse" Orange.gif
rm -f Orange.mov
rm -f palette.png

ffmpeg -i Yellow.mov -filter_complex "[0:v] palettegen" palette.png
ffmpeg -i Yellow.mov -i palette.png -filter_complex "[0:v][1:v] paletteuse" Yellow.gif
rm -f Yellow.mov
rm -f palette.png

ffmpeg -i Red.mov -filter_complex "[0:v] palettegen" palette.png
ffmpeg -i Red.mov -i palette.png -filter_complex "[0:v][1:v] paletteuse" Red.gif
rm -f Red.mov
rm -f palette.png