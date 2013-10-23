#! /usr/bin/env python3.4
"""
class TripsHistory:
    cities: {City}
    def trips
    def travelers

class Trip:
    when: date
    travelers: {str}
    start: City
    where: City
    end: City
    def locations

class City:
    visits: {Trip}
    def last_visited
    name: str
    latlong: [float]
    def visit_count
    def visited_by
    def from_trip(self, name, trip)
    def from_travels(self, name, travelers)

class GeoJSON:
    def linestring(self, coordinates, properties=None)
    def point(self, coordinate, properties=None)
    def __str__(self)
    http://geojson.org/geojson-spec.html
"""
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
        # XXX

    @staticmethod
    def _geojson_feature(type_, coordinates, properties=None):
        feature = {
            'type': 'Feature',
            'geometry': {'type': type_, 'coordinates': coordinates}
        }
        if properties is not None:
            feature['properties'] = properties
        return feature

    @staticmethod
    def _trip_to_linestring(trip, properties=None):
        """Converts a trip to a GeoJSON linestring."""
        return _geojson_feature('LineString', trip, properties)

    @staticmethod
    def _city_to_point(city, properties=None):
        """Converts a city to a GeoJSON point."""
        return _geojson_feature('Point', city, properties)

    def to_geojson(self):
        """Creates GeoJSON from the trips data."""
        features = []
        geojson = {'type': 'FeatureCollection', 'features': features}
        locations = self._collect_locations()
        for trip in self.trips_data['trips']:
            cities = []
            with contextlib.suppress(KeyError):
                cities.append(self.latlong_map[trip['start']])
            features.extend(map(self.latlong_map.__getitem__, trips['where']))
            with contextlib.suppress(KeyError):
                cities.append(self.latlong_map[trip['end']])
        for city in locations:
            latlong = self.latlong_map['city']
            features.append(self._city_to_point(latlong))
            # XXX marker size
            # XXX marker colour
        # XXX https://help.github.com/articles/mapping-geojson-files-on-github
        return geojson



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
