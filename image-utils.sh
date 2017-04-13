#!/bin/bash

# This is a work in progress.
#
# If someday I want to change this script to prompt the user for input and validate it until they succeed:
# http://alvinalexander.com/linux-unix/shell-script-how-prompt-read-user-input-bash

me=`basename "$0"`

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

    re='^.*(png|jpg)+$'
    if ! [[ $3 =~ $re ]] ; then
       echo "error: Third argument is the suffix of files the script should use, like \".png\"" >&2; exit 1
    fi

    framerate="$1"
    filename="$2"
    files="*$3"
    type=`echo $3 | rev | cut -d'.' -f1 | rev`
    type=${type/jpg/jpeg}
    echo "I'm creating your movie!"
    nice -19 mencoder -nosound -ovc lavc -lavcopts \
        vcodec=mpeg4:mbd=2:trell \
        -mf type=$type:fps=$framerate \
        mf://$files -o $filename.mp4
    echo "Done."
}

function superview() {
    command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "'ffmpeg' is not installed; aborting."; exit 1; }

    list=`ls *.mp4`
    for line in ${list}
    do
        filename=`echo ${line} | rev | cut -f 2- -d'.' | rev`
        filename=${filename}_superview;
        echo "Making superview of $filename."
        ffmpeg -i ${line} -sameq -vcodec mpeg4 -acodec ac3 -aspect 16:9 -strict experimental $filename.mp4
    done
    echo "Done."
}

function fisheye() {
    command -v nice >/dev/null 2>&1 || { echo >&2 "'nice' is not installed; aborting."; exit 1; }
    command -v convert >/dev/null 2>&1 || { echo >&2 "'convert' is not installed; aborting."; exit 1; }

    re='^.*(png|jpg)+$'
    if ! [[ $1 =~ $re ]] ; then
       echo "error: First argument is the suffix of files the script should use, like \".png\"" >&2; exit 1
    fi

    list=`ls *$1`
    for line in ${list}
    do
        echo "Fixing distortion on $line."
        filename=`echo ${line} | rev | cut -f 2- -d'.' | rev`
        # Olympus 8mm body cap lens on Pen E-PL5
        # Data from http://lensfun.sourceforge.net/, instructions from http://www.imagemagick.org/Usage/lens/#scratch,
        # k1 parameter in the lensfun database goes into 'b' param, according to: http://www.imagemagick.org/discourse-server/viewtopic.php?t=28592#p127010
        nice -19 convert ${line} -distort barrel "0 -0.03111 0" -quality 80 ${filename}.barrel.png
        # but that doesn't seem to be working, so maybe I need to measure it like the "Data from" line above.
        # Also probably helpful:  http://m43photo.blogspot.de/2014/07/olympus-9mm-fisheye-vs-rectilinear.html
    done
    echo "Done."
}

function convert() {
    command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "'ffmpeg' is not installed; aborting."; exit 1; }

    list=`ls *.mp4`
    for line in ${list}
    do
        echo "Making a .mov from $line."
        filename=`echo ${line} | rev | cut -f 2- -d'.' | rev`;
        ffmpeg -i ${line} -sameq -vcodec mpeg4 $filename.mov;
    done
    echo "Done."
}

function scale() {
    command -v nice >/dev/null 2>&1 || { echo >&2 "'nice' is not installed; aborting."; exit 1; }
    command -v convert >/dev/null 2>&1 || { echo >&2 "'convert' is not installed; aborting."; exit 1; }

    re='^.*(png|jpg)+$'
    if ! [[ $1 =~ $re ]] ; then
       echo "error: First argument is the suffix of files the script should use, like \".png\"" >&2; exit 1
    fi

    re='^[0-9]+$'
    if ! [[ $2 =~ $re ]] ; then
       echo "error: Second argument is the desired scaled maximum width and must be between 800 and 1920" >&2; exit 1
    fi

    if [ $2 -gt 1920 ] || [ $2 -lt 800 ] ; then
       echo "error: Second argument is the desired scaled maximum width and must be between 800 and 1920" >&2; exit 1
    fi

    if ! [[ $3 =~ $re ]] ; then
       echo "error: Third argument is the desired scaled maximum width and must be between 600 and 1200" >&2; exit 1
    fi

    if [ $3 -gt 1200 ] || [ $3 -lt 600 ] ; then
       echo "error: Third argument is the desired scaled maximum width and must be between 600 and 1200" >&2; exit 1
    fi

    w="$2"
    h="$3"
    list=`ls *$1`

    mkdir ${w}x${h}
    for line in ${list}
    do
        echo "Scaling $line."
  	    filename=`echo ${line} | rev | cut -f 2- -d'.' | rev`
        # https://redskiesatnight.com/2005/04/06/sharpening-using-image-magick/
  	    nice -19 convert ${line} -scale ${w}x${h} -unsharp 2x1+1.5+0.1 -quality 80 ${w}x${h}/${filename}.scaled.png
    done
    echo "Done."
}

function thumbs() {
    command -v nice >/dev/null 2>&1 || { echo >&2 "'nice' is not installed; aborting."; exit 1; }
    command -v convert >/dev/null 2>&1 || { echo >&2 "'convert' is not installed; aborting."; exit 1; }

    re='^.*(png|jpg)+$'
    if ! [[ $1 =~ $re ]] ; then
       echo "error: First argument is the suffix of files the script should use, like \".png\"" >&2; exit 1
    fi

    re='^[0-9]+$'
    if ! [[ $2 =~ $re ]] ; then
       echo "error: Second argument is the desired scaled maximum width and must be between 50 and 200" >&2; exit 1
    fi

    if [ $2 -gt 200 ] || [ $2 -lt 50 ] ; then
       echo "error: Second argument is the desired scaled maximum width and must be between 50 and 200" >&2; exit 1
    fi

    if ! [[ $3 =~ $re ]] ; then
       echo "error: Third argument is the desired scaled maximum width and must be between 50 and 200" >&2; exit 1
    fi

    if [ $3 -gt 200 ] || [ $3 -lt 50 ] ; then
       echo "error: Third argument is the desired scaled maximum width and must be between 50 and 200" >&2; exit 1
    fi

    w="$2"
    h="$3"
    list=`ls *$1`

    mkdir ${w}x${h}
    for line in ${list}
    do
        echo "Thumbing $line."
  	    filename=`echo ${line} | rev | cut -f 2- -d'.' | rev`
        # https://redskiesatnight.com/2005/04/06/sharpening-using-image-magick/
  	    nice -19 convert ${line} -scale ${w}x${h} -unsharp 1x0.5+2+0 -quality 80 ${w}x${h}/${filename}.thumb.png
    done
}

function help() {
    me=`basename "$0"`
    printf "Image Utilities Script\n"
    printf "Usage:\n"
    printf "\n"
    printf "$me timelapse [fps] [outfilename] [sourcefiles]\n"
    printf "Makes a timelapse with all images (png or jpg) in the current folder.\n"
    printf "Example: $me timelapse 30 timelapse.mp4 \".scaled.png\"\n"
    printf "\n"
    printf "$me superview\n"
    printf "Applies SuperView to all videos (*.mp4) in the current dir\n"
    printf "\n"
    printf "$me fisheye\n"
    printf "Fixes barrel distortion (Olympus micro 4/3 body cap lens) to all images (png or jpg) in the current folder, copying the output to new file suffixed with .barrel\n"
    printf "Example: $me fisheye \".png\"\n"
    printf "\n"
    printf "$me convert\n"
    printf "Converts all MP4 (*.mp4) videos to MPEG4 MOV videos for easy editing\n"
    printf "Example: $me convert\n"
    printf "\n"
    printf "$me scale\n"
    printf "Scales and sharpens all images (png or jpg) in the current folder to the specified values, copying the output to new file suffixed with .scaled\n"
    printf "Example: $me scale 800 600 \".png\"\n"
    printf "\n"
    printf "$me thumbs\n"
    printf "Scales and sharpens all images (png or jpg) in the current folder to the specified values, copying the output to new file suffixed with .thumb\n"
    printf "Example: $me thumbs 150 100 \".png\"\n"
    printf "\n"
}

echo "Create Time Lapse Script"
echo "To see a list of commands and syntax available run: $me help"
$@
