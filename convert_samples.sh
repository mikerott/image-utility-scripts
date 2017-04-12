list=`ls IMG_*`
for line in ${list}
do
	filename=`echo ${line} | cut -f1 -d'.'`
	# widescreen:  example starting with 1600x1200, crop to bottom 800px scale to 720 height, preserving aspect
	nice -19 convert ${line} -crop 1600x900+0+0 -scale x720 -unsharp 0.3x2+1.5 -quality 80 ${filename}_tovid.jpg
	#convert ${line} -scale x720 -unsharp 0.3x2+1.5 -quality 80 ${filename}_tovid.jpg
done
