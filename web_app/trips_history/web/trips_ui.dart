import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';
import 'trips_history.dart';

@Controller(
    selector: '[trips-history]',
    publishAs: 'ctrl')
class TripsHistoryController {
  // Person
  List<Person> people = new List();
  String personName;
  String personColour;
  // City
  String cityName;
  String cityCountryCode;
  String cityLongitude;
  String cityLatitude;
  bool cityLivedIn;
  List<City> cities = new List();
  // Trip
  String tripName;
  String tripYear;
  String tripMonth;
  String tripPerson;
  String tripCity;
  List<City> tripVisited = new List();
  List<Trip> trips = new List();
  // Import/Export
  String importExportState = "Import";
  String importExport;

  TripsHistoryController() {
    // TODO: remove example data.
    var a = new Person('Andrea', '#EEEE00');
    var b = new Person('Brett', '#0000EE');
    var ab = new Person('Andrea & Brett', '#00EE00');
    people.add(a);
    people.add(b);
    people.add(ab);

    var vancouver = new City('Vancouver', 'CA',
        longitude: -123.11934, latitude: 49.24966, livedHere:true);
    var buenosAires = new City('Buenos Aires', 'AR',
        longitude: -58.37723, latitude: -34.61315);
    cities.add(vancouver);
    cities.add(buenosAires);

    var trip = new Trip();
    trip.name = "Some trip";
    trip.when = new DateTime(2014, 4);
    trip.who = a;
    trip.visited.add(vancouver);
    trips.add(trip);
  }

  void _nowExport() {
    importExportState = "Export";
  }

  void addPerson() {
    var person = new Person(personName, personColour);
    people.add(person);
    personName = personColour = '';
    _nowExport();
  }

  void addCity() {
    var city = new City(cityName, cityCountryCode,
        longitude: double.parse(cityLongitude),
        latitude: double.parse(cityLatitude),
        livedHere: cityLivedIn);
    cities.add(city);
    cityName = cityCountryCode = cityLatitude = cityLongitude = '';
    cityLivedIn = false;
    _nowExport();
  }

  void appendCityToTrip() {
    // TODO: handle case where previous city is selected again.
    var city = cities.firstWhere((c) => c.name == tripCity);
    tripVisited.add(city);
    tripCity = '';
  }

  void addTrip() {
    // TODO: handle case where no city has been saved.
    var date = new DateTime(int.parse(tripYear), int.parse(tripMonth));
    var person = people.firstWhere((p) => p.name == tripPerson);
    var trip = new Trip();
    trip.name = tripName;
    trip.when = date;
    trip.who = person;
    trip.visited = tripVisited;
    trips.add(trip);
    tripName = tripYear = tripMonth = tripPerson = '';
    tripVisited = new List();
    _nowExport();
  }

  void importOrExport() {
    // TODO: export
    // TODO: import
  }
}

class TripsHistoryModule extends Module {

  TripsHistoryModule() {
    type(TripsHistoryController);
  }
}

main() {
  applicationFactory()
      .addModule(new TripsHistoryModule())
      .run();
}