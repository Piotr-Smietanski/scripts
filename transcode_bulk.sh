#!/bin/bash

# This script bulk transcodes media files into desired format.
# Output file format is specified by 'target_format' variable.
# Output files are saved into subdirectory named after target output format.
#
# To ensure usability of your PC during transcoding this script also let you
# limit max number of concurrent files being transcoded at any given time
# by changing value of variable 'maxjobs'.
# By default it is set to number of threads of your CPU however
# you may end up running more ffmpeg threads depending on target format
# (most encoders do support multithreading) - because of this jobs are
# given the lowest possible prority.
# If you have fewer than 4 threads - set it to 1
# otherwise leave it as is.
# It could be done automatically but on such underpowered machine it's up to you
# to decide whether you prioritize usability or completion time.
#
# How to use:
# 1. Using shell navigate to folder where you store your input files.
# 2. Run script and as arguments pass file names.
# 3. Wait until you see output line "DONE"
#
# WARNING!
# Output of ffmpeg is squelched and you will not see any errors.
# If you abort the script you may end up with currently encoded
# files being broken or cropped.
# Launching again this script will not overwrite these broken files and
# it's up to you to find and manually delete them in order to fix them.


maxjobs=$(grep "processor" /proc/cpuinfo | wc -l)
#maxjobs=1
reserved_load=5 # target CPU idle time percentage
jobname="ffmpeg"
target_format="mp3"
destdir="$target_format"
tmpdir=/tmp/transcode_bulk.sh
CPU_load_file_full_path=$tmpdir/cpuload.txt

trap 'sigintexit' SIGINT # handle Ctrl+C

sigintexit(){
	# kill load monitor and all running jobs
	kill $(jobs -p) 2> /dev/null
	trap SIGINT
	exit 1
}

if [ $# == 0 ]
then
	echo "ERROR: You must provide at least one input file as command line argument! (can use '*')"
	echo "INFO:  Output $target_format files will be stored in $destdir subdirectory relative to your present working directory."
	exit 1
fi

ffmpeg -version 2>&1> /dev/null
if [ $? != 0 ]
then
	echo "ERROR: Can not launch ffmpeg! Make sure it is installed correctly."
	exit 1
fi

if [ ! -d "$destdir" ]
then
	mkdir "$destdir"
	if [ $? != 0 ]
	then
		echo "ERROR: Destination directory doesn't exist and failed creating it!"
		exit 1
	fi
fi

if [ ! -d "$tmpdir" ]
then
	mkdir "$tmpdir"
	if [ $? != 0 ]
	then
		echo "ERROR: Temporary directory doesn't exist and failed creating it!"
		exit 1
	fi
fi

# start monitoring cpu utilization/idle time
vmstat 1  > $CPU_load_file_full_path &

progress=0
for song_name in "$@"
do
	nice -n 19 ffmpeg -n -i "$song_name" -f $target_format "$destdir/$(echo "$song_name" | sed -r 's/\.(.{3,4})$/.'${target_format}'/')" 2> /dev/null&
	((progress++))

	clear
	echo "Progress: (${progress}/$#)"
	
	while [[ $(ps -Af | grep "$jobname" | wc -l) -gt $maxjobs || $(tail -1 $CPU_load_file_full_path | awk '{print $15}') -lt $reserved_load ]] # > instead of >= because grep is also present on process list
	do
		sleep 1
	done
done

#wait for all ffmpeg jobs to finish
while [[ rem_jobs=$(jobs | grep "Running" | wc -l) -gt 1 ]] #1 job left running is cpu load monitor (vmstat)
do
	echo "Waiting for remaining jobs($rem_jobs) to finish..."
	sleep 1
done

kill $(jobs -p) 2> /dev/null   # kill load monitor
trap SIGINT                    # release ^C trap

echo "DONE"
exit 0
