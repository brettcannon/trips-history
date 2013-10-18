#! /usr/bin/env python3.4
import collections
import contextlib
import json
import types


class TripsHistory:

    def __init__(self, trips_data, traveler_colours):
        self.trips_data = trips_data
        self.travelers = set()
        self._validate_data()
        self.traveler_colours = self._parse_traveler_colours(
                traveler_colours,
                trips_data['known travelers'])
        self.latlong_map = {}
        self.city_stats = {}
        self.city_colours = {}

    def _validate_data(self):
        """Make sure everything that's needed in the trips data is there.

        Extra data which is superfluous is left alone.
        """

    def _parse_traveler_colours(self, traveler_colours, known_travelers):
        """Split comma-separate-list:hex-colour strings from the command-line."""
        traveler_colours = []
        for stuff in traveler_colours:
            travelers_string, colour = stuff.split(':')
            travelers = frozenset(travelers_string.split(','))
            for traveler in travelers:
                if traveler not in travelers:
                    raise ValueError('{} is not a known traveler'.format(traveler))
            traveler_colours.append((travelers, colour))

    def _collect_locations(self):
        """Gathers every location into an iterable."""
        locations = set()
        for city_and_travelers in self.trips_data['misc. cities visited']:
            locations.add(city_and_travelers[0])
        for trip in self.trips_data['trips']:
            with contextlib.suppress(KeyError):
                locations.add(trip['start'])
            with contextlib.suppress(KeyError):
                locations.add(trip['end'])
            for city in trip['where']:
                locations.add(city)
        return locations

    def get_latlongs(self):
        """Maps all locations to latlong."""
        locations = self._collect_locations()
        # XXX set latlong_map
        # XXX use asyncio?

    def calc_city_stats(self):
        """Calculates how many trips have passed through a city.

        The count does not include start/end locations nor misc. cities.
        """
        self.city_stats = collections.Counter()
        for trip in self.trips_data['trips']:
            self.city_stats.update(trip['where'])

    def calc_city_colours(self):
        """Map cities to a possible colour based on who has visited."""

    def _trip_to_linestring(self, trip):
        """Converts a trip to a GeoJSON linestring."""

    def _city_to_point(self, city):
        """Converts a city to a GeoJSON point."""

    def to_geojson(self):
        """Creates GeoJSON from the trips data."""
        geojson = {'type': 'FeatureCollection', 'features': []}
        # XXX https://help.github.com/articles/mapping-geojson-files-on-github



if __name__ == '__main__':
    import argparse

    arg_parser = argparse.ArgumentParser(description='XXX')
    arg_parser.add_argument('input_path', help='File path containing trips JSON')
    arg_parser.add_argument('output_path', help='File path to write GeoJSON to')
    arg_parser.add_argument('--traveler', action='append',
                            help='comma-separated list of travelers and a ' +
                                 'hex-specified colour to represent them ' +
                                 '(e.g. `Brett:0000FF` or `Andrea,Brett:00FF00`); ' +
                                 'may be specified multiple times')

    args = arg_parser.parse_args()

    # Read the trips data.
    with open(args.input_path) as file:
        trips_data = json.load(file)

    trips_history = TripsHistory(trips_data, args.traveler)
    trips_history.get_latlongs()
    trips_history.calc_city_stats()
    trips_history.calc_city_colours()

    with open(args.output_path, 'w') as file:
        json.dump(trips_history.to_geojson(), file)
