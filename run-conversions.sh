#!/bin/bash

psql -f src/step-1-merge-stations.sql
psql -f src/step-2-eliminate-internal-lines.sql
psql -f src/step-3-split-lines-passing-stations.sql
psql -f src/step-4-insert-join-stations.sql
