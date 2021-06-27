<?php
$fp = fopen( "about.html", "w" );

if(!$fp)
{echo "Couldn't open the data file. Try again later.";
exit;}

$content = $_POST['content']; 
$content = stripcslashes($content);
fwrite( $fp, $content );
fclose( $fp );
?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
<title>Your Page Title</title>
<meta http-equiv="REFRESH" content="3;url=../drums/editor.html"></HEAD>
<BODY>
The page would be redirected to main page in 3 secon.
</BODY>
</HTML>