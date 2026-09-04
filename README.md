# Melbourne Public Transport — interactive map

Interactive, poster-grade map of the public transport network of
**metropolitan Melbourne**: the PTV bus network across myki zones 1 and 2,
the five SkyBus airport expresses, all 24 Yarra Trams routes and the sixteen
Metro Trains lines — drawn along the real street and track geometry.

## Live

**https://miqell24.github.io/melbourne-bus-map/** — GitHub Pages serves `main:/docs`; local build on port 8180 (`npm run serve`).

Everything comes from ONE bundle — the **PTV GTFS Schedule** published by
Transport Victoria (<https://discover.data.vic.gov.au/dataset/gtfs-schedule>,
CC BY 4.0, refreshed weekly). The zip holds the whole state as numbered
sub-feeds, each a `google_transit.zip` of its own: 1 regional trains (V/Line),
2 Metro Trains, 3 trams, 4 buses, 5 regional coaches, 6 regional buses,
10 interstate, 11 SkyBus. The map takes four of them:

| mode | sub-feed | route_type | scope | graph |
|---|---|---|---|---|
| buses | 4 | 3 | the metropolitan network — every line but 684 | OSM roadways |
| SkyBus | 11 | 3 | all five airport expresses (no short names in the feed — keyed by brand) | OSM roadways |
| trams | 3 | 0 | all 24 routes, family red | `railway=tram` |
| trains | 2 | 400 | all sixteen Metro lines, colours from the feed | `railway=rail` |

The scope needs no radius rule: PTV's own coding of the bus feed IS the
metropolitan region. Sub-feed 4 carries the metro buses as route_type 3 —
Melton and Sunbury in the west and north, Whittlesea and Kinglake, Healesville
and Warburton in the east, Gembrook and Pakenham, and the Mornington Peninsula
down to Portsea and Flinders — and, in the same folder as 701, the town
networks of Geelong, Ballarat, Bendigo, Seymour and the Latrobe Valley,
60–150 km out. Only the 3s are drawn.

Cut deliberately:

* **bus 684 Ringwood – Eildon** — the one metropolitan-coded line that leaves
  the region, 110 km out to Lake Eildon; it alone would stretch the frame
  40 km north-east into the ranges. The rule: no stop farther than 80 km from
  Flinders Street — every other line fits (Flinders 72 km, Warburton 71 km,
  Portsea 63 km);
* **the V/Line regional trains and coaches** (sub-feeds 1 and 5) — the state,
  not the city; and the regional town buses (the 701s, sub-feed 6);
* **the "Replacement Bus" routes** of the train feed — one per line, orange
  `FE5000`: rail replacement is not a line, same as Berlin's Ersatzverkehr,
  Budapest's *pótló* and London's "Replacement Service";
* **the "City Circle" train route** — a Flinders Street – loop – Flinders
  Street round trip with 20 trips a week: it is the City Loop that every
  Burnley, Clifton Hill, Northern and Caulfield group line already draws, and
  PTV's own map does not show it.

Line keys need nothing invented. Bus numbers are unique across the
metropolitan network — the repeated short names (200 ×3, 903 ×4, 663 ×4) are
one line published once per contracted operator (the `14-`/`17-`/`33-`
prefixes of `route_id`), so they merge on the shared key by themselves. Trams
are their numbers, trains the names the platform signs and PTV's maps use
("Belgrave", "Glen Waverley"). SkyBus ships empty short names, so its five
routes are keyed by the brand printed on the buses: SkyBus (City), SkyBus
Box Hill, SkyBus Frankston, SkyBus Sunshine, SkyBus Avalon.

**Colours.** The train colours come from the feed itself — PTV fills
`route_color` on every Metro line, and they are the group colours of its
network map: navy for the Burnley group (Alamein, Belgrave, Glen Waverley,
Lilydale), red Clifton Hill (Hurstbridge, Mernda), yellow Northern
(Craigieburn, Upfield), cyan Sunbury and the Dandenong pair (Cranbourne,
Pakenham), green Frankston and Stony Point, pink Cross-City (Sandringham,
Werribee, Williamstown), grey the Flemington Racecourse race-day line. Trams
keep the family red: the feed ships Yarra Trams' route colours too, but colour
means the *mode* on these maps, and the tram colours are a wayfinding scheme
of their own, not a group code.

**Train stops are platforms.** The train feed's `stop_times` reference
platform stops (`stop_id` per platform under a `parent_station`), so every
pattern differing only by the platform used would count as a branch of its
own — that is why the train cfg does not use `allVariants`; each line draws
its longest regular pattern per direction (the Werribee line therefore shows
one of its two paths between Newport and Laverton).

## Pipeline

`npm run download` fetches the PTV bundle, unpacks the four sub-feeds into
`data/gtfs-{bus,tram,train,skybus}/`, and cuts the OSM extracts. **The OSM data
comes from Geofabrik, not Overpass**: the frame is 120 × 120 km, more than the
public mirrors serve in one go, and Geofabrik has no Victoria extract — so
`australia-latest.osm.pbf` (960 MB) comes down once and
`pipeline/pbf-tiles.py` (needs `pip3 install --user osmium`) cuts a 5 × 5 road
grid and the rail file out of it in one pass, writing exactly the JSON shape
Overpass would have returned, node ids included.

`npm run build` map-matches every line (HMM/Viterbi on the OSM graphs) and
writes GeoJSON to `data/out/`; `npm run lines` adds the line-by-line view;
`npm run audit` checks the drawn result. `npm run serve` hosts the map at
<http://localhost:8180>.

Data: Transport Victoria (PTV GTFS Schedule, CC BY 4.0) ·
base map © OpenFreeMap / OpenMapTiles / OpenStreetMap contributors.
