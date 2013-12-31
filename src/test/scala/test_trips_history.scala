package ca.yvrsfo.tripshistory

import org.scalatest._

import java.util.GregorianCalendar
import scala.util.parsing.json.{JSON, JSONArray, JSONObject}

class CitySpec extends FlatSpec with Matchers {
    "City" should ".name" in {
        Nowhere.name should be ("Nowhere")
    }

    it should ".latlong" in {
        Nowhere.latlong should be ("0.0", "0.0")
    }

    it should ".toGeoJSON" in {
        val geoJson = Nowhere.toGeoJSON
        val jsonMap = geoJson.obj
        jsonMap should contain ("type" -> "Feature")
        jsonMap should contain key ("geometry")
        val geom = jsonMap("geometry").asInstanceOf[JSONObject].obj
        geom should contain ("type" -> "Point")
        geom should contain key ("coordinates")
        val coords = geom("coordinates").asInstanceOf[JSONArray].list
        coords should be (List(Nowhere.latlong._1, Nowhere.latlong._2))
        jsonMap should contain key ("properties")
        val properties = jsonMap("properties").asInstanceOf[JSONObject].obj
        properties should contain ("name" -> Nowhere.name)

        val geoJSONString: String = geoJson.toString
        val roundtripped = JSON.parseFull(geoJSONString) match {
            case Some(jsonObject) => jsonObject
            case None => fail(s"not emitting valid JSON: $geoJSONString")
        }
    }

    it should ".toGeoJSON(properties)" in {
        val extraProps = Map("key" -> "value")
        val props = Nowhere.toGeoJSON(extraProps).obj("properties").asInstanceOf[JSONObject].obj
        props should contain ("key" -> "value")
        props should contain ("name" -> Nowhere.name)
    }

    it should "implement ==" in {
        val name = "Vancouver, BC, CA"
        new DumbCity(name) should be (new DumbCity(name.toLowerCase))
    }
}

class TripSpec extends FlatSpec with Matchers {
    val start = new City("Start") {
        def latlong = ("1", "0")
    }

    val end = new City("End") {
        def latlong = ("0", "1")
    }

    "Trip" should ".toGeoJSON" in {
        val trip = new Trip("Some Trip", new GregorianCalendar(2013, 12, 14),
                            Set("Andrea", "Brett"), List(Nowhere))
        val jsonMap = trip.toGeoJSON.obj
        jsonMap should contain ("type" -> "Feature")
        jsonMap should contain key ("geometry")
        val geom = jsonMap("geometry").asInstanceOf[JSONObject].obj
        geom should contain ("type" -> "LineString")
        geom should contain key ("coordinates")
        val coords = geom("coordinates").asInstanceOf[JSONArray].list(0).asInstanceOf[JSONArray].list
        coords should be (List(Nowhere.latlong._1, Nowhere.latlong._2))
        jsonMap should contain key ("properties")
        val properties = jsonMap("properties").asInstanceOf[JSONObject].obj
        properties should contain ("name" -> trip.title)

        val geoJSON: String = trip.toGeoJSON.toString
        val translated = JSON.parseFull(geoJSON) match {
                case Some(jsonObject) => jsonObject
                case None => fail(s"not emitting valid JSON: $geoJSON")
        }
    }

    it should ".toGeoJSON(start)" in {
        val trip = new Trip("Some Trip", new GregorianCalendar(2013, 12, 14),
                            Set("Andrea", "Brett"), List(Nowhere), start=start)
        val coords = trip.toGeoJSON.obj("geometry").asInstanceOf[JSONObject].obj("coordinates").asInstanceOf[JSONArray].list
        coords should be (List(
                List(start.latlong._1, start.latlong._2),
                List(Nowhere.latlong._1, Nowhere.latlong._2)))
    }

    it should ".toGeoJSON(end)" in {
        val trip = new Trip("Some Trip", new GregorianCalendar(2013, 12, 14),
                            Set("Andrea", "Brett"), List(Nowhere), end=end)
        val coords = trip.toGeoJSON.obj("geometry").asInstanceOf[JSONObject].obj("coordinates").asInstanceOf[JSONArray].list
        coords should be (List(
                List(Nowhere.latlong._1, Nowhere.latlong._2),
                List(end.latlong._1, end.latlong._2)))

    }

    it should ".toGeoJSON(start, end)" in {
        val trip = new Trip("Some Trip", new GregorianCalendar(2013, 12, 14),
                            Set("Andrea", "Brett"), List(Nowhere), start, end)
        val coords = trip.toGeoJSON.obj("geometry").asInstanceOf[JSONObject].obj("coordinates").asInstanceOf[JSONArray].list
        coords should be (List(
                List(start.latlong._1, start.latlong._2),
                List(Nowhere.latlong._1, Nowhere.latlong._2),
                List(end.latlong._1, end.latlong._2)))

    }

    it should ".toGeoJSON(properties)" in {
        val trip = new Trip("Some Trip", new GregorianCalendar(2013, 12, 14),
                            Set("Andrea", "Brett"), List(Nowhere))
        val extraProps = Map("key" -> "value")
        val props = trip.toGeoJSON(extraProps).obj("properties").asInstanceOf[JSONObject].obj
        props should contain ("key" -> "value")
        props should contain ("name" -> trip.title)
    }
}

class TripsHistorySpec extends FlatSpec with Matchers {

    class DumbTripsHistory extends TripsHistory {
        override def createCity(name: String) = new DumbCity(name)
    }

    val title = "Some Trip"
    val travellers = Set("Andrea", "Brett")
    val whereTo = List("Vancouver, BC, CA")

    val defaultTrip = Map(
            "title" -> title,
            "travellers" -> travellers.toList,
            "where" -> whereTo)

    "TripsHistory" should ".parseTrip() w/o start, end" in {
        val trip = new DumbTripsHistory().parseTrip(defaultTrip)

        trip.title should be (title)
        trip.travellers should be (travellers)
        trip.where should be (whereTo map (new DumbCity(_)))
        trip.start should be (Nowhere)
        trip.end should be (Nowhere)
    }

    it should ".parseTrip() w/ start" in {
        val details = defaultTrip + ("start" -> "Toronto, ON, CA")
        val trip = new DumbTripsHistory().parseTrip(details)

        trip.start should be (new DumbCity("Toronto, ON, CA"))
    }

    it should ".parseTrip() w/ end" in {
        val details = defaultTrip + ("end" -> "Toronto, ON, CA")
        val trip = new DumbTripsHistory().parseTrip(details)

        trip.end should be (new DumbCity("Toronto, ON, CA"))
    }

    it should ".parseTrip() w/ start, end" in {
        val details = defaultTrip + ("start" -> "Toronto, ON, CA") + ("end" -> "San Francisco, CA, US")
        val trip = new DumbTripsHistory().parseTrip(details)

        trip.start should be (new DumbCity("Toronto, ON, CA"))
        trip.end should be (new DumbCity("San Francisco, CA, US"))
    }

    it should ".toGeoJSON()" in {
        // XXX
    }
}

class CLISpec extends FlatSpec with Matchers {

    "The CLI" should "parse JSON" in {
        val json = """
            {
                "trips": [
                    {
                        "title": "Some Trip",
                        "travellers": ["Brett"],
                        "when": "2013-12",
                        "where": ["Vancouver, BC, CA"],
                        "start": "Toronto, ON, CA",
                        "end": "San Francisco, CA, US"
                    }
                ]
            }
        """
        val translated: String = CLI.parseJSON(json)
        val geoJSON = JSON.parseFull(translated) match {
                case Some(jsonObject) => jsonObject
                case None => fail(s"not emitting valid JSON: $translated")
        }

        // XXX verify details?
    }
}
