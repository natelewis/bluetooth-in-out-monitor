#!/usr/bin/perl
# bluetooth-monitor.pl - Version 0.0.1
# Database backed Bluetooth scanner for Raspberry Pi
# Copyright (C) 2017 Nate Lewis - natelewis.net

use Net::Bluetooth;
use DBI;
use strict;

# No buffer for you
$| = 1;

print time . " Bluetooth device monitor starting\n";

# how long you have been missing before updating the board
# you have left
my $max_time_gone   = 60;

# 2.4G Reprieve
# spamming bluetooth will eat your 2.4 wireless b-g if you don't give a break
# those networks will die
my $wireless_break  = 10;

# DB Settings
my $driver          = 'SQLite';
my $database        = 'bluetooth_monitor.db';
my $dsn             = "DBI:$driver:dbname=$database";
my $userid          = '';
my $password        = '';

print time . " Connected to DB\n";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;

print time . " Creating tables if not present\n";
$dbh->do("CREATE TABLE IF NOT EXISTS device (address CHAR(50) PRIMARY KEY NOT NULL, name TEXT NOT NULL, checkin_time INT NOT NULL, last_seen INT NOT NULL, available BOOLEAN NOT NULL)");
$dbh->do("CREATE TABLE IF NOT EXISTS board (address CHAR(50) NOT NULL, time_in INT NOT NULL, time_out INT NOT NULL)");
$dbh->do("CREATE INDEX IF NOT EXISTS device_available ON device (available)");
$dbh->do("CREATE INDEX IF NOT EXISTS board_address ON board (address)");
$dbh->do("CREATE INDEX IF NOT EXISTS board_time_in ON board (time_in)");
$dbh->do("CREATE INDEX IF NOT EXISTS board_time_out ON board (time_out)");

# Endless loop
while ( 1 ) {

    print time . " Looking for new devices\n";
    # fined all remote devices in the area that are in descovery mode
    my $device_ref = get_remote_devices();

    foreach my $address (keys %$device_ref) {

        # got one!
        print time . " Found: $address Name: $device_ref->{$address}\n";

        # add the mto the DB
        my $sth = $dbh->prepare("INSERT OR IGNORE INTO device (address, name, checkin_time, last_seen, available) VALUES (?, ?, ?, ?, 1)");
        $sth->execute($address, $device_ref->{$address}, time, time);
    }

    # take a break!
    sleep $wireless_break;

    # see who is searchable
    my $sth = $dbh->prepare("SELECT address, checkin_time, last_seen, available FROM device");
    $sth->execute();

    while (my @row = $sth->fetchrow_array) {

        my $address         = shift @row;
        my $checkin_time    = shift @row;
        my $last_seen       = shift @row;
        my $available       = shift @row;

        # check to see if we can search the address
        my @sdp_result = sdp_search($address, 0, '');

        # if we have something we are now available
        if ( $sdp_result[0] ) {

            print time . " $address is within range\n";
            my $sth = $dbh->prepare("UPDATE device SET last_seen = ? WHERE address = ?");
            $sth->execute(time, $address);

            # if we are checking in, set the available flag and checkin time
            if ( !$available ) {
                my $sth = $dbh->prepare("UPDATE device SET checkin_time = ?, available = 1 WHERE address = ?");
                $sth->execute(time, $address);
            }

        # we are not available figure out what the state for that device is
        } else {

            # calculate how long they have been gone
            my $time_gone = time - $last_seen;

            # check to see if they have left, if so, mark them as unavailable and update the board
            if ( $time_gone > $max_time_gone && $available ) {

                print time . " $address has just checked out\n";

                # set the status of the device
                my $sth = $dbh->prepare("UPDATE device SET available = 0 WHERE address = ?");
                $sth->execute($address);

                #add an entry to the board
                my $sth = $dbh->prepare("INSERT INTO board (address, time_in, time_out) VALUES (?, ?, ?)");
                $sth->execute($address, $checkin_time, time);

            # you have checked out, or will be soon
            } else {
                if ( $available ) {
                    print time . " $address has been missing for $time_gone seconds\n";
                } else {
                    print time . " $address is checked out\n";
                }
            }
        }

        # take a break!
        sleep $wireless_break;
    }
}

1;
