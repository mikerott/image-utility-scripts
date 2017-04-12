#!/bin/bash
#
###############################################################################
# Photo sorting program by Mike Beach
# For usage and instructions, and to leave feedback, see
# http://mikebeach.org/?p=4729
#
# Last update: 20-May-2013
###############################################################################
#
# The following are the only settings you should need to change:
#
# JPEG_TO_JPG: The following option is here for personal preference. If TRUE, this will
# cause .jpg to be used instead of .jpeg as the file extension. If FALSE (or any other
# value) .jpeg is used instead. This is only used if USE_FILE_EXT is TRUE and used.
#
JPEG_TO_JPG=FALSE
#
#
# The following is an array of filetypes that we intend to locate using find.
# Any imagemagick-supported filetype can be used, but EXIF data is only present in
# jpeg and tiff. Script will optionally use the last-modified time for sorting (see above)
# Extensions are matched case-insensitive. *.jpg is treated the same as *.JPG, etc.
# Can handle any file type; not just EXIF-enabled file types. See USE_LMDATE above.
#
FILETYPES=("*.jpg" "*.jpeg" "*.png" "*.tif" "*.tiff" "*.gif" "*.xcf" "*.cr2" "*.orf" "*.dng" "*.nef")
#
# Optional: Prefix of new top-level directory to move sorted photos to.
# if you use MOVETO, it MUST have a trailing slash! Can be a relative pathspec, but an
# absolute pathspec is recommended.
# FIXME: Gracefully handle unavailable destinations, non-trailing slash, etc.
#
MOVETO="/data/pictures/raw_SORTED/"
#
###############################################################################
# End of settings. If you feel the need to modify anything below here, please share
# your edits at the URL above so that improvements can be made to the script. Thanks!
#
#
# Assume find, grep, stat, awk, sed, tr, etc.. are already here, valid, and working.
# This may be an issue for environments which use gawk instead of awk, etc.
# Please report your environment and adjustments at the URL above.
#
###############################################################################
# Nested execution (action) call
# This is invoked when the programs calls itself with
# $1 = "doAction"
# $2 = <file to handle>
# This is NOT expected to be run by the user in this matter, but can be for single image
# sorting. Minor output issue when run in this manner. Related to find -print0 below.
#
# Are we supposed to run an action? If not, skip this entire section.
if [[ "$1" == "doAction" && "$2" != "" ]]; then
 # Check for EXIF and process it
 echo -n ": Checking EXIF on $2... "

 ORIGDIRNAME=`dirname "$2"`
 FILENAMENOEXT=`basename "$2" | awk -F '.' '{print $1}'`

 DATETIME=`exiftool "$2" | grep "Date/Time Original *: " | awk -F ':|[ ]+|: ' '{print $3, $4, $5, $6, $7, $8, $9}'`
 if [[ "$DATETIME" == "" ]]; then
   echo "not found."
   echo " Moving to ./noexif/"
   mkdir -p "${MOVETO}noexif" && mv -f "$ORIGDIRNAME/$FILENAMENOEXT."* "${MOVETO}noexif" --backup=numbered
   exit
 else
   echo "found: $DATETIME"
 fi;
 # The previous iteration of this script had a major bug which involved handling the
 # renaming of the file when using TS_AS_FILENAME. The following sections have been
 # rewritten to handle the action correctly as well as fix previously mangled filenames.
 # FIXME: Collisions are not handled.
 #
 EDATE=`echo $DATETIME | awk -F ' ' '{print $1":"$2":"$3}'`
 # DIRectory NAME for the file move
 # sed issue for y command fix provided by thomas
 DIRNAME=`echo $EDATE | sed y-:-/- | sed 's/\<[0-9]\>/0&/'`
 echo -n " Moving to ${MOVETO}${DIRNAME} ... "
 echo ""
 mkdir -p "${MOVETO}${DIRNAME}" && mv -f "$ORIGDIRNAME/$FILENAMENOEXT."* "${MOVETO}${DIRNAME}" --backup=numbered
 exit
fi;
#
###############################################################################
# Scanning (find) loop
# This is the normal loop that is run when the program is executed by the user.
# This runs find for the recursive searching, then find invokes this program with the two
# parameters required to trigger the above loop to do the heavy lifting of the sorting.
# Could probably be optimized into a function instead, but I don't think there's an
# advantage performance-wise. Suggestions are welcome at the URL at the top.
for x in "${FILETYPES[@]}"; do
  echo "Scanning for $x..."
  # FIXME: Eliminate problems with unusual characters in filenames.
  # Currently the exec call will fail and they will be skipped.
  find . -iname "$x" -print0 -exec sh -c "$0 doAction '{}'" \;
  echo "... end of $x"
done;
# clean up empty directories. Find can do this easily.
# Remove Thumbs.db first because of thumbnail caching
echo -n "Removing Thumbs.db files ... "
find . -name Thumbs.db -delete
echo "done."
echo -n "Cleaning up empty directories ... "
find . -empty -delete
echo "done."
