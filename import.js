
var findit = require('findit');
var zlib = require('zlib');
var fs = require('fs');
var xml2js = require('xml2js');
var sys = require('sys');
var exec = require('child_process').exec;
var mysql = require('mysql');
var admzip = require('adm-zip');


/*
drop table kivet;
create table kivet(
gid bigint primary key,
x double,
y double,
wsg_x double,
wsg_y double,
wsg_r_x float,
wsg_r_y float);
create index kivet_wsg_r_xy on kivet (wsg_r_x, wsg_r_y);

*/

var connection = mysql.createConnection({host:"example.database.com", user:"example-user", password:"example", database:"example-database"});
connection.connect(function(err) {
    console.log("mysql connected");

    var files = findit.sync("./gml");
    console.log("files: ", files);

    (function nextFile(i) {
	if (i < 0) {
	    console.log("All files completed");
	    connection.destroy();
	    return;
	}
	var file = files[i];
	
	processZippedFile(file, function() {
	    nextFile(i - 1);
	});
    })(files.length - 1);

});




function processZippedFile(file, cb) {

    var zip = new admzip(file);
    var zipEntries = zip.getEntries();
    var i = 0;
    zipEntries.forEach(function (zipEntry) {
	if (i > 0) {
	    console.warn("Multiple files in one zip!", zipEntry.entryName, "in zip", file);
	    return;
	}
	i++;

	var buffer = zipEntry.getData();
	var parser = new xml2js.Parser();
	parser.on('end', function (result) {
	    if (result.Maastotiedot.kivet[0].Kivi) {
		processRocks(result.Maastotiedot.kivet[0].Kivi, cb);
	    } else {
		console.log("No rocks in", file);
		cb();
	    }
	});
	
	parser.on('error', function (err) {
	    console.log("Parser error", err);
	});
	
	if (buffer[0] != 60) {// '<'
	    for (var i = 0; i < 10; i++) {
		if (buffer[i] == 60) { // '<'
		    break;
		}
	    }
	    console.log("Slicing buffer, starting from", i);
	    buffer = buffer.slice(i);
	}
	console.log("Starting parsing of", buffer.length, "bytes from file", zipEntry.entryName);
	parser.parseString(buffer.toString());
    });

/*    var buffer = fs.readFileSync(file).slice(0);
    console.log("Starting parsing of", buffer.length, "bytes");

    
*/
}

function processRocks(rocks, cb) {
    console.log("Processing", rocks.length, "rocks");

    (function next(i) {
	if (i < 0) {
	    cb();
	    return;
	}

	processRock(rocks[i], function () {
	    next(i - 1);
	});
    })(rocks.length - 1);

}

function processRock(rock, done) {
    console.log("Rock", rock);
// Rock { '$': { gid: '425407209',
    var gid = rock['$']['gid'];
    var str = rock.sijainti[0].Piste[0]['gml:pos'][0]['_'];
    var parts = str.split(" ");
    var x = parts[1];
    var y = parts[0];
    console.log("coordinates", x, y);
    var cmd = "perl convert.pl " + x + " " + y;
    exec(cmd, function (error, stdout, stderr) {
	if (error) {
	    console.error("Error on cmd", cmd, error);
	}
	var wsg = stdout.split(" ");

	var data = {
	    gid : gid,
	    x : x,
	    y : y,
	    wsg_x : parseFloat(wsg[0]),
	    wsg_y : parseFloat(wsg[1]),
	    wsg_r_x : parseFloat(wsg[0]).toFixed(2),
	    wsg_r_y : parseFloat(wsg[1]).toFixed(2)
	};

	connection.query("INSERT INTO kivet SET ?", data, function (err, result) {
	    if (err) {
		console.error("Error on insert", data);
	    }
	    done();
	});
    });

}
