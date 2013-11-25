import trips_history

import datetime
import unittest


class CityTests(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.name = 'Vancouver, BC, Canada'
        cls.city = trips_history.City(cls.name)
        cls.lowercase_city = trips_history.City(cls.name.lower())

    def test_hash(self):
        self.assertEqual(hash(self.city), hash(self.lowercase_city))

    def test_no_getitem(self):
        with self.assertRaises(TypeError):
            self.city[0]

    def test_eq(self):
        self.assertEqual(self.city, self.city)
        self.assertEqual(self.city, self.lowercase_city)

    def test_repr(self):
        self.assertIn(self.name, repr(self.city))

    def test_name(self):
        self.assertEqual(self.city.name, self.city.name)
        self.assertEqual(self.city.name.lower(), self.lowercase_city.name)


class TripTests(unittest.TestCase):

    def test_init(self):
        city1 = trips_history.City('Vancouver, BC, Canada')
        city2 = trips_history.City('Berkeley, CA, USA')
        city3 = trips_history.City('San Francisco, CA, USA')
        title = 'first trip'
        trip = trips_history.Trip(title, '2013-10', {'andrea', 'brett'},
                                  [city2], start=city1, end=city3)
        self.assertEqual(title, trip.title)
        self.assertEqual({'Andrea', 'Brett'}, trip.travelers)
        self.assertEqual(datetime.date(2013, 10, 1), trip.when)
        self.assertEqual((city2,), trip.where)
        self.assertEqual(trip.start, city1)
        self.assertEqual(trip.start, city1)
        self.assertEqual(trip.end, city3)


class TripsHistoryTests(unittest.TestCase):

    @unittest.skip('not implemented')
    def test_city(self):
        pass

    @unittest.skip('not implemented')
    def test_add_trip(self):
        pass


if __name__ == '__main__':
    unittest.main()
