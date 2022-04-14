#!/usr/bin/env bash

json=$(curl -s "https://location.services.mozilla.com/v1/geolocate?key=geoclue")
location=$(echo $json | jq '.location | "\(.lat):\(.lng)"' | sed s/\"//g)
gammastep -l $location
