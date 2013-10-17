Trips History
=============

Convert from a trip-oriented JSON format for easy inputting to [GeoJSON](http://geojson.org/) for easy mapping.


JSON trip format
----------------
```json
{
    "known travelers": ["List of travelers on any trip; for input verification"],
    "misc. cities visited": [
        ["location ...", ["travelers ..."]]
    ],
    "trips": [
        {
            "title": "A unique name for the trip",
            "travelers": ["Who went on the trip"],
            "when": "YYYY-MM",
            "start": "OTIONAL: Where the trip started, if important",
            "where": [
                "Location visited",
                "Listing a location more than once to the the route accurate is fine"
            ],
            "end": "OPTIONAL: Where the trip ended, if important"
        }
    ]
}
```
