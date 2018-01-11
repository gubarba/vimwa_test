#!/usr/bin/env bash
#make-run.sh
#make sure a process is always running.

export DISPLAY=:0 #needed if you are running a simple gui app.
xrandr_command=$(cat displays.conf)
$xrandr_command
sleep 2
list=`cat vimwa.conf`
rm keep_log.txt
echo -e "$list" >> keep_log.txt
while sleep 5 ; do
	processes=$(ps aux | grep -v grep | grep vlc)
	echo -e "\n checking processes" >> keep_log.txt
	while read -r line
	do
		search=`echo "$line" | grep -Po "(?<=video-title\=).*\b(?=\s--video-x)"`
		echo $search
		is_alive=$( printf "%s\n" "$processes" | grep -c $search )
		if [[ $is_alive -lt 1 ]]; then
    		cvlc --$line &
    		echo -e "\nrunning clvl --$line" >> keep_log.txt
		fi
	done <<<"$list"
done
