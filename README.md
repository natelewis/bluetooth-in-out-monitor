# bluetooth-in-out-monitor
Database backed Bluetooth scanner for Raspberry Pi

By running the script it will monitor and record bluetooth scanned presence and keep track of them on an in-out board database.   The database is a SQLite3 database called bluetooth_monitor.db.  Other scripts can then access this data and use it to relay relevent information to other services about the presence of blootooth monitored devices in it's area.

## Install modules required
apt -y install libnet-bluetooth-perl libdbi-perl libdbd-sqlite3-perl

## Run from startup or from command line
./bluetooth_monitor.pl

## Database structure

Table board:

  * address: mac address ( xx:xx:xx:xx:xx )

  * time_in: epoch time ( 1234567 )
  
  * time_out: epoch time ( 1234567 )

Table device:
  
  * address: mac address ( xx:xx:xx:xx:xx ) ( unique )
  
  * name: given name of device ( Your IPhone )
  
  * checkin_time: epoch time ( 1234567 )
  
  * last_seen: epoch time ( 1234567 )
  
  * available: boolean true if checked in ( 0 | 1 )
