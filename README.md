# Trips History
Various bits of code to help maintain a [GeoJSON](http://geojson.org/) record of one's trips.
All part of a [blog
post](http://nothingbutsnark.svbtle.com/my-impressions-of-scala).

## Fixup/tweak GeoJSON `properties` metadata
`fixup_trips.py` helps with changing GeoJSON 'properties' metadata. It's mostly
meant to clean up the output from the trips DSL (mentioned below).

## Convert from a trips JSON DSL to GeoJSON
The Scala code for `trips_history.scala` will take a JSON file using a DSL format
and emit (roughly) GeoJSON.

### JSON trip format
```json
{
    "known travelers": ["List of travelers on any trip; for input verification"],
    "misc. cities visited": [
        ["Location", ["Travelers"]]
    ],
    "trips": [
        {
            "title": "A unique name for the trip",
            "travelers": ["Who went on the trip"],
            "when": "YYYY-MM",
            "start": "OTIONAL: Where the trip started, if important",
            "where": [
                "Location",
                "Listing a location more than once to get the route accurate is fine"
            ],
            "end": "OPTIONAL: Where the trip ended, if important"
        }
    ]
}
```
