# bluetooth-in-out-monitor
Database backed Bluetooth scanner for Raspberry Pi

## Install modules required
apt -y install libnet-bluetooth-perl libdbi-perl libdbd-sqlite3-perl

## Run from startup or from command line
./bluetooth_monitor.pl

## Database structure

Table board:

  address: mac address ( xx:xx:xx:xx:xx )

  time_in: epoch time ( 1234567 )
  
   time_out: epoch time ( 1234567 )

Table device:
  
  address: mac address ( xx:xx:xx:xx:xx )
  
  name: given name of device ( Your Iphone )
  
  checkin_time: epoch time ( 1234567 )
  
  last_seen: epoch time ( 1234567 )
  
  available: boolean true if checked in ( 0 | 1 )
 
