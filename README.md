Trips History
=============

Convert from a trip-oriented JSON format for easy inputting to [GeoJSON](http://geojson.org/) for easy mapping.


JSON trip format
----------------
```json
{
    // List of travelers on any trip; for input verification
    "known travelers": ["..."],
    // List of cities visited for which you don't have a trip entry for
    // (i.e. a city you can claim to have visited but don't remember the trip
    //  details well enough to have a trip entry for it)
    "misc. cities visited": [
        ["location ...", ["travelers ..."]
    ],

    "trips": [
        {
            // A unique name for the trip
            "title": "...",
            // Who went on the trip
            "travelers": ["..."],
            // The month when the majority of the trip occurred
            "when": "YYYY-MM",
            // OPTIONAL: Where the trip started, if important
            "start": "...",
            // List of locations visited, in order; if you visited a city and
            // then returned back to a previous city (i.e. spoke-and-hub trip),
            // list the city you returned to each time so as to have travel
            // routes drawn accurately
            "where": ["..."],
            // OPTIONAL: Where the trip ended, if important
            "end": "..."
        }
    ]
}
```
