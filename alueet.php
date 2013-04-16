<?php
header("Cache-Control: no-cache, must-revalidate"); // HTTP/1.1
header("Expires: Sat, 26 Jul 1997 05:00:00 GMT"); // Date in the past

include('datastore.inc');

$handle = get_mysql_db_handle();

?><!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no">
    <meta charset="utf-8">
    <title>Google Maps JavaScript API v3 Example: Marker Simple</title>
    <link href="https://developers.google.com/maps/documentation/javascript/examples/default.css" rel="stylesheet">
    <script src="https://maps.googleapis.com/maps/api/js?v=3.exp&sensor=false"></script>
    <script>
      function initialize() {
        var myLatlng = new google.maps.LatLng(60.8,25.127979);
        var mapOptions = {
          zoom: 8,
          center: myLatlng,
          mapTypeId: google.maps.MapTypeId.ROADMAP
        }
        var map = new google.maps.Map(document.getElementById('map-canvas'), mapOptions);

<?php
  $limit = (int) $_GET['limit'];
  if (!$limit) {
    $limit = 15;
  } 
  $res = mysql_query("select wsg_r_x, wsg_r_y, count(*) as c from kivet group by wsg_r_x, wsg_r_y having count(*) > $limit order by count(gid)", $handle);
  if (!$res) {
    error_log("no res");
    error_log(mysql_error());
    return null;
  }

  while ($row = mysql_fetch_array($res, MYSQL_ASSOC)) {
?>
        var marker = new google.maps.Marker({
            position: new google.maps.LatLng(<?php echo $row['wsg_r_x']; ?>, <?php echo $row['wsg_r_y']; ?>),
            map: map,
	    url : "http://www.juhonkoti.net/suomen-kivet/maasto.php?x=<?php echo $row['wsg_r_x']; ?>&y=<?php echo $row['wsg_r_y']; ?>",
            title: 'Total <?php echo $row['c']; ?> rocks in this area'
        });

	google.maps.event.addListener(marker, 'click', function() {
		window.location.href = this.url;
	});

<?php
	}
?>
      }
    </script>
  </head>
  <body onload="initialize()">
    <div id="map-canvas"></div>
  </body>
</html>
