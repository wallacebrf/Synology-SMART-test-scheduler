# Synology-SMART-test-scheduler
Scheduler of Synology SMART tests

<div id="top"></div>
<!--
*** comments....
-->



<!-- PROJECT LOGO -->
<br />
<div align="center">
<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/logo.png" alt="Logo" width="207" height="207">
<h3 align="center">Synology SMART test scheduler + email notifications</h3>

  <p align="center">
    This project is comprised of a shell script that is configured in Synology Task Scheduler to run once every 10 to 15 minutes. The script performs commands to perform SMART tests on a user defined schedule.  
    <br />
    <a href="https://github.com/wallacebrf/Synology-SMART-test-scheduler"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/wallacebrf/Synology-SMART-test-scheduler/issues">Report Bug</a>
    ·
    <a href="https://github.com/wallacebrf/Synology-SMART-test-scheduler/issues">Request Feature</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#About_the_project_Details">About The Project</a> 
   </li>
   <li>
      <a href="#Example_outputs_of_the_script">Example Images</a>
	   <ul>
		<li><a href="#No_Scheduled_Tests">2.1.) (Bash View) No Scheduled Tests</a> </li>
		<li><a href="#All_drives_concurrently">2.2.) (Bash View) All drives concurrently</a></li>
		<li><a href="#Drives_testing_individually">2.3.) (Bash View) Drives testing individually, disk 1 of 3 scanning, other two drives waiting</a></li>
		<li><a href="#testing_individually_disk_2_of_3_scanning">2.4.)  (Bash View) Testing individually, disk 2 of 3 scanning, the first marked complete and the third drive waiting</a> </li>
		<li><a href="#drives_testing_individually_disk_3_of_3_scanning">2.5.) (Bash View) Drives testing individually, disk 3 of 3 scanning, the first and 2nd marked complete</a></li>
		<li><a href="#email_of_a_disk_starting_testing">2.6.) Email of a disk starting testing</a></li>
		<li><a href="#email_of_a_disk_finishing_testing">2.7.) Email of a disk finishing testing</a> </li>
		<li><a href="#disk_test_manually_canceled_by_the_user">2.8.) (Bash View) Disk test manually canceled by the user</a></li>
		<li><a href="#manual_test_running">2.9.) (Bash View) Manual test running</a></li>
		<li><a href="#disk_test_manually_started_by_the_user">2.10.) Email of disk test manually started by the user</a></li>
		<li><a href="#Synology_System_with_disks_in_the_main_DS920_unit_and_disks_inside_a_DX517_expansion_unit">2.11.) (Bash View) Synology System with disks in the main DS920 unit and disks inside a DX517 expansion unit</a></li>
		<li><a href="#USB_drive_started_manually_by_user">2.12.) (Bash View) USB drive (on a Synology DS920) started manually by user</a></li>
		<li><a href="#Web-Interface_Synology_With_all_drives_currently_testing">2.13.1.) Web-Interface (Synology System) With drives currently testing</a></li>
		<li><a href="#Interface_With_all_drives_currently_testing">2.13.2.) Web-Interface (NON-Synology System) With drives currently testing</a></li>
	        <li><a href="#Scrubbing_Active_and_Tests_Delayed">2.14.) (Bash View) Scrubbing Active and SMART Tests Delayed</a></li>
	   </ul>
   </li>
   <li>
      <a href="#Disk_Logging">Disk Logging</a>
    </li>
 <li>
      <a href="#Getting_Started">Getting Started</a>
    </li>
	  <li>
      <a href="#Prerequisites">Prerequisites</a> 
   </li>
	   <li>
      <a href="#Installation">Installation</a> 
		   <ul>
			<li><a href="#Configuration_synology_SMART_control.sh">6.1) Configuration synology SMART control.sh</a> </li>
			   <li><a href="#Automatic_Scheduled_Execution_of_Script_every_10-15_minutes_syno">6.2.1) Automatic Scheduled Execution of Script every 10-15 minutes (Synology)</a> </li>
			   <li><a href="#Automatic_Scheduled_Execution_of_Script_every_10-15_minutes">6.2.2) Automatic Scheduled Execution of Script every 10-15 minutes (Non Synology Systems)</a> </li>
			   <li><a href="#Configuration_smart_scheduler_config">6.3) Configuration smart scheduler config</a> </li>
			   <li><a href="#Configuration_of_http_user_permissions">6.4) Configuration of http user permissions (Synology Only)</a> </li>
			   <li><a href="#Configuration_of_msmtp_email_settings_for_Non-Synology_systems">6.5.) Configuration of msmtp email settings (Non-Synology systems)</a> </li>
			   <li><a href="#Synology_Web-Station_setup">6.6) Synology Web-Station setup</a> </li>
			   <li><a href="#Asustor_web_portal_setup">6.7) Asustor web-portal setup</a> </li>
			   <li><a href="#Configuration_through_PHP_Web-Interface">6.8.1) Configuration through PHP Web-Interface</a> </li>
			   <li><a href="#Configuration_without_using_a_web-interface">6.8.2 Configuration without using a web-interface</a> </li>
      		   </ul>
   </li>
	  <li>
      <a href="#Contributing">Contributing</a> 
   </li>
	  <li>
      <a href="#License">License</a> 
   </li>
	  <li>
      <a href="#Contact">Contact</a> 
   </li>
	  <li>
      <a href="#Acknowledgments">Acknowledgments</a> 
   </li>
  </ol>




<!-- ABOUT THE PROJECT -->
<div id="About_the_project_Details"></div>
### 1.) About the project Details

It is <a href="https://www.reddit.com/r/synology/comments/1gh7x45/synology_is_going_to_deprecate_smart_task/">rumored</a> that Synology may be removing the ability to schedule SMART tests in the DSM GUI. 

This script has been preemptively made to cover this possibility. While automated scheduling of SMART tests is already possible with <a href="https://help.ubuntu.com/community/Smartmontools">Smartmontools</a>, this requires the installation of <a href="https://community.synology.com/enu/forum/17/post/15462">IPKG</a> and editing files that are overwritten during system updates. 
The purpose of this script is to be able to operate using Synology DSM in its "stock" form and configuration. 

This script supports SATA, USB, and SAS drives. For USB drives, they are supported even if not visible inside Synology DSM's Storage Manager. 

This script along with the associated web-interface will allow for:

#1.) Scheduling extended SMART tests either daily, weekly, monthly, 3-months, 6-months (short test scheduling not supported) 

#2.) When scheduling tests, either allow for *all drives at once* (as DSM already does) or *one drive at a time* performed sequentially (one drive at a time reduces the system load)

#3.) Manually trigger long or short SMART tests either on all drives or select drives*

#4.) Manually cancel active long or short SMART tests on individually select-able drives*

#5.) See the historical logs of previous extended SMART tests executed using this script. This script will not gather logs from SMART tests performed using DSM in the past

#6.) See the "live" status of SMART testing.* 

#7.) The script will not allow scheduled SMART tests to execute while either BTRFS or MDADM RAID scrubbing are active to prevent too much load being applied to disks and systenm resources

#8.) Support for USB disk SMART testing. Disks do not need to be visible under Synology Storage Manager

*NOTE: As this script must be executed to get updated "live" smart status, start or stop tests, the rate in which the "live" data is refreshed, or how quickly a SMART test is actually executed once a manual test is started or cancelled, depends on how often the script is executed in Task Scheduler. It is recommended to have the script execute every 15 minutes. As a result, it can take UP TO 15 minutes (in this example) before the script can respond to commands. 


### 2.) Example outputs of the script
<div id="Example_outputs_of_the_script"></div>

<div id="No_Scheduled_Tests"></div>

### 2.1.) No Scheduled Tests 

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/1.png" alt="Logo">

<div id="All_drives_concurrently"></div>

### 2.2.) All drives concurrently

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/2.png" alt="Logo">

<div id="Drives_testing_individually"></div>

### 2.3.) Drives testing individually, disk 1 of 3 scanning, other two drives waiting

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/3.png" alt="Logo">

<div id="testing_individually_disk_2_of_3_scanning"></div>

### 2.4.)  testing individually, disk 2 of 3 scanning, the first marked complete and the third drive waiting 

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/4.png" alt="Logo">

<div id="drives_testing_individually_disk_3_of_3_scanning"></div>

### 2.5.) drives testing individually, disk 3 of 3 scanning, the first and 2nd marked complete

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/5.png" alt="Logo">

<div id="email_of_a_disk_starting_testing"></div>

### 2.6.) email of a disk starting testing

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/6.png" alt="Logo">

<div id="email_of_a_disk_finishing_testing"></div>

### 2.7.) email of a disk finishing testing 

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/7.png" alt="Logo">

<div id="disk_test_manually_canceled_by_the_user"></div>

### 2.8.) disk test manually canceled by the user

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/8.png" alt="Logo">

<div id="manual_test_running"></div>

### 2.9.) manual test running

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/9.png" alt="Logo">

<div id="disk_test_manually_started_by_the_user"></div>

### 2.10.) disk test manually started by the user

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/10.png" alt="Logo">

<div id="Synology_System_with_disks_in_the_main_DS920_unit_and_disks_inside_a_DX517_expansion_unit"></div>

### 2.11.) Synology System with disks in the main DS920 unit and disks inside a DX517 expansion unit

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/11.png" alt="Logo">

<div id="USB_drive_started_manually_by_user"></div>

### 2.12.) USB drive (on a Synology DS920) started manually by user

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/12.png" alt="Logo">

<div id="Web-Interface_Synology_With_all_drives_currently_testing"></div>

### 2.13.1.) Web-Interface (Synology System) With drives currently testing

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/13.png" alt="Logo">

<div id="Web-Interface_With_all_drives_currently_testing"></div>

### 2.13.2.) Web-Interface (NON-Synology System) With drives currently testing

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/14.png" alt="Logo">

<div id="Scrubbing_Active_and_Tests_Delayed"></div>

### 2.14.) Scrubbing Active and Tests Delayed

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/16.png" alt="Logo">

<p align="right">(<a href="#top">back to top</a>)</p>

### 3.) Disk Logging
<div id="Disk_Logging"></div>
<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/17.png" alt="Logo">
Every time a SMART test is performed by the script, either manually or through a schedule, it will save the following information to a file. The log files are displayed in the web-interface for easy access. 

```
Synology Drive Slot: 2 [Main Unit]
Disk: /dev/sata3
Model: HUH721212ALE604
Serial: REDACTED
User Capacity:    12,000,138,625,024 bytes [12.0 TB]
Test Started: 10/11/2024 17:31:06:308
Test Completed: 10/11/2024 17:31:55:703
Test Status: PASSED

Full SMART Test Details:


smartctl 6.5 (build date Sep 26 2022) [x86_64-linux-4.4.302+] (local build)
Copyright (C) 2002-16, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Model Family:     HGST Ultrastar DC HC520 (He12)
Device Model:     HGST HUH721212ALE604
Serial Number:    REDACTED
LU WWN Device Id: 5 000cca 278dc1dde
Firmware Version: REDACTED
User Capacity:    12,000,138,625,024 bytes [12.0 TB]
Sector Sizes:     512 bytes logical, 4096 bytes physical
Rotation Rate:    7200 rpm
Form Factor:      3.5 inches
Device is:        In smartctl database [for details use: -P show]
ATA Version is:   ACS-2, ATA8-ACS T13/1699-D revision 4
SATA Version is:  SATA 3.2, 6.0 Gb/s (current: 6.0 Gb/s)
Local Time is:    Sun Nov 10 17:31:55 2024 CST
SMART support is: Available - device has SMART capability.
SMART support is: Enabled

=== START OF READ SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED

General SMART Values:
Offline data collection status:  (0x82)	Offline data collection activity
					was completed without error.
					Auto Offline Data Collection: Enabled.
Self-test execution status:      (  25)	The self-test routine was aborted by
					the host.
Total time to complete Offline 
data collection: 		(   87) seconds.
Offline data collection
capabilities: 			 (0x5b) SMART execute Offline immediate.
					Auto Offline data collection on/off support.
					Suspend Offline collection upon new
					command.
					Offline surface scan supported.
					Self-test supported.
					No Conveyance Self-test supported.
					Selective Self-test supported.
SMART capabilities:            (0x0003)	Saves SMART data before entering
					power-saving mode.
					Supports SMART auto save timer.
Error logging capability:        (0x01)	Error logging supported.
					General Purpose Logging supported.
Short self-test routine 
recommended polling time: 	 (   2) minutes.
Extended self-test routine
recommended polling time: 	 (1287) minutes.
SCT capabilities: 	       (0x003d)	SCT Status supported.
					SCT Error Recovery Control supported.
					SCT Feature Control supported.
					SCT Data Table supported.

SMART Attributes Data Structure revision number: 16
Vendor Specific SMART Attributes with Thresholds:
ID# ATTRIBUTE_NAME                                                   FLAG     VALUE WORST THRESH TYPE      UPDATED  WHEN_FAILED RAW_VALUE
  1 Raw_Read_Error_Rate                                              0x000b   100   100   016    Pre-fail  Always       -       0
  2 Throughput_Performance                                           0x0005   132   132   054    Pre-fail  Offline      -       96
  3 Spin_Up_Time                                                     0x0007   181   181   024    Pre-fail  Always       -       400 (Average 327)
  4 Start_Stop_Count                                                 0x0012   100   100   000    Old_age   Always       -       276
  5 Reallocated_Sector_Ct                                            0x0033   100   100   005    Pre-fail  Always       -       0
  7 Seek_Error_Rate                                                  0x000b   100   100   067    Pre-fail  Always       -       0
  8 Seek_Time_Performance                                            0x0005   128   128   020    Pre-fail  Offline      -       18
  9 Power_On_Hours                                                   0x0012   100   100   000    Old_age   Always       -       3164
 10 Spin_Retry_Count                                                 0x0013   100   100   060    Pre-fail  Always       -       0
 12 Power_Cycle_Count                                                0x0032   100   100   000    Old_age   Always       -       160
 22 Helium_Level                                                     0x0023   100   100   025    Pre-fail  Always       -       100
192 Power-Off_Retract_Count                                          0x0032   100   100   000    Old_age   Always       -       395
193 Load_Cycle_Count                                                 0x0012   100   100   000    Old_age   Always       -       395
194 Temperature_Celsius                                              0x0002   171   171   000    Old_age   Always       -       35 (Min/Max 14/41)
196 Reallocated_Event_Count                                          0x0032   100   100   000    Old_age   Always       -       0
197 Current_Pending_Sector                                           0x0022   100   100   000    Old_age   Always       -       0
198 Offline_Uncorrectable                                            0x0008   100   100   000    Old_age   Offline      -       0
199 UDMA_CRC_Error_Count                                             0x000a   200   200   000    Old_age   Always       -       0

SMART Error Log Version: 1
No Errors Logged

SMART Self-test log structure revision number 1
Num  Test_Description    Status                  Remaining  LifeTime(hours)  LBA_of_first_error
# 1  Extended offline    Aborted by host               90%      3164         -
# 2  Extended offline    Aborted by host               90%      3163         -
# 3  Extended offline    Aborted by host               90%      3163         -
# 4  Extended offline    Aborted by host               90%      3109         -
# 5  Extended offline    Aborted by host               90%      3108         -
# 6  Extended offline    Aborted by host               90%      3093         -
# 7  Extended offline    Aborted by host               90%      3092         -
# 8  Extended offline    Aborted by host               90%      3065         -
# 9  Extended offline    Aborted by host               90%      3065         -
#10  Extended offline    Aborted by host               90%      3065         -
#11  Extended offline    Aborted by host               90%      3065         -
#12  Extended offline    Aborted by host               90%      3064         -
#13  Extended offline    Aborted by host               90%      3064         -
#14  Extended offline    Aborted by host               90%      3064         -
#15  Extended offline    Aborted by host               90%      3064         -
#16  Extended offline    Aborted by host               90%      3062         -
#17  Extended offline    Aborted by host               90%      3061         -
#18  Extended offline    Aborted by host               90%      3016         -
#19  Extended offline    Aborted by host               90%      3016         -
#20  Extended offline    Aborted by host               90%      3016         -
#21  Extended offline    Aborted by host               90%      3015         -

SMART Selective self-test log data structure revision number 1
 SPAN  MIN_LBA  MAX_LBA  CURRENT_TEST_STATUS
    1        0        0  Not_testing
    2        0        0  Not_testing
    3        0        0  Not_testing
    4        0        0  Not_testing
    5        0        0  Not_testing
Selective self-test flags (0x0):
  After scanning selected spans, do NOT read-scan remainder of disk.
If Selective self-test is pending on power-up, resume after 0 minute delay.
```

<!-- GETTING STARTED -->
<div id="Getting_Started"></div>

## 4.) Getting Started

This project is written around a Synology NAS, however it should work with any linux based system with ```smartctl``` installed and a working PHP powered web-server (Note, PHP web server is not required, but adds useful features and ease of use. Refer to the details below on configuring the script without the web-interface). The script has been verified to work Asustor NAS units in adition to Synology NAS units. The script supports three mail programs, ```sendmail``` used by Synology MailPlus Server, ```snmp``` which Synology uses but is not maintained any longer, and ```msmtp```. If a linux system uses something other than these three programs, email notifications will not work. Please feel free to submit either an issue request and or a pull request to add addtional mail program handlers. 

<div id="Prerequisites"></div>

### 5.) Prerequisites

For email notifications:

This project requires EITHER Synology Mail Plus Server to be installed and running

OR

This project requires that Synology's ```Control Panel --> Notification``` SMTP server settings are properly configured.

OR

for non-Synology systems, use ```msmtp```. This read-me will lightly touch on configuration of ```msmtp``` however these instructions may not apply to all linux systems.  

The user can choose which email notification service is preferred. It is recommended to use the Synology control panel SMTP notification option (if using Synology) as it does not require additional packages to be installed. However if Synology Mail Plus Server is already installed and running, it is recommended to use it as it sends emails faster, supports message queues and provides logs/history of messages sent. 

<div id="Installation"></div>

### 6.) Installation

 Create the following directories starting in the root of your web server. 

```
1.) /path_to_server_root/synology_smart

2.) /path_to_server_root/synology_smart/config

3.) /path_to_server_root/synology_smart/log

4.) /path_to_server_root/synology_smart/log/history

5.) /path_to_server_root/synology_smart/temp
```


The ```synology_SMART_control.sh``` script file must be downloaded and placed in the ```/path_to_server_root/synology_smart``` directory. 

<div id="Configuration_synology_SMART_control.sh"></div>

### 6.1.) Configuration "synology_SMART_control.sh"

The script has the following configuration parameters. 

```
#########################################################
# User Variables
#########################################################
#suggest to install the script in Synology web directory on volume1 at /volume1/web
#if a different directory is desired, change variable "script_location" accordingly
script_location="/volume1/web/synology_smart"

#EMAIL SETTINGS USED IF CONFIGURATION FILE IS UNAVAILABLE
#These variables will be overwritten with new corrected data if the configuration file loads properly. 
email_address="email@email.com"
from_email_address="email@email.com"
#########################################################
```

Ensure that the path ```script_location="/volume1/web/synology_smart"``` matches where your NAS web server software has its root directory configured. This setup guide does not detail how to install and configure a working PHP web-server on Synology or non-Synology systems. 

Edit the email lines so if the script cannot load the configuration file it can still send an email warning notification. 

### 6.2.) Automatic Scheduled Execution of Script every 10-15 minutes 
There are two ways to ensure the script executes every 10-15 minutes. That would be using crontab (works on both Synology and non-Synology systems) or use Synology Task Scheduler (Synology Only)

<div id="Automatic_Scheduled_Execution_of_Script_every_10-15_minutes_syno"></div>

### 6.2.1.) Configuration of Synology Task Scheduler (For Synology Systems)

Once the script is on the NAS, go to Control Panel --> Task Scheduler

Click on Create --> Scheduled Task --> User-defined_script

In the new window, name the script something useful like "Smart Schedule" and set user to root

Go to the schedule tab, and at the bottom, change the "Frequency" to "every 15-minutes" and change the "first time run" to "00:00" and "last time run" to "23:45". 

Go to the "Task Settings" tab. in the "user defined script" area at the bottom enter ```bash %PATH_TO_SCRIPT%/synology_SMART_control.sh``` for example. Ensure the path is the path to where the file was placed on the NAS. 

Click OK. Enter your account password to confirm that the task will use root

<div id="Automatic_Scheduled_Execution_of_Script_every_10-15_minutes"></div>

### 6.2.2.) Configuration of crontab (for Non-Synology Systems)

Edit the crontab at /etc/crontab using ```vi /etc/crontab``` 
	
add the following line: 
```	0,15,30,45 * * * *	root	%PATH_TO_SCRIPT%/synology_SMART_control.sh```

This will execute the script at minute 0, 15, 30, and 45 of every hour, of every day. 

details on crontab can be found here: https://man7.org/linux/man-pages/man5/crontab.5.html and here https://crontab.guru/

<div id="Configuration_smart_scheduler_config"></div>

### 6.3.) Configuration "smart_scheduler_config.php"

The file ```smart_scheduler_config.php``` has three user configurable parameters:

```
$script_location="/volume1/web/synology_smart";
$use_login_sessions=false; //set to false if not using user login sessions
$form_submittal_destination="smart_scheduler_config.php";
```

ensure ```$script_location="/volume1/web/synology_smart";``` matches where the script files are located on your machine

if your PHP web server uses log-in sessions and user names, change ```$use_login_sessions=false;``` to true

if the PHP configuration file is included within a larger PHP file using the ```include_once()``` command, then change the line ```$form_submittal_destination="smart_scheduler_config.php";``` to the correct address of the file calling out this config file. 

<div id="Configuration_of_http_user_permissions"></div>

### 6.4.) Configuration of "http" user permissions (Synology Only)

by default the Synology user "http" that web station uses does not have write permissions to the "web" file share. 

1. Go to Control Panel -> User & Group -> "Group" tab
2. Click on the "http" user and press the "edit" button
3. Go to the "permissions" tab
4. Scroll down the list of shared folders to find "web" and click on the right check-box under "customize" 
5. Check ALL boxes and click "done"
6. Verify the window indicates the "http" user group has "Full Control" and click the check-box at the bottom "Apply to this folder, sub folders and files" and click "Save"

<img src="https://raw.githubusercontent.com/wallacebrf/synology_snmp/main/Images/http_user1.png" alt="1313">
<img src="https://raw.githubusercontent.com/wallacebrf/synology_snmp/main/Images/http_user2.png" alt="1314">
<img src="https://raw.githubusercontent.com/wallacebrf/synology_snmp/main/Images/http_user3.png" alt="1314">

<div id="Configuration_of_msmtp_email_settings_for_Non-Synology_systems"></div>

### 6.5.) Configuration of msmtp email settings for Non-Synology systems

In Linux the msmtprc file can be either:

```
    /etc/msmtprc
    ~/.msmtprc
    $XDG_CONFIG_HOME/msmtp/config
```
	
In Asustor's ADM it's:

```
    /usr/builtin/etc/msmtp/msmtprc
```

By default the msmtp file contains:

```
# Set default values for all following accounts.
defaults
timeout 15
tls on
tls_trust_file /usr/builtin/etc/msmtp/ca-certificates.crt
#logfile ~/.msmtplog

# The SMTP server of the provider.
#account user@gmail.com
#host smtp.gmail.com
#port 587
#from user@gmail.com
#auth on
#user user@gmail.com
#password passwd

# Set a default account
#account default: user@gmail.com
```
Ensure the SMTP server is configured for the server of your choice, and ensure the ```account default``` email address is properly configured.

If sending from a gmail account you will need to generate an "app password" and use that instead of your gmail password.

1. Go to https://myaccount.google.com/apppasswords and sign into google.
2. Enter a name in the form of `appname@computer-name` like `smarttest@ubuntu` and click Create.
3. In the "Generated app password" popup copy the 16 character app password which will be like `abcd efgh ijkl mnop`
4. In your msmtprc or config file replace `password passwd` with the 16 character app password (without spaces) like:
```
password abcdefghijklmnop
```

<div id="Synology_Web-Station_setup"></div>

### 6.6.) Synology Web-Station setup
If using a Synology NAS and wish to utilize the PHP web-interface, follow these instructions to setup Web Station

1. Ensure Web Station and PHP 8.2 are installed in Package Center

2. Inside Web Station go to "Script Language Settings --> PHP tab --> Create"

    a. Enter Profile name as "core"
     
    b. Enter Description as "core"
    
    c. Choose PHP 8.2 for PHP version
     
    d. Click "Enable display_errors to display PHP error messages"
    
    e. Keep "Customize PHO open_basedir" as "default"
     
    f. Click Next
    
    g. Enable all extensions
    
    h. Click Next
    
    i. Leave as default
    
    j. Click Next
    
    k. Leave as default
    
    l. Click Next
    
    m. Review the settings and click "Create"

3. Inside Web Station go to "Web Service" --> Create"
   
    a. Choose "Native script language website"
   
    b. Under Service, click PHP 8.2 and choose the "core" PHP profile previously created
   
    c. Click "Next"
   
    d. Enter the Name "core"
   
    e. Enter Description as "core"
  
    f. Choose Document root as "/volume1/web" shared folder
  
    g. For HTTP back-end-server click "Nginx"
  
    h. Leave timeout settings as default
   
    i. Click "Next"
  
    j. Review the settings, and click "Create"

4. Inside Web Station to to "Web Portal --> Create"
  
    a. Choose the "Web service portal"
  
    b. Under "Service" choose the "core" service we created previously
  
    c. Under Portal type leave as "Name-based"
  
    d. Choose a Hostname, like "home". This should be same value as the NAS's name
   
    e. Choose ports. Suggest standard web-server ports 80/443
   
    f. Under HTTPS settings, choose to enable "HSTS"
   
    g. Under "Access control profile" leave as "Not configured"
   
    h. Under "Error page profile" choose "Default error page profile"
  
    i. Enable "Enable access logs"
  
    j. Click Create

<div id="Asustor_web_portal_setup"></div>

### 6.7.) Asustor web portal setup
If using an Austor NAS and wish to utilize the PHP web-interface, follow these instructions to setup the web portal

1. In ADM click on Web Center > Implementation.

2. Check that PHP is installed and showing "Status: Active".

3. Check either Apache or Nginx is installed and showing "Status: Active".

4. Click on the "Web Server" tab.

5. Check "Web server implementation" is set to Apache or Nginx.

6. Tick "Enable Web server port" and/or "Enable secure Web server port".

7. Change the "Web server port" and/or "secure Web server port" to your desired ports, or leave them on the defaults.

8. Check "PHP implementation" is set to the installed PHP version.

9. Click on the "Virtual Host" tab.

10. Click Add.

11. Give it a unique Host name (e.g. "smart" will do).

12. Select the Protocol you prefer (HTTP or HTTPS).

13. If you set a web server port in step 7 make sure that "Port number" matches.

14. Click Browse and browse to "Web > synology_smart".

15. Click OK.

You can now access the Synology-SMART-scheduler webui on either:
- `https://<ip-address>/synology_smart/smart_scheduler_config.php`
- `http://<ip-address>/synology_smart/smart_scheduler_config.php`

Note: Replace <ip-address> with your Asustor's IP Address or Hostname.

### 6.8.) Configuration of required user level settings

<div id="Configuration_through_PHP_Web-Interface"></div>

### 6.8.1.) Configuration through PHP Web-Interface

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/15.png" alt="Logo">

1. Now that the files are where they need to be, using a browser go to the "smart_scheduler_config.php" page. When the page loads for the first time, it will automatically create a configuration file in the ```config``` directory if one does not already exist. the values will all be default values and must be configured. 

2. Ensure the script is enabled

3. configure email settings like the destination email address, the from email address

4. Configure how often the SMART scans will occur. The available options are: daily, weekly, monthly, every three months, or every 6 months

5. Configure the date and time when the next scan will start

6. Configure the scan type. Two options are available. Either scan all drives concurrently as Synology's DSM already does, or scan one drive at a time sequentially to reduce system load impacts. 

7. Give a name to your system so the email notifications can signify which system the messages are from. 

8. Chose to use either Synology Mail Plus Server (if it is installed and available) or use the integrated Synology SNMP notifications settings found under ```Control Panel --> Notification```

<div id="Configuration_without_using_a_web-interface"></div>

### 6.8.2.) Configuration without using a web-interface
In the event use of this script is desired without using the web-interface, the script settings can be configured using a text editor. 

open file ```/path_to_server_root/synology_smart/config/smart_control_config.txt``` and edit the paramters as detailed below

```
1,4,1,email@email.com,email@email.com,1,NAS_NAME,0
| | |      |               |          |     |    |
| | |      |               |          |     |    |
| | |      |               |          |     |    |---> Email Program: ssmtp (0) / Synology MailPlus-Server (1) / msmtp (2)
| | |      |               |          |     |---> System Name used to send email notifications
| | |      |               |          |---> Next Scan Type: All Drives Concurrently (1) / One Drive at a time sequentailly (0)
| | |      |               |---> To Email Address (multiple addresses separate by semi-colon
| | |      |---> From Email Address
| | |---> Email Notifications: Enabled (1) / Disabled (0)
| |---> Next Scan Time Window: daily (1) / weekly (2) / monthly (3) / every three months (4) / every 6 months (5)
|---> Script Enable: (1) / Script Disable (0)
```

If the date/time of the next scan needs to be changed, use the following web site: https://www.epochconverter.com/ to generate the epoc time stamp of the date/time desired for the next scan

edit the following file in a text editor: ```/path_to_server_root/synology_smart/config/next_scan_time.txt```

<div id="Contributing"></div>

## 7.) Contributing

Contributor and beta tester: Dave Russell "007revad" https://github.com/007revad

   -->  Adder of USB support and SAS support to the script
   
   --> 	For the code to determine the drive number of a Synology disk
   

<p align="right">(<a href="#top">back to top</a>)</p>

<div id="License"></div>

## 8.) License

This is free to use code, use as you wish

<p align="right">(<a href="#top">back to top</a>)</p>

<div id="Contact"></div>

## 9.) Contact

Your Name - Brian Wallace - wallacebrf@hotmail.com

Project Link: [https://github.com/wallacebrf/Synology-SMART-test-scheduler)

<p align="right">(<a href="#top">back to top</a>)</p>

<div id="Acknowledgments"></div>

## 10.) Acknowledgments

https://github.com/007revad 	For the code to determine the drive number of a Synology disk. Also for suggesting the logo image. 

https://pixabay.com/vectors/glasses-smart-clever-intelligent-98452/ for the logo image

<p align="right">(<a href="#top">back to top</a>)</p>
