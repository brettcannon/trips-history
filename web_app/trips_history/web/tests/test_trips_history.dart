import '../trips_history.dart';

import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';

import 'dart:convert';

jsonEncodeDecode(thing) => JSON.decode(JSON.encode(thing));

basicTripsHistory() => {'type': 'FeatureCollection', 'features': []};
basicCity() => {'type': 'Feature', 'properties': {'description': 'Vancouver, CA'},
                'geometry': {'type': 'Point', 'coordinates': [1.0, -1.0]}};
basicTrip() => {'type': 'Feature', 'properties': {},
                'geometry': {'type': 'LineString',
                  'coordinates': [[1.0, -1.0], [-1.0, 1.0]]}};

void main() {
  useVMConfiguration();

  group('Person', () {
    test('constructor', () {
      // Validation.
      expect(() => new Person('A', 'red'), throwsArgumentError);
      expect(() => new Person('B', '#ace'), returnsNormally);
      expect(() => new Person('C', 'ace'), returnsNormally);
      expect(() => new Person('D', '#aaccee'), returnsNormally);
      expect(() => new Person('E', 'aaccee'), returnsNormally);
      expect(() => new Person('F', 'efg'), throwsArgumentError);

      // No reformatting of the colour.
      expect(new Person('G', '#ABC').colour, '#ABC');
      expect(new Person('H', 'ABC').colour, 'ABC');
      expect(new Person('I', '#AABBCC').colour, '#AABBCC');
      expect(new Person('J', 'AABBCC').colour, 'AABBCC');
    });
  });

  group('City', () {
    test('.fromJson()', () {
      var data = basicCity();
      data['properties']['visited by'] = 'Andrea';
      data['properties']['lived here'] = true;
      var people = {'Andrea': new Person('Andrea', 'ace')};

      var result = new City.fromJson(data, people);
      expect(result.name, 'Vancouver, CA');
      expect(result.locality, 'Vancouver');
      expect(result.country, 'CA');
      expect(result.longitude, 1.0);
      expect(result.latitude, -1.0);
      expect(result.visitedBy, people['Andrea']);
      expect(result.livedHere, isTrue);

      data['properties']['description'] = 'Vancouver, ca';
      result = new City.fromJson(data, people);
      expect(result.country, 'CA');
      for (var country in ['CAN', 'C']) {
        data['properties']['description'] = 'Vancouver, ' + country;
        expect(() => new City.fromJson(data, people), throwsArgumentError);
      }
    });

    test('setVisitor()', () {
      var ins = new City.fromJson(basicCity(), {});
      var andrea = new Person('Andrea', '000');
      var both = new Person('Andrea & Brett', 'FFF');

      expect(ins.visitedBy, isNull);
      ins.setVisitor(andrea);
      expect(ins.visitedBy, andrea);
      ins.setVisitor(both);
      expect(ins.visitedBy, both);
      ins.setVisitor(andrea);
      expect(ins.visitedBy, both);
    });

    test('.toJson()', () {
      var person = new Person('Andrea & Brett', '0E0');
      var city = new City('Vancouver', 'CA', longitude: 4.0, latitude: 3.0,
                          visitedBy: person, livedHere: true);
      var json = city.toJson();

      expect(json['type'], 'Feature');
      expect(json['geometry']['type'], 'Point');
      expect(json['geometry']['coordinates'], [4.0, 3.0]);
      expect(json['properties']['description'], 'Vancouver, CA');
      expect(json['properties']['visited by'], 'Andrea & Brett');
      expect(json['properties']['marker-symbol'], 'building');
      expect(json['properties']['marker-color'], '0E0');
    });
  });

  group('Trip', () {
    test('.fromJson()', () {
      var people = {'Andrea': new Person('Andrea', 'ace'),
                    'Brett': new Person('Brett', 'eca')};
      var vancity = new City('Vancouver', 'BC',
                             longitude: -123.1241, latitude: 49.2573,
                             visitedBy:  people['Andrea']);
      var sf = new City('San Francisco', 'US',
                        longitude: -122.4194, latitude: 37.7749,
                        visitedBy: people['Brett']);
      var cities = {'Vancouver, CA': vancity, 'San Francisco, US': sf};
      var data = basicTrip();
      var name = 'YVR to SFO';
      var date = '2014-02';
      var description = '$name: $date';
      data['properties']['description'] = description;
      data['properties']['visited'] = ['Vancouver, CA', 'San Francisco, US'];
      data['properties']['visited by'] = 'Andrea';

      var result = new Trip.fromJson(data, people, cities);
      expect(result.description, description);
      expect(result.name, name);
      expect(result.when, new DateTime(2014, 02));
      expect(result.who, people['Andrea']);
      expect(result.visited, [vancity, sf]);

      var tripSet = new Set.from([result]);
      expect(vancity.trips, tripSet);
      expect(vancity.trips, tripSet);
    });

    test('.toJson()', () {
      var trip = new Trip();
      var description = trip.description = 'Some Trip: 2014-04';
      trip.name = 'Some Trip';
      trip.when = new DateTime(2014, 4);
      var city1 = new City('Vancouver', 'CA', longitude: 4.0, latitude: 3.0);
      var city2 = new City('San Francisco', 'US', longitude: 2.0, latitude: 1.0);
      trip.visited = [city1];
      var person = new Person('Andrea & Brett', '0E0');
      trip.who = person;

      // Test with a single city for the duplicated coordinates case.
      trip.visited = [city1];
      var json = trip.toJson();
      expect(json['type'], 'Feature');
      expect(json['geometry']['type'], 'LineString');
      expect(json['properties']['description'], description);
      expect(json['properties']['visited by'], person.name);
      expect(json['properties']['visited'], [city1.name]);
      expect(json['geometry']['coordinates'],
          [[city1.longitude, city1.latitude], [city1.longitude, city1.latitude]]);
      // Test with > 1 cities to verify coordinates are okay.
      trip.visited = [city1, city2];
      json = trip.toJson();
      expect(json['properties']['visited'], [city1.name, city2.name]);
      expect(json['geometry']['coordinates'],
          [[city1.longitude, city1.latitude], [city2.longitude, city2.latitude]]);
    });
  });

  group('TripsHistory', () {
    group('.fromJSON()', () {
      test('outermost type', () {
        expect(() => new TripsHistory.fromJson({}), throwsArgumentError);
        expect(() => new TripsHistory.fromJson({'type': 'Point'}),
               throwsArgumentError);
        expect(() => new TripsHistory.fromJson(basicTripsHistory()),
               returnsNormally);
      });

      test('people', () {
        var data = basicTripsHistory();
        data['properties'] = {
            'people': {
                'Andrea': 'EE0',
                'Brett': '00e',
                'Andrea & Brett': '#0E0'
             }
        };

        var result = new TripsHistory.fromJson(data);
        var people = result.people;
        expect(people, contains('Andrea'));
        expect(people['Andrea'].colour, 'EE0');
        expect(people, contains('Brett'));
        expect(people['Brett'].colour, '00e');
        expect(people, contains('Andrea & Brett'));
        expect(people['Andrea & Brett'].colour, '#0E0');
      });

      test('cities', () {
        var data = basicTripsHistory();
        data['properties'] = {'people': {'Andrea': 'ace'}};
        var cityData = basicCity();
        cityData['properties']['visited by'] = 'Andrea';
        data['features'].add(cityData);

        var history = new TripsHistory.fromJson(data);
        var city = history.cities['Vancouver, CA'];
        expect(city.name, 'Vancouver, CA');
        expect(city.locality, 'Vancouver');
        expect(city.country, 'CA');
        expect(city.longitude, 1.0);
        expect(city.latitude, -1.0);
        var person = city.visitedBy;
        expect(person.name, 'Andrea');
        expect(person.colour, 'ace');
      });
    });

    group('.toJson()', () {
      test('basics', () {
        var tripsHistory = new TripsHistory();
        var result = jsonEncodeDecode(tripsHistory);
        expect(result['type'], 'FeatureCollection');
      });

      test('people', () {
        var tripsHistory = new TripsHistory();
        tripsHistory.addPerson(new Person('Andrea', 'ee0'));
        tripsHistory.addPerson(new Person('Brett', '00e'));

        var result = jsonEncodeDecode(tripsHistory);
        expect(result['properties']['people']['Andrea'], 'ee0');
        expect(result['properties']['people']['Brett'], '00e');
      });

      test('cities', () {
        // TODO
      });

      test('trips', () {
        // TODO
      });
    });
  });
}