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
  }

  void addPerson() {
    var person = new Person(personName, personColour);
    people.add(person);
    personName = '';
    personColour = '';
  }

  void addCity() {
    var city = new City(cityName, cityCountryCode,
        longitude: double.parse(cityLongitude),
        latitude: double.parse(cityLatitude),
        livedHere: cityLivedIn);
    cities.add(city);
    cityName = '';
    cityCountryCode = '';
    cityLatitude = '';
    cityLongitude = '';
    cityLivedIn = false;
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