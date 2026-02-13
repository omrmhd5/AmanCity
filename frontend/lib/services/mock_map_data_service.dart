import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/map_incident.dart';
import '../models/emergency_poi.dart';
import '../models/danger_zone.dart';

class MockMapDataService {
  // Cairo coordinates: 30.0444° N, 31.2357° E
  static const LatLng cairoCenter = LatLng(30.0444, 31.2357);

  // Mock incidents around Cairo
  static List<MapIncident> getMockIncidents() {
    return [
      MapIncident(
        id: 'inc_1',
        type: IncidentType.harassment,
        severity: SeverityLevel.high,
        position: const LatLng(30.0464, 31.2337), // Near Tahrir
        title: 'Verbal Harassment',
        description:
            'Reported near Tahrir Square entrance. Large group gathering.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      MapIncident(
        id: 'inc_2',
        type: IncidentType.theft,
        severity: SeverityLevel.medium,
        position: const LatLng(30.0404, 31.2297), // Downtown area
        title: 'Theft Report',
        description: 'Pickpocketing incident reported in crowded area.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      MapIncident(
        id: 'inc_3',
        type: IncidentType.suspicious,
        severity: SeverityLevel.low,
        position: const LatLng(30.0484, 31.2407), // Garden City
        title: 'Suspicious Activity',
        description: 'Suspicious vehicle reported in residential area.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      MapIncident(
        id: 'inc_4',
        type: IncidentType.harassment,
        severity: SeverityLevel.medium,
        position: const LatLng(30.0424, 31.2387), // Corniche
        title: 'Street Harassment',
        description: 'Catcalling reported on Corniche walkway.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      MapIncident(
        id: 'inc_5',
        type: IncidentType.assault,
        severity: SeverityLevel.critical,
        position: const LatLng(30.0374, 31.2337), // Ramses area
        title: 'Physical Assault',
        description: 'Assault reported near train station. Police notified.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  // Mock emergency POIs around Cairo
  static List<EmergencyPOI> getMockPOIs() {
    return [
      EmergencyPOI(
        id: 'poi_1',
        type: POIType.hospital,
        position: const LatLng(30.0444, 31.2427),
        name: 'Cairo University Hospital',
        address: 'El-Manial, Cairo',
        phoneNumber: '+20 2 23648261',
      ),
      EmergencyPOI(
        id: 'poi_2',
        type: POIType.policeStation,
        position: const LatLng(30.0474, 31.2357),
        name: 'Qasr El Nil Police Station',
        address: 'Downtown, Cairo',
        phoneNumber: '122',
      ),
      EmergencyPOI(
        id: 'poi_3',
        type: POIType.hospital,
        position: const LatLng(30.0394, 31.2307),
        name: 'El-Monira Hospital',
        address: 'El-Monira, Cairo',
        phoneNumber: '+20 2 23648533',
      ),
      EmergencyPOI(
        id: 'poi_4',
        type: POIType.safeCafe,
        position: const LatLng(30.0454, 31.2307),
        name: 'Safe Haven Café',
        address: 'Talaat Harb, Downtown',
        phoneNumber: '+20 2 27963666',
      ),
      EmergencyPOI(
        id: 'poi_5',
        type: POIType.policeStation,
        position: const LatLng(30.0404, 31.2437),
        name: 'Garden City Police Station',
        address: 'Garden City, Cairo',
        phoneNumber: '122',
      ),
      EmergencyPOI(
        id: 'poi_6',
        type: POIType.safeZone,
        position: const LatLng(30.0494, 31.2387),
        name: 'Community Safe Zone',
        address: 'Zamalek Bridge Area',
        phoneNumber: null,
      ),
    ];
  }

  // Mock danger zones around Cairo
  static List<DangerZone> getMockDangerZones() {
    return [
      DangerZone(
        id: 'zone_1',
        center: const LatLng(30.0464, 31.2337), // Tahrir area
        radiusMeters: 300,
        level: DangerLevel.high,
        description: 'High incident rate area - exercise caution',
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      DangerZone(
        id: 'zone_2',
        center: const LatLng(30.0374, 31.2337), // Ramses
        radiusMeters: 250,
        level: DangerLevel.medium,
        description: 'Crowded area with moderate safety concerns',
        lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      DangerZone(
        id: 'zone_3',
        center: const LatLng(30.0404, 31.2287), // Western Downtown
        radiusMeters: 200,
        level: DangerLevel.low,
        description: 'Low lighting reported in evening hours',
        lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  // Get safe zone around user (complementary to danger zones)
  static List<DangerZone> getMockSafeZones() {
    return [
      DangerZone(
        id: 'safe_1',
        center: const LatLng(30.0494, 31.2387), // Zamalek bridge
        radiusMeters: 200,
        level: DangerLevel.low, // Repurposed to represent safe zone
        description: 'Safe Zone - Police presence active',
        lastUpdated: DateTime.now(),
      ),
    ];
  }
}
