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

    -e, --read [offset]              Reads eeprom content at given offset (default 0)
                                     If used with quet option - puts string output to stdout

    -l, --len len                    Specifies length in bytes to read (default: max)

Destructive operations:
    -t, --write-at [offset]          Writes data at given offset (default: 0) - data is taken from first argument and hex-decoded
                                     If used with quiet option - data is taken from ARGF

    -r, --restore file               File from which eeprom will be restored
    -w, --wipe                       Wipe eeprom memory content(needs also size argument)

Runtime options
    -q, --quiet                      Quiet mode - dont show progressbar or other info

Debug/Advanced:
    -i, --interactive                Run in interactive mode (needs also size argument)

Other:
    -h, --help                       Shows this message

```
Ex: `ruby 24XXtools.rb -d /dev/buspirate -o dump.bin -s 256`
## Project status
Tested and working on linux, definitely will not work in windows (contributions are welcomed)
## TODO
* Split project into serveal gems (one for buspirate, one for eeprom)
* Add backends support
* Add native linux backend
