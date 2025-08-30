#!/bin/zsh

# ScanSnap iX500 Shortcuts
# Usage: source scan_shortcuts.sh

alias scan-color='ssh Scanserver "scanimage -l 2 -t 3 -x 210 -y 292 --page-height 315 --overscan=Off --source '"'"'ADF Front'"'"' --mode Color --resolution 300 --bgcolor White --brightness 10 --contrast 15 --format=jpeg --batch=scan-$(date +%Y-%m-%d_%H-%M)_%02d.jpg"'

alias scan-bw='ssh Scanserver "scanimage -l 2 -t 3 -x 210 -y 292 --page-height 315 --overscan=Off --source '"'"'ADF Front'"'"' --mode Gray --resolution 300 --bgcolor White --brightness 10 --contrast 15 --format=jpeg --batch=scan-$(date +%Y-%m-%d_%H-%M)_%02d.jpg"'

alias scan-duplex='ssh Scanserver "scanimage -l 2 -t 3 -x 210 -y 292 --page-height 315 --overscan=Off --source '"'"'ADF Duplex'"'"' --mode Color --resolution 300 --bgcolor White --brightness 10 --contrast 15 --format=jpeg --batch=scan-$(date +%Y-%m-%d_%H-%M)_%02d.jpg"'

alias scan-duplex-bw='ssh Scanserver "scanimage -l 2 -t 3 -x 210 -y 292 --page-height 315 --overscan=Off --source '"'"'ADF Duplex'"'"' --mode Gray --resolution 300 --bgcolor White --brightness 10 --contrast 15 --format=jpeg --batch=scan-$(date +%Y-%m-%d_%H-%M)_%02d.jpg"'

echo "Scan shortcuts loaded!"
echo "Available commands:"
echo "  scan-color     - Single-sided color"
echo "  scan-bw        - Single-sided B&W"
echo "  scan-duplex    - Double-sided color"
echo "  scan-duplex-bw - Double-sided B&W"