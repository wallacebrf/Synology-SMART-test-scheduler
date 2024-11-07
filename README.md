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
### About_the_project_Details

It is rumored that Synology may be removing the ability to schedule SMART tests in the DSM GUI. 

https://www.reddit.com/r/synology/comments/1gh7x45/synology_is_going_to_deprecate_smart_task/

This script has been preemptively made to cover this possibility. While automated scheduling of SMART tests is already possible with <a href="https://help.ubuntu.com/community/Smartmontools">Smartmontools</a>, this requires the installation of <a href="https://community.synology.com/enu/forum/17/post/15462">IPKG</a> and editing files that are overwritten during system updates. 
The purpose of this script is to be able to operate using Synology DSM in its "stock" form and configuration. 

This script along with the associated web-interface will allow for:

#1.) Scheduling extended SMART tests either daily, weekly, monthly, 3-months, 6-months (short test scheduling not supported) 

#2.) When scheduling tests, either allow for *all drives at once* (as DSM already does) or *one drive at a time* performed sequentially (one drive at a time reduces the system load)

#3.) Manually trigger long or short SMART tests either on all drives or select drives*

#4.) Manually cancel active long or short SMART tests on individually select-able drives*

#5.) See the historical logs of previous extednded SMART tests executed using this script. This script will not gather logs from SMART tests performed using DSM in the past

#6.) See the "live" status of SMART testing.* 

*NOTE: As this script must be executed to get updated "live" smart status, start or stop tests, the rate in which the "live" data is refreshed, or how quickly a SMART test is actually executed once a manual test is started or cancelled, depends on how often the script is executed in Task Scheduler. It is recommended to have the script execute every 15 minutes. As a result, it can take UP TO 15 minutes (in this example) before the script can respond to commands. 

Example outputs of the script

### No Scheduled Tests 

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/1.png" alt="Logo">

### All drives concurrently

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/2.png" alt="Logo">

### Drives testing individually, disk 1 of 3 scanning, other two drives waiting

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/3.png" alt="Logo">

### drives testing individually, disk 2 of 3 scanning, the first marked complete and the third drive waiting 

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/4.png" alt="Logo">

### drives testing individually, disk 3 of 3 scanning, the first and 2nd marked complete

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/5.png" alt="Logo">

### email of a disk starting testing

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/6.png" alt="Logo">

### email of a disk finishing testing 

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/7.png" alt="Logo">

### disk test manually canceled by the user

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/8.png" alt="Logo">

### manual test running

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/9.png" alt="Logo">

### disk test manually started by the user

<img src="https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/10.png" alt="Logo">

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

This project is written around a Synology NAS, however it should work with any linux based system with ```smartctl``` installed and a working PHP powered web-server 

### Prerequisites

For email notifications:

This project requires EITHER Synology Mail Plus Server to be installed and running

OR

This project requires that Synology's ```Control Panel --> Notifications``` SMTP server settings are properly configured. 

The user can choose which email notification service is preferred. It is recommended to use the Synology control panel SMTP notification option as it does not require additional packages to be installed. However if Synology Mail Plus Server is already installed and running, it is recommended to use it as it sends emails faster, supports message queues and provides logs/history of messages sent. 

### Installation

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

### Configuration "synology_SMART_control.sh"

The script has the following configuration parameters, the only part of the parameters that should be edited is the path to the web server's root folder. 

```
config_file_location="/volume1/web/synology_smart/config"
config_file_name="smart_control_config.txt"
log_dir="/volume1/web/synology_smart/log"
temp_dir="/volume1/web/synology_smart/temp"
email_contents="SMART_email_contents.txt"
lock_file_location="$temp_dir/SMART_control.lock"
```
Ensure that the path ```/volume1/web/``` matches where your NAS web-station package has its root configured. This setup guide does not detail how to install and configure a working PHP web-server on Synology. 

Edit the following lines so if the script cannot load the configuration file it can still send an email

```
#########################################################
#EMAIL SETTINGS USED IF CONFIGURATION FILE IS UNAVAILABLE
#These variables will be overwritten with new corrected data if the configuration file loads properly. 
email_address="email@email.com"
from_email_address="email@email.com"
########################################################
```

### Configuration of Synology Task Scheduler (For Synology Systems)

Once the script is on the NAS, go to Control Panel --> Task Scheduler

Click on Create --> Scheduled Task --> User-defined_script

In the new window, name the script something useful like "Smart Schedule" and set user to root

Go to the schedule tab, and at the bottom, change the "Frequency" to "every 15-minutes" and change the "first time run" to "00:00" and "last time run" to "23:45". 

Go to the "Task Settings" tab. in the "user defined script" area at the bottom enter ```bash %PATH_TO_SCRIPT%/synology_SMART_control.sh``` for example. Ensure the path is the path to where the file was placed on the NAS. 

Click OK. Enter your account password to confirm that the task will use root

### Configuration of crontab (for Non-Synology Systems)

Edit the crontab at /etc/crontab using ```vi /etc/crontab``` 
	
add the following line: 
```	0,15,30,45 * * * *	root	%PATH_TO_SCRIPT%/synology_SMART_control.sh```

This will execute the script at minute 0, 15, 30, and 45 of every hour, of every day. 

details on crontab can be found here: https://man7.org/linux/man-pages/man5/crontab.5.html and here https://crontab.guru/


### Configuration "smart_scheduler_config.php"

TO BE COMPLETED		TO BE COMPLETED		TO BE COMPLETED
TO BE COMPLETED		TO BE COMPLETED		TO BE COMPLETED
TO BE COMPLETED		TO BE COMPLETED		TO BE COMPLETED
TO BE COMPLETED		TO BE COMPLETED		TO BE COMPLETED
TO BE COMPLETED		TO BE COMPLETED		TO BE COMPLETED


### Configuration of Synology web server "http" user permissions

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


### Configuration of required web-interface settings


1. Now that the files are where they need to be, using a browser go to the "smart_scheduler_config.php" page. When the page loads for the first time, it will automatically create a configuration file in the ```config``` directory if one does not already exist. the values will all be default values and must be configured. 

2. Ensure the script is enabled

3. configure email settings like the destination email address, the from email address

4. Configure how often the SMART scans will occur. The available options are: daily, weekly, monthly, every three months, or every 6 months

5. Configure the date and time when the next scan will start

6. Configure the scan type. Two options are available. Either scan all drives concurrently as Synology's DSM already does, or scan one drive at a time sequentially to reduce system load impacts. 

7. Give a name to your system so the email notifications can signify which system the messages are from. 

8. Chose to use either Synology Mail Plus Server (if it is installed and available) or use the integrated Synology SNMP notifications settings found under ```Control Panel --> Notifications```


<!-- CONTRIBUTING -->
## Contributing
https://github.com/007revad 	For the code to determine the drive number of a Synology disk

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- LICENSE -->
## License

This is free to use code, use as you wish

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Your Name - Brian Wallace - wallacebrf@hotmail.com

Project Link: [https://github.com/wallacebrf/Synology-SMART-test-scheduler)

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

https://github.com/007revad 	For the code to determine the drive number of a Synology disk

<p align="right">(<a href="#top">back to top</a>)</p>
