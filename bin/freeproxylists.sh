#!/bin/bash
cmd1=$HOME"/scraper/bin/Proxy -t=freeproxylists -s=15"
cmd2=$HOME"/scraper/bin/Proxy -t=freeproxylists -s=9"
cmd3=$HOME"/scraper/bin/Proxy -t=freeproxylists -p -d -v"
$cmd1
sleep 5
$cmd2
$cmd3
