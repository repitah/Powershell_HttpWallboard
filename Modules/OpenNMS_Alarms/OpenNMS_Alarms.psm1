#Module to poll OpenNMS and display outages that are not currently acknowledged.
$OPENNMS_CREDENTIAL = New-Object System.Management.Automation.PSCredential ("admin", (ConvertTo-SecureString "admin" -Force -AsPlainText)) #Note! These should be changed appropriately
$OPENNMS_URL = "http://10.1.14.130:8980/opennms/rest"

function OpenNMS_get_PendingAlarms{
	$thisURL = $OPENNMS_URL + "/alarms"
	Write-Host $thisURL
	$alarmcount = (Invoke-WebRequest -Uri ($thisURL + "/count") -ContentType "application/xml" -Credential $OPENNMS_CREDENTIAL).content
	if ($alarmcount -eq 0) { return $null }
	$alarmdetails = [xml] (Invoke-WebRequest -Uri ($thisURL + "?limit=0") -ContentType "application/xml" -Credential $OPENNMS_CREDENTIAL)
	$alarmdetails = $alarmdetails.alarms.alarm
		
	$retval = $alarmdetails | Where-Object -Property Severity -NE 'CLEARED' | ForEach-Object {
			[PSCustomObject]@{
				IpAddress = $_.ipAddress
				NodeLabel = $_.nodeLabel
				Message = (
					[system.String]::Join(" ", ([string]($_.LogMessage).split("`r")| ForEach-Object {$_.trim()}))
					).trim()
				time = Get-Date $_.LastEventTime
				Severity = $_.Severity
			}
	}
	if ($retval -eq $null) { return $null }
	return ($retval | Sort-Object -Property time)
}

Function OpenNMS_htmldoc{
	function OPENNMS_rowbuilder ($data){
		switch ($data.severity) {
			'Major' { $RowColour = "tomato"; break }
			'Minor' { $RowColour = "yellow"; break }
		}
		$row='<tr style="background-color:' + $RowColour + '">'
		$row+= '<td>' + (Get-Date $data.time -Format "MM/dd hh:mm")  + '</td>'
		$row+= '<td>' + $data.NodeLabel + '</td>'
		$row+= '<td>' + $data.ipAddress + '</td>'
		$row+= '<td>' + $data.Message + '</td>'
		$row+= '</tr>'
		return $row
	}
	
	$htmldoc = @'
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>User issue</title>
<meta http-equiv="refresh" content="60">
<meta HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE">
<style type="text/css">
body {background-color:black; color:white}
table, th, td {border: 1px solid black;}
table {font-family: Arial, Helvetica, sans-serif; border-collapse: collapse; Width:95%; margin: auto;}
thead {color: white; background-color: black; Font-Size: 2vw}
tbody {Font-Size: 1.5vw; color:black}
td {padding:3px;}
</style>
</head>
<body>
'@
	$alarms = $null
	$alarms = OpenNMS_get_PendingAlarms
	if ($alarms -ne $null) {
		$htmldoc += @'
<table><thead><tr><th>Time</th><th>Name</th><th>IP</th><th>Message</th></tr></thead><tbody>
'@
		$htmldoc += $alarms | ForEach-Object { OPENNMS_rowbuilder $_ }
		$htmldoc += "</tbody></table>"
	}
	$htmldoc += "</body></html>"
	return $htmldoc
}