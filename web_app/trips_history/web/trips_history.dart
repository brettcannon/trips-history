/* Format changes
 * 'visited by' is only a string
 * 'travellers' is only a string
 * 'trip' renamed to 'description'
 * 'city' renamed to 'description'
 * city names are only locality, country
 * people are all listed in the FeatureCollection's properties: people dict of name: colour
 */

library trips_history;

import 'dart:convert';
import 'package:intl/intl.dart';

/**
 * Match a person(s) to a colour.
 *
 * For instances where you want to represent more than one person
 * (e.g., Andrea & Brett), specify the [name] by listing all
 * of the people in a format the displays nicely (e.g. `Andrea & Brett`).
 */
class Person implements Comparable {
  String name;
  String _colour;

  // Relying on property to validate colour, so not using parameter setters.
  Person(String name, String colour) {
    this.name = name;
    this.colour = colour;
  }

  /**
   * Sort based on name.
   */
  int compareTo(Person other) {
    return name.compareTo(other.name);
  }

  /**
   * Validate the colour to represent the person.
   *
   * The rules for acceptable values are:
   *
   * 1. It may start with `#`
   * 2. Digits are hexidecimal (upper or lowercase)
   * 3. Either 3 or 6 digits (sans `#`)
   */
  void _validateColour(String colour) {
    var shortLength = 3;
    var longLength = 6;
    if (colour.startsWith('#')) {
       shortLength++;
       longLength++;
    }
    if (colour.length != shortLength && colour.length != longLength) {
       throw new ArgumentError(
           'colour should be 3 or 6 hex digits longs (not including hash');
    }

    var hexRegExp = new RegExp('#?[A-F0-9]+');
    var matched = hexRegExp.stringMatch(colour.toUpperCase());
    if (colour.toUpperCase() != matched) {
      throw new ArgumentError('colour must be a hex colour, not ${colour}');
    }
  }

  String _formatColour(String colour) {
    if (!colour.startsWith('#')) {
      colour = '#' + colour;
    }

    if (colour.length == 4) {
      colour = '#' + colour[1]*2 + colour[2]*2 + colour[3]*2;
    }

    return colour.toUpperCase();
  }

  String get colour => _colour;

  set colour(String colour) {
    _validateColour(colour);
    _colour = _formatColour(colour);
  }

  // JSON convertion handled by [TripsHistory.toJSON].
}

/**
 * A city that has been visited.
 */
class City implements Comparable {
  String locality;
  String country;
  double longitude;
  double latitude;
  Person visitedBy;
  bool livedHere = false;

  City(this.locality, this.country,
       {this.longitude, this.latitude, this.visitedBy: null,
        this.livedHere: false});

  String get name => "$locality, $country";

  /**
   * Sort cities by country, then city name.
   */
  int compareTo(City other) {
    if (country != other.country) {
      return country.compareTo(other.country);
    } else if (locality != other.locality) {
      return locality.compareTo(other.locality);
    }
    return 0;
  }

  /**
   * Construct a City from GeoJSON data.
   *
   * Data is taken from a Point's:
   *
   * - `geometry['coordinates']` for [longitude]/[latitude]
   * - `properties`
   *   + `description` for [name]; format expected to be "[locality], [country]"
   *   + `visited by` for [visitedBy]
   *   + `lived here` for [livedHere]
   */
  City.fromJson(Map data, Map<String, Person> people) {
    if (!data['geometry'].containsKey('coordinates')) {
      throw new ArgumentError('Point is missing coordinates');
    }
    var coordinates = data['geometry']['coordinates'];
    if (coordinates.length != 2) {
      throw new ArgumentError('Point should have two coordinates');
    }
    var properties = data['properties'];

    if (!properties.containsKey('description')) {
      throw new ArgumentError('Point is lacking a "description" property');
    }

    // Need to watch out for cases like "Washington, DC, US".
    var name = properties['description'];
    var comma_index = name.lastIndexOf(',');
    if (comma_index == -1) {
      throw new ArgumentError(
          'name should be in the form of "<locality>, <country>"');
    }
    locality = name.substring(0, comma_index).trim();
    country = name.substring(comma_index+1).trim().toUpperCase();
    if (country.length != 2) {
      throw new ArgumentError('country should be in ISO 3166-1 alpha-2 format');
    }

    longitude = coordinates[0];
    latitude = coordinates[1];

    setVisitor(people[properties['visited by']]);

    livedHere = properties['lived here'] == true;
  }

  /**
   * Set who has visited the city.
   *
   * The [person] with the longest name is kept as the value. The assumption
   * is that if multiple people visit a city then their combined name will
   * be longer than either of them on their own. This prevents any manual
   * override of who has visited a city compared to what is specified by trips.
   */
  void setVisitor(Person person) {
    if (visitedBy == null || person.name.length > visitedBy.name.length) {
      visitedBy = person;
    }
  }

  Map toJson() {
    var json = {'type': 'Feature'};
    var geometry = {'type': 'Point',
                    'coordinates': [longitude, latitude]};
    var properties = {'description': name, 'marker-size': 'small'};

    if (visitedBy != null) {
      properties['visited by'] = visitedBy.name;
      properties['marker-color'] = visitedBy.colour;
    }

    if (livedHere == true) {
      properties['lived here'] = true;
      properties['marker-symbol'] = 'building';
      properties['marker-size'] = 'medium';
    }

    json['geometry'] = geometry;
    json['properties'] = properties;
    return json;
  }
}

/**
 * A single trip.
 */
class Trip implements Comparable {
  String name;
  DateTime when;
  final _formatYear = new NumberFormat("0000");
  final _formatMonth = new NumberFormat("00");
  Person who;
  List<City> visited = new List();

  Trip() {}

  String _formatDate() =>
      '${_formatYear.format(when.year)}-${_formatMonth.format(when.month)}';

  String get description => '$name: ${_formatDate()}';

  /**
   * Sort trips by their date, then by their name.
   */
  int compareTo(Trip other) {
    if (when != other.when){
      return when.compareTo(other.when);
    } else if (name != other.name){
      return name.compareTo(other.name);
    }
    return 0;
  }

  /**
   * Create a trip from GeoJSON data.
   *
   * Data comes from:
   *
   * - `properties
   *   + `description` for [description]; format expected to be "[name]: [when]"
   *   + `travellers` for [who]
   *   + `visited by` for [visited]
   */
  Trip.fromJson(
      Map data,
      Map<String, Person> people,
      Map<String, City> cities) {
    var properties = data['properties'];
    if (!properties.containsKey('description')) {
      throw new ArgumentError('LineString lacks a description');
    }
    var description = properties['description'];

    var nameParts = description.split(':').map((e) => e.trim()).toList();
    if (nameParts.length != 2) {
      throw new ArgumentError('Description "$name" malformed');
    }
    name = nameParts[0];
    var dateParts = nameParts[1].split('-').map((e) => int.parse(e)).toList();
    when = new DateTime(dateParts[0], dateParts[1]);

    who = people[properties['visited by']];

    for (var place in properties['visited']) {
      var city = cities[place];
      visited.add(city);
      city.setVisitor(who);
    }
  }

  Map toJson() {
    var json = {'type': 'Feature', 'geometry': {'type': 'LineString'},
                'properties': {}};
    json['properties']['description'] = description;
    json['properties']['visited by'] = who.name;
    json['properties']['stroke-opacity'] = 0.5;
    json['properties']['stroke'] = who.colour;
    json['properties']['visited'] = visited.map((c) => c.name).toList();
    if (visited.length == 1) {
      var coordinates = [visited.first.longitude, visited.first.latitude];
      json['geometry']['coordinates'] = [coordinates, coordinates];
    } else {
      json['geometry']['coordinates'] = visited.map((c) => [c.longitude, c.latitude]).toList();
    }
    return json;
  }
}

/**
 * Encode the various trip details into GeoJSON.
 */
String encode(Iterable<Person> people, Iterable<City> cities, Iterable<Trip> trips) {
  var data = {'type': 'FeatureCollection', 'geometry': {},
                  'properties': {'people': {}}, 'features': []};

  var sortedPeople = people.toList();
  sortedPeople.sort();
  sortedPeople.forEach((person) {
    data['properties']['people'][person.name] = person.colour;
  });

  var sortedCities = cities.toList();
  sortedCities.sort();
  data['features'].addAll(sortedCities);
  var sortedTrips = trips.toList();
  sortedTrips.sort();
  data['features'].addAll(sortedTrips);

  return JSON.encode(data);
}

/**
 * Decode GeoJSON into a map of people, cities, and trips.
 */
Map<String, Set> decode(String jsonString) {
  var data = JSON.decode(jsonString);
  var people = new Map();
  var cities = new Map();
  var trips = new Map();

  if (data['type'] != 'FeatureCollection') {
    throw new ArgumentError('GeoJSON requires the outermost "type" to be '
                            '"FeatureCollection, not ${data['type']}');
  }

  if (data.containsKey('properties')) {
    Map properties = data['properties'];
    if (properties.containsKey('people')) {
      properties['people'].forEach(
          (key, value) => people[key] = new Person(key, value));
    }
  }

  if (!data.containsKey('features')) {
    throw new ArgumentError('"features" section missing');
  }

  var points = new List();
  var lineStrings = new List();
  for (var feature in data['features']) {
    if (!feature.containsKey('type')) {
      throw new ArgumentError('Feature lacks a "type" value');
    } else if (feature['type'] != 'Feature') {
      throw new ArgumentError('expected a Feature, not ${feature["type"]}');
    }

    if (!feature.containsKey('geometry')) {
      throw new ArgumentError('Feature must have a "geometry" key');
    } else if (!feature.containsKey('properties')) {
      throw new ArgumentError('Feature must have a "properties" key');
    }

    var geometry = feature['geometry'];
    if (geometry['type'] != 'Point' && geometry['type'] != 'LineString') {
      throw new ArgumentError(
          'Feature should be a Point or LineString, not ${geometry["type"]}');
    } else if (geometry['type'] == 'Point') {
      points.add(feature);
    } else {
      lineStrings.add(feature);
    }
  }

  for (var point in points) {
    var city = new City.fromJson(point, people);
    cities[city.name] = city;
  }

  for (var lineString in lineStrings) {
    var trip = new Trip.fromJson(lineString, people, cities);
    trips[trip.description]= trip;
  }

  return {'people': people.values.toSet(), 'cities': cities.values.toSet(), 'trips': trips.values.toSet()};
}