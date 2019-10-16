# This is a **SIMPLE** and very basic powershell webserver
# Heavily modified version of https://gist.github.com/19WAS85/5424431
# NOTE: To end the loop you have to kill the powershell terminal. ctrl-c wont work :/
# NOTE: To add URL paths, you will need to stop and restart the entire powershell session.
# 2019-09-26 MODIFY — Change by @Repitah: GET and several if statements to switch
# 2019-09-27 MODIFY - Change by @Repitah: More dynamic server by reloading modules


#REGION Module loader
$ModulesBasePath = (Join-Path $PSScriptRoot "Modules" )
#$ModulesBasePath = (Join-Path ( Split-Path -Parent $MyInvocation.MyCommand.Path ) "Modules" )
if ( -not (($env:PSModulePath).split(';') -contains $ModulesBasePath)) {
	[Environment]::SetEnvironmentVariable("PSModulePath", ($env:PSModulePath + ';' + $ModulesBasePath) )

}

function reload-module {
Param(
			[Parameter(Mandatory=$true)]
			[string]$ModuleName
		)
		write-host ("Reloading " + $ModuleName)
		Remove-Module -Name $ModuleName -ErrorAction SilentlyContinue
		Import-Module -Name $ModuleName
}
#ENDREGION

function http_server() {
    # Http Server
    $http = [System.Net.HttpListener]::new() 
    # Hostname and port to listen on
    $http.Prefixes.Add("http://127.0.0.1:8080/")
    # Start the Http Server 
    $http.Start()

    # Log ready message to terminal 
    if ($http.IsListening) {
        write-host " HTTP Server Ready!  " -f 'black' -b 'gre'
    }

    # INFINTE LOOP
    # Used to listen for requests
    while ($http.IsListening) {
        # Get Request Url
        # When a request is made in a web browser the GetContext() method will return a request object
        # Our route examples below will use the request object properties to decide how to respond
        $context = $http.GetContext()
		
        
        if ($context.Request.HttpMethod -eq 'GET') {
			switch ($context.Request.RawUrl) {
				'/' {
					reload-module('Web_root')
					$html = webtoot_htmldoc
					$buffer = [System.Text.Encoding]::UTF8.GetBytes( $html) 
					$context.Response.ContentLength64 = $buffer.Length
					$context.Response.OutputStream.Write($buffer, 0, $buffer.Length) 
					$context.Response.OutputStream.Close()
				}
				'/AD_Issues' {
					reload-module('AD_Issues')
					$html = AD_Issues_htmldoc
					$buffer = [System.Text.Encoding]::UTF8.GetBytes( $html) 
					$context.Response.ContentLength64 = $buffer.Length
					$context.Response.OutputStream.Write($buffer, 0, $buffer.Length) 
					$context.Response.OutputStream.Close()
				}
				'/Tickets' {
					reload-module('Studio_Tickets')
					$html = tickets_htmldoc
					$buffer = [System.Text.Encoding]::UTF8.GetBytes( $html) 
					$context.Response.ContentLength64 = $buffer.Length
					$context.Response.OutputStream.Write($buffer, 0, $buffer.Length) 
					$context.Response.OutputStream.Close()
				}
				'/OpenNMS' {
					reload-module('OpenNMS_alarms')
					$html = OpenNMS_htmldoc
					$buffer = [System.Text.Encoding]::UTF8.GetBytes( $html) 
					$context.Response.ContentLength64 = $buffer.Length
					$context.Response.OutputStream.Write($buffer, 0, $buffer.Length) 
					$context.Response.OutputStream.Close()
				}
			}
		}
    } # powershell will continue looping and listen for new requests...
}
http_server