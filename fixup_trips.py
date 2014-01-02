"""Various functions to help cleanup/tweak 'properties' metadata.

Edit the fixup() function to call which other function you wish to use to
translate the JSON data.

"""
import json


def fixup(points, linestrings):
    return valid_linestrings(points, linestrings)


def valid_linestrings(points, linestrings):
    """GeoJSON requires at least 2 sets of coordinates for a linestring."""
    for line in linestrings:
        coords = coordinates(line)
        if len(coords) == 1:
            coords.append(coords[-1])
    return points, linestrings


def cross_ref(points, linestrings):
    """List trips visiting a city and what cities a trip visited."""
    coordinate_to_point = points_by_coordinates(points)
    for line in linestrings:
        trip_name = line['properties']['trip']
        visited = []
        for coordinate in map(tuple, coordinates(line)):
            pt = coordinate_to_point[coordinate]
            city_name = pt['properties']['city']
            if len(visited) == 0 or visited[-1] != city_name:  # If a city is listed twice in a row it's just to be valid GeoJSON.
                visited.append(city_name)
                city_trips = pt['properties'].setdefault('trips', list())
                if trip_name not in city_trips:
                    city_trips.append(trip_name)
        line['properties']['visited'] = visited
    return points, linestrings


def sort(points, linestrings):
    for pt in points:
        name = pt['properties']['city']
        if ', ' not in name:
            raise ValueError(name + ' is missing a comma')
    for line in linestrings:
        name = line['properties']['trip']
        if name.count(':') > 1:
            raise ValueError(name + ' contains a colon')
    sorted_points = sorted(points, key=lambda pt: tuple(reversed(pt['properties']['city'].split(', '))))
    sorted_lines = sorted(linestrings, key=lambda l: l['properties']['trip'].partition(': ')[-1], reverse=True)
    return sorted_points, sorted_lines


def rename_trips(points, linestrings):
    """Rename trips to '{name}: {when}' and delete the 'when' value."""
    for line in linestrings:
        name = line['properties']['trip']
        when = line['properties']['when']
        new_name = '{}: {}'.format(name, when)
        line['properties']['trip'] = new_name
        del line['properties']['when']
    return points, linestrings


def rename_name(points, linestrings):
    """Rename the 'name' property to 'trip' on linestrings and 'city' on points."""
    for point in points:
        name = point['properties']['name']
        point['properties']['city'] = name
        del point['properties']['name']
    for linestring in linestrings:
        name = linestring['properties']['name']
        linestring['properties']['trip'] = name
        del linestring['properties']['name']
    return points, linestrings


def remove_duplicated_points(points, linestrings):
    cleaned_points = []
    seen = {}
    for point in points:
        name = point['properties']['name']
        coordinate = coordinates(point)
        if name not in seen:
            cleaned_points.append(point)
            seen[name] = coordinate
        elif coordinate != seen[name]:
            raise ValueError(name + ' seen twice, but coordinates do not match')
        else:
            print(name)
    return cleaned_points, linestrings


def point_visited_by(points, linestrings):
    """Record who has visited what cities based on travellers on various trips."""
    coordinates_mapping = points_by_coordinates(points)
    point_visiters = {pt['properties']['name']: set() for pt in points}
    for linestring in linestrings:
        travellers = linestring['properties']['travellers']
        travellers.sort()  # Just to clean up along the way.
        travellers = set(travellers)
        for coordinate in coordinates(linestring):
            try:
                point = coordinates_mapping[tuple(coordinate)]
            except KeyError:
                raise ValueError('{!r} has unrecognized point {}'.format(linestring['properties']['name'], coordinate))
            point_visiters[point['properties']['name']].update(travellers)
    for point in points:
        name = point['properties']['name']
        point['properties']['visited by'] = sorted(point_visiters[name])
    return points, linestrings


def coordinates(thing):
    return thing['geometry']['coordinates']


def points_by_coordinates(points):
    """Create a dict with keys of coordinates and values of points."""
    mapping = {}
    for point in points:
        coordinate = coordinates(point)
        if len(coordinate) != 2:
            raise ValueError('Point has an improper coordinate: {}'.format(coordinate))
        mapping[tuple(coordinate)] = point
    return mapping


def separate_types(data):
    """Separate out the points from the linestrings."""
    if data['type'] != 'FeatureCollection':
        raise TypeError('expected a FeatureCollection, not ' + data['type'])
    points = []
    linestrings = []
    for thing in data['features']:
        if thing['type'] != 'Feature':
            raise TypeError('expected Feature, not ' + thing['type'])
        geometry_type = thing['geometry']['type']
        if geometry_type == 'Point':
            points.append(thing)
        elif geometry_type == 'LineString':
            linestrings.append(thing)
        else:
            raise TypeError('expected Point or LineString, not ' + geometry_type)
    return points, linestrings


def reconstruct(point, linestrings):
    """Reconstruct the GeoJSON FeatureCollection."""
    return {'type': 'FeatureCollection', 'features': list(point) + list(linestrings)}


if __name__ == '__main__':
    import sys
    in_path = sys.argv[1]
    out_path = sys.argv[2]
    with open(in_path) as file:
        data = json.load(file)
    points, linestrings = separate_types(data)
    fixed_points, fixed_linestrings = fixup(points, linestrings)
    fixed_data = reconstruct(fixed_points, fixed_linestrings)
    with open(out_path, 'w') as file:
        json.dump(fixed_data, file, indent=2)
