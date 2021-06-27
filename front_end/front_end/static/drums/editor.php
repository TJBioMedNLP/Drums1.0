<?php
require('../auth/sas.php');
?>


<html>
<head>
<title>Untitled Page</title>

<script type="text/javascript" src="../tinymce/jscripts/tiny_mce/tiny_mce.js"></script>
<script type="text/javascript">
	tinyMCE.init({
		mode : "textareas",
		theme : "advanced",
        theme_advanced_buttons2 : "image,paintwebEdit",

	});
</script>


</head>
<body bgcolor="#ffffff">


<?=$logout_button?>


</body>

<body onload=" resizeTextArea()" onresize=" resizeTextArea()"> 
<form method="post" action="submit.php">
<input type="submit" name="SUBMIT">
<textarea id="drums_editor" name="content" style="width: 100%; height: 100%">
<?php include('about.html'); ?>
</textarea>

</form>
                
             <script type="text/javascript">
                 function resizeTextArea() {
                     //Wrap your form contents in a div and get it's offset height
                     //var heightOfForm = document.getElementById('fromWrapper').offsetHeight;
                     var heightOfForm = 0;
                     
                     //Get Height of body (accounting for user installed toolbars)
                     var heightOfBody = document.body.clientHeight;
                     var buffer = 35; //Accounts for misc padding etc
                     //Set the height of the Text Area Dynamically
                     document.getElementById('drums_editor').style.height = 800;//(heightOfBody - heightOfForm) - buffer;
                     //NOTE: For extra pinnache' add onresize="resizeTextArea()" to the body
                 }
            </script>
            </body>


</html>