package ca.yvrsfo.tripshistory

import java.util.{Calendar, GregorianCalendar}
import scala.io.Source
import scala.util.parsing.json.{JSON, JSONArray, JSONObject}

/** A [[City]] has a geographical location on a map in latitude/longitude along
 *  with a name.
 */
abstract class City(val name: String) {

    override def equals(other: Any) = {
        other.isInstanceOf[City] &&
        other.asInstanceOf[City].name.toLowerCase == name.toLowerCase
    }

    override def hashCode = name.toLowerCase.hashCode

    def latlong: (Double, Double)

    def toGeoJSON(properties: Map[String, String]): JSONObject = {
        val allProperties = new JSONObject(properties + ("name" -> name))
        val coordinates = new JSONArray(List(latlong._1, latlong._2))
        val geometry = new JSONObject(Map("type" -> "Point", "coordinates" -> coordinates))
        val attributes = Map("type" -> "Feature", "geometry" -> geometry,
                             "properties" -> allProperties)
        new JSONObject(attributes)
    }

    def toGeoJSON: JSONObject = toGeoJSON(Map())
}

class DumbCity(name: String) extends City(name) {
    def latlong = (0.0, 0.0)
}

class StaticCity(name: String) extends City(name) {
    val knownCoordinates = Map(
        "Buenos Aires, AR" -> (-58.37723, -34.61315),
        "Brussels, BE" -> (4.34878, 50.85045),
        "Ghent, BE" -> (3.71667, 51.05),
        "Calgary, AB, CA" -> (-114.08529, 51.05011),
        "Edmonton, AB, CA" -> (-113.46871, 53.55014),
        "Bowen Island, BC, CA" -> (-123.33622, 49.3847),
        "Vancouver, BC, CA" -> (-123.11934, 49.24966),
        "Victoria, BC, CA" -> (-123.3693, 48.43294),
        "Fredericton, NB, CA" -> (-66.66558, 45.94541),
        "Sackville, NB, CA" -> (-64.38455, 45.91875),
        "Halifax, NS, CA" -> (-63.57239, 44.64533),
        "Guelph, ON, CA" -> (-80.25599, 43.54594),
        "Kingston, ON, CA" -> (-76.48098, 44.22976),
        "Niagara Falls, ON, CA" -> (-79.06627, 43.10012),
        "Niagara-on-the-Lake, ON, CA" -> (-79.06627, 43.25012),
        "Ottawa, ON, CA" -> (-75.69812, 45.41117),
        "Owen Sound, ON, CA" -> (-80.94349, 44.56717),
        "Toronto, ON, CA" -> (-79.4163, 43.70011),
        "Charlottetown, PE, CA" -> (-63.12671, 46.23525),
        "Montréal, QC, CA" -> (-73.58781, 45.50884),
        "Québec, QC, CA" -> (-71.21454, 46.81228),
        "Geneva, CH" -> (6.14569, 46.20222),
        "Havana, CU" -> (-82.38304, 23.13302),
        "Prague, CZ" -> (14.42076, 50.08804),
        "Punta Cana, DO" -> (-68.40431, 18.58182),
        "Barcelona, ES" -> (2.15899, 41.38879),
        "Grenoble, FR" -> (5.71667, 45.16667),
        "Paris, FR" -> (2.3488, 48.85341),
        "Annaka, JP" -> (138.9, 36.31667),
        "Hiroshima, JP" -> (132.45937, 34.39627),
        "Kyoto, JP" -> (135.75385, 35.02107),
        "Nara, JP" -> (135.80485, 34.68505),
        "Osaka, JP" -> (135.50218, 34.69374),
        "Tokyo, JP" -> (139.69171, 35.6895),
        "Birmingham, UK" -> (-1.89983, 52.48142),
        "Brighton, UK" -> (-0.13947, 50.82838),
        "Edinburgh, UK" -> (-3.19648, 55.95206),
        "Glasgow, UK" -> (-4.25763, 55.86515),
        "Lancaster, UK" -> (-2.79988, 54.04649),
        "Liverpool, UK" -> (-2.97794, 53.41058),
        "London, UK" -> (-0.12574, 51.50853),
        "Manchester, UK" -> (-2.23743, 53.48095),
        "Stirling, UK" -> (-3.93682, 56.11903),
        "York, UK" -> (-1.08271, 53.95763),
        "Anaheim, CA, US" -> (-117.9145, 33.83529),
        "Berkeley, CA, US" -> (-122.27275, 37.87159),
        "Los Angeles, CA, US" -> (-118.24368, 34.05223),
        "Mammoth Lakes, CA, US" -> (-118.97208, 37.64855),
        "Monterey, CA, US" -> (-121.89468, 36.60024),
        "Mountain View, CA, US" -> (-122.08385, 37.38605),
        "Oxford, UK" -> (-1.25596, 51.75222),
        "Roseville, CA, US" -> (-121.28801, 38.75212),
        "San Francisco, CA, US" -> (-122.41941, 37.77926),
        "Santa Cruz, CA, US" -> (-122.0308, 36.97412),
        "Washington, DC, US" -> (-77.03525, 38.88956),
        "Atlanta, GA, US" -> (-84.38798, 33.749),
        "Meridian, ID, US" -> (-116.39151, 43.61211),
        "Chicago, IL, US" -> (-87.65005, 41.85003),
        "Rosemont, IL, US" -> (-87.88451, 41.99531),
        "Ann Arbor, MI, US" -> (-83.74088, 42.27756),
        "Las Vegas, NV, US" -> (-115.13722, 36.17497),
        "Montclair, NJ, US" -> (-74.21109, 40.82553),
        "New York, NY, US" -> (-74.00597, 40.71427),
        "Raleigh, NC, US" -> (-78.63861, 35.7721),
        "Portland, OR, US" -> (-122.67621, 45.52345),
        "Pittsburgh, PA, US" -> (-79.99589, 40.44062),
        "Addison, TX, US" -> (-96.82917, 32.96179),
        "Charlottesville, VA, US" -> (-78.47668, 38.02931),
        "Langley, WA, US" -> (-122.40626, 48.04009),
        "Seattle, WA, US" -> (-122.33207, 47.60621)
    )

    def latlong = knownCoordinates(name)
}

/**
    A [[City]] singleton with no concept of geographical location.
*/
object Nowhere extends City("Nowhere") {
    def latlong = (0.0, 0.0)
}

// XXX: concrete implementation of City using some online service to get latlong

class Trip(val title: String, val when: Calendar, val travellers: Set[String],
           val where: List[City], val start: City = Nowhere,
           val end: City = Nowhere) {

    def toGeoJSON(properties: Map[String, String] = Map()): JSONObject = {
        val coords =
            (if (start ne Nowhere)
                List(List(start.latlong._1, start.latlong._2))
             else
                List()) ++
            (where map
                ((city: City) => List(city.latlong._1, city.latlong._2))) ++
            (if (end ne Nowhere)
                List(List(end.latlong._1, end.latlong._2))
             else
                List())
        val coordsArray = new JSONArray(coords map (new JSONArray(_)))
        val geometry = new JSONObject(
                Map("type" -> "LineString", "coordinates" -> coordsArray))
        val allProperties = new JSONObject(properties + ("name" -> title))
        // TODO: travellers
        // TODO: when
        new JSONObject(Map("type" -> "Feature", "geometry" -> geometry,
                           "properties" -> allProperties))
    }

    def toGeoJSON: JSONObject = toGeoJSON(Map())
}

class TripsHistory {

    def jsonArrayToStringList(thing: Any) = thing.asInstanceOf[List[String]]

    def createCity(name: String): City = new StaticCity(name)

    var cachedCities: Map[String, City] = Map()

    def findCity(name: String) = {
        val lowerName = name.toLowerCase
        if (cachedCities contains lowerName) {
            cachedCities(lowerName)
        }

        val city = createCity(name)
        cachedCities = cachedCities + (lowerName -> city)
        city
    }

    def parseTrip(jsonTrip: Map[String, Any]): Trip = {
        val title = jsonTrip("title").asInstanceOf[String]
        val travellers = jsonArrayToStringList(jsonTrip("travellers")).toSet
        // TODO: when
        val start = {
            if (jsonTrip contains "start")
                findCity(jsonTrip("start").asInstanceOf[String])
            else
                Nowhere
        }
        val end = {
            if (jsonTrip contains "end")
                findCity(jsonTrip("end").asInstanceOf[String])
            else
                Nowhere
        }
        val where = for (name <- jsonArrayToStringList(jsonTrip("where")))
                yield findCity(name)
        new Trip(title, new GregorianCalendar(), travellers, where, start, end)
    }

    def toGeoJSON(trips: Seq[Trip]): JSONObject = {
        val cities = trips flatMap ((trip: Trip) => trip.where)
        val citiesJSON = cities map ((city: City) => city.toGeoJSON)
        val tripsJSON = trips map ((trip: Trip) => trip.toGeoJSON)

        val features = new JSONArray(citiesJSON.toList ++ tripsJSON.toList)

        new JSONObject(Map("type" -> "FeatureCollection", "features" -> features))
    }
}


object CLI {

    val tripsHistory = new TripsHistory

    def toGeoJSONString(input: Map[String, Any]): String = {
        if (!(input contains "trips")) {
            throw new Exception("No specified trips")
        }
        val trips = for (anyTrip <- input("trips").asInstanceOf[List[Any]])
                yield tripsHistory.parseTrip(anyTrip.asInstanceOf[Map[String, Any]])

        tripsHistory.toGeoJSON(trips).toString
    }

    def parseJSON(json: String) = {
        JSON.parseFull(json) match {
            case Some(jsonObject) => toGeoJSONString(jsonObject.asInstanceOf[Map[String, Any]])
            case None => throw new Exception("not valid JSON")
        }
    }

    def main(args: Array[String]) = {
        val path = args(0)
        val jsonSource = Source.fromFile(path).mkString
        println(parseJSON(jsonSource))
    }
}
