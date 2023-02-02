#!/usr/bin/env perl

# Name: Sortation
# Purpose: Sorting MPNs
# Author: Andras Kelemen, Miroslaw Duraj
# Date: 29/Feb/2020
$version = '-2.5';

#use strict;
use Term::ANSIColor;
#use warnings;
use v5.10; # for say() function
use Time::Piece;
use File::Basename ();

$dir = File::Basename::dirname($0);
$logfile = "$0.log";
$time = localtime->datetime;
 
use DBI;
say "Perl MySQL Connect Database";
# MySQL database configuration
$dsn0 = "DBI:mysql:general:172.30.1.199";
$dsn = "DBI:mysql:p3:172.30.1.199";
$username = "p3user";
$password = 'p3user';

#######
#######
#######

$stn = substr(`system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'`,30,12);

system ("echo '$time\tSortation tool started\n' >> $logfile");

system "clear";
$dbh = DBI->connect($dsn0,$username,$password, \%attr) or handle_error (DBI::errstr);

check_sn($dbh);

$dbh->disconnect();
##########ADDED

$line = '';

check_line();
	
##########END

###################################################################### SCAN START

RESET:

if (index($stn, "SORTATION-IN") != -1)
	{
		goto SCANUPC;
	}
elsif (index($stn, "SORTATION-OUT") != -1)
	{
		goto SORTATION;
	}
else
	{
		print color('bold red');
		print "Station has not been set up yet. Contact Supervisor!\n";
		print color('reset');
		print "Press Enter to close...";
		<>;
		exit;
	}
	
SCANUPC:

$UPC = '';
$UPC_len = '';
$indicator2 = '';
$qty_max = '';
$result_qty = '';
$mpn_upc = '';

while (1)
{
	system clear;
	print color('bold green');
	print "Sortation$version - $stn\n";
	print color('reset');
	
	$dbh = DBI->connect($dsn,$username,$password, \%attr) or handle_error (DBI::errstr);
	check_setup($dbh);

	print("Scan UPC of the unit: ");

	chomp ($UPC = <>);
	$UPC = uc($UPC);

	$UPC_len = length $UPC;

	if ($UPC =~ /\D/ || $UPC_len != 12)
	{
		print color('red');
		print("Not valid UPC code. Try again...\n");
		system ("afplay '$dir/wrongansr.wav'");
		sleep 3;
		system ("echo '$time\t$UPC : Not valid UPC code\n' >> $logfile");
		goto SCANUPC;
	} else {
	
		check_qty_max($dbh);
		if ($result_qty == 1)
		{
			print color('bold red');
			print("UPC not found in database!\n");
			print color('reset');
			print "Contact your Supervisor.\n";
			system ("afplay '$dir/wrongansr.wav'");
			sleep 3;
			system ("echo '$time\t$UPC not found in database\n' >> $logfile");
			goto SCANUPC;
		}
		
		check_sort_loc($dbh);

		if ($location eq '') 
		{
			$dbh = DBI->connect($dsn,$username,$password, \%attr) or handle_error (DBI::errstr);
			check_first_loc($dbh);
			$indicator2 = 'empty';
			$qty_slot = $qty_max;
		}
		goto SCANSERIAL;
	}
}

SCANSERIAL:

$serial = '';
$serial_len = '';
$serial_first = '';

while (1)
{
	system "clear";
	print color('bold green');
	print "Sortation$version - $stn\n";
	print color('reset');

	print("Scan SERIAL NUMBER of the unit or press 'COMPLETE' to go back: ");
	chomp ($serial = <>);
	$serial = uc($serial);
	
	$serial_len = length $serial;
	$serial_first = substr($serial, 0, 1);
	
	if ($serial eq "COMPLETE")
	{
		goto SCANUPC;
	}
	elsif ($serial_first ne "S" || $serial_len != 13)
	{
		print color('bold red');
		print("No valid Serial number. Try again...\n");
		print color('reset');
		system ("afplay '$dir/wrongansr.wav'");
		sleep 3;
		system ("echo '$time\t$serial : No valid Serial number. Try again...\n' >> $logfile");
		goto SCANSERIAL; 
	} else {
		goto SORT;
	}
}

SORT:

$validate = '';

while (1) {

$dbh = DBI->connect($dsn,$username,$password, \%attr) or handle_error (DBI::errstr);
check_sn_in_sort($dbh);

	if ($result ne '')
	{
		print color('bold red');
		print "Serial $serial has already been scanned to location $result.\n";
		print color('reset');
		system ("afplay '$dir/wrongansr.wav'");
		sleep 1;
		print "Contact your Supervisor immediately\n";
		print "Press Enter to continue...";
		<>;
		system ("echo '\n$time\t$serial : SERIAL already present\n' >> $logfile");
		goto SCANUPC;
	}
	
	print color('bold green');
	print "Place unit $serial into location ";print color("bold blue");print "$location";print color('bold green');print " and scan the location to confirm: ";
	print color('reset');
		
	chomp ($validate = <>);
	$validate = uc($validate);
	
	if ($validate eq 'COMPLETE')
	{
		goto RESET;
	}
		
	if ($validate ne $location)
	{
		system ("echo 'Incorrect location scanned: \n$time\t$serial\t$location\t$validate\n' >> $logfile");

		print color('bold red');
		print "Incorrect location scanned, resetting!\n";
		print color('reset');
		system ("afplay '$dir/wrongansr.wav'");
		print "Press Enter to continue...\n";
		<>;
		goto SCANUPC;
	}
	
if ($indicator2 eq 'empty')
	{
		$dbh = DBI->connect($dsn,$username,$password, \%attr) or handle_error (DBI::errstr);
		update_first_empty($dbh);
	}
else
	{
		$dbh = DBI->connect($dsn,$username,$password, \%attr) or handle_error (DBI::errstr);
		update_first_open($dbh);
	}
	
$dbh = DBI->connect($dsn,$username,$password, \%attr) or handle_error (DBI::errstr);
insert_serial($dbh);

system ("echo '___Added: \n$time\t$stn\t$serial\t$location\n\n' >> $logfile");

print color('bold green');
print "\nItem added to location!";
print color('reset');

system ("afplay '$dir/rightansr.wav'");
sleep 1;

check_version();

goto SCANUPC;

}

SORTATION:

$location = '';
$first_6 = '';
$quantity = '';
$status = '';
$serial = '';
$indicator_open = '';

while (1)
{
system clear;
print color('bold green');
print "Sortation$version - $stn\n";
print color('reset');

$dbh = DBI->connect($dsn,$username,$password, \%attr) or handle_error (DBI::errstr);
display_sortation($dbh);


print("Scan location you want to clear: ");

chomp ($location = <>);
$location = uc($location);
$first_8 = substr($location,0,8);

if ($location eq '')
	{
		print color('red');
		print "No location scanned...Restarting\n";
		system ("afplay '$dir/wrongansr.wav'");
		sleep 1;
		goto SORTATION;
	
	} elsif ($location eq 'REFRESH') {
		$indicator = "REFRESH";
		goto SORTATION;
	
	} elsif ($location eq 'REFRESH_FULL') {
		$indicator = 'REFRESH_FULL';
		goto SORTATION;		
	
	} elsif ($first_8 ne $location_type) {
		system ("afplay '$dir/wrongansr.wav'");
		print color('bold red');
		print "Wrong value scanned. Scan again. Press Enter to continue...\n";
		<>;
		goto SORTATION;

	}

$dbh = DBI->connect($dsn,$username,$password, \%attr) or handle_error (DBI::errstr);
check_loc($dbh);

if ($status eq 'EMPTY')
	{
		print color('bold red');
		print "Location should be empty. If not contact your Supervisor\n";
		print color('reset');
		system ("afplay '$dir/wrongansr.wav'");
		print "Press Enter to Continue...";
		system ("echo '\n$time\t$location : LOCATION should be empty\n' >> $logfile");
		<>;
		goto SORTATION;
	
	}
	elsif ($status ne 'FULL')
	{
		print "Location is not FULL. Press 'Y' to continue or any other key to cancel: ";
		
		chomp ($confirm = <>);
		$confirm = uc($confirm);
		
		if ($confirm ne 'Y')
			{
				print color('red');
				print "Aborted.\n";
				print color('reset');
				sleep 1;
				goto SORTATION;
			}
		$dbh = DBI->connect($dsn,$username,$password, \%attr) or handle_error (DBI::errstr);
		change_status_to_full($dbh);
		$indicator_open = 1;
	} 
	
	goto CLEAR;
}

CLEAR:

$serial = '';
$serial_len = '';
$serial_first = '';

while(1)
{
	print("Scan one of the serial numbers from location $location or scan COMPLETE to cancel: ");
	chomp ($serial = <>);
	$serial = uc($serial);
	
	$serial_len = length $serial;
	$serial_first = substr($serial, 0, 1);
	
	if ($serial eq 'COMPLETE')
	{
		if ($indicator_open == 1)
		{
			$dbh = DBI->connect($dsn,$username,$password, \%attr) or handle_error (DBI::errstr);
			change_status_to_open($dbh);
			$indicator_open = '';
		}
		goto SORTATION;
	}
	
	if ($serial_first ne "S" || $serial_len != 13)
	{
		print("No valid serial number. Try again...\n");
		system ("afplay '$dir/wrongansr.wav'");
		sleep 2;
		system ("echo '$time\t$serial : Invalid SERIAL scan\n' >> $logfile");
		goto CLEAR; 
	}
	
$dbh = DBI->connect($dsn,$username,$password, \%attr) or handle_error (DBI::errstr);
check_sn_in_sort($dbh);

	if ($result eq '')
	{
		system ("afplay '$dir/wrongansr.wav'");
		print color('bold red');
		print "No location found for serial $serial\n";
		print color('reset');
		print "Press Enter to scan another location...";
		system ("echo '$time\t$serial : No location found\n' >> $logfile");
		<>;
		
		if ($indicator_open == 1)
		{
			$dbh = DBI->connect($dsn,$username,$password, \%attr) or handle_error (DBI::errstr);
			change_status_to_open($dbh);
		}
		
		goto SORTATION;
		
	}
	elsif ($result ne $location)
	{
		print color('bold red');
		print "This serial number does not belong to this slot! Contact your Supervisor.\n";
		print color('reset');
		system ("afplay '$dir/wrongansr.wav'");
		print "Press Enter to continue...";
		system ("echo '$time\t$serial : SERIAL does NOT belong to this LOCATION\n' >> $logfile");
		<>;
		if ($indicator_open == 1)
		{
			$dbh = DBI->connect($dsn,$username,$password, \%attr) or handle_error (DBI::errstr);
			change_status_to_open($dbh);
		}
		goto SORTATION;
	}
	
print "Press Enter once you have taken all units from location $location\n";
<>;

$dbh = DBI->connect($dsn,$username,$password, \%attr) or handle_error (DBI::errstr);
clear_sortation($dbh);

system ("echo '$time\t$serial\t$location : Sortation cleared\n' >> $logfile");

print color('bold green');
print "Location $location has been cleared.\n";
print color('reset');
system ("afplay '$dir/rightansr.wav'");
sleep 2;
print "Please print GS1 label in Oryx, press enter to continue...\n";
<>;

check_version();

goto SORTATION;
	
}


#sub routines
sub change_status_to_open{
	# query from the links table
    ($dbh) = @_;
    $sql = "UPDATE SORTATION SET STATUS='OPEN'
	WHERE LOCATION = '$location'";
    $sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
   
    $sth->finish;
}

sub change_status_to_full{
	# query from the links table
    ($dbh) = @_;
    $sql = "UPDATE SORTATION SET STATUS='FULL'
	WHERE LOCATION = '$location'";
    $sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
   
    $sth->finish;
}

sub check_line{

	my ($str_begin ,$str_end , $nth_begin, $nth_end, $find, $p_begin, $p_end, $p);

	$str_begin = $stn;
	$str_end = $stn;
	$nth_begin = 1; $find = '_'; $nth_end = $nth_begin+1;

	$str_begin =~ m/(?:.*?$find){$nth_begin}/g;
	$str_end =~ m/(?:.*?$find){$nth_end}/g;
	$p_begin = pos($str_begin) - length($find) +1;
	$p_end = pos($str_end) - length($find);
	$p = ($p_end - $p_begin);

	$line = substr($str_begin, $p_begin, 4) if $p_begin>-1;
	
	if ($line eq '')
	{
		system ("afplay '$dir/redalert.wav' &");
		system ("echo '$time\tWrong format of station setup\n' >> $logfile");
		print color('bold red');
		print "Wrong format of station setup.\n"; print color('reset');
		print "Contact Supervisor.\nPress Enter to close...";
		<>;
		exit;
	}
}

sub check_qty_max{
	$mpn_upc = '';
	$type_upc = '';
	$qty_max = '';
	# query from the links table
    ($dbh) = @_;
    $sql = "SELECT mpn,type,qty_max FROM mpn_bom
	WHERE UPC =('$UPC')";
    $sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
   
    my $ref;
    
    $ref = $sth->fetchall_arrayref([]);
    
    #print "Number of rows returned is ", 0 + @{$ref}, "\n";    
    if ((0 + @{$ref}) > 0)
    {
        foreach $data (@$ref)
        {
            ($mpn_upc, $type_upc, $qty_max) = @$data;
        }
        $result_qty = 0;
    }
    else
    {
	    $result_qty = 1;
    }
      $sth->finish;
}

sub display_sortation{

	if ($indicator eq 'REFRESH' || $indicator eq '')
	{
		$sql = "SELECT LOCATION, QUANTITY, STATUS, MPN FROM SORTATION
		WHERE LINE='$line' AND STATUS NOT LIKE 'EMPTY'";
	} elsif ($indicator eq 'REFRESH_FULL') {
		$sql = "SELECT LOCATION, QUANTITY, STATUS, MPN FROM SORTATION
		WHERE LINE='$line' AND STATUS = 'FULL'";
	}

	# query from the links table
	($dbh) = @_;
	
	$sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
	
	my $ref;
    
    $ref = $sth->fetchall_arrayref([]);
    
    #print "Number of rows returned is ", 0 + @{$ref}, "\n";    
    if ((0 + @{$ref}) > 0)
    {
    	print "|LOCATION\tQTY\tSTATUS\tMPN\t   |\n";
        foreach $data (@$ref)
        {
            ($location,$quantity,$status,$mpn) = @$data;
            print "|$location\t$quantity\t$status\t$mpn  |\n";
        }
    $location_type = substr($location,0,8);
	
    } else {
    	print color('bold red');
    	print "No locations available\n";
		print color('reset');
		system ("afplay '$dir/wrongansr.wav'");
		print "Press Enter to continue...";
		<>;
		$indicator = '';
    	goto SORTATION;
    }
	
    $sth->finish;
}

sub clear_sortation{
	# query from the links table
	($dbh) = @_;
	$sql = "UPDATE SORT_LOC SET location='',date_out=CURRENT_TIMESTAMP
	WHERE LOCATION = '$location'";
	$sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
	
	$sql = "UPDATE SORTATION SET UPC=NULL,QUANTITY='0',STATUS='EMPTY',last_change=NULL,qty_max=0,mpn=NULL
	WHERE LOCATION = '$location'";
    $sth = $dbh->prepare($sql);
    $sth->execute();
        
    $sth->finish;
}

sub check_loc{
	# query from the links table
    ($dbh) = @_;
    $sql = "SELECT STATUS FROM SORTATION
	WHERE LOCATION = '$location'";
    $sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
   
    my $ref;
    
    $ref = $sth->fetchall_arrayref([]);
    
   # print "Number of rows returned is ", 0 + @{$ref}, "\n";    
    if ((0 + @{$ref}) > 0)
    {
        foreach $data (@$ref)
        {
            ($status) = @$data;
        }
    }
    else
    {
	  	print color('bold red');
	  	print "ERROR: Location does not exist. Contact your Supervisor!\n";
	  	print color ('reset');
	  	system ("afplay '$dir/wrongansr.wav'");
	  	print "Press ENTER to continue...";
	  	<>;
	    goto SORTATION;
    }
      $sth->finish;
}

sub check_first_loc{
    # query from the links table
    ($dbh) = @_;
    $sql = "SELECT LOCATION, QUANTITY FROM SORTATION
	WHERE LOCATION LIKE 'P3SORT%' AND LINE='$line' AND STATUS = 'EMPTY' AND loc_status = 'LIVE' LIMIT 1";
    $sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
   
    my $ref;
    
    $ref = $sth->fetchall_arrayref([]);
    
    #print "Number of rows returned is ", 0 + @{$ref}, "\n";    
    if ((0 + @{$ref}) > 0)
    {
        foreach $data (@$ref)
        {
            ($location) = @$data;
        }
    }
    else
    {
	  	print color('bold red');
	  	print "ERROR: No available locations. Contact your Supervisor!\n";
	  	print color ('reset');
	  	system ("afplay '$dir/wrongansr.wav'");
	  	print "Press ENTER to continue...";
	  	<>;
	    $location = '';
	    goto SCANUPC;
    }
      $sth->finish;
}

sub update_first_empty{
    # query from the links table
    ($dbh) = @_;
    $sql = "UPDATE SORTATION SET UPC = ('$UPC'), QUANTITY = QUANTITY+1, STATUS='OPEN', LAST_CHANGE=CURRENT_TIMESTAMP, qty_max='$qty_max', mpn='$mpn_upc'
	WHERE LOCATION = ('$location')";
    $sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
    $sth->finish;
}

sub update_first_open{
    # query from the links table
    ($dbh) = @_;

    if ( $quantity < ($qty_slot-1) ) 
    {
		$sql = "UPDATE SORTATION SET QUANTITY = QUANTITY+1, LAST_CHANGE=CURRENT_TIMESTAMP WHERE LOCATION = '$location'"; 
	}
	else 
	{
		$sql = "UPDATE SORTATION SET STATUS = 'FULL', QUANTITY = QUANTITY+1, LAST_CHANGE=CURRENT_TIMESTAMP WHERE LOCATION = '$location'";
	}
		
    $sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
    $sth->finish;
}

sub check_sort_loc{
    # query from the links table
    ($dbh) = @_;
    $sql = "SELECT LOCATION, QUANTITY, QTY_MAX FROM SORTATION
	WHERE UPC =('$UPC') AND STATUS = 'OPEN' AND line='$line' AND loc_status='LIVE'";
    $sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
   
    my $ref;
    
    $ref = $sth->fetchall_arrayref([]);
    
    #print "Number of rows returned is ", 0 + @{$ref}, "\n";    
    if ((0 + @{$ref}) > 0)
    {
        foreach $data (@$ref)
        {
            ($location, $quantity, $qty_slot) = @$data;
        }
        
    }
    else
    {
	    $location = '';
	    $quantity = '';
	    $qty_slot = $qty_max;
    }
      $sth->finish;
}

sub check_setup{
	# query from the links table
    ($dbh) = @_;
    $sql = "SELECT line FROM SORTATION
	WHERE line =('$line') LIMIT 1";
    $sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
   
    my $ref;
    
    $ref = $sth->fetchall_arrayref([]);
    
    #print "Number of rows returned is ", 0 + @{$ref}, "\n";    
            foreach $data (@$ref)
            {
                ($setup) = @$data;
            }
            
    $sth->finish;

    if ($setup eq '')
    {
    	print color('bold red');
		print "The line has not been set up for this process. Contact your Supervisor!\n";
		print color('reset');
		system ("afplay '$dir/wrongansr.wav'");
		print "Press Enter to close...";
		<>;
		exit;
    }
    
    $setup = '';
    ($dbh) = @_;
    $sql = "SELECT id FROM SORTATION
	WHERE line =('$line') AND loc_status='LIVE' AND status NOT LIKE 'FULL' LIMIT 1";
    $sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
   
    my $ref;
    
    $ref = $sth->fetchall_arrayref([]);
    
    #print "Number of rows returned is ", 0 + @{$ref}, "\n";    
            foreach $data (@$ref)
            {
                ($setup) = @$data;
            }
            
    $sth->finish;

	if ($setup eq '')
    {
    	print color('bold red');
		print "No locations available. Contact your Supervisor!\n";
		print color('reset');
		system ("afplay '$dir/wrongansr.wav'");
		print "Press Enter to refresh...";
		<>;
		goto SCANUPC;
    }
    
}

sub check_sn{
    # query from the links table
    ($dbh) = @_;
    $sql = "SELECT * FROM stations
	WHERE serial_number =('$stn')";
    $sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
   
    my $ref;
    
    $ref = $sth->fetchall_arrayref([]);
    
    #print "Number of rows returned is ", 0 + @{$ref}, "\n";    
            foreach $data (@$ref)
            {
                ($serial, $station,) = @$data;
            }
            
      $sth->finish;
      
      if ($station eq '')
	{
		my $station = $stn;
		print ("Station: $stn\n");
		system ("echo '$time\t$stn\tNo location set up in db\n' >> $logfile");
		print color('bold red');
		print "Station has not been set up yet. Contact Supervisor!\n";
		print color('reset');
		print "Press Enter to close...";
		<>;
		exit;
	} 
	else 
	{
		$stn = $station;
		print ("Station: $stn\n");
	}
      
}

sub check_sn_in_sort{
    # query from the links table
    ($dbh) = @_;
    $sql = "SELECT LOCATION FROM SORT_LOC
	WHERE serial_number =('$serial')";
    $sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
   
    my $ref;
    
    $ref = $sth->fetchall_arrayref([]);
    
    #print "Number of rows returned is ", 0 + @{$ref}, "\n";    
    if ((0 + @{$ref}) > 0)
    {
        foreach $data (@$ref)
        {
            ($result) = @$data;
        }
    }
    else
    {
	    $result = '';
    }
      $sth->finish;
}

sub insert_serial{
    # query from the links table
    
    ($dbh) = @_;
    $sql = "INSERT INTO SORT_LOC
    VALUES (NULL,'$line','$location','$serial', '$UPC','$location',CURRENT_TIMESTAMP,NULL)";
    $sth = $dbh->prepare($sql);
    
    # execute the query
    $sth->execute();
    
    $sth->finish();
}

sub handle_error{
	print color('bold red');
	$time = localtime->datetime;
	system ("echo '$time\tUnable to connect to database\n' >> $logfile");
	print "Unable to connect to database. Contact your Supervisor\n";
	system ("afplay '$dir/wrongansr.wav'");
	print "Press Enter to close...\n";
	print color('reset');
	<>;
	exit;
}

sub check_version{
my $file = '/Users/Shared/Sortation.command';

open(FH, $file) or die $!;

while(my $string = <FH>)
{
	if($string =~ /.version.[=]./)
	{
		print "$string";
		$len_string = (length $string) - 15;
		$new_ver = substr($string,12,$len_string);
		print "\nNew version: $new_ver\n";
		print "Current version: $version\n";
		if ($new_ver eq $version)
		{
			print "Found a match. Doing nothing...\n";
		
		}
		else
		{
			print "Found mismatch match. Restarting...\n";
			
			system("/Users/Shared/Launch_sortation.command $arg1");
			exit;
		}
	}
}
close(FH);
}
