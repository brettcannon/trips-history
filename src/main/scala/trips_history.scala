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

    def latlong: (String, String)

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
    def latlong = ("0.0", "0.0")
}

/**
    A [[City]] singleton with no concept of geographical location.
*/
object Nowhere extends City("Nowhere") {
    def latlong = ("0.0", "0.0")
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

    def createCity(name: String) = new DumbCity(name)

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
