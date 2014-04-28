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
  static final importLabel = "Import";
  static final exportLabel = "Export";
  String importExportState = importLabel;
  String importExport;

  void _nowExport() {
    importExportState = exportLabel;
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
    if (importExportState == exportLabel) {
      importExport = encode(people, cities, trips);
    } else {
      var data = decode(importExport);
      people.addAll(data['people']);
      cities.addAll(data['cities']);
      trips.addAll(data['trips']);
      _nowExport();
    }
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