#!/bin/bash
# Genere et affiche un qrcode
# Usage :
# ./qr.sh "Hello, QR Code!

qrencode $1 -o - | display -

