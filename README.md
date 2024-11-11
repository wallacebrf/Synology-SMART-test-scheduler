# Synology-SMART-test-scheduler
Scheduler of Synology SMART tests

<div id="top"></div>
<!--
*** comments....
-->



<!-- PROJECT LOGO -->
<br />
<div align="center">

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
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#About_the_project_Details">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Road map</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
### 1.) About the project Details

It is <a href="https://www.reddit.com/r/synology/comments/1gh7x45/synology_is_going_to_deprecate_smart_task/">rumored</a> that Synology may be removing the ability to schedule SMART tests in the DSM GUI. 

This script has been preemptively made to cover this possibility. While automated scheduling of SMART tests is already possible with <a href="https://help.ubuntu.com/community/Smartmontools">Smartmontools</a>, this requires the installation of <a href="https://community.synology.com/enu/forum/17/post/15462">IPKG</a> and editing files that are overwritten during system updates. 
The purpose of this script is to be able to operate using Synology DSM in its "stock" form and configuration. 

This script support SATA, USB, and SAS drives. For USB drives, they are supported even if not visible inside Synology DSM's Storage Manager. 

This script along with the associated web-interface will allow for:

#1.) Scheduling extended SMART tests either daily, weekly, monthly, 3-months, 6-months (short test scheduling not supported) 

#2.) When scheduling tests, either allow for *all drives at once* (as DSM already does) or *one drive at a time* performed sequentially (one drive at a time reduces the system load)

#3.) Manually trigger long or short SMART tests either on all drives or select drives*

#4.) Manually cancel active long or short SMART tests on individually select-able drives*

#5.) See the historical logs of previous extended SMART tests executed using this script. This script will not gather logs from SMART tests performed using DSM in the past

#6.) See the "live" status of SMART testing.* 

*NOTE: As this script must be executed to get updated "live" smart status, start or stop tests, the rate in which the "live" data is refreshed, or how quickly a SMART test is actually executed once a manual test is started or cancelled, depends on how often the script is executed in Task Scheduler. It is recommended to have the script execute every 15 minutes. As a result, it can take UP TO 15 minutes (in this example) before the script can respond to commands. 


### 2.) Example outputs of the script
<details>

<summary>Expand to see examples</summary>

### 2.1.) No Scheduled Tests 

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/1.png" alt="Logo">

### 2.2.) All drives concurrently

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/2.png" alt="Logo">

### 2.3.) Drives testing individually, disk 1 of 3 scanning, other two drives waiting

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/3.png" alt="Logo">

### 2.4.)  testing individually, disk 2 of 3 scanning, the first marked complete and the third drive waiting 

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/4.png" alt="Logo">

### 2.5.) drives testing individually, disk 3 of 3 scanning, the first and 2nd marked complete

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/5.png" alt="Logo">

### 2.6.) email of a disk starting testing

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/6.png" alt="Logo">

### 2.7.) email of a disk finishing testing 

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/7.png" alt="Logo">

### 2.8.) disk test manually canceled by the user

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/8.png" alt="Logo">

### 2.9.) manual test running

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/9.png" alt="Logo">

### 2.10.) disk test manually started by the user

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/10.png" alt="Logo">

### 2.11.) Synology System with disks in the main DS920 unit and disks inside a DX517 expansion unit

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/11.png" alt="Logo">

### 2.12.) USB drive (on a Synology DS920) started manually by user

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/12.png" alt="Logo">

</details>
<p align="right">(<a href="#top">back to top</a>)</p>

### 3.) Disk Logging
Every time a SMART test is performed by the script, either manually or through a schedule, it will save the following information to a file. The log files are displayed in the web-interface for easy access. 

<details>

<summary>Expand to see Results of Disk Logging</summary>

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
</details>

<!-- GETTING STARTED -->
## 4.) Getting Started

This project is written around a Synology NAS, however it should work with any linux based system with ```smartctl``` installed and a working PHP powered web-server. It has been verified to work Asustor NAS units. The script supports three mail programs, ```sendmail``` used by Synology MailPlus Server, ```snmp``` which Synology uses but is not maintained any longer, and ```msmtp```. If a linux system uses something other than these three programs, email notifications will not work. 

### 5.) Prerequisites

For email notifications:

This project requires EITHER Synology Mail Plus Server to be installed and running

OR

This project requires that Synology's ```Control Panel --> Notifications``` SMTP server settings are properly configured.

OR

for non-Synology systems, use ```msmtp```. This read-me will lightly touch on configuration of ```msmtp``` however these instructions may not apply to all linux systems.  

The user can choose which email notification service is preferred. It is recommended to use the Synology control panel SMTP notification option (if using Synology) as it does not require additional packages to be installed. However if Synology Mail Plus Server is already installed and running, it is recommended to use it as it sends emails faster, supports message queues and provides logs/history of messages sent. 

### 6.) Installation

Download the zip file ```synology_smart.zip``` as that already contains the required files, and folder structure. 

If that is not desired, manually create the following directories starting in the root of your web server. 

```
1.) /path_to_server_root/synology_smart

2.) /path_to_server_root/synology_smart/config

3.) /path_to_server_root/synology_smart/log

4.) /path_to_server_root/synology_smart/log/history

5.) /path_to_server_root/synology_smart/temp
```


The ```synology_SMART_control.sh``` script file must be downloaded and placed in the ```/path_to_server_root/synology_smart``` directory. 

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


### 6.2.) Configuration of Synology Task Scheduler (For Synology Systems)

Once the script is on the NAS, go to Control Panel --> Task Scheduler

Click on Create --> Scheduled Task --> User-defined_script

In the new window, name the script something useful like "Smart Schedule" and set user to root

Go to the schedule tab, and at the bottom, change the "Frequency" to "every 15-minutes" and change the "first time run" to "00:00" and "last time run" to "23:45". 

Go to the "Task Settings" tab. in the "user defined script" area at the bottom enter ```bash %PATH_TO_SCRIPT%/synology_SMART_control.sh``` for example. Ensure the path is the path to where the file was placed on the NAS. 

Click OK. Enter your account password to confirm that the task will use root

### 6.3.) Configuration of crontab (for Non-Synology Systems)

Edit the crontab at /etc/crontab using ```vi /etc/crontab``` 
	
add the following line: 
```	0,15,30,45 * * * *	root	%PATH_TO_SCRIPT%/synology_SMART_control.sh```

This will execute the script at minute 0, 15, 30, and 45 of every hour, of every day. 

details on crontab can be found here: https://man7.org/linux/man-pages/man5/crontab.5.html and here https://crontab.guru/

### 6.4.) Configuration "smart_scheduler_config.php"

TO BE COMPLETED		TO BE COMPLETED		TO BE COMPLETED
TO BE COMPLETED		TO BE COMPLETED		TO BE COMPLETED
TO BE COMPLETED		TO BE COMPLETED		TO BE COMPLETED
TO BE COMPLETED		TO BE COMPLETED		TO BE COMPLETED
TO BE COMPLETED		TO BE COMPLETED		TO BE COMPLETED


### 6.5.) Configuration of Synology web server "http" user permissions

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

### 6.6.) Configuration of msmtp email settings for Non-Synology systems

In Linux the msmtprc file can be either:

```
    /etc/msmtprc
    ~/.msmtprc
    $XDG_CONFIG_HOME/msmtp/config
```
	
In Asustor's ADM it's:

    ```/usr/builtin/etc/msmtp/msmtprc```

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

### 6.7.) Configuration of required web-interface settings


1. Now that the files are where they need to be, using a browser go to the "smart_scheduler_config.php" page. When the page loads for the first time, it will automatically create a configuration file in the ```config``` directory if one does not already exist. the values will all be default values and must be configured. 

2. Ensure the script is enabled

3. configure email settings like the destination email address, the from email address

4. Configure how often the SMART scans will occur. The available options are: daily, weekly, monthly, every three months, or every 6 months

5. Configure the date and time when the next scan will start

6. Configure the scan type. Two options are available. Either scan all drives concurrently as Synology's DSM already does, or scan one drive at a time sequentially to reduce system load impacts. 

7. Give a name to your system so the email notifications can signify which system the messages are from. 

8. Chose to use either Synology Mail Plus Server (if it is installed and available) or use the integrated Synology SNMP notifications settings found under ```Control Panel --> Notifications```

<!-- CONTRIBUTING -->
## 7.) Contributing

Contributor and beta tester: Dave Russell "007revad" https://github.com/007revad

   -->  Adder of USB support and SAS support to the script
   
   --> 	For the code to determine the drive number of a Synology disk
   

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- LICENSE -->
## 8.) License

This is free to use code, use as you wish

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- CONTACT -->
## 9.) Contact

Your Name - Brian Wallace - wallacebrf@hotmail.com

Project Link: [https://github.com/wallacebrf/Synology-SMART-test-scheduler)

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## 10.) Acknowledgments

https://github.com/007revad 	For the code to determine the drive number of a Synology disk

<p align="right">(<a href="#top">back to top</a>)</p>
