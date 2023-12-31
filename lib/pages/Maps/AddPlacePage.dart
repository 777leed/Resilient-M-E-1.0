import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:montoring_app/components/categorieButton.dart';
import 'package:montoring_app/components/goback.dart';
import 'package:montoring_app/models/Place.dart';
import 'package:montoring_app/pages/wherePage.dart';
import 'package:montoring_app/styles.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class AddPlacePage extends StatefulWidget {
  const AddPlacePage({Key? key});

  @override
  State<AddPlacePage> createState() => _AddPlacePageState();
}

class _AddPlacePageState extends State<AddPlacePage> {
  bool isLoading = false;
  List<dynamic>? selectedMarker;
  Place? selectedPlace;
  String? id;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  GoogleMapController? _googleMapController;

  var dropdownValue = "Unknown";
  Set<Marker> myMarkers = {};
  List<String> list = <String>[
    'Unknown',
    'Safe',
    'Severe',
    'Moderate',
    'Minor'
  ];
  List<dynamic> availablePlaces = [];
  final userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    selectedMarker = [];
    loadMarkers();
    super.initState();
  }

  Future<void> addCurrentLocationToFirestore() async {
    try {
      // Request location permissions
      PermissionStatus status = await Permission.location.request();

      if (status.isGranted) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Loading..."),
                ],
              ),
            );
          },
        );

        // Get the current location
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Get the address information based on the coordinates
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        String placeName = "Unknown Place";

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String street = place.street ?? "";
          String subLocality = place.subLocality ?? "";
          String subAdministrativeArea = place.subAdministrativeArea ?? "";
          String postalCode = place.postalCode ?? "";

          placeName = "$street $subLocality $subAdministrativeArea $postalCode";
        }
        final nameController = TextEditingController();
        final latitudeController =
            TextEditingController(text: position.latitude.toString());
        final longitudeController =
            TextEditingController(text: position.longitude.toString());

        Navigator.of(context).pop(); // Close loading indicator

        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Add Current Location'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Title(color: Colors.black, child: Text(placeName)),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Custom Name",
                      ),
                    ),
                    TextFormField(
                      controller: latitudeController,
                      decoration: InputDecoration(
                        labelText: 'Latitude',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: longitudeController,
                      decoration: InputDecoration(
                        labelText: 'Longitude',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Save'),
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        nameController.text != "" &&
                        nameController.text.length < 20) {
                      String customName = nameController.text.isNotEmpty
                          ? nameController.text
                          : "unknown";
                      final double newlatitude =
                          double.parse(latitudeController.text);
                      final double newlongitude =
                          double.parse(longitudeController.text);

                      addPlaceToFirestore(
                        customName,
                        newlatitude,
                        newlongitude,
                        dropdownValue,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Current location added as a marker: $customName'),
                        ),
                      );

                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Name Is Empty or Is too long'),
                        ),
                      );
                    }
                  },
                ),
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permissions denied'),
          ),
        );
      }
    } catch (e) {
      print('Error adding current location to Firestore: $e');
    }
  }

  Future<void> updatePlace(Function callback) async {
    if (selectedMarker != null && selectedMarker!.isNotEmpty) {
      final selectedLatitude = selectedMarker![0].position.latitude;
      final selectedLongitude = selectedMarker![0].position.longitude;
      try {
        final querySnapshot = await firestore
            .collection('places')
            .where('latitude', isEqualTo: selectedLatitude)
            .where('longitude', isEqualTo: selectedLongitude)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final placeId = querySnapshot.docs[0].id;

          final placeDoc =
              await firestore.collection('places').doc(placeId).get();
          if (placeDoc.exists) {
            final place = placeDoc.data();
            final name = place!['name'];
            final latitude = place['latitude'];
            final longitude = place['longitude'];
            final status = place['status'];
            final needs = List<String>.from(place['needs'] ?? []);

            setState(() {
              selectedPlace = Place(
                  name: name,
                  latitude: latitude,
                  longitude: longitude,
                  status: status,
                  needs: needs,
                  addedBy: userId);
              id = placeId;
            });
            callback();
          }
        } else {
          print(
              'Place not found for latitude: $selectedLatitude, longitude: $selectedLongitude');
        }
      } catch (e) {
        print('Error getting place from Firestore: $e');
      }
    }
  }

  Future<void> deleteMarker(double latitude, double longitude) async {
    try {
      final querySnapshot = await firestore
          .collection('places')
          .where('latitude', isEqualTo: latitude)
          .where('longitude', isEqualTo: longitude)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final placeId = querySnapshot.docs[0].id;

        await firestore.collection('places').doc(placeId).delete();
        selectedMarker = [];

        loadMarkers();
      } else {
        print('Place not found for latitude: $latitude, longitude: $longitude');
      }
    } catch (e) {
      print('Error deleting place from Firestore: $e');
    }
  }

  Future<void> addPlaceToFirestore(
    String name,
    double latitude,
    double longitude,
    String status,
  ) async {
    try {
      final querySnapshot = await firestore
          .collection('places')
          .where('latitude', isEqualTo: latitude)
          .where('longitude', isEqualTo: longitude)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location already added'),
          ),
        );
      } else {
        await firestore.collection('places').add({
          'name': name,
          'latitude': latitude,
          'longitude': longitude,
          'status': status,
          'needs': [],
          'infrastructure': [],
          'population': [],
          'supplies': [],
          'contacts': [],
          'AddedBy': userId
        });
      }

      loadMarkers();
    } catch (e) {
      print('Error adding place to Firestore: $e');
    }
  }

  void loadMarkers() async {
    try {
      final placesSnapshot = await firestore.collection('places').get();
      final places = placesSnapshot.docs;

      final updatedMarkers = <Marker>{};
      for (final place in places) {
        final name = place.get('name');
        final latitude = place.get('latitude');
        final longitude = place.get('longitude');
        final status = place.get('status');

        BitmapDescriptor markerIcon;
        switch (status) {
          case 'Safe':
            markerIcon = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            );
            break;
          case 'Severe':
            markerIcon = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            );
            break;
          case 'Moderate':
            markerIcon = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            );
            break;
          case 'Minor':
            markerIcon = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueYellow,
            );
            break;
          default:
            markerIcon = BitmapDescriptor.defaultMarker;
            break;
        }

        final marker = Marker(
          markerId: MarkerId(name),
          position: LatLng(latitude, longitude),
          icon: markerIcon,
          onTap: () {
            setState(() {
              selectedMarker = [
                Marker(
                  markerId: MarkerId(name),
                  position: LatLng(latitude, longitude),
                  icon: markerIcon,
                ),
                status,
              ];
            });
          },
        );

        updatedMarkers.add(marker);
      }

      setState(() {
        myMarkers = updatedMarkers;
      });
    } catch (e) {
      print('Error loading markers from Firestore: $e');
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Future<void> showPlaceList() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _buildLoadingIndicator();
      },
    );

    try {
      final placesSnapshot = await firestore.collection('places').get();
      final places = placesSnapshot.docs;

      final placeList = places.map((place) {
        final name = place.get('name');
        final latitude = place.get('latitude');
        final longitude = place.get('longitude');
        final status = place.get('status');
        final addedby = place.get('AddedBy');

        return Place(
            name: name,
            latitude: latitude,
            longitude: longitude,
            status: status,
            addedBy: addedby);
      }).toList();

      // Close loading indicator
      Navigator.of(context).pop();

      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return ListView.builder(
            itemCount: placeList.length,
            itemBuilder: (context, index) {
              final place = placeList[index];
              return ListTile(
                title: Text(place.name),
                subtitle: Text("Status: ${place.status}"),
                onTap: () {
                  // Close the modal and navigate to the selected place
                  Navigator.pop(context);
                  _goToPlaceOnMap(place);
                },
              );
            },
          );
        },
      );
    } catch (e) {
      print('Error loading places from Firestore: $e');
      // Close loading indicator in case of an error
      Navigator.of(context).pop();
    }
  }

  void _goToPlaceOnMap(Place place) {
    final cameraPosition = CameraPosition(
      target: LatLng(place.latitude, place.longitude),
      zoom: 15.0,
    );

    _googleMapController!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    // Update the selectedMarker when you navigate to the selected place
    setState(() {
      selectedMarker = [
        Marker(
          markerId: MarkerId(place.name), // Use a unique markerId
          position: LatLng(place.latitude, place.longitude),
        ),
        place.status,
      ];
    });
  }

  void navigateToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => wherePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        navigateToHomePage();
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: GoBack(
                  title: "MAP",
                  onTap: () {
                    navigateToHomePage();
                  },
                ),
              ),
              Expanded(
                child: GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _googleMapController = controller;
                  },
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(31.794525, -7.0849336),
                    zoom: 7,
                  ),
                  markers: myMarkers,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  selectedMarker != null &&
                                          selectedMarker!.isNotEmpty
                                      ? selectedMarker![0].markerId.value
                                      : "Select an Area",
                                  style: TextStyle(fontSize: 20),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.pin_drop_rounded)
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  selectedMarker != null &&
                                          selectedMarker!.isNotEmpty
                                      ? "Status: ${selectedMarker![1]}"
                                      : "Status: Invalid",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Spacer(),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                addCurrentLocationToFirestore();
                              },
                              child: Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: CustomColors.mainColor,
                                ),
                                child: Icon(
                                  Icons.add_location,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        categorieButton(
                          text: "All Areas",
                          icon: Icon(
                            Icons.local_attraction,
                            color: Colors.white,
                          ),
                          color: CustomColors.mainColor,
                          onTap: () {
                            showPlaceList();
                          },
                        ),
                        categorieButton(
                          text: "Remove Area",
                          icon: Icon(
                            Icons.remove_circle_outline_rounded,
                            color: Colors.white,
                          ),
                          color: const Color.fromARGB(255, 119, 14, 14),
                          onTap: () {
                            deleteMarker(selectedMarker![0].position.latitude,
                                selectedMarker![0].position.longitude);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
