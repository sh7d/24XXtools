# 24XXtools
## About
Simple tool made to manipulate content of 24XX eeprom chip family using bus pirate
### Reason
I had to access directly cyfral intercom central (CC-2000) config memory, and i had no fucking idea how to use hardware provided by producent (GC-2000), so i wrote my custom software
## Requirments
* Ruby (tested on 2.6.3)
* Bus pirate (tested on hardware version 3.6)
* Unix-like Os (tested on arch linux)

## Usage
```
bundle install
```
```
24XXtools - generic program for dumping/restoring 24XX  family eeproms using buspirate

Usage: 24XXtools.rb [options]
Mandatory config:
    -d, --device device              Path to buspirate device
Operations:
    -o, --output file                Dumps eeprom content to file (needs also size argiment)
    -s, --size size                  Specifies eeprom size in kilobits (eg: 256 for 24LC256)

    -r, --restore file               File from which eeprom will be restored
```
`ex: ruby 24XXtools.rb -d /dev/buspirate -o dump.bin -s 256`
## Project status
Tested and working om linux, definitely will not work in windows (contributions are welcomed)
## TODO
* Allow to disable psu or/and pull-up resistors in case of external hardware used/dumpig content directly from the board
* Allow to modify and read n bytes at x memory position
* Wipe - just to make chaos and destruction