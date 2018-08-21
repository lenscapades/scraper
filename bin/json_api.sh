#!/bin/bash
cmd1=$HOME"/scraper/bin/Json_Api -s=15"
cmd2=$HOME"/scraper/bin/Json_Api -s=9"
cmd3=$HOME"/scraper/bin/Json_Api -d -v"
$cmd1
sleep 5
$cmd2
$cmd3
