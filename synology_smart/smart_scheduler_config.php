<?php
$version="Version 1.8 Dated 11/18/2024";
//By Brian Wallace
//Note Ensure the location of the configuration file matches the values in the synology_SMART_control.sh script 
/*This web administration page allows for the configuration of all settings used in the synology_SMART_control.sh script file
ensure to visit this web page and configure all settings as required prior to running the synology_SMART_control.sh script for the first time. 
this html file has no major formatting as it is intended to be included in a larger php file using the command include_once" for example:

include_once 'smart_scheduler_config.php';

that file with the above line would include the needed headers, footers, and call outs for formatting*/


///////////////////////////////////////////////////
//User Defined Variables
///////////////////////////////////////////////////
error_reporting(E_NOTICE);
$script_location="/volume1/web/synology_smart";
$use_login_sessions=false; //set to false if not using user login sessions
$form_submittal_destination="smart_scheduler_config.php";
$host_name=php_uname('n');
$page_title="".$host_name." S.M.A.R.T Scheduler<br><font size=\"2\">".$version."</font>";

$nas_ip=$_SERVER['SERVER_ADDR'];
if ($_SERVER['HTTPS'] == 0){
    $prot = "https://";
}else{
    $prot = "http://";
}
$home="$prot$nas_ip";


///////////////////////////////////////////////////
//Beginning file, do not edit past this point
///////////////////////////////////////////////////
$config_file_location="".$script_location."/config";
$config_file_name="smart_control_config.txt";

///////////////////////////////////////////////////
//Function to print out and display links to the test history files
///////////////////////////////////////////////////
function print_gallery_history($dir){
  
  	//reads contents of current gallery folder for all the file names

	//opens the directory for reading
	$dp = opendir($dir)
		or die("<br /><font color=\"#FF0000\">Cannot Open The Directory </font><br>");
	
	//add all files in directory to $theFiles array
	while ($currentFile !== false){
  		$currentFile = readDir($dp);
  		$theFiles[] = $currentFile;
	} // end while
	
	//because we opened the dir, we need to close it
	closedir($dp);
	
	//sorts all the files
	rsort ($theFiles);
	
	$imageFiles = $theFiles;
	
	$last_image = end($imageFiles);
	//begins printing out the gallery
	$output = "";
	$picInRow = 0;
	print "<table border=\"1px\">";
	foreach ($imageFiles as $currentFile){
		$urlname = explode("_", $currentFile);
		if ( $urlname[1] != ""){
			if ($picInRow == 0){
				$output .= <<<HERE
<tr>
HERE;
			}//end if
			$disk_name=str_replace(".txt", "", "$urlname[2]");
			$output .= <<<HERE
<td> <a href = "$home/synology_smart/log/history/$currentFile" target=\"_blank\"><table border="0"><tr><td colspan="2" align="center">$urlname[0]</td></tr><tr><td><b>Disk:</b> $disk_name</td><td><b>Serial:</b> $urlname[1]</td></tr></table></a></td>	
HERE;
			$picInRow++;
			if ($picInRow == 7){//this controls how many images are in each row, this being set to 5 makes 5 images be in each row
				$output .= <<<HERE
</tr>\n
HERE;
				$picInRow = 0;
			}else{
				if ($currentFile == $last_image){
					$output .= <<<HERE
</tr>\n
HERE;
				}
			}//end if
		}
	} // end foreach
$output .= <<<HERE
</table>
HERE;	
	return $output;
}//end function\


///////////////////////////////////////////////////
//Beginning of configuration page
///////////////////////////////////////////////////
if($use_login_sessions){


	if($_SERVER['HTTPS']!="on") {

	$redirect= "https://".$_SERVER['HTTP_HOST'].$_SERVER['REQUEST_URI'];

	header("Location:$redirect"); } 

	// Initialize the session
	if(session_status() !== PHP_SESSION_ACTIVE) session_start();
	 
	$current_time=time();

	if(!isset($_SESSION["session_start_time"])){
		$expire_time=$current_time-60;
	}else{
		$expire_time=$_SESSION["session_start_time"]+3600; #un-refreshed session will only be good for 1 hour
	}


	// Check if the user is logged in, if not then redirect him to login page
	if(!isset($_SESSION["loggedin"]) || $_SESSION["loggedin"] !== true || $current_time > $expire_time || !isset($_SESSION["session_user_id"])){
		// Unset all of the session variables
		$_SESSION = array();
		// Destroy the session.
		session_destroy();
		header("location: ../login.php");
		exit;
	}else{
		$_SESSION["session_start_time"]=$current_time; //refresh session start time
	}
}else{
	session_start();
}

$config_file="".$config_file_location."/".$config_file_name."";

include $_SERVER['DOCUMENT_ROOT']."/synology_smart/functions.php";

//define empty variables
$smart_email_error="";
$smart_date_time_error="";
$smart_voltage_error="";
$generic_error="";
$from_email_error="";
$next_scan_time_window_error="";
$NAS_name_error="";
$use_send_mail_error="";
$syno_check=0;
$number_drives=0;
$drive_slot=[]; 
$drive_name=[]; 
$drive_model=[]; 
$drive_serial=[]; 
$drive_test_status=[]; 
$drive_test_percent=[];
$drive_test_pass_fail=[]; 
$drive_capacity=[]; 
$drive_test_duration=[];
$drive_smart_enabled=[];


if (file_exists("".$script_location."/config/syno_model.txt")) {
	$syno_check=1;
	$model = file_get_contents("".$script_location."/config/syno_model.txt");
}else if (file_exists("".$script_location."/config/not_syno_model.txt")) {
	$model = file_get_contents("".$script_location."/config/not_syno_model.txt");
}

if (file_exists("".$script_location."/log/disk_scan_status.txt")) {
		$data = file_get_contents("".$script_location."/log/disk_scan_status.txt");
		$pieces = explode(";", $data);
		$last_updated=$pieces[0];
		$number_drives=(sizeof($pieces)-1)/10;
		
		for ($x = 0; $x < $number_drives; $x++) {
			array_push($drive_slot, $pieces[1+$x*10]);
			array_push($drive_name, $pieces[2+$x*10]);
			array_push($drive_model, $pieces[3+$x*10]);
			array_push($drive_serial, $pieces[4+$x*10]);
			array_push($drive_test_status, $pieces[5+$x*10]);
			array_push($drive_test_percent, $pieces[6+$x*10]);
			array_push($drive_test_pass_fail, $pieces[7+$x*10]);
			array_push($drive_capacity, $pieces[8+$x*10]);
			array_push($drive_test_duration, $pieces[9+$x*10]);
			array_push($drive_smart_enabled, $pieces[10+$x*10]);
		}
}
	
if(isset($_POST['submit_smart']) && $_POST['randcheck']==$_SESSION['rand']){
	
	//process disk testing cancellations and starts 
	for ($x = 0; $x < $number_drives; $x++) {
		[$disk_cancel, $generic_error] = test_input_processing($_POST['disk_'.$x.'_cancel'], "", "checkbox", 0, 0);
		if ($disk_cancel == 1 ){
			file_put_contents("".$script_location."/temp/cancel_".str_replace("/dev/", "", $drive_name[$x]).".txt", "");
		}
		
		[$disk_start, $generic_error] = test_input_processing($_POST['disk_'.$x.'_start'], 0, "numeric", 0, 2);
		//1=extended, 2=short
		if ($disk_start == 1 ){
			file_put_contents("".$script_location."/temp/start_long_".str_replace("/dev/", "", $drive_name[$x]).".txt", "");
		}else if ($disk_start == 2 ){
			file_put_contents("".$script_location."/temp/start_short_".str_replace("/dev/", "", $drive_name[$x]).".txt", "");
		}
	}
	
	if (file_exists("$config_file")) {
		$data = file_get_contents("$config_file");
		$pieces = explode(",", $data);
	}

	//perform data verification of submitted values
	[$script_enable, $generic_error] = test_input_processing($_POST['script_enable'], "", "checkbox", 0, 0);
	
	[$next_scan_time_window, $next_scan_time_window_error] = test_input_processing($_POST['next_scan_time_window'], $pieces[1], "numeric", 1, 5);
	
	$myDate = date('m/d/Y');
	[$next_date, $smart_date_time_error] = test_input_processing($_POST['next_date'], $myDate, "date_slash", 1, 1);
	
	$myDate =  date("H:i:s");
	[$next_time, $smart_date_time_error] = test_input_processing($_POST['next_time'], $myDate, "time", 1, 1);
	
	[$enable_email_notifications, $generic_error] = test_input_processing($_POST['enable_email_notifications'], "", "checkbox", 0, 0);
	
	[$from_email_address, $from_email_error] = test_input_processing($_POST['from_email_address'], $pieces[3], "email", 0, 0);
	
	[$to_email_address, $smart_email_error] = test_input_processing($_POST['to_email_address'], $pieces[4], "email", 0, 0);
	
	[$next_scan_type, $generic_error] = test_input_processing($_POST['next_scan_type'], "", "checkbox", 0, 0);
	
	if ($_POST['NAS_name'] ==""){
		$NAS_name=php_uname('n');
	}else{
		[$NAS_name, $NAS_name_error] = test_input_processing($_POST['NAS_name'], $pieces[6], "name", 0, 0);
	}
	
	[$use_send_mail, $use_send_mail_error] = test_input_processing($_POST['use_send_mail'], $pieces[7], "numeric", 0, 2);
	  
	$put_contents_string="".$script_enable.",".$next_scan_time_window.",".$enable_email_notifications.",".$from_email_address.",".$to_email_address.",".$next_scan_type.",".$NAS_name.",".$use_send_mail."";
		  
	file_put_contents("$config_file",$put_contents_string );
	
	file_put_contents("".$config_file_location."/scan_window_tracker.txt",$next_scan_time_window );
	
	$new_epoc_time=strtotime("".$next_date." ".$next_time."");
	
	file_put_contents("".$config_file_location."/next_scan_time.txt",$new_epoc_time );
	$pieces = explode(" ", date("Y-m-d H:i:s", substr($new_epoc_time, 0, 10)));
	$next_date=$pieces[0];
	$next_time=$pieces[1];
	unset($_POST['submit_smart']);
	unset($_POST['randcheck']);
	header("Location: smart_scheduler_config.php");
    exit;
		  
}else{
	if (file_exists("$config_file")) {
		$data = file_get_contents("$config_file");
		$pieces = explode(",", $data);
			
		$script_enable=$pieces[0];
		$next_scan_time_window=$pieces[1];
		$enable_email_notifications=$pieces[2];
		$from_email_address=$pieces[3];
		$to_email_address=$pieces[4];
		$next_scan_type=$pieces[5];
		$NAS_name=$pieces[6];
		$use_send_mail=$pieces[7];
	}else{
		$script_enable=0;
		$next_scan_time_window=5;
		$enable_email_notifications=0;
		$from_email_address="email@email.com";
		$to_email_address="email@email.com";
		$next_scan_type=1;
		$NAS_name=php_uname('n');
		$use_send_mail=0;
		$put_contents_string="".$script_enable.",".$next_scan_time_window.",".$enable_email_notifications.",".$from_email_address.",".$to_email_address.",".$next_scan_type.",".$NAS_name.",".$use_send_mail."";
		  
		file_put_contents("$config_file",$put_contents_string );
	}
	
	if (file_exists("".$config_file_location."/next_scan_time.txt")) {
		$data = file_get_contents("".$config_file_location."/next_scan_time.txt");
		$pieces = explode(" ", date("Y-m-d H:i:s", substr($data, 0, 10)));
		$next_date=$pieces[0];
		$next_time=$pieces[1];
	}else{
		$next_date=date('m/d/Y');
		$next_time=date("H:i:s");
	}
}



if (file_exists("./logo.png")) {
	$logo = "./logo.png";
} else {
	$logo = "https://raw.githubusercontent.com/wallacebrf/Synology-SMART-test-scheduler/refs/heads/main/images/logo.png";
}

$rand=rand();
$_SESSION['rand']=$rand;	   
print "<br>
<fieldset>
	<legend>
		<h3>".$page_title."</h3>
	</legend>
	<table border=\"0\">
		<tr>
			<td>
				<table border=\"0\">
					<tr>
						<td><img src=\"$logo\" alt=\"Logo\" width=\"64\" height=\"64\"></td>
						<td>";
							if ($script_enable==1){
								print "<font color=\"green\"><h3>Script Status: Active</h3></font>";
							}else{
								print "<font color=\"red\"><h3>Script Status: Inactive</h3></font>";
							}
print "					</td>
					</tr>
				</table>
			</td>
		</tr>
		<tr>
			<td align=\"left\">
				<form action=\"".$form_submittal_destination."\" method=\"post\">
					<fieldset>
						<legend>
							<b>General Settings</b>
						</legend>
						<p><input type=\"checkbox\" name=\"script_enable\" value=\"1\" ";
						if ($script_enable==1){
							print "checked";
						}
						print ">Enable Entire Script?</p>
						<p>System Name: <input type=\"text\" maxlength=\"15\" size=\"15\" name=\"NAS_name\" value=".$NAS_name."><font size=\"1\">Leave Blank to Automatically set to System Name/Description</font>".$NAS_name_error."</p>
					</fieldset>
					<fieldset>
						<legend>
							<b>Email Notification Settings</b>
						</legend>	
						<p>Alert Email Recipient: <input type=\"text\" name=\"to_email_address\" value=".$to_email_address."><font size=\"1\">Separate Addresses by a semicolon</font> ".$smart_email_error."</p>
						<p>From Email: <input type=\"text\" name=\"from_email_address\" value=".$from_email_address."> ".$from_email_error."</p>
						<p><input type=\"checkbox\" name=\"enable_email_notifications\" value=\"1\" ";
						if ($enable_email_notifications==1){
							print "checked";
						}
						
print "					<p>Email Program : <select name=\"use_send_mail\">";
						if ($use_send_mail==0){
							print "<option value=\"0\" selected>Use ssmtp</option>
							<option value=\"1\">Use Mail Plus Server</option>
							<option value=\"2\">Use msmtp</option>";
						}else if ($use_send_mail==1){
							print "<option value=\"0\">Use ssmtp</option>
							<option value=\"1\" selected>Use Mail Plus Server</option>
							<option value=\"2\">Use msmtp</option>";
						}else if ($use_send_mail==2){
							print "<option value=\"0\">Use ssmtp</option>
							<option value=\"1\">Use Mail Plus Server</option>
							<option value=\"2\" selected>Use msmtp</option>";
						}
print "					</select></p>
					</fieldset>
					<fieldset>
						<legend>
							<b>Schedule Settings</b>
						</legend>
						<p>Next Scan Time : <input type=\"date\" id=\"next_date\" name=\"next_date\" value=".$next_date." min=\"2024-01-01\" max=\"2099-12-31\" /> <input type=\"time\" id=\"next_time\" name=\"next_time\" min=\"00:00\" max=\"23:59\" value=".$next_time." required />
						<p>Scan Window : <select name=\"next_scan_time_window\">";
						if ($next_scan_time_window==1){
							print "<option value=\"1\" selected>Daily</option>
							<option value=\"2\">Weekly</option>
							<option value=\"3\">Monthly</option>
							<option value=\"4\">Every 3-Months</option>
							<option value=\"5\">Every 6-Months</option>";
						}else if ($next_scan_time_window==2){
							print "<option value=\"1\">Daily</option>
							<option value=\"2\" selected>Weekly</option>
							<option value=\"3\">Monthly</option>
							<option value=\"4\">Every 3-Months</option>
							<option value=\"5\">Every 6-Months</option>";
						}else if ($next_scan_time_window==3){
							print "<option value=\"1\">Daily</option>
							<option value=\"2\">Weekly</option>
							<option value=\"3\" selected>Monthly</option>
							<option value=\"4\">Every 3-Months</option>
							<option value=\"5\">Every 6-Months</option>";
						}else if ($next_scan_time_window==4){
							print "<option value=\"1\">Daily</option>
							<option value=\"2\">Weekly</option>
							<option value=\"3\">Monthly</option>
							<option value=\"4\" selected>Every 3-Months</option>
							<option value=\"5\">Every 6-Months</option>";
						}else if ($next_scan_time_window==5){
							print "<option value=\"1\">Daily</option>
							<option value=\"2\">Weekly</option>
							<option value=\"3\">Monthly</option>
							<option value=\"4\">Every 3-Months</option>
							<option value=\"5\" selected>Every 6-Months</option>";
						}
print "					</select></p>

						<p>Scan Type : <select name=\"next_scan_type\">";
						if ($next_scan_type==0){
							print "<option value=\"0\" selected>One Drive At a Time Sequentially</option>
							<option value=\"1\">All Drives Concurrently</option>";
						}else if ($next_scan_type==1){
							print "<option value=\"0\">One Drive At a Time Sequentially</option>
							<option value=\"1\" selected>All Drives Concurrently</option>";
						}
print "					</select></p>
					</fieldset>	
					<fieldset>
						<legend>
							<b>Live Disk S.M.A.R.T. Status [Last Updated: ".$last_updated."]</b>
						</legend>";
						echo "<table border=\"1\">
						<tr>";
							if ($syno_check == 1){
								print "<td align=\"center\"><b>Synology Slot</b></td>";
							}
print "						<td align=\"center\"><b>Disk Name</b></td>
							<td align=\"center\"><b>Disk Model</b></td>
							<td align=\"center\"><b>Disk Serial</b></td>
							<td align=\"center\"><b>Test Status</b></td>
							<td align=\"center\"><b>Test Percent</b></td>
							<td align=\"center\"><b>Test Result</b></td>
							<td align=\"center\"><b>Disk Capacity</b></td>
							<td align=\"center\"><b>Smart Enabled</b></td>
						</tr>";
						for ($x = 0; $x < $number_drives; $x++) {
							
							echo "<tr>";
									if ($syno_check == 1){
										print "<td align=\"center\">".$drive_slot[$x]."</td>";
									}
print "								<td align=\"center\">".$drive_name[$x]."</td>
									<td align=\"center\">".$drive_model[$x]."</td>
									<td align=\"center\">".$drive_serial[$x]."</td>";
									if ($drive_test_status[$x] == 1){
										print "<td align=\"center\"><font color=\"blue\"><h4>ACTIVE</h4></font></td>";
									}else{
										print "<td align=\"center\">NOT ACTIVE</td>";
									}
print "								<td align=\"center\">".$drive_test_percent[$x]."</td>";
									if ($drive_test_pass_fail[$x] == "PASSED"){
										print "<td align=\"center\"><font color=\"green\">".$drive_test_pass_fail[$x]."</font></td>";
									}else {
										print "<td align=\"center\"><font color=\"red\">".$drive_test_pass_fail[$x]."</font></td>";
									}
print "								<td align=\"center\">".str_replace("User Capacity: ", "", "$drive_capacity[$x]")."</td>";
									if ($drive_smart_enabled[$x] == 1){
										print "<td align=\"center\"><font color=\"green\"><h4>ENABLED</h4></font></td>";
									}else{
										print "<td align=\"center\"><font color=\"red\"><h4>DISABLED</h4></font></td>";
									}
print "							</tr>";
						}
						

print "					</table></fieldset>	

						<fieldset>
						<legend>
							<b>Manual S.M.A.R.T Test Control</b>
						</legend>
						<table border=\"1\">
						<tr>";
							if ($syno_check == 1){
								print "<td align=\"center\"><b>Synology Slot</b></td>";
							}
print "						<td align=\"center\"><b>Disk Name</b></td>
							<td align=\"center\"><b>Cancel Test?</b></td>
							<td align=\"center\"><b>Manual Start Test?</b></td>
							<td align=\"center\"><b>Extended Test Duration (est</b>)</td>
							<td align=\"center\"><b>Short Test Duration (est</b>)</td>
						</tr>";
						for ($x = 0; $x < $number_drives; $x++) {
							$drive_duration_explode = explode(",", $drive_test_duration[$x]);
							print "<tr>";
							if ($syno_check == 1){
								print "<td align=\"center\">".$drive_slot[$x]."</td>";
							}
							print "<td align=\"center\">".$drive_name[$x]."</td>";
							if ($drive_smart_enabled[$x] == 1){
								if ($drive_test_status[$x] == 1){
											$test_started = substr(file_get_contents("".$script_location."/temp/".str_replace("/dev/", "", $drive_name[$x]).".txt"), 0, 10);
											print "<td align=\"center\"><input type=\"checkbox\" name=\"disk_".$x."_cancel\" value=\"1\"></td>
													<td align=\"center\"><font color=\"blue\"><h4>Test Started ".$test_started."</h4></font></td>
													<td bgcolor= \"a7abb0\"></td>
													<td bgcolor= \"a7abb0\"></td>";
								}else{
										print "<td align=\"center\">No Active Test</td>
										<td align=\"center\">
											<select name=\"disk_".$x."_start\">
												<option value=\"0\" selected></option>
												<option value=\"1\">Extended Test</option>
												<option value=\"2\">Short Test</option>
											</select>
										</td>
										<td align=\"center\">".$drive_duration_explode[0]."</td>
										<td align=\"center\">".$drive_duration_explode[1]."</td>";	
										
								}
							}else{
								print "<td align=\"center\"><font color=\"red\"><h4>Unavailable</h4></font></td><td align=\"center\"><font color=\"red\"><h4>Unavailable</h4></font></td><td align=\"center\"><font color=\"red\"><h4>Unavailable</h4></font></td><td align=\"center\"><font color=\"red\"><h4>Unavailable</h4></font></td>";
							}
print "						</tr>";	
						}
						
					
print "				</table></fieldset>	<center><input type=\"hidden\" value=\"".$rand."\" name=\"randcheck\" /><input type=\"submit\" name=\"submit_smart\" value=\"Submit\" /></center>
				</form>
				<fieldset>
					<legend>
						<b>HISTORY LOGS</b>
					</legend>";
				echo "".print_gallery_history("".$script_location."/log/history/")."";
				print "<fieldset>";
print "		</td>
		</tr>
	</table>
</fieldset>";
?>
