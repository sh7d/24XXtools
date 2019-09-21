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
24XXtools - generic program for manipulating 24XX eeproms family memory content using buspirate

Usage: 24XXtools.rb [options]
Mandatory config:
    -d, --device device              Path to buspirate device

Buspirate config:
        --disable-power              Disable PSU
        --disable-pull-up            Disable pull-up resistors

Eeprom config:
    -s, --size size                  Specifies eeprom size in kilobits (eg: 256 for 24LC256)

Non-destructive operations:
    -o, --output file                Dumps eeprom content to file (needs also size argument)

    -e, --read offset                Reads eeprom content at given offset
    -l, --len len                    Specifies length in bytes to read (default: 16)

Destructive operations:
    -r, --restore file               File from which eeprom will be restored
    -w, --wipe                       Wipe eeprom memory content(needs also size argument)

Debug/Advanced:
    -i, --interactive                Run in interactive mode (needs also size argument)

Other:
    -h, --help                       Shows this message
```
`ex: ruby 24XXtools.rb -d /dev/buspirate -o dump.bin -s 256`
## Project status
Tested and working on linux, definitely will not work in windows (contributions are welcomed)
## TODO
* Allow to modify n bytes at x memory position
* Quiet mode
