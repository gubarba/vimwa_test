#!/usr/bin/env bash

set_displays(){
	clear
	echo -e "This will set up your connected displays, if some display won't show here, make sure it's connected and rerun configure "
	xrandr_command="xrandr"
	local displays="$(xrandr | grep -i connected )"
	local display_number=0
	OLDIFS="$IFS"
	IFS=$'\n' # bash specific
	for display in $displays; do
		if [ `echo $display | grep -i disconnected` ] ; then
			use=NO
		fi
		echo -e "\nDisplay: $display"
		local display_number=$(($display_number + 1))
		local display_name=$(echo $display | awk '{print $1}')
		local aux=$(echo $display | grep -oP "\d+x\d+\+\d+\+\d+")
		local display_width=$(echo $aux | awk -F + '{ print $1}' | awk -F x '{print $1}')
		local display_height=$(echo $aux | awk -F + '{ print $1}' | awk -F x '{print $2}')
		local width_origin=$(echo $aux | awk -F + '{ print $2}')
		local height_origin=$(echo $aux | awk -F + '{ print $3}')
		# echo -e "name=$display_name width=$display_width display_height=$display_height width_origin=$width_origin height_origin=$height_origin "
		# echo -e "Configuring display number $display_number ($display_name)"
		# xterm -geometry 100x50+$width_origin+$height_origin	-e 'bash ./vimwa_identify.sh'
		# xfce4-terminal --command="./identify.sh $display_number"
		until [[ $use =~ ^(y|Y|YES|yes|n|N|NO|no)$ ]]; do
			read -n1 -s -p "Do you wish to use display number $display_number ($display_name) ? (y/n): " use
			sleep 0.5
		done
		if [[ $use =~ ^(y|Y|YES|yes)$ ]]; then
			xrandr_command="$xrandr_command --output $display_name --mode ${display_width}x$display_height --pos ${width_origin}x$height_origin --rotate normal"
		else
			xrandr_command="$xrandr_command --output $display_name --off"
		fi
		use="reset"
	done
	IFS="$OLDIFS"
	echo -e "\n\n$xrandr_command"
	# sed -i -e '/xrandr_command=/ s/=.*/=$xrandr_command/' ./vimwa.conf
	echo $xrandr_command > displays.conf
	# sleep 5 
	# cat vimwa.conf
}

set_resources(){
	rm vimwa.conf
	xrandr_command=$(cat displays.conf)
	$xrandr_command
	sleep 3
	local displays="$(xrandr | grep -i connected | grep -v disconnected)"
	local display_number=0
	OLDIFS="$IFS"
	IFS=$'\n' # bash specific
	for display in $displays; do
		# echo $display
		local display_number=$(($display_number + 1))
		local display_name=$(echo $display | awk '{print $1}')
		local aux=$(echo $display | grep -oP "\d+x\d+\+\d+\+\d+")
		local display_width=$(echo $aux | awk -F + '{ print $1}' | awk -F x '{print $1}')
		local display_height=$(echo $aux | awk -F + '{ print $1}' | awk -F x '{print $2}')
		local width_origin=$(echo $aux | awk -F + '{ print $2}')
		local height_origin=$(echo $aux | awk -F + '{ print $3}')
		if [ ! `cat displays.conf | grep "output $display_name --off" ` ]; then
			echo -e "Configuring display number $display_number ($display_name)"

			# xterm -geometry 100x50+$width_origin+$height_origin	-e 'bash ./vimwa_identify.sh $display_number'
			# xfce4-terminal --command="./identify.sh $display_number $display_name"
			echo -e ""
			echo -e "Alright! Now, about display number $display_number ($display_name)..."
			input_configs
			local max_width=$(($display_width/$columns))
			local max_height=$(($display_height/$rows))

			local column=0
			local row=0

			for URL in $(cat $file_path); do
				if (("$column" < "$columns")); then
					print_command $URL $row $column $width_origin $height_origin $max_width $max_height
					column=$(($column + 1))
				else
					column=0
					row=$(($row + 1))
					if (("$row" < "$rows")) ; then
						print_command $URL $row $column $width_origin $height_origin $max_width $max_height
						column=$(($column + 1))
					else
						printf "\n Exceeded maximum number of resources for this Grid number, maybe increase the columns and rows numbers numbers???"
						break
					fi
				fi
			done
			sleep 3
			clear
		fi
	done
	IFS="$OLDIFS"

}

input_configs () {
	local state=0
	while [  $state != 3 ]; do
		if [ $state = "0" ]; then
            read -p "Type in the number of COLUMNS and press enter: " columns
			columns=${columns:-1} # this sets the variable to the default value if not defined
			if [[ -n ${columns//[0-9]/} ]]; then
			    echo "Only numbers allowed!"
			else
				state=1
			fi
        elif [ $state = "1" ]; then
            read -p "Type in the number of ROWS and press enter: " rows
			rows=${rows:-1}
			if [[ -n ${rows//[0-9]/} ]]; then
			    echo "Only numbers allowed!"
			else
				state=2
			fi
        elif [ $state = "2" ]; then
            read -p "Type in the number location of the file to read (if not informed defaults to ./urls.txt ): " file_path
			file_path=${file_path:-"./urls.txt"}
			if [ -e $file_path ]; then
				if [ ! -r $file_path ]; then
				    echo "Couldn't read file, please check for permissions."
				else
					state=3
				fi
			else
				echo "File not found!"
			fi
        fi
        if [[ $columns = "q" || $rows = "q" || $file_path = "q" ]]; then
        	exit
        fi 
	done
}

print_command () {
	local URL=$1
	local row=$2
	local column=$3
	local x_axis_offset=$4
	local y_axis_offset=$5
	local max_width=$6
	local max_height=$7
	printf "Adding resource $URL  Row $row Column $column  \n"
	let "VIDEO_X=$x_axis_offset+$column*$max_width"
	let "VIDEO_Y=$y_axis_offset+0+$row*$max_height"
	# local probe=$(avprobe -show_streams  ${1} 2>/dev/null | grep -oP "((?<=^width=).*)|((?<=^height=).*)");
	probe=$(avprobe -show_streams  ${URL} 2>/dev/null);
	while [[ `echo "$probe" | grep -i "invalid data found when processing input" 2> /dev/null ` || "$probe" = "" ]]; do
		probe=$(avprobe -show_streams  ${URL} 2>/dev/null);
		echo "trying again"
		echo -e ""
	done
	probe=$(echo "$probe" | grep -oP "((?<=^width=).*)|((?<=^height=).*)");
	local video_width=$(echo $probe | awk '{print $1}')
	local video_height=$(echo $probe | awk '{print $2}')
	# # local video_width=8000
	# # local video_height=601 
	local video_zoom=0
	local temp_width=$(echo "scale=3; ${max_width} / ${video_width}" | bc)
	local temp_height=$(echo "scale=3; ${max_height} / ${video_height}" | bc)
	##### Verifica qual das dimensões tem o menor zoom 
	if [[ $(echo "scale=3; ${temp_width} < ${temp_height}" | bc) -eq 1 ]]; then
		video_zoom=$(echo "scale=3; ${max_width} / ${video_width}" | bc )
	else
		video_zoom=$(echo "scale=3; ${max_height} / ${video_height}" | bc)
	fi
	#prependa o 0 caso o número venha no formato .123
	if [[ $video_zoom =~ ^\. ]]; then
		video_zoom="0$video_zoom"
	fi
	#printa a linha com url, posicao no eixo x, no eixo y e zoom
	printf "loop --aout=none --drop-late-frames --skip-frames --network-caching=1000 --no-overlay --no-embedded-video --video-title=$URL --video-x=$VIDEO_X --video-y=$VIDEO_Y --zoom=$video_zoom $1\n" >> vimwa.conf
}

menu(){
	while [ "$option" != "q" ]; do
		clear
		echo -e ""
		if [ "$option" != "" ] ; then echo -e "Invalid option!" ; fi
		echo -e "This is vimwa configuration type in your option"
		echo -e "1 )          Set (enable/disable) displays"
		echo -e "2 )          Set Grid and Video resources"
		echo -e ""
		echo -e "q )          Quit"

		read -n1 -p "Type in your option: " option
		if [ $option = "1" ]; then
			set_displays            
            option=""
        elif [ $option = "2" ]; then
        	set_resources
            option=""
        # elif [ $state = "2" ]; then

        # 	option=""
        # else    
        fi
        
	done
}

menu
echo "Exiting..."
sleep 2
# until [[ $use =~ ^(y|Y|YES|yes|n|N|NO|no)$ ]]; do
# 			local read -p "Do you wish to use display number $display_number ($display_name) ? (y/n): " use
# 			sleep 0.5
# 		done
# 		if [[ $use =~ ^(y|Y|YES|yes)$ ]]; then
# 			xrandr_command="$xrandr_command --output $display_name --mode ${display_width}x$display_height --pos ${width_origin}x$height_origin --rotate normal"
# 		else
# 			xrandr_command="$xrandr_command --output $display_name --off"
# 		fi
# 		use="reset"


# display_width=$(xrandr |grep -i current |awk '{print $8,$10}' | tr -d ,)
# display_height=$(echo $display_width | awk '{print $2}')
# display_width=$(echo $display_width | awk '{print $1}')
# printf "\n\ndisplay_width = $display_width    display_height= $display_height\n\n If you wish to quit, type a q\n\n"

# input_configs
# max_width=$(($display_width/$columns))
# max_height=$(($display_height/$rows))

# column=0
# row=0

# for URL in $(cat $file_path); do
# 	if (("$column" < "$columns")); then
# 		print_command $URL $column $row
# 		column=$(($column + 1))
# 	else
# 		column=0
# 		row=$(($row + 1))
# 		if (("$row" < "$rows")) ; then
# 			print_command $URL $column $row
# 			column=$(($column + 1))
# 		else
# 			printf "\n Exceeded maximum number of cameras for this Columns and Rows number, maybe increase those numbers???"
# 			break
# 		fi
# 	fi
# done


# for URL in $(cat ./urls.txt); do
# 	if (("$row" < "$rows")) ; then
# 		print_command $URL $column $row
# 		if (("$column" < "$columns")); then
# 			column=$(($column + 1))
# 		else
# 			column=0
# 			row=$(($row + 1))
# 		fi
# 	else
# 		printf "\n Exceeded maximum number of cameras for this Columns and Rows number, maybe increase those numbers???"
# 		break
# 	fi
# done









# max_width=$1;
# max_height=$2;
# printf "\n max_width ${max_width}"
# printf "\n max_height ${max_height}"
# URL=rtsp://video.quero.education:7447/595194eeea9634466400b4a4_2;
# temp=(`avprobe -show_streams  ${URL} 2>/dev/null | grep -oP "((?<=^width=).*)|((?<=^height=).*)"`);
# video_width=${temp[0]}
# video_height=${temp[1]}
# ###### Verifica qual das dimensões tem o menor zoom 
# if (( $(bc <<< "(${max_width} / ${video_width}) < (${max_height} / ${video_height})") )); then
# 	video_zoom=$(echo "scale=3; ${max_width} / ${video_width}" | bc )
# else
# 	video_zoom=$(echo "scale=3; ${max_height} / ${video_height}" | bc)
# fi
# #prependa o 0 caso o número venha no formato .123
# if [[ $video_zoom =~ ^\. ]]; then
# 	video_zoom="0$video_zoom"
# fi
# printf "\n video_width ${video_width}"
# printf "\n video_height ${video_height}"
# printf "\n video_zoom1 ${video_zoom}"



# read_number () {
# 	read -p "Type in the number of COLUMNS and press enter: " columns
# 	columns=${columns:-1}
# 	if [[ -n ${input//[0-9]/} ]]; then
# 	    echo "Contains letters!"
# 	fi
# 	str="Some string"
# 	echo $str | awk '{print toupper($0)}'

# }





	# read -p "Type in the number of COLUMNS and press enter: " columns
	# columns=${columns:-1}
	# read -p "Type in the number of ROWS and press enter: " rows
	# rows=${rows:-1}
	# read -p "Type in the number location of the file to read (if not informed defaults to ./urls.txt ): " file_path
	# file_path=${file_path:-"./urls.txt"}