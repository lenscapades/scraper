#!/bin/bash
cmd1=$HOME"/scraper/bin/Scraper -t=new -s=15"
cmd2=$HOME"/scraper/bin/Scraper -t=new -s=9"
cmd3=$HOME"/scraper/bin/Scraper -t=new -p -d -v"
$cmd1
sleep 5
$cmd2
$cmd3
