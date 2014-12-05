#!/usr/bin/zsh
source json.bash
json='{"name":"Jason","friends":["Jimmy","Joe"]}'
JSON.load "$json" jason
#set -x
JSON.get -s /friends/0 jason
