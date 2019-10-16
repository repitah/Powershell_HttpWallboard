#Module that server as the base/root page for the wallboard.
#Here you set your iframes or divs as you please to divide the wallboard up.

Function webtoot_htmldoc{
	$htmldoc = @'
<!DOCTYPE html>
<html>
<head><title>Wallboard</title>
<meta http-equiv="refresh" content="3000"/>
<meta http-equiv="cache-control" content="no-cache"/>
<style type="text/css">
html, body{
    margin: 0;
    padding: 0;
	overflow: hidden;

    min-width: 100%;
    width: 100%;
    max-width: 100%;

    min-height: 100%;
    height: 100%;
    max-height: 100%;
}
body {
	position:absolute;
	top:0;
	bottom:0;
	left:0;
	right:0;
	color: white; 
	background-color: black;
}
iframe {
	width: 100%; 
	height: 100%; 
	border: none; 
	padding: 0;
	margin: 0;
	overflow: hidden;
}
</style>
</head>
<body>
<div style="width: 100%; height: 45%;"><iframe src="Tickets"></iframe></div>
<div style="width: 100%; height: 25%;"><iframe src="AD_issues"></iframe></div>
<div style="width: 100%; height: 30%;"><iframe src="OpenNMS"></iframe></div>
</body></html>
'@
	return $htmldoc
}