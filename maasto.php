
<!DOCTYPE HTML>
<html>
  <head>
    <title>OpenLayers Demo</title>
    <style type="text/css">
      html, body, #basicMap {
          width: 100%;
          height: 100%;
          margin: 0;
      }
    </style>
    <!-- <script src="http://www.openlayers.org/api/OpenLayers.js"></script> -->
    <script src="OpenLayers3.js"></script>
    <script src="MML.js"></script>
    <script>
      function init() {
        map = new OpenLayers.Map("basicMap");
        var mapnik         = new OpenLayers.Layer.OSM();
        var fromProjection = new OpenLayers.Projection("EPSG:4326");   // Transform from WGS 1984
        var toProjection   = new OpenLayers.Projection("EPSG:900913"); // to Spherical Mercator Projection
        var position       = new OpenLayers.LonLat(<?php echo $_GET['y'] ?>, <?php echo $_GET['x'] ?>).transform( fromProjection, toProjection);
        var zoom           = 15; 

	///map.addLayer(mapnik);
	var peruskartta = new OpenLayers.Layer.MML("Peruskartta", [
	    "http://tile1.kartat.kapsi.fi/1.0.0/peruskartta/${z}/${x}/${y}.png",
		"http://tile2.kartat.kapsi.fi/1.0.0/peruskartta/${z}/${x}/${y}.png"
		], {
		   numZoomLevels: 21,
		   		  sphericalMecator: true,
				  		    transitionEffect: 'resize'
						    });

						    var ortokuva = new OpenLayers.Layer.MML("Ortokuva", [
						    	"http://tile1.kartat.kapsi.fi/1.0.0/ortokuva/${z}/${x}/${y}.png",
								"http://tile2.kartat.kapsi.fi/1.0.0/ortokuva/${z}/${x}/${y}.png"
								], {
								   numZoomLevels: 21,
								   		  sphericalMecator: true,
										  		    transitionEffect: 'resize'
												    });

												    var taustakartta = new OpenLayers.Layer.MML("Taustakartta", [
												    	"http://tile1.kartat.kapsi.fi/1.0.0/taustakartta/${z}/${x}/${y}.png",
														"http://tile2.kartat.kapsi.fi/1.0.0/taustakartta/${z}/${x}/${y}.png"
														], {
														   numZoomLevels: 21,
														   		  sphericalMecator: true,
																  		    transitionEffect: 'resize'
																		    });
																		    
																		    map.addLayer(peruskartta);
																		    map.addLayer(ortokuva);
																		    map.addLayer(taustakartta);
        map.setCenter(position, zoom );
	map.addControl(new OpenLayers.Control.LayerSwitcher());
      }
    </script>
  </head>
  <body onload="init();">
    <div id="basicMap"></div>
  </body>
</html>
