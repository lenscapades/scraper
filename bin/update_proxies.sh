#!/bin/bash
cmd1=$HOME"/scraper/bin/Proxy -u -s=15"
cmd2=$HOME"/scraper/bin/Proxy -u -s=9"
cmd3=$HOME"/scraper/bin/Proxy -u -d -v"
$cmd1
sleep 5
$cmd2
$cmd3
