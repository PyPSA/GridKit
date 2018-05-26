#!/bin/bash

BASE=${1-entsoe}
ZOOM=${2-6}

python fixup-mapbox-tiles.py ${BASE} ${BASE}*-z${ZOOM}.geojson
python ../util/geojson-to-postgis.py ${BASE}-*-fixed.geojson
