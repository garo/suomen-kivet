use 5.008006;
use strict;
#use warnings;
use Carp;
use Math::Trig;

sub new {
    my $class = shift;
    
    my $self = {};

    bless($self, $class);

    # Constants used in calculations transforming between WGS84 and ETRS-TM35FIN 
    add_constant($self, 'Ca', 6378137.0);
    add_constant($self, 'Cb', 6356752.314245);
    add_constant($self, 'Cf', 1.0 / 298.257223563);
    add_constant($self, 'Ck0', 0.9996);
    add_constant($self, 'Clo0', Math::Trig::deg2rad(27.0));
    add_constant($self, 'CE0', 500000.0);
    add_constant($self, 'Cn', get_c($self, 'Cf') / (2.0 - get_c($self, 'Cf')));
    add_constant($self, 'CA1', get_c($self, 'Ca') / (1.0 + get_c($self, 'Cn')) * (1.0 + (get_c($self, 'Cn') ** 2.0) / 4.0 + (get_c($self, 'Cn') ** 4.0) / 64.0));
    add_constant($self, 'Ce', sqrt(2.0 * get_c($self, 'Cf') - get_c($self, 'Cf') ** 2.0));
    add_constant($self, 'Ch1', 1.0/2.0 * get_c($self, 'Cn') - 2.0/3.0 * (get_c($self, 'Cn') ** 2.0) + 37.0/96.0 * (get_c($self, 'Cn') ** 3.0) - 1.0/360.0 * (get_c($self, 'Cn') ** 4.0));
    add_constant($self, 'Ch2', 1.0/48.0 * (get_c($self, 'Cn') ** 2.0) + 1.0/15.0 * (get_c($self, 'Cn') ** 3.0) - 437.0/1440.0 * (get_c($self, 'Cn') ** 4.0));
    add_constant($self, 'Ch3', 17.0/480.0 * (get_c($self, 'Cn') ** 3.0) - 37.0/840.0 * (get_c($self, 'Cn') ** 4.0));
    add_constant($self, 'Ch4', 4397.0/161280.0 * (get_c($self, 'Cn') ** 4.0));
    add_constant($self, 'Ch1p', 1.0/2.0 * get_c($self, 'Cn') - 2.0/3.0 * (get_c($self, 'Cn') ** 2.0) + 5.0/16.0 * (get_c($self, 'Cn') ** 3.0) + 41.0/180.0 * (get_c($self, 'Cn') ** 4.0));
    add_constant($self, 'Ch2p', 13.0/48.0 * (get_c($self, 'Cn') ** 2.0) - 3.0/5.0 * (get_c($self, 'Cn') ** 3.0) + 557.0/1440.0 * (get_c($self, 'Cn') ** 4.0));
    add_constant($self, 'Ch3p', 61.0/240.0 * (get_c($self, 'Cn') ** 3.0) - 103.0/140.0 * (get_c($self, 'Cn') ** 4.0));
    add_constant($self, 'Ch4p', 49561.0/161280.0 * (get_c($self, 'Cn') ** 4.0));

    # WGS84 bounds (ref. http://spatialreference.org/ref/epsg/3067/)
    add_constant($self, 'WGS84_min_la', "59.3000");
    add_constant($self, 'WGS84_max_la', "70.1300");
    add_constant($self, 'WGS84_min_lo', "19.0900");
    add_constant($self, 'WGS84_max_lo', "31.5900");

    # ETRS-TM35FIN bounds (ref. http://spatialreference.org/ref/epsg/3067/)
    add_constant($self, 'ETRSTM35FIN_min_x', "6582464.0358");
    add_constant($self, 'ETRSTM35FIN_max_x', "7799839.8902");
    add_constant($self, 'ETRSTM35FIN_min_y', "50199.4814");
    add_constant($self, 'ETRSTM35FIN_max_y', "761274.6247");
    
    return $self;
}

sub add_constant {
    my ($class, $constant_name, $constant_value) = @_;
    
    $class->{$constant_name} = $constant_value;
    
    return;
}

sub get_constant {
    my ($class, $constant_name) = @_;
    
    return $class->{$constant_name};
}

# Alias for get_constant

sub get_c {
    my ($class, $constant_name) = @_;
    
    return get_constant($class, $constant_name);
}

sub is_defined_ETRSTM35FINxy {
    my @params = @_;
    my ($class, $etrs_x, $etrs_y) = @params;
    
    if (scalar(@params) != 3) {
	croak 'Geo::Coordinates::ETRSTM35FIN::is_defined_ETRSTM35FINxy needs two arguments';
    }

    if (($etrs_x >= get_c($class, 'ETRSTM35FIN_min_x')) and ($etrs_x <= get_c($class, 'ETRSTM35FIN_max_x')) and
	($etrs_y >= get_c($class, 'ETRSTM35FIN_min_y')) and ($etrs_y <= get_c($class, 'ETRSTM35FIN_max_y'))) {
	# Is in bounds
	return 1;
    }
    
    return;
}

sub is_defined_WGS84lalo {
    my @params = @_;
    my ($class, $wgs_la, $wgs_lo) = @params;
    
    if (scalar(@params) != 3) {
	croak 'Geo::Coordinates::ETRSTM35FIN::is_defined_WGS84lalo needs two arguments';
    }

    if (($wgs_la >= get_c($class, 'WGS84_min_la')) and ($wgs_la <= get_c($class, 'WGS84_max_la')) and
	($wgs_lo >= get_c($class, 'WGS84_min_lo')) and ($wgs_lo <= get_c($class, 'WGS84_max_lo'))) {
	# Is in bounds
	return 1;
    }
    
    return;
}

sub ETRSTM35FINxy_to_WGS84lalo {
    my @params = @_;
    my ($class, $etrs_x, $etrs_y) = @params;

    if (scalar(@params) != 3) {
	croak 'Geo::Coordinates::ETRSTM35FIN::ETRSTM35FINxy_to_WGS84lalo needs two arguments'
    }

    if (!is_defined_ETRSTM35FINxy($class,$etrs_x, $etrs_y)) {
	return (undef, undef);
    }
    
    my $E = $etrs_x / (get_c($class,'CA1') * get_c($class,'Ck0'));
    my $nn = ($etrs_y - get_c($class,'CE0')) / (get_c($class,'CA1') * get_c($class,'Ck0'));
  
    my $E1p = get_c($class,'Ch1') * sin(2.0 * $E) * Math::Trig::cosh(2.0 * $nn);
    my $E2p = get_c($class,'Ch2') * sin(4.0 * $E) * Math::Trig::cosh(4.0 * $nn);
    my $E3p = get_c($class,'Ch3') * sin(6.0 * $E) * Math::Trig::cosh(6.0 * $nn);
    my $E4p = get_c($class,'Ch4') * sin(8.0 * $E) * Math::Trig::cosh(8.0 * $nn);
    my $nn1p = get_c($class,'Ch1') * cos(2.0 * $E) * Math::Trig::sinh(2.0 * $nn);
    my $nn2p = get_c($class,'Ch2') * cos(4.0 * $E) * Math::Trig::sinh(4.0 * $nn);
    my $nn3p = get_c($class,'Ch3') * cos(6.0 * $E) * Math::Trig::sinh(6.0 * $nn);
    my $nn4p = get_c($class,'Ch4') * cos(8.0 * $E) * Math::Trig::sinh(8.0 * $nn);
    my $Ep = $E - $E1p - $E2p - $E3p - $E4p;
    my $nnp = $nn - $nn1p - $nn2p - $nn3p - $nn4p;
    my $be = Math::Trig::asin(sin($Ep) / Math::Trig::cosh($nnp));
  
    my $Q = Math::Trig::asinh(Math::Trig::tan($be));
    my $Qp = $Q + get_c($class,'Ce') * Math::Trig::atanh(get_c($class,'Ce') * Math::Trig::tanh($Q));
    $Qp = $Q + get_c($class,'Ce') * Math::Trig::atanh(get_c($class,'Ce') * Math::Trig::tanh($Qp));
    $Qp = $Q + get_c($class,'Ce') * Math::Trig::atanh(get_c($class,'Ce') * Math::Trig::tanh($Qp));
    $Qp = $Q + get_c($class,'Ce') * Math::Trig::atanh(get_c($class,'Ce') * Math::Trig::tanh($Qp));
    
    my $wgs_la = Math::Trig::rad2deg(Math::Trig::atan(Math::Trig::sinh($Qp)));
    my $wgs_lo = Math::Trig::rad2deg(get_c($class,'Clo0') + Math::Trig::asin(Math::Trig::tanh($nnp) / cos($be)));

    return ($wgs_la, $wgs_lo);
}


my $i = new();
my ($x, $y) = $i->ETRSTM35FINxy_to_WGS84lalo($ARGV[0], $ARGV[1]);

print "$x $y\n";
