#!/bin/bash
set -e

hdiutil create -o /tmp/Sequoia -size 17g -volname ISO -layout SPUD -fs HFS+J -type UDTO -attach
sudo /Applications/Install\ macOS\ Sequoia.app/Contents/Resources/createinstallmedia --volume /Volumes/ISO
hdiutil detach /Volumes/ISO
hdiutil convert /tmp/Sequoia.cdr -format UDTO -o ~/Desktop/Sequoia.iso
rm -fv /tmp/Sequoia.cdr 
mv ~/Desktop/Sequoia.iso.cdr ~/Desktop/Sequoia.iso
