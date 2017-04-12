#!/bin/bash

# This is a work in progress.
# prompt the end user for input, and validate it until they succeed:
# http://alvinalexander.com/linux-unix/shell-script-how-prompt-read-user-input-bash

me=`basename "$0"`

function scaled_timelapse() {
    command -v nice >/dev/null 2>&1 || { echo >&2 "'nice' is not installed; aborting."; exit 1; }
    command -v mencoder >/dev/null 2>&1 || { echo >&2 "'mencoder' is not installed; aborting."; exit 1; }

    re='^10|15|30|60+$'
    if ! [[ $1 =~ $re ]] ; then
       echo "error: First argument must be a framerate set to 10, 15, 30, or 60" >&2; exit 1
    fi

    re='^[a-zA-Z0-9]+$'
    if ! [[ $2 =~ $re ]] ; then
       echo "error: Second argument must be the desired filename consisting of at least one alphanumeric char" >&2; exit 1
    fi

    re='^[0-9]+$'
    if ! [[ $3 =~ $re ]] ; then
       echo "error: Third argument is the desired scaled maximum width and must be between 320 and 1920" >&2; exit 1
    fi

    if [ $3 -ge 1921 ] || [ $3 -le 319 ] ; then
       echo "error: Third argument is the desired scaled maximum width and must be between 320 and 1920" >&2; exit 1
    fi

    if ! [[ $4 =~ $re ]] ; then
       echo "error: Fourth argument is the desired scaled maximum height and must be between 240 and 1080" >&2; exit 1
    fi

    if [ $4 -ge 1081 ] || [ $4 -le 239 ] ; then
       echo "error: Fourth argument is the desired scaled maximum height and must be between 240 and 1080" >&2; exit 1
    fi

    framerate="$1"
    filename="$2"
    resolution_width="$3"
    resolution_height="$4"
    nice -19 mencoder -nosound -ovc lavc -lavcopts \
        vcodec=mpeg4:mbd=2:trell:autoaspect:vqscale=3 \
        -vf scale=$resolution_width:$resolution_height -mf type=png:fps=$framerate \
        mf://*.png -o $filename.mp4
}

function timelapse() {
    command -v nice >/dev/null 2>&1 || { echo >&2 "'nice' is not installed; aborting."; exit 1; }
    command -v mencoder >/dev/null 2>&1 || { echo >&2 "'mencoder' is not installed; aborting."; exit 1; }

    re='^10|15|30|60+$'
    if ! [[ $1 =~ $re ]] ; then
       echo "error: First argument must be a framerate set to 10, 15, 30, or 60" >&2; exit 1
    fi

    re='^[a-zA-Z0-9]+$'
    if ! [[ $2 =~ $re ]] ; then
       echo "error: Second argument must be the desired filename consisting of at least one alphanumeric char" >&2; exit 1
    fi

    framerate="$1"
    filename="$2"
    nice -19 mencoder -nosound -ovc lavc -lavcopts \
        vcodec=msmpeg4v2 \
        -mf type=png:fps=$framerate \
        mf://*.png -o $filename.mp4
}

function superview() {
    command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "'ffmpeg' is not installed; aborting."; exit 1; }

    for i in *.mp4;
        do name=`echo $i | cut -d'.' -f1`+S;
        echo $name;
        ffmpeg -i $i -sameq -vcodec mpeg4 -acodec ac3 -aspect 16:9 -strict experimental $name.mp4
    done
}

function fisheye() {
    command -v mogrify >/dev/null 2>&1 || { echo >&2 "'mogrify' is not installed; aborting."; exit 1; }
    # Olympus 8mm body cap lens on Pen E-PL5
    # Data from http://lensfun.sourceforge.net/, instructions from http://www.imagemagick.org/Usage/lens/#scratch,
    # k1 parameter in the lensfun database goes into 'b' param, according to: http://www.imagemagick.org/discourse-server/viewtopic.php?t=28592#p127010
    mogrify -distort barrel "0 -0.03111 0" *.png
}

function convert(){
    command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "'ffmpeg' is not installed; aborting."; exit 1; }

    for i in *.mp4;
        do name=`echo $i | cut -d'.' -f1`;
        echo $name;
        ffmpeg -i $i -sameq -vcodec mpeg4 $name.mov;
    done
}

function resize() {
    command -v nice >/dev/null 2>&1 || { echo >&2 "'nice' is not installed; aborting."; exit 1; }
    command -v convert >/dev/null 2>&1 || { echo >&2 "'convert' is not installed; aborting."; exit 1; }

    list=`ls *.png`
    for line in ${list}
    do
  	    filename=`echo ${line} | cut -f1 -d'.'`
  	    # widescreen:  example starting with 1600x1200, crop to bottom 800px scale to 720 height, preserving aspect
  	    nice -19 convert ${line} -crop 1600x900+0+0 -scale x720 -unsharp 0.3x2+1.5 -quality 80 ${filename}_tovid.png
  	    #convert ${line} -scale x720 -unsharp 0.3x2+1.5 -quality 80 ${filename}_tovid.png
    done
}

function trim(){
    command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "'ffmpeg' is not installed; aborting."; exit 1; }

    ffmpeg -i $1 -ss $3 -t $4 -sameq -vcodec libx264 $2
}

function help() {
    me=`basename "$0"`
    printf "Create Time Lapse Script\n"
    printf "Usage:\n"
    printf "\n"
    printf "$me timelapse [fps] [outfilename]\n"
    printf "Makes a timelapse with all images (*.png) in the current folder.\n"
    printf "Example: $me timelapse 30 timelapse.mp4\n"
    printf "\n"
    printf "$me scaled_timelapse [fps] [outfilename] [res width] [res height]\n"
    printf "Makes a timelapse with all images (*.png) in the current folder.\n"
    printf "Example: $me timelapse 30 scaledtimelapse.mp4 1920 1080\n"
    printf "\n"
    printf "$me superview\n"
    printf "Applies SuperView to all videos (*.mp4) in the current dir\n"
    printf "\n"
    printf "$me fisheye\n"
    printf "Fixes barrel distortion to all images (*.png) in the current folder\n"
    printf "\n"
    printf "$me convert\n"
    printf "Converts all MP4 (*.mp4) videos to MPEG4 MOV videos for easy editing\n"
    printf "\n"
    printf "$me resize\n"
    printf "Crops, resizes, and sharpens all images (*.png) in the current folder to the hard-coded values, copying the output to new file suffixed with _tovid\n"
    printf "\n"
    printf "$me trim [input video] [output video] [HH:MM:SS start] [HH:MM:SS stop]\n"
    printf "Trims a video, use this to trim a slow motion video!\n"
    printf "Example: $me trim original.mp4 trimmed.mp4 00:05:04 00:07:43\n"
    printf "\n"
}

echo "Create Time Lapse Script"
echo "To see a list of commands and syntax available run: $me help"
$@
