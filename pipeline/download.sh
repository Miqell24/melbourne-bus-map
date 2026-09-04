#!/usr/bin/env bash
# Downloads input data: the PTV GTFS bundle, the OSM extract (Geofabrik), MapLibre GL.
# Everything is cached — re-running only fetches what is missing.
#
# Melbourne: Transport Victoria publishes ONE zip for the whole state
# (discover.data.vic.gov.au/dataset/gtfs-schedule, CC BY 4.0, weekly) holding
# numbered sub-feeds, each a google_transit.zip of its own: 1 regional trains,
# 2 Metro Trains, 3 trams, 4 buses, 5 regional coaches, 6 regional buses,
# 10 interstate, 11 SkyBus. The map takes 2, 3, 4 and 11 (see build.mjs).
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p data/osm/tiles web/vendor

# pyosmium does the cutting; it is the one dependency outside Node here.
need_osmium () {
  python3 -c "import osmium" 2>/dev/null && return 0
  echo "brak pakietu osmium — zainstaluj: pip3 install --user osmium" >&2
  return 1
}

# 1) GTFS — the state bundle, then the four sub-feeds out of it
GTFS_URL="https://opendata.transport.vic.gov.au/dataset/3f4e292e-7f8a-4ffe-831f-1953be0fe448/resource/fb152201-859f-4882-9206-b768060b50ad/download/gtfs.zip"
if [ ! -f data/gtfs-bus/routes.txt ] || [ ! -f data/gtfs-tram/routes.txt ] \
   || [ ! -f data/gtfs-train/routes.txt ] || [ ! -f data/gtfs-skybus/routes.txt ]; then
  if [ ! -f data/ptv-gtfs.zip ]; then
    echo "== PTV GTFS Schedule (whole of Victoria, ~290 MB) =="
    curl -fL --retry 3 --max-time 1800 -o data/ptv-gtfs.zip "$GTFS_URL"
  fi
  for pair in "2:gtfs-train" "3:gtfs-tram" "4:gtfs-bus" "11:gtfs-skybus"; do
    n="${pair%%:*}"; d="${pair##*:}"
    [ -f "data/$d/routes.txt" ] && continue
    echo "== sub-feed $n → data/$d =="
    mkdir -p "data/$d"
    unzip -q -o data/ptv-gtfs.zip "$n/google_transit.zip" -d data/_sub
    unzip -q -o "data/_sub/$n/google_transit.zip" -d "data/$d"
    rm -rf data/_sub
  done
fi

# 2) OSM — from the Geofabrik extract, not Overpass.
#    The frame is 120 × 120 km (Melton to Warburton, Sunbury to the
#    Mornington Peninsula) — more than the public Overpass mirrors serve in one
#    go. Geofabrik has no Victoria extract, so the whole country comes down
#    (960 MB) and pipeline/pbf-tiles.py cuts the 5 × 5 road grid and the rail
#    file out of it in one pass, writing exactly the JSON shape Overpass would
#    have returned (ways with tags, NODE IDS and geometry — buildGraph silently
#    drops ways without el.nodes).
if [ ! -f data/osm/tiles/t25.json ] || [ ! -f data/osm/melbourne-rail.json ]; then
  need_osmium
  if [ ! -f data/australia-latest.osm.pbf ]; then
    echo "== Geofabrik australia-latest.osm.pbf =="
    curl -fL --retry 5 --retry-delay 5 -C - --max-time 3600 -o data/australia-latest.osm.pbf \
      "https://download.geofabrik.de/australia-oceania/australia-latest.osm.pbf"
  fi
  echo "== cutting OSM tiles out of the extract =="
  python3 pipeline/pbf-tiles.py
fi

# 3) MapLibre GL (vendored, no CDN at runtime)
if [ ! -f web/vendor/maplibre-gl.js ]; then
  echo "== MapLibre GL =="
  curl -fL --retry 3 -o web/vendor/maplibre-gl.js  https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.js
  curl -fL --retry 3 -o web/vendor/maplibre-gl.css https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.css
fi

echo "OK — data ready:"
du -sh data/gtfs-* data/osm 2>/dev/null || true
