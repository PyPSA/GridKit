#!/bin/bash

ZOOM=${1-6}

npm install vt-geojson

export MapboxAccessToken=pk.eyJ1IjoiZW50c29lIiwiYSI6ImNpbWxxYXJocDAwMG53Ymx3N2JxNGhtZDYifQ.YjNgK9usqRNrzxWXnR152g
for key in rusty.cm0b8gzp rusty.02rit83j entsoe.1nr7sorj entsoe.5m43hs6u; do
    echo Getting ${key}
    node_modules/vt-geojson/cli.js ${key} -z ${ZOOM} > ${key}-z${ZOOM}.geojson
done
