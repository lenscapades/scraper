#!/bin/bash
cmd1=$HOME"/scraper/bin/Scraper -t=daily -s=15"
cmd2=$HOME"/scraper/bin/Scraper -t=daily -s=9"
cmd3=$HOME"/scraper/bin/Scraper -t=daily -p -d -v"
$cmd1
sleep 5
$cmd2
$cmd3
