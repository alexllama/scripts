#!/bin/zsh

# script used on system startup to enable conky

## Wait 10 seconds
sleep 20

## Run conky
conky -c ~/.config/conky/conky.conf & 
