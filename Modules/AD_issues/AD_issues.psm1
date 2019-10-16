#Module to poll Active Directory (host must be joined to AD) and display AccountExpired, LockedOut and ExpiredPasswords in that order
$AD_USER_SearchBase = "OU=Main User OU,DC=ACME,DC=CO"
$ADaccess_USER = "" #An AD user account (service account)
$ADaccess_PASSWORD = ConvertTo-SecureString -Force -AsPlainText "" #Beware of the plaintext password for tthe 
$ADCredential = New-Object System.Management.Automation.PsCredential($ADaccess_USER,$ADaccess_PASSWORD)

function AD_get_expiredAccount{
	$Today = Get-Date
	$ADUsers = Search-ADAccount -AccountExpired -Credential $ADCredential | Where-Object {$_.Enabled -eq $true}
	#Get-ADUser -Filter  {(Enabled -eq $True) -and (AccountExpirationDate -lt $Today)} -Properties AccountExpirationDate -SearchBase $AD_USER_SearchBase
	return $ADUsers
}

function AD_get_lockedout{
	$ADUsers = Search-ADAccount -LockedOut -Credential $ADCredential | Where-Object {$_.Enabled -eq $true}
	return $ADUsers
}

function AD_get_expiredPassword{
	#$ADUsers = Search-ADAccount -PasswordExpired -Credential $ADCredential | Where-Object {$_.Enabled -eq $true}
	$ADUsers = Get-ADUser -Credential $ADCredential -Filter * -Properties PasswordExpired -SearchBase $AD_USER_SearchBase | Where {$_.PasswordExpired -eq $True} | Where-Object {$_.Enabled -eq $true}
	return $ADUsers
}

Function AD_Issues_htmldoc{
	function AD_issue_rowbuilder{
		Param(
			[Parameter(Mandatory=$true)]
			[string]$DistinguishedName,
			[Parameter(Mandatory=$true)]
			[string]$ADproblem,
			[Parameter(Mandatory=$true)]
			[string]$RowColour
		)
		$excludeOU = "Mustek Users"
		
		$thisUser = $null
		$thisUserOU = New-Object Collections.Generic.List[String]
		
		$DistinguishedName.Split(',') | ForEach-Object { 
			$container = $_.Split('=')	
			switch ($container[0]){
				'CN' {
					if ($thisUser -eq $null){
						$thisUser = $container[1]
					} else {
						$thisUserOU.Insert(0,$container[1])
					}
				}
				'OU' {if (-not ($container[1] -eq $excludeOU)) { $thisUserOU.Insert(0,$container[1]) } }
			}
		}
		$row='<tr style="background-color:' + $RowColour + '"><td>' + $ADproblem  + '</td><td>' + [String]::Join("\",$thisUserOU) + '</td><td style="font-weight: bold">' + $thisUser + '</td></tr>'
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
thead {color: white; background-color: black; Font-Size: 10pt;}
tbody {Font-Size: 14pt; color:black}
td {padding:3px;}
</style>
</head>
<body>
'@
	$rows = ''
	AD_get_expiredAccount | ForEach-Object {
		$rows += (AD_issue_rowbuilder -DistinguishedName $_.DistinguishedName -RowColour "Tomato" -ADproblem "Expired User")
	}

	AD_get_LockedOut | ForEach-Object {
		$rows += (AD_issue_rowbuilder -DistinguishedName $_.DistinguishedName -RowColour "Violet" -ADproblem "Locked")
	}

	AD_get_expiredPassword | ForEach-Object {
		$rows += (AD_issue_rowbuilder -DistinguishedName $_.DistinguishedName -RowColour "yellow" -ADproblem "Password Expired")
	}
	
	if ($rows -ne '') {
		$htmldoc += "<table><thead><tr><th>Type</th><th>OU</th><th>Name</th></tr></thead><tbody>"
		$htmldoc += $rows
		$htmldoc += "</tbody></table></body></html>"
	}
	return $htmldoc
}