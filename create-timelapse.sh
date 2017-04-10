#!/bin/bash

me=`basename "$0"`

function timelapse() {
    framerate="$1"
    filename="$2"
    resolution_width="$3"
    resolution_height="$4"
    ls -1tr > timelapse_list.txt
    mencoder -nosound -ovc lavc -lavcopts \
        vcodec=mpeg4:mbd=2:trell:autoaspect:vqscale=3 \
        -vf scale=$resolution_width:$resolution_height -mf type=jpeg:fps=$framerate \
        mf://@timelapse_list.txt -o $filename
}

function superview() {
    for i in *.MP4;
        do name=`echo $i | cut -d'.' -f1`+S;
        echo $name;
        ffmpeg -i $i -sameq -vcodec mpeg4 -acodec ac3 -aspect 16:9 -strict experimental $name.MP4
    done
}

function fisheye(){
    mogrify -distort barrel "0 0 -0.3" *.JPG
}

function convert(){
for i in *.MP4;
    do name=`echo $i | cut -d'.' -f1`;
    echo $name;
    ffmpeg -i $i -sameq -vcodec mpeg4 $name.mov;
done
}

function trim(){
    ffmpeg -i $1 -ss $3 -t $4 -sameq -vcodec libx264 $2
}

function help() {
    me=`basename "$0"`
    printf "Create Time Lapse Script\nUsage:\n\n- $me timelapse [fps] [outfilename] [res width] [res height]\nMakes a timelapse with images in the current folder.\nExample: $me timelapse 30 my-timelapse.mp4 1920 1080\n\n- $me superview\nApplies SuperView to all videos in the current dir\n\n- $me fisheye\nFixes barrel distortion to all images in the current folder\n\n- $me convert\nConverts all MP4 videos to MPEG4 MOV videos for easy editing\n\n- $me trim [input video] [output video] [HH:MM:SS start] [HH:MM:SS stop]\nTrims a video, use this to trim a slow motion video!\nExample: $me trim GOPR0553.MP4 Trimmed.mp4 00:05:04 00:07:43\n\n"
}

echo "Create Time Lapse Script"
echo "To see a list of commands and syntax available run: $me help"
echo "Checking dependencies..."
hash ffmpeg 2> /dev/null || { echo >&2 "ffmpeg ..... Not installed!";}
hash mogrify 2> /dev/null || { echo >&2 "mogrify ..... Not installed!";}
hash mencoder 2> /dev/null || { echo >&2 "mencoder ..... Not installed!";}
$@
