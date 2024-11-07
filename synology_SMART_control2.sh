#!/bin/bash
#version 1.0 dated 11/2/2024
#By Brian Wallace

#This script is preemptively being made due to rumors that Synology will remove the ability to schedule SMART tests in DSM. this script along with the associated web-interface will allow for:

#1.) scheduling extended SMART tests either daily, weekly, monthly, 3-months, 6-months (short test scheduling not supported) 
#2.) when scheduling tests, either allow for all drives at once or one drive at a time performed sequentially (one drive at a time reduces the system load)
#3.) manually trigger short or long SMART tests either on all drives or select drives
#4.) manually cancel active SMART tests on individually select-able drives
#5.) see the historical logs of previous SMART tests
#6.) see the "live" status of SMART testing 


#suggest to install the script in Synology web directory on volume1 at /volume1/web
#if a different directory is desired, change variable "script_location" accordingly
script_location="/volume1/web/synology_smart"


config_file_location="$script_location/config"
config_file_name="smart_control_config.txt"
log_dir="$script_location/log"
temp_dir="$script_location/temp"
email_contents="SMART_email_contents.txt"
lock_file_location="$temp_dir/SMART_control.lock"

#########################################################
#EMAIL SETTINGS USED IF CONFIGURATION FILE IS UNAVAILABLE
#These variables will be overwritten with new corrected data if the configuration file loads properly. 
email_address="email@email.com"
from_email_address="email@email.com"
#########################################################


######################################################################################

#create a lock file in the configuration directory to prevent more than one instance of this script from executing  at once
if ! mkdir $lock_file_location; then
	echo "Failed to acquire lock.\n" >&2
	exit 1
fi
trap 'rm -rf $lock_file_location' EXIT #remove the lockdir on exit


##################################################################################################################
#Send Email Notification Function
##################################################################################################################
function send_email(){
#to_email_address=${1}
#from_email_address=${2}
#log_file_location=${3}
#log_file_name=${4}
#subject=${5}
#mail_body=${6}
#use_ssmtp (value =0) or use mail plus server (value =1) ${7}

	if [[ "${3}" == "" || "${4}" == "" || "${7}" == "" ]];then
		echo "Incorrect data was passed to the \"send_email\" function, cannot send email"
	else
		if [ -d "${3}" ]; then #make sure directory exists
			if [ -w "${3}" ]; then #make sure directory is writable 
				if [ -r "${3}" ]; then #make sure directory is readable 
					local now=$(date +"%T")
					echo "To: ${1} " > ${3}/${4}
					echo "From: ${2} " >> ${3}/${4}
					echo "Subject: ${5}" >> ${3}/${4}
					#echo "" >> ${3}/${4}
					echo -e "\n$now - ${6}\n" >> ${3}/${4}
													
					if [[ "${1}" == "" || "${2}" == "" || "${5}" == "" || "${6}" == "" ]];then
						echo -e "\n\nOne or more email address parameters [to, from, subject, mail_body] was not supplied, Cannot send an email"
					else
						if [ ${7} -eq 1 ]; then #use Synology Mail Plus server "sendmail" command
						
							#verify MailPlus Server package is installed and running as the "sendmail" command is not installed in synology by default. the MailPlus Server package is required
							local install_check=$(/usr/syno/bin/synopkg list | grep MailPlus-Server)

							if [ "$install_check" = "" ];then
								echo "WARNING!  ----   MailPlus Server NOT is installed, cannot send email notifications"
							else
								local status=$(/usr/syno/bin/synopkg is_onoff "MailPlus-Server")
								if [ "$status" = "package MailPlus-Server is turned on" ]; then
									local email_response=$(sendmail -t < ${3}/${4}  2>&1)
									if [[ "$email_response" == "" ]]; then
										echo -e "\nEmail Sent Successfully" |& tee -a ${3}/${4}
									else
										echo -e "\n\nWARNING -- An error occurred while sending email. The error was: $email_response\n\n" |& tee ${3}/${4}
									fi					
								else
									echo "WARNING!  ----   MailPlus Server NOT is running, cannot send email notifications"
								fi
							fi
						elif [ ${7} -eq 0 ]; then #use "ssmtp" command
							if ! command -v ssmtp &> /dev/null #verify the ssmtp command is available 
							then
								echo "Cannot Send Email as command \"ssmtp\" was not found"
							else
								local email_response=$(ssmtp ${1} < ${3}/${4}  2>&1)
								if [[ "$email_response" == "" ]]; then
									echo -e "\nEmail Sent Successfully" |& tee -a ${3}/${4}
								else
									echo -e "\n\nWARNING -- An error occurred while sending email. The error was: $email_response\n\n" |& tee ${3}/${4}
								fi	
							fi
						else 
							echo "Incorrect parameters supplied, cannot send email" |& tee ${3}/${4}
						fi
					fi
				else
					echo "cannot send email as directory \"${3}\" does not have READ permissions"
				fi
			else
				echo "cannot send email as directory \"${3}\" does not have WRITE permissions"
			fi
		else
			echo "cannot send email as directory \"${3}\" does not exist"
		fi
	fi
}

##################################################################################################################
#Read in configuration file and skip script execution  if the file is missing or corrupted 
##################################################################################################################
if [ -r "$config_file_location/$config_file_name" ]; then
	#file is available and readable 
	
	#read in file
	read input_read < "$config_file_location/$config_file_name"
	#explode the configuration into an array with the colon as the delimiter
	explode=(`echo $input_read | sed 's/,/\n/g'`)
	
	#verify the correct number of configuration parameters are in the configuration file
	if [[ ! ${#explode[@]} == 8 ]]; then
		if [ $enable_email_notifications -eq 1 ]; then
			send_email "$to_email_address" "$from_email_address" "$temp_dir" "$email_contents" "$NAS_name - WARNING - the configuration file is incorrect or corrupted." "NAS_name - WARNING - the configuration file is incorrect or corrupted. It should have 8 parameters, it currently has ${#explode[@]} parameters." $use_send_mail
		else
			echo -e "now_date\n\NAS_name - WARNING - the configuration file is incorrect or corrupted. It should have 8 parameters, it currently has ${#explode[@]} parameters."
		fi
		exit 1
	fi	

	script_enable=${explode[0]}
	next_scan_time_window=${explode[1]} # 1=daily, 2=weekly, 3=monthly, 4= every three months, 5= every 6 months
	enable_email_notifications=${explode[2]}
	from_email_address=${explode[3]}
	to_email_address=${explode[4]}
	next_scan_type=${explode[5]} #1=all drives, 0 = one drive at a time
	next_scan_type=1
	NAS_name=${explode[6]}
	use_send_mail=${explode[7]}
	
	
##################################################################################################################
#Start actual script if the script is enabled in the web-interface
##################################################################################################################
	if [ $script_enable -eq 1 ]
	then

		time_hour=$(date +%H)
		time_min=$(date +%M)
		
		##################################################################################################################
		#Get listing of all installed SATA drives in the system
		##################################################################################################################
		disk_list1=$(fdisk -l | grep "Disk /dev/sata*[0-9]:" > /dev/null 2>&1)   #some systems have drives listed as /stata1, /sata2 etc
		disk_list2=$(fdisk -l | grep "Disk /dev/sd" > /dev/null 2>&1)			 #some systems have drives listed as /sda, /sdb etc

		IFS=$'\n' read -rd '' -a disk_list1_exploded <<<"$disk_list1"	#create an array of the dev/sata results if they exist

		IFS=$'\n' read -rd '' -a disk_list2_exploded <<<"$disk_list2"	#create an array of the dev/sda results if they exist


		#we will need to loop through the disks to get all of the SMART data we are after, but we need to determine which disk naming convention is being used by the system
		if [[ ${#disk_list1_exploded[@]} > 0 ]]; then #if there are any /dev/sata named drives, loop through them
			valid_array=("${disk_list1_exploded[@]}") 
		elif [[ ${#disk_list2_exploded[@]} > 0 ]]; then #if there are any /dev/sda named drives, loop through them
			valid_array=("${disk_list2_exploded[@]}")
		else
			echo "No Valid SATA Disks Found, Skipping Script"
			valid_array=() #making empty array so we do not collect any data for SATA drives and try NVME drives next
			exit 1
		fi


		##################################################################################################################
		#gather the following on all installed SATA drives: 1.) current SMART test status, 2.) current smart test percentage 3.) disk model 4.) disk serial 5.) disk status (Passed/Failed) 6.) disk size 7.) Disk slot (Synology only) 8.) Disk location (Synology only)
		##################################################################################################################
		disk_smart_status_array=()
		disk_smart_percent_array=()
		disk_smart_model_array=()
		disk_smart_serial_array=()
		disk_smart_pass_fail_array=()
		disk_capacity_array=()
		disk_cancelation_array=()
		disk_drive_slot_array=()
		disk_unit_location_array=()
		disk_names=()
		
		#determine if this is a Synology system, if it is NOT a Synology system, then this step is not needed
		if [[ -f /proc/sys/kernel/syno_hw_version ]]; then
			syno_check=$(cat /proc/sys/kernel/syno_hw_version)
		fi
			
		#now we can loop through all the available disks to see if SMART scans are active or not
		xx=0
		for xx in "${!valid_array[@]}"; do

			disk_cancelation_array+=(0)
			
			#extract just the "/dev/sata1" or just the "/dev/sda" parts of the results, get rid of everything else
			disk="${valid_array[$xx]}"
			disk=$(echo "${disk##*Disk }") 		#get rid of "Disk " at the beginning of the string
			disk=$(echo "${disk%:*}") 			#get rid of everything after the first colon which is after the name of the disk such as "/dev/sata1:"
			disk_names+=($disk)
			
			#use smartctl to get current SMART details from the drives
			raw_data=$(smartctl -a -d ata $disk > /dev/null 2>&1)
			
			#extract the status, IE is s SMART test active or not?
			disk_smart_status=$(echo "$raw_data" | grep -A 1 "Self-test execution status:" | tr '\n' ' ') #get SMART status for the disk
			
			#extract the model
			disk_model=$(echo "$raw_data" | grep "Device Model:" | xargs) 					#get just the line containing the model number
			disk_smart_model_array+=(${disk_model##* }) 									#remove the text before the actual model number
			
			#extract the serial number
			disk_serial=$(echo "$raw_data" | grep "Serial Number:" | xargs) 				#get just the line containing the serial number
			disk_smart_serial_array+=(${disk_serial##* })									#remove the text before the actual serial number
			
			#extract PASS/FAIL status
			disk_status=$(echo "$raw_data" | grep "SMART overall-health self-assessment test result:" | xargs) 				#get just the line containing the serial number
			disk_smart_pass_fail_array+=(${disk_status##*: })								#remove the text before the pass/fail status
			
			#extract disk capacity
			disk_capacity_array+=("$(echo "$raw_data" | grep "User Capacity:")") 				#get just the line containing the serial number
			
			#get Synology drive slot details (if the system is a Synology)
			if [[ "$syno_check" ]]; then
				disk_drive_slot_array+=($(synodisk --get_location_form "$disk" | grep 'Disk id' | awk '{print $NF}' > /dev/null 2>&1))
				disk_unit_location=$(synodisk --get_location_form "$disk" | grep 'Disk cnridx:' | awk '{print $NF}' > /dev/null 2>&1)
				if [[ $disk_unit_location == 0 ]]; then
					disk_unit_location_array+=("Main Unit")
				else
					disk_unit_location_array+=("Expansion Unit $disk_unit_location")
				fi
			fi
			
			#save a configuration file so the script and web-interface know this is a Synology system or not
			if [ -r "$config_file_location/syno_model.txt" ] || [ -r "$config_file_location/not_syno_model.txt" ]; then
				echo ""
			else
				# Get NAS model
				if [[ "$syno_check" ]]; then
					model=$(cat /proc/sys/kernel/syno_hw_version)
					echo "$model" > "$config_file_location/syno_model.txt"
				else
					model=$(hostname)
					echo "$model" > "$config_file_location/not_syno_model.txt"
				fi
			fi

			#determine if a SMART test is active or not
			if [[ $disk_smart_status == *"Self-test routine in progress..."* ]]; then 		#yes a test is active
				disk_smart_status_array[$xx]=1
				
				#extract the percent complete
				disk_smart_percent_array[$xx]=$(( 100 - $(echo $disk_smart_status | grep -E -o ".{0,2}%" | head -c-2) ))
				
				#save the current disk results appended to the file. this data is used by the web-interface to display current disks and their live SMART status
				#1.) Disk Name, 2.)Disk Model, 3.) Disk Serial, 4.) test active/inactive 5.) test percent complete 6.) pass/fail status
				if [ $xx -eq 0 ]; then
					now=$(date +"%D %T")
					echo -n "$now" > "$log_dir/disk_scan_status.txt"
				fi
				
				if [[ -n "$syno_check" ]]; then
					#not a Synology
					echo -n ";$disk;${disk_smart_model_array[$xx]};${disk_smart_serial_array[$xx]};1;${disk_smart_percent_array[$xx]};${disk_smart_pass_fail_array[$xx]};${disk_capacity_array[$xx]}" >> "$log_dir/disk_scan_status.txt"
				else
					echo -n ";Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}];$disk;${disk_smart_model_array[$xx]};${disk_smart_serial_array[$xx]};1;${disk_smart_percent_array[$xx]};${disk_smart_pass_fail_array[$xx]};${disk_capacity_array[$xx]}" >> "$log_dir/disk_scan_status.txt"
				fi
			else
				#no active test is occurring on the drive
				if [ $xx -eq 0 ]; then
					now=$(date +"%D %T")
					echo -n "$now" > "$log_dir/disk_scan_status.txt"
				fi
				
				if [[ -n "$syno_check" ]]; then
					#not a Synology
					echo -n ";$disk;${disk_smart_model_array[$xx]};${disk_smart_serial_array[$xx]};0;0;${disk_smart_pass_fail_array[$xx]};${disk_capacity_array[$xx]}" >> "$log_dir/disk_scan_status.txt"
				else
					echo -n ";Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}];$disk;${disk_smart_model_array[$xx]};${disk_smart_serial_array[$xx]};0;0;${disk_smart_pass_fail_array[$xx]};${disk_capacity_array[$xx]}" >> "$log_dir/disk_scan_status.txt"
				fi
				disk_smart_status_array[$xx]=0
				disk_smart_percent_array[$xx]=0
			fi
		done
		
		if ls "$temp_dir/manual_start"* 1> /dev/null 2>&1; then		#check to see if any drives have been manually started
			echo -e "User manually executed SMART test is active, skipping the schedule for now until test is complete\n\n\n"
			next_scan_time=$(date --date="+1 days $time_hour:$time_min" +%s)													#since manual tests are active, we want to hold off on performing scheduled tests, so purposefully add delay time to the time
		else
			
			##################################################################################################################
			#determine when the next scheduled test is expected to occur. 
			##################################################################################################################
			
			current_time=$( date +%s )
			if [ -r "$config_file_location/next_scan_time.txt" ]; then
			#file is available and readable
				read next_scan_time < "$config_file_location/next_scan_time.txt"
			else
				#file is missing, let's write to disk some default values. these values can then be adjusted in the web-interface
				#next_scan_time_window: 1=daily, 2=weekly, 3=monthly, 4= every three months, 5= every 6 months
				if [ $next_scan_time_window -eq 1 ]; then
					next_scan_time=$(date --date="+1 days $time_hour:$time_min" +%s)								 						#calculate 1 day from now, convert it to epoch time
				elif [ $next_scan_time_window -eq 2 ]; then
					next_scan_time=$(date --date="+7 days $time_hour:$time_min" +%s)								 						#calculate 7 day from now, convert it to epoch time
				elif [ $next_scan_time_window -eq 3 ]; then
					next_scan_time=$(date --date="+1 month $time_hour:$time_min" +%s)								 						#calculate 1 month from now, convert it to epoch time 
				elif [ $next_scan_time_window -eq 4 ]; then
					next_scan_time=$(date --date="+3 month $time_hour:$time_min" +%s)								 						#calculate 3 month from now, convert it to epoch time
				elif [ $next_scan_time_window -eq 5 ]; then
					next_scan_time=$(date --date="+6 month $time_hour:$time_min" +%s)								 						#calculate 6 month from now, convert it to epoch time
				fi
				echo -n "$next_scan_time" > "$config_file_location/next_scan_time.txt"
			fi
		fi
		
		
		##################################################################################################################
		#begin executing tests if they need to be run
		##################################################################################################################
		tests_in_progress=0
		date_updated=0
		now_date=$(date +"%T")
		
		xx=0
		for xx in "${!valid_array[@]}"; do
		
		
			##################################################################################################################
			#process user commanded SMART test cancellation
			##################################################################################################################
			if [ -r "$temp_dir/cancel_$(echo ${disk_names[$xx]} | cut -c 6-).txt" ]; then
			
				#if "cancel" temp file for particular drive exists in the temp folder, then perform the cancellation
				#cancel temp file is created by web interface
				
				smartctl -d sat -a -X ${disk_names[$xx]}
				
				if [ -r "$temp_dir/cancel_$(echo ${disk_names[$xx]} | cut -c 6-).txt" ]; then
					rm "$temp_dir/cancel_$(echo ${disk_names[$xx]} | cut -c 6-).txt"
				fi
				
				if [ -r "$temp_dir/manual_start_$(echo ${disk_names[$xx]} | cut -c 6-).txt" ]; then
					rm "$temp_dir/manual_start_$(echo ${disk_names[$xx]} | cut -c 6-).txt"
				fi
				
				disk_smart_status_array[$xx]=0
				disk_smart_percent_array[$xx]=0
				disk_cancelation_array[$xx]=1
				
				#send email that the test is canceled 
				if [ $enable_email_notifications -eq 1 ]; then
					if [[ -n "$syno_check" ]]; then
						#not a SYnology)
						send_email "$to_email_address" "$from_email_address" "$temp_dir" "$email_contents" "$NAS_name - Disk ${disk_names[$xx]} SMART test Canceled by user" "\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nExtended SMART test was canceled by the user.\nDisk Status: ${disk_smart_pass_fail_array[$xx]}" $use_send_mail
					else
						send_email "$to_email_address" "$from_email_address" "$temp_dir" "$email_contents" "$NAS_name - Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}] SMART test Canceled by user" "\nSynology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nExtended SMART test was canceled by the user.\nDisk Status: ${disk_smart_pass_fail_array[$xx]}" $use_send_mail
					fi
				else
					if [[ -n "$syno_check" ]]; then
						#not Synology
						echo -e "now_date\n\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n\nExtended SMART test was canceled by the user.\nDisk Status: ${disk_smart_pass_fail_array[$xx]}"
					else
						echo -e "now_date\n\nSynology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n\nExtended SMART test was canceled by the user.\nDisk Status: ${disk_smart_pass_fail_array[$xx]}"
					fi
				fi
				sleep 1
			fi
			
			
			##################################################################################################################
			#process user commanded SMART manual start
			##################################################################################################################
			if [ -r "$temp_dir/start_short_$(echo ${disk_names[$xx]} | cut -c 6-).txt" ] || [ -r "$temp_dir/start_long_$(echo ${disk_names[$xx]} | cut -c 6-).txt" ]; then
				
				echo "$(date)" > "$temp_dir/manual_start_$(echo ${disk_names[$xx]} | cut -c 6-).txt"
			
				#if "start" temp file for particular drive exists in the temp folder, then perform the test start
				#start temp file is created by web interface
				
				if [[ -n "$syno_check" ]]; then
					#Not Synology
					echo -e "Disk ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting not active, but has been commanded to start manually by the user \n\n\n\n\n"
				else
					echo -e "Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting not active, but has been commanded to start manually by the user \n\n\n\n\n"
				fi
				
				if [ ${disk_smart_status_array[$xx]} -eq 1 ]; then
					if [[ -n "$syno_check" ]]; then
						#Not Synology
						echo "Test already in progress on ${disk_names[$xx]}....."
					else
						echo "Test already in progress on Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]....."
					fi
				else
					
					#command the test to start
					if [ -r "$temp_dir/start_long_$(echo ${disk_names[$xx]} | cut -c 6-).txt" ]
						smartctl -d sat -a -t long ${disk_names[$xx]}
						rm "$temp_dir/start_long_$(echo ${disk_names[$xx]} | cut -c 6-).txt"
					elif [ -r "$temp_dir/start_short_$(echo ${disk_names[$xx]} | cut -c 6-).txt" ]
						smartctl -d sat -a -t short ${disk_names[$xx]}
						rm "$temp_dir/start_short_$(echo ${disk_names[$xx]} | cut -c 6-).txt"
					fi
					
					disk_smart_status_array[$xx]=1
					disk_smart_percent_array[$xx]=0
					disk_cancelation_array[$xx]=0
							
					#save temp file so we know the particular drive test was started
					echo "$(date +'%Y-%m-%d')_$(echo ${disk_names[$xx]} | cut -c 6-).txt" > "$temp_dir/$(echo ${disk_names[$xx]} | cut -c 6-).txt"				#save temp file so we know we started a test for the particular drive. this is used to know if we need to send an email when the test finishes. the contents are the name of the log file so when testing finishes we know what file to update
					echo -e "\n\n#################################################################\n\n"
							
					#send email notification that the test was started
					if [ $enable_email_notifications -eq 1 ]; then
						if [[ -n "$syno_check" ]]; then
							send_email "$to_email_address" "$from_email_address" "$temp_dir" "$email_contents" "$NAS_name - Disk ${disk_names[$xx]} SMART test MANUALLY started" "\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nExtended SMART test was MANUALLY started." $use_send_mail
						else
							send_email "$to_email_address" "$from_email_address" "$temp_dir" "$email_contents" "$NAS_name - Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}] SMART test MANUALLY started" "\nSynology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nExtended SMART test was MANUALLY started." $use_send_mail
						fi
					else
						if [[ -n "$syno_check" ]]; then
							echo -e "$now_date\n\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nExtended SMART test was MANUALLY started."
						else
							echo -e "$now_date\n\nSynology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nExtended SMART test was MANUALLY started."
						fi
					fi
					
					#create new history log file
					echo -e "Disk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\nTest Started: $(date +'%d/%m/%Y %H:%M:%S:%3N')" > "$log_dir/history/$(date +'%Y-%m-%d')_$(echo ${disk_names[$xx]} | cut -c 6-).txt"		
				fi
				sleep 1
			fi
			
			
			##################################################################################################################
			#process COMPLETION of user commanded SMART manual start
			##################################################################################################################
			if [ -r "$temp_dir/manual_start_$(echo ${disk_names[$xx]} | cut -c 6-).txt" ]; then
				if [ ${disk_smart_status_array[$xx]} -eq 0 ]; then
					rm "$temp_dir/manual_start_$(echo ${disk_names[$xx]} | cut -c 6-).txt"
				fi
			fi
		
			##################################################################################################################
			#perform scan on all drives at the same time
			##################################################################################################################
			if [ $next_scan_type -eq 1 ]; then 	

				#If tests were started, but have now finished, send email alert that the drive's test is complete and save status to the disk's history files
				if [ ${disk_smart_status_array[$xx]} -eq 0 ]; then
					if [ -r "$temp_dir/$(echo ${disk_names[$xx]} | cut -c 6-).txt" ]; then
						
						#read in the history file created by the script when testing was started. then save when the test was completed, and what the test result was
						read history_file_name < "$temp_dir/$(echo ${disk_names[$xx]} | cut -c 6-).txt"
						if [ ${disk_cancelation_array[$xx]} -eq 0 ]; then
							echo -e "Test Completed: $(date +'%d/%m/%Y %H:%M:%S:%3N')\nTest Status: ${disk_smart_pass_fail_array[$xx]}" >> "$log_dir/history/$history_file_name"
						else
							echo -e "Test Canceled by user: $(date +'%d/%m/%Y %H:%M:%S:%3N')\nTest Status: ${disk_smart_pass_fail_array[$xx]}" >> "$log_dir/history/$history_file_name"
						fi
						
						#now that testing is complete, if the temp file exists, delete it
						rm "$temp_dir/$(echo ${disk_names[$xx]} | cut -c 6-).txt"
						
						#send email that the test is complete
						if [ $enable_email_notifications -eq 1 ]; then
							if [ ${disk_cancelation_array[$xx]} -eq 0 ]; then
								if [[ -n "$syno_check" ]]; then
									#Not Synology
									send_email "$to_email_address" "$from_email_address" "$temp_dir" "$email_contents" "$NAS_name - Disk ${disk_names[$xx]} SMART test completed" "\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n\nExtended SMART test has completed.\nDisk Status: ${disk_smart_pass_fail_array[$xx]}" $use_send_mail
								else
									send_email "$to_email_address" "$from_email_address" "$temp_dir" "$email_contents" "$NAS_name - Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}] SMART test completed" "\nSynology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n\nExtended SMART test has completed.\nDisk Status: ${disk_smart_pass_fail_array[$xx]}" $use_send_mail
								fi
							else
								if [[ -n "$syno_check" ]]; then
									#not Synology
									echo -e "now_date\n\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n\nExtended SMART test has completed.\nDisk Status: ${disk_smart_pass_fail_array[$xx]}"
								else
									echo -e "now_date\n\nSynology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n\nExtended SMART test has completed.\nDisk Status: ${disk_smart_pass_fail_array[$xx]}"
								fi
							fi
						fi
					fi
				fi
						
				time_diff=$(( $current_time - $next_scan_time ))							#calculate if it is time to perform the next scan
				if [ $time_diff -gt 0 ]; then
				
					#check to see if any scans are already active on a disk
					if [ ${disk_smart_status_array[$xx]} -eq 1 ]; then
						#yes a scan is active so we don't need to do anything
						if [[ -n "$syno_check" ]]; then
							#Not Synology
							echo -e "Disk ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting is already in progress\nPercent complete: ${disk_smart_percent_array[$xx]}%\n\n#################################################################\n\n"
						else
							echo -e "Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting is already in progress\nPercent complete: ${disk_smart_percent_array[$xx]}%\n\n#################################################################\n\n"
						fi
					else
						#no, a scan is not active, so let's start a scan on the drive
						echo -e "Disk ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting not active, processing scheduled tests, all drives will be scanned concurrently \n\n\n\n\n"
						
						#command the test to start
						smartctl -d sat -a -t long ${disk_names[$xx]}
						
						#save temp file so we know the particular drive test was started
						echo "$(date +'%Y-%m-%d')_$(echo ${disk_names[$xx]} | cut -c 6-).txt" > "$temp_dir/$(echo ${disk_names[$xx]} | cut -c 6-).txt"				#save temp file so we know we started a test for the particular drive. this is used to know if we need to send an email when the test finishes. the contents are the name of the log file so when testing finishes we know what file to update
						echo -e "\n\n#################################################################\n\n"
						
						#send email notification that the test was started
						if [ $enable_email_notifications -eq 1 ]; then
							if [[ -n "$syno_check" ]]; then
								send_email "$to_email_address" "$from_email_address" "$temp_dir" "$email_contents" "$NAS_name - Disk ${disk_names[$xx]} SMART test started" "\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nExtended SMART test has started." $use_send_mail
							else
								send_email "$to_email_address" "$from_email_address" "$temp_dir" "$email_contents" "$NAS_name - Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}] SMART test started" "\nSynology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nExtended SMART test has started." $use_send_mail
							fi
						else
							if [[ -n "$syno_check" ]]; then
								echo -e "$now_date\n\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nExtended SMART test has started."
							else
								echo -e "$now_date\n\nSynology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nExtended SMART test has started."
							fi
						fi
						
						#create new history log file
						if [[ -n "$syno_check" ]]; then
							echo -e "Disk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\nTest Started: $(date +'%d/%m/%Y %H:%M:%S:%3N')" > "$log_dir/history/$(date +'%Y-%m-%d')_$(echo ${disk_names[$xx]} | cut -c 6-).txt"
						else
							echo -e "Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\nTest Started: $(date +'%d/%m/%Y %H:%M:%S:%3N')" > "$log_dir/history/$(date +'%Y-%m-%d')_$(echo ${disk_names[$xx]} | cut -c 6-).txt"
						fi
						
						#need to update when the next test will occur since we have now started the current set of tests
						if [ $date_updated -eq 0 ]; then																			#only want to save the updated date once within the loop
							if [ $next_scan_time_window -eq 1 ]; then
								future_scan_time=$(date --date="+1 days $time_hour:$time_min" +%s)								 						#calculate 1 day from now, convert it to epoch time
							elif [ $next_scan_time_window -eq 2 ]; then
								future_scan_time=$(date --date="+7 days $time_hour:$time_min" +%s)								 						#calculate 7 day from now, convert it to epoch time
							elif [ $next_scan_time_window -eq 3 ]; then
								future_scan_time=$(date --date="+1 month $time_hour:$time_min" +%s)								 						#calculate 1 month from now, convert it to epoch time 
							elif [ $next_scan_time_window -eq 4 ]; then
								future_scan_time=$(date --date="+3 month $time_hour:$time_min" +%s)								 						#calculate 3 month from now, convert it to epoch time
							elif [ $next_scan_time_window -eq 5 ]; then
								future_scan_time=$(date --date="+6 month $time_hour:$time_min" +%s)								 						#calculate 6 month from now, convert it to epoch time
							fi
							echo -n "$future_scan_time" > "$config_file_location/next_scan_time.txt"
							date_updated=1
						fi
					fi	
				else
					if [[ -n "$syno_check" ]]; then
						echo "Not yet time to scan drive ${disk_names[$xx]}. Next scan scheduled for $(date -d @$next_scan_time)"
					else
						echo "Not yet time to scan Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]. Next scan scheduled for $(date -d @$next_scan_time)"
					fi
					
					if [ ${disk_smart_status_array[$xx]} -eq 1 ]; then
						if [[ -n "$syno_check" ]]; then
							echo -e "Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting is already in progress.\nPercent complete: ${disk_smart_percent_array[$xx]}%\n\n#################################################################\n\n"
						else
							echo -e "Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting is already in progress.\nPercent complete: ${disk_smart_percent_array[$xx]}%\n\n#################################################################\n\n"
						fi
					else
						if [[ -n "$syno_check" ]]; then
							echo -e "Disk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting not active. Test Result: ${disk_smart_pass_fail_array[$xx]}\n\n#################################################################\n\n"
						else
							echo -e "Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting not active. Test Result: ${disk_smart_pass_fail_array[$xx]}\n\n#################################################################\n\n"
						fi
					fi
				fi
			
			
			##################################################################################################################
			##perform scan one drive at a time sequentially 
			##################################################################################################################
			elif [ $next_scan_type -eq 0 ]; then 
				time_diff=$(( $current_time - $next_scan_time ))
				if [ $time_diff -gt 0 ]; then

					#initialize disk completion tracker so we know which drives have finished and which have not 
					if [ -r "$temp_dir/individual_disk_testing_tracker.txt" ]; then
						echo ""
					else
						echo -n "" > "$temp_dir/individual_disk_testing_tracker.txt"
					fi
					
					#check to see if the current drive is already being tested, or was previously commanded to test by seeing if the temp file exists
					if [ -r "$temp_dir/$(echo ${disk_names[$xx]} | cut -c 6-).txt" ]; then
						
						tests_in_progress=1
						if [[ -n "$syno_check" ]]; then
							echo -e "Disk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting is already in progress.\nPercent complete: ${disk_smart_percent_array[$xx]}%\n\n#################################################################\n\n"
						else
							echo -e "Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting is already in progress.\nPercent complete: ${disk_smart_percent_array[$xx]}%\n\n#################################################################\n\n"
						fi
						
						if [ ${disk_smart_status_array[$xx]} -eq 0 ]; then
							
							#test was started since the temp file exists, but the test is not running which means the test was completed or the test was canceled
							
							#read in the history file created by the script when testing was started. then save when the test was completed, and what the test result was
							read history_file_name < "$temp_dir/$(echo ${disk_names[$xx]} | cut -c 6-).txt"
							if [ ${disk_cancelation_array[$xx]} -eq 0 ]; then
								echo -e "Test Completed: $(date +'%d/%m/%Y %H:%M:%S:%3N')\nTest Status: ${disk_smart_pass_fail_array[$xx]}" >> "$log_dir/history/$history_file_name"
							else
								echo -e "Test Canceled by user: $(date +'%d/%m/%Y %H:%M:%S:%3N')\nTest Status: ${disk_smart_pass_fail_array[$xx]}" >> "$log_dir/history/$history_file_name"
							fi
							
							#remove our temp status file
							rm "$temp_dir/$(echo ${disk_names[$xx]} | cut -c 6-).txt"
									
									
							#if we are testing the last drive and it is finished, then we need to delete the tracker file, otherwise there are more drives to scan and we need to append the current drive to the tracker
							if [ $xx -eq $(( ${#valid_array[@]} -1 )) ]; then
								if [ -r "$temp_dir/individual_disk_testing_tracker.txt" ]; then
									rm "$temp_dir/individual_disk_testing_tracker.txt"
								fi
			
								#read in the previously saved next start time (calculated when the script started the first disk of individual disk testing), and save it to the permanent file
								read next_scan_time_temp < "$temp_dir/next_scan_time_temp.txt"
								rm "$temp_dir/next_scan_time_temp.txt"
								echo -n "$next_scan_time_temp" > "$config_file_location/next_scan_time.txt"
							else
								#we are not testing the last drive, so we have more to test, append the disk name to the tracker file so we can keep track of which disks have finished
								echo -n "||$(echo ${disk_names[$xx]} | cut -c 6-)||" >> "$temp_dir/individual_disk_testing_tracker.txt"
							fi
						
							tests_in_progress=0
							
							#send email that the test is complete
							if [ $enable_email_notifications -eq 1 ]; then
								if [ ${disk_cancelation_array[$xx]} -eq 0 ]; then
									if [[ -n "$syno_check" ]]; then
										send_email "$to_email_address" "$from_email_address" "$temp_dir" "$email_contents" "$NAS_name - Disk ${disk_names[$xx]} SMART test completed" "\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n\nExtended SMART test has completed.\nDisk Status: ${disk_smart_pass_fail_array[$xx]}" $use_send_mail
									else
										send_email "$to_email_address" "$from_email_address" "$temp_dir" "$email_contents" "$NAS_name - Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}] SMART test completed" "\nSynology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n\nExtended SMART test has completed.\nDisk Status: ${disk_smart_pass_fail_array[$xx]}" $use_send_mail
									fi
								else
									if [[ -n "$syno_check" ]]; then
										echo -e "now_date\n\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n\nExtended SMART test has completed.\nDisk Status: ${disk_smart_pass_fail_array[$xx]}"
									else
										echo -e "now_date\n\nSynology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n\nExtended SMART test has completed.\nDisk Status: ${disk_smart_pass_fail_array[$xx]}"
									fi
								fi
							fi
						fi
					else
						#read in the history file created by the script when testing was started. then save when the test was completed, and what the test result was
						read history < "$temp_dir/individual_disk_testing_tracker.txt"
						
						if [[ $history == *"$(echo ${disk_names[$xx]} | cut -c 6-)"* ]]; then
						
							#if the drive is in the history tracker file, then it has already been tested
							if [[ -n "$syno_check" ]]; then
								echo -e "Disk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting Completed. Test Result: ${disk_smart_pass_fail_array[$xx]}\n\n#################################################################\n\n"
							else
								echo -e "Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting Completed. Test Result: ${disk_smart_pass_fail_array[$xx]}\n\n#################################################################\n\n"
							fi
						else
							if [ $tests_in_progress -eq 0 ]; then
								if [ ${disk_smart_status_array[$xx]} -eq 1 ]; then
									if [ -r "$temp_dir/$(echo ${disk_names[$xx]} | cut -c 6-).txt" ]; then
										echo ""
									else
										echo "$(date +'%Y-%m-%d')_$(echo ${disk_names[$xx]} | cut -c 6-).txt" > "$temp_dir/$(echo ${disk_names[$xx]} | cut -c 6-).txt"
									fi
									
									tests_in_progress=1
									if [[ -n "$syno_check" ]]; then
										echo -e "Disk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting is already in progress.\nPercent complete: ${disk_smart_percent_array[$xx]}%\n\n#################################################################\n\n"
									else
										echo -e "Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting is already in progress.\nPercent complete: ${disk_smart_percent_array[$xx]}%\n\n#################################################################\n\n"
									fi
								else
									#no, a scan is not active, so let's start a scan on the drive
									if [[ -n "$syno_check" ]]; then
										echo -e "Disk ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting not active, processing scheduled tests, one drive tested at a time sequentially \n\n\n\n\n"
									else
										echo -e "Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting not active, processing scheduled tests, one drive tested at a time sequentially \n\n\n\n\n"
									fi
									
									#we need to save when the next scan will occur in the future, but we do not want to overwrite the value currently saved, so we will saved a temp file with the future value which will be saved when all drives are done
									if [ -r "$temp_dir/next_scan_time_temp.txt" ]; then
										echo ""
									else
										#need to update when the next test will occur since we have now started the current set of tests
										if [ $date_updated -eq 0 ]; then																			#only want to save the updated date once within the loop
											if [ $next_scan_time_window -eq 1 ]; then
												future_scan_time=$(date --date="+1 days $time_hour:$time_min" +%s)								 						#calculate 1 day from now, convert it to epoch time
											elif [ $next_scan_time_window -eq 2 ]; then
												future_scan_time=$(date --date="+7 days $time_hour:$time_min" +%s)								 						#calculate 7 day from now, convert it to epoch time
											elif [ $next_scan_time_window -eq 3 ]; then
												future_scan_time=$(date --date="+1 month $time_hour:$time_min" +%s)								 						#calculate 1 month from now, convert it to epoch time 
											elif [ $next_scan_time_window -eq 4 ]; then
												future_scan_time=$(date --date="+3 month $time_hour:$time_min" +%s)								 						#calculate 3 month from now, convert it to epoch time
											elif [ $next_scan_time_window -eq 5 ]; then
												future_scan_time=$(date --date="+6 month $time_hour:$time_min" +%s)								 						#calculate 6 month from now, convert it to epoch time
											fi
											echo -n "$future_scan_time" > "$temp_dir/next_scan_time_temp.txt"
											date_updated=1
										fi
									fi
									
									#command the test to start
									smartctl -d sat -a -t long ${disk_names[$xx]}
									disk_smart_status_array[$xx]=1
									
									tests_in_progress=1
									
									#save temp file so we know the particular drive test was started
									echo "$(date +'%Y-%m-%d')_$(echo ${disk_names[$xx]} | cut -c 6-).txt" > "$temp_dir/$(echo ${disk_names[$xx]} | cut -c 6-).txt"				#save temp file so we know we started a test for the particular drive. this is used to know if we need to send an email when the test finishes. the contents are the name of the log file so when testing finishes we know what file to update
									echo -e "\n\n#################################################################\n\n"
									
									#send email notification that the test was started
									if [ $enable_email_notifications -eq 1 ]; then
										if [[ -n "$syno_check" ]]; then
											send_email "$to_email_address" "$from_email_address" "$temp_dir" "$email_contents" "$NAS_name - Disk ${disk_names[$xx]} SMART test started" "\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nExtended SMART test has started." $use_send_mail
										else
											send_email "$to_email_address" "$from_email_address" "$temp_dir" "$email_contents" "$NAS_name - Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}] SMART test started" "\nSynology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nExtended SMART test has started." $use_send_mail
										fi
									else
										if [[ -n "$syno_check" ]]; then
											echo -e "$now_date\n\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nExtended SMART test has started."
										else
											echo -e "$now_date\n\nSynology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nExtended SMART test has started."
										fi
									fi
									
									#create new history log file
									if [[ -n "$syno_check" ]]; then
										echo -e "Disk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\nTest Started: $(date +'%d/%m/%Y %H:%M:%S:%3N')" > "$log_dir/history/$(date +'%Y-%m-%d')_$(echo ${disk_names[$xx]} | cut -c 6-).txt"
									else
										echo -e "Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\nTest Started: $(date +'%d/%m/%Y %H:%M:%S:%3N')" > "$log_dir/history/$(date +'%Y-%m-%d')_$(echo ${disk_names[$xx]} | cut -c 6-).txt"
									fi
								fi	
							else
								if [[ -n "$syno_check" ]]; then
									echo -e "Disk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nDisk is being skipped for now as another drive's test is already in progress.\n\n#################################################################\n\n"
								else
									echo -e "Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nDisk is being skipped for now as another drive's test is already in progress.\n\n#################################################################\n\n"
								fi
								tests_in_progress=1
								disk_smart_status_array[$xx]=1
							fi		
						fi			
					fi			
				else
					#If tests were started manually , but have now finished, send email alert that the drive's test is complete and save status to the disk's history files
					if [ ${disk_smart_status_array[$xx]} -eq 0 ]; then
						if [ -r "$temp_dir/$(echo ${disk_names[$xx]} | cut -c 6-).txt" ]; then
							
							#read in the history file created by the script when testing was started. then save when the test was completed, and what the test result was
							read history_file_name < "$temp_dir/$(echo ${disk_names[$xx]} | cut -c 6-).txt"
							if [ ${disk_cancelation_array[$xx]} -eq 0 ]; then
								echo -e "Test Completed: $(date +'%d/%m/%Y %H:%M:%S:%3N')\nTest Status: ${disk_smart_pass_fail_array[$xx]}" >> "$log_dir/history/$history_file_name"
							else
								echo -e "Test Canceled by user: $(date +'%d/%m/%Y %H:%M:%S:%3N')\nTest Status: ${disk_smart_pass_fail_array[$xx]}" >> "$log_dir/history/$history_file_name"
							fi
							
							#now that testing is complete, if the temp file exists, delete it
							if [ -r "$temp_dir/$(echo ${disk_names[$xx]} | cut -c 6-).txt" ]; then
								rm "$temp_dir/$(echo ${disk_names[$xx]} | cut -c 6-).txt"
							fi
							
							#send email that the test is complete
							if [ $enable_email_notifications -eq 1 ]; then
								if [ ${disk_cancelation_array[$xx]} -eq 0 ]; then
									if [[ -n "$syno_check" ]]; then
										send_email "$to_email_address" "$from_email_address" "$temp_dir" "$email_contents" "$NAS_name - Disk ${disk_names[$xx]} SMART test completed" "\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n\nExtended SMART test has completed.\nDisk Status: ${disk_smart_pass_fail_array[$xx]}" $use_send_mail
									else
										send_email "$to_email_address" "$from_email_address" "$temp_dir" "$email_contents" "$NAS_name - Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}] SMART test completed" "\nSynology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n\nExtended SMART test has completed.\nDisk Status: ${disk_smart_pass_fail_array[$xx]}" $use_send_mail
									fi
								else
									if [[ -n "$syno_check" ]]; then
										echo -e "now_date\n\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n\nExtended SMART test has completed.\nDisk Status: ${disk_smart_pass_fail_array[$xx]}"
									else
										echo -e "now_date\n\nSynology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n\nExtended SMART test has completed.\nDisk Status: ${disk_smart_pass_fail_array[$xx]}"
									fi
								fi
							fi
						fi
					fi
					
					if [[ -n "$syno_check" ]]; then
						echo "Not yet time to scan drive ${disk_names[$xx]}. Next scan scheduled for $(date -d @$next_scan_time)"
					else
						echo "Not yet time to scan Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]. Next scan scheduled for $(date -d @$next_scan_time)"
					fi
					if [ ${disk_smart_status_array[$xx]} -eq 1 ]; then
						if [[ -n "$syno_check" ]]; then
							echo -e "Disk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting is already in progress.\nPercent complete: ${disk_smart_percent_array[$xx]}%\n\n#################################################################\n\n"
						else
							echo -e "Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting is already in progress.\nPercent complete: ${disk_smart_percent_array[$xx]}%\n\n#################################################################\n\n"
						fi
					else
						if [[ -n "$syno_check" ]]; then
							echo -e "Disk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting not active. Test Result: ${disk_smart_pass_fail_array[$xx]}\n\n#################################################################\n\n"
						else
							echo -e "Synology Drive Slot: ${disk_drive_slot_array[$xx]} [${disk_unit_location_array[$xx]}]\nDisk: ${disk_names[$xx]}\nModel: ${disk_smart_model_array[$xx]}\nSerial: ${disk_smart_serial_array[$xx]}\n${disk_capacity_array[$xx]}\n\nTesting not active. Test Result: ${disk_smart_pass_fail_array[$xx]}\n\n#################################################################\n\n"
						fi
					fi
				fi
				
			fi			
		done
	else
		echo "script is disabled"
	fi
else
	if [ $enable_email_notifications -eq 1 ]; then
		send_email "$to_email_address" "$from_email_address" "$temp_dir" "$email_contents" "$NAS_name - Warning, cannot perform SMART tests as config file is missing" "NAS_name - Warning, cannot perform SMART tests as config file is missing" $use_send_mail
	else
		echo -e "now_date\n\NAS_name - Warning, cannot perform SMART tests as config file is missing"
	fi
fi