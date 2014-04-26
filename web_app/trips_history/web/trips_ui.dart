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

  TripsHistoryController() {
    // TODO: remove example people.
    var a = new Person('Andrea', '#EEEE00');
    var b = new Person('Brett', '#0000EE');
    var ab = new Person('Andrea & Brett', '#00EE00');
    people.add(a);
    people.add(b);
    people.add(ab);
  }

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