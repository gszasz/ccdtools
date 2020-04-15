# The ccdtools package

Set of tools to handle and archive CCD photometric data according to
the Hlohovec Observatory standards.

## License

This script is licensed under the terms of the GNU GPLv3, a copy of
which you should have received with this package

## Dependencies

* cmunipack v1.1 or newer

## Installation

1. Copy repository content to `/usr/local/share/ccdtools`.

2. Create links to the individual binaries

       ln -s /usr/local/share/ccdtools/ccdaverage/ccdaverage.sh /usr/local/bin
       ln -s /usr/local/share/ccdtools/ccdexport/ccdexport.sh /usr/local/bin
       ln -s /usr/local/share/ccdtools/ccdget/ccdget.sh /usr/local/bin
       ln -s /usr/local/share/ccdtools/ccdhelcor/ccdhelcor.sh /usr/local/bin
       ln -s /usr/local/share/ccdtools/ccdphase/ccdphase.sh /usr/local/bin
       ln -s /usr/local/share/ccdtools/ccdrename/ccdrename.sh /usr/local/bin
       ln -s /usr/local/share/ccdtools/ccdtidy/ccdtidy.sh /usr/local/bin
