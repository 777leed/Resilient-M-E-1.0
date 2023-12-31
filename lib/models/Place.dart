import 'package:montoring_app/models/Infrastructure.dart';
import 'package:montoring_app/models/Population.dart';
import 'package:montoring_app/models/Supplies.dart';
import 'package:montoring_app/models/Contacts.dart';

class Place {
  String name;
  double latitude;
  double longitude;
  String status;
  List<String>? needs;
  List<Supplies>? supplies;
  Population? population;
  Infrastructure? infrastructure;
  List<Contacts>? contacts;
  String addedBy; // AddedBy attribute

  Place({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.needs,
    this.supplies,
    this.population,
    this.infrastructure,
    this.contacts,
    required this.addedBy, // AddedBy attribute
  });

  factory Place.fromFirestore(Map<String, dynamic> data) {
    return Place(
      name: data['name'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      status: data['status'],
      needs: List<String>.from(data['needs'] ?? []),
      supplies: (data['supplies'] as List<dynamic>?)
          ?.map((supply) => Supplies.fromMap(supply))
          .toList(),
      population: data['population'] != null
          ? Population.fromMap(data['population'])
          : null,
      infrastructure: Infrastructure.fromMap(data['infrastructure'] ??
          {}), // Assuming infrastructure is represented as a map
      contacts: (data['contacts'] as List<dynamic>?)
          ?.map((contact) => Contacts.fromMap(contact))
          .toList(),
      addedBy: data['AddedBy'], // AddedBy attribute
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'needs': needs,
      'supplies': supplies?.map((supply) => supply.toMap()).toList(),
      'population': population != null ? population!.toMap() : null,
      'infrastructure': infrastructure!
          .toMap(), // Assuming infrastructure can be converted to a map
      'contacts': contacts?.map((contact) => contact.toMap()).toList(),
      'addedBy': addedBy, // AddedBy attribute
    };
  }
}
