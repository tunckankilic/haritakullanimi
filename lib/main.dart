// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

//Google Servisten alınan geçici api anahtarı
const gApiKey = "AIzaSyASN-XHVoXc78gyYQVnWCwS8Vh4aLB2-vQ";

class _HomePageState extends State<HomePage> {
  //Arama alanı geçişi için scaffold anahtarı
  final homeScaffold = GlobalKey<ScaffoldState>();
  //Cihaz içi lokasyon izni alımı sağlar
  Future<Position> konumIzniAl() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }

  final mode = Mode.overlay;
  //Hata durumunda olacak olan aksiyon
  void onError(PlacesAutocompleteResponse hata) {
    homeScaffold.currentState!.showSnackBar(
      SnackBar(
        content: Text(
          hata.errorMessage.toString(),
        ),
      ),
    );
  }

  //Arama alanı tahmini sağlar
  Future<void> tahminGosterimi(
      {required Prediction p, required ScaffoldState scaffoldState}) async {
    //Harita kullanım setup
    GoogleMapsPlaces places = GoogleMapsPlaces(
        apiKey: gApiKey, apiHeaders: await GoogleApiHeaders().getHeaders());
    //Girilecek olan metin için arama
    PlacesDetailsResponse detailsResponse =
        await places.getDetailsByPlaceId(p.placeId.toString());
    final lat = detailsResponse.result.geometry!.location.lat;
    final lng = detailsResponse.result.geometry!.location.lng;
    markersList.clear();
    markersList.add(
      //Haritada nokta gösterimi sağlayan imleç
      Marker(
          markerId: MarkerId("0"),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: detailsResponse.result.name)),
    );
    setState(() {});
    googleMapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(lat, lng),
        12,
      ),
    );
  }

  @override
  void initState() {
    konumIzniAl();
    super.initState();
  }

  //Harita Kontrolcüsü
  late GoogleMapController googleMapController;
  //Varsayılan nokta(Uygulama apisinden müşteri koordinatları latlng parametrelerine girilecek)
  var baslangic = CameraPosition(
    target: LatLng(
      36.782599,
      34.572200,
    ),
    zoom: 12,
  );

  //imleç kayıt listesi
  Set<Marker> markersList = {};

  //Arama alanı oluşturan method
  //Google textfield oluşturur
  Future<void> _aramaAlani() async {
    Prediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey: gApiKey,
      onError: onError,
      mode: mode,
      language: "tr",
      strictbounds: false,
      types: [""],
      components: [
        Component(
          Component.country,
          "tr",
        ),
      ],
      decoration: InputDecoration(
        hintText: "Ara...",
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.white,
          ),
        ),
      ),
    );
    tahminGosterimi(p: p!, scaffoldState: homeScaffold.currentState!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: homeScaffold,
      appBar: AppBar(
        title: Text('Maps Kullanımı'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: baslangic,
            markers: markersList,
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController controller) {
              googleMapController = controller;
            },
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    _aramaAlani();
                  },
                  child: Text("Konum Ara"),
                ),
                SizedBox(
                  width: 20,
                ),
               
              ],
            ),
          ),
        ],
      ),
    );
  }
}
