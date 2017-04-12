# raw avi -- will be HUGE
#nice -19 mencoder -nosound mf://*.jpg -mf fps=15:type=jpg -ovc copy -o time_lapse-test.avi
# encoded with mpeg4 -- much nicer file size.  Adjust bitrate to adjust quality up or down
nice -19 mencoder -nosound mf://*_tovid.jpg -mf fps=15 -ovc lavc -lavcopts vcodec=msmpeg4v2:vbitrate=4800 -o time_lapse-test.avi
