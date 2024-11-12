<?php
//Version 11/12/2024
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
$script_location="/volume1/web/synology_smart";
$use_login_sessions=false; //set to false if not using user login sessions
$form_submittal_destination="smart_scheduler_config.php";
$page_title="Server2 S.M.A.R.T Scheduler";



///////////////////////////////////////////////////
//Beginning file, do not edit past this point
///////////////////////////////////////////////////
$config_file_location="".$script_location."/config";
$config_file_name="smart_control_config.txt";

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
}

$config_file="".$config_file_location."/".$config_file_name."";
error_reporting(E_NOTICE);
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
	
if(isset($_POST['submit_ups_monitor'])){
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
	
	[$NAS_name, $NAS_name_error] = test_input_processing($_POST['NAS_name'], $pieces[6], "name", 0, 0);
	
	[$use_send_mail, $use_send_mail_error] = test_input_processing($_POST['use_send_mail'], $pieces[7], "numeric", 0, 2);
	  
	$put_contents_string="".$script_enable.",".$next_scan_time_window.",".$enable_email_notifications.",".$from_email_address.",".$to_email_address.",".$next_scan_type.",".$NAS_name.",".$use_send_mail."";
		  
	file_put_contents("$config_file",$put_contents_string );
	
	file_put_contents("".$config_file_location."/scan_window_tracker.txt",$next_scan_time_window );
	
	$new_epoc_time=strtotime("".$next_date." ".$next_time."");
	
	file_put_contents("".$config_file_location."/next_scan_time.txt",$new_epoc_time );
	$pieces = explode(" ", date("Y-m-d H:i:s", substr($new_epoc_time, 0, 10)));
	$next_date=$pieces[0];
	$next_time=$pieces[1];
		  
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
		$NAS_name="NAS Name";
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
	   
print "<br>
<fieldset>
	<legend>
		<h3>$page_title</h3>
	</legend>
	<table border=\"0\">
		<tr>
			<td>";
				if ($script_enable==1){
					print "<font color=\"green\"><h3>Script Status: Active</h3></font>";
				}else{
					print "<font color=\"red\"><h3>Script Status: Inactive</h3></font>";
				}
print "		</td>
		</tr>
		<tr>
			<td align=\"left\">
				<form action=\"$form_submittal_destination\" method=\"post\">
					<fieldset>
						<legend>
							<b>General Settings</b>
						</legend>
						<p><input type=\"checkbox\" name=\"script_enable\" value=\"1\" ";
						if ($script_enable==1){
							print "checked";
						}
						print ">Enable Entire Script?</p>
						<p>System Name: <input type=\"text\" maxlength=\"15\" size=\"15\" name=\"NAS_name\" value=".$NAS_name.">".$NAS_name_error."</p>
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
						
						
					
					<center><input type=\"submit\" name=\"submit_ups_monitor\" value=\"Submit\" /></center>
				</form>
			</td>
		</tr>
	</table>
</fieldset>";
?>