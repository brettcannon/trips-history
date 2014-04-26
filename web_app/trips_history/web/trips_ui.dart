import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';
import 'trips_history.dart';

@Controller(
    selector: '[trips-history]',
    publishAs: 'ctrl')
class TripsHistoryController {
  List<Person> people = new List();
  String personName;
  String personColour;

  void addPerson() {
    var person = new Person(personName, personColour);
    people.add(person);
    personName = '';
    personColour = '';
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