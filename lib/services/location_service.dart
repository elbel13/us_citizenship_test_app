import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle location permissions and government official lookup
class LocationService {
  /// Request location permission from the user
  Future<bool> requestLocationPermission() async {
    // Check if permission is already granted
    final status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    }

    // Request permission
    final result = await Permission.location.request();
    return result.isGranted;
  }

  /// Get current position
  /// Throws exception if permission is denied or location services are disabled
  Future<Position?> getCurrentPosition() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException(
        'Location services are disabled. Please enable location services in your device settings.',
      );
    }

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw PermissionDeniedException(
        'Location permissions are permanently denied. Please enable them in app settings.',
      );
    }

    // Get position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy:
          LocationAccuracy.low, // We only need state-level accuracy
    );
  }

  /// Get state from zip code
  /// This is a simplified implementation - in production, you'd use a zip code database
  /// or API to get accurate state information
  String? getStateFromZipCode(String zipCode) {
    // Basic validation
    if (zipCode.length != 5) {
      return null;
    }

    final int? zip = int.tryParse(zipCode);
    if (zip == null) {
      return null;
    }

    // Simplified zip code to state mapping (first digit patterns)
    // This is not comprehensive - a full implementation would use a proper database
    if (zip >= 35000 && zip <= 36999) return 'Alabama';
    if (zip >= 99500 && zip <= 99999) return 'Alaska';
    if (zip >= 85000 && zip <= 86999) return 'Arizona';
    if (zip >= 71600 && zip <= 72999) return 'Arkansas';
    if (zip >= 90000 && zip <= 96699) return 'California';
    if (zip >= 80000 && zip <= 81999) return 'Colorado';
    if (zip >= 6000 && zip <= 6999) return 'Connecticut';
    if (zip >= 19700 && zip <= 19999) return 'Delaware';
    if (zip >= 32000 && zip <= 34999) return 'Florida';
    if (zip >= 30000 && zip <= 31999) return 'Georgia';
    if (zip >= 96700 && zip <= 96899) return 'Hawaii';
    if (zip >= 83200 && zip <= 83999) return 'Idaho';
    if (zip >= 60000 && zip <= 62999) return 'Illinois';
    if (zip >= 46000 && zip <= 47999) return 'Indiana';
    if (zip >= 50000 && zip <= 52999) return 'Iowa';
    if (zip >= 66000 && zip <= 67999) return 'Kansas';
    if (zip >= 40000 && zip <= 42999) return 'Kentucky';
    if (zip >= 70000 && zip <= 71599) return 'Louisiana';
    if (zip >= 3900 && zip <= 4999) return 'Maine';
    if (zip >= 20600 && zip <= 21999) return 'Maryland';
    if (zip >= 1000 && zip <= 2799) return 'Massachusetts';
    if (zip >= 48000 && zip <= 49999) return 'Michigan';
    if (zip >= 55000 && zip <= 56999) return 'Minnesota';
    if (zip >= 38600 && zip <= 39999) return 'Mississippi';
    if (zip >= 63000 && zip <= 65999) return 'Missouri';
    if (zip >= 59000 && zip <= 59999) return 'Montana';
    if (zip >= 68000 && zip <= 69999) return 'Nebraska';
    if (zip >= 88900 && zip <= 89999) return 'Nevada';
    if (zip >= 3000 && zip <= 3899) return 'New Hampshire';
    if (zip >= 7000 && zip <= 8999) return 'New Jersey';
    if (zip >= 87000 && zip <= 88499) return 'New Mexico';
    if (zip >= 10000 && zip <= 14999) return 'New York';
    if (zip >= 27000 && zip <= 28999) return 'North Carolina';
    if (zip >= 58000 && zip <= 58999) return 'North Dakota';
    if (zip >= 43000 && zip <= 45999) return 'Ohio';
    if (zip >= 73000 && zip <= 74999) return 'Oklahoma';
    if (zip >= 97000 && zip <= 97999) return 'Oregon';
    if (zip >= 15000 && zip <= 19699) return 'Pennsylvania';
    if (zip >= 2800 && zip <= 2999) return 'Rhode Island';
    if (zip >= 29000 && zip <= 29999) return 'South Carolina';
    if (zip >= 57000 && zip <= 57999) return 'South Dakota';
    if (zip >= 37000 && zip <= 38599) return 'Tennessee';
    if (zip >= 75000 && zip <= 79999 || zip >= 88500 && zip <= 88599) {
      return 'Texas';
    }
    if (zip >= 84000 && zip <= 84999) return 'Utah';
    if (zip >= 5000 && zip <= 5999) return 'Vermont';
    if (zip >= 20100 && zip <= 20199 || zip >= 22000 && zip <= 24699) {
      return 'Virginia';
    }
    if (zip >= 98000 && zip <= 99499) return 'Washington';
    if (zip >= 24700 && zip <= 26999) return 'West Virginia';
    if (zip >= 53000 && zip <= 54999) return 'Wisconsin';
    if (zip >= 82000 && zip <= 83199) return 'Wyoming';
    if (zip >= 20000 && zip <= 20099 || zip >= 20200 && zip <= 20599) {
      return 'District of Columbia';
    }

    return null;
  }

  /// Get government officials for a state
  /// This is a placeholder - actual implementation would call congress.gov API
  /// or maintain a database of current officials
  Future<GovernmentOfficials> getOfficialsForState(String state) async {
    // TODO: Implement actual API calls to congress.gov and usa.gov
    // For now, return placeholder data
    // Users will need to manually verify and update this information

    return GovernmentOfficials(
      state: state,
      governor: 'Your state\'s current governor',
      senator1: 'One of your state\'s current U.S. Senators',
      senator2: 'One of your state\'s current U.S. Senators',
      representative: 'Your U.S. Representative',
      needsManualVerification: true,
    );
  }

  /// Get government officials from zip code
  Future<GovernmentOfficials?> getOfficialsFromZipCode(String zipCode) async {
    final state = getStateFromZipCode(zipCode);
    if (state == null) {
      return null;
    }

    return await getOfficialsForState(state);
  }
}

/// Model for government officials
class GovernmentOfficials {
  final String state;
  final String governor;
  final String senator1;
  final String senator2;
  final String representative;
  final bool needsManualVerification;

  GovernmentOfficials({
    required this.state,
    required this.governor,
    required this.senator1,
    required this.senator2,
    required this.representative,
    this.needsManualVerification = false,
  });
}

/// Exception thrown when location services are disabled
class LocationServiceDisabledException implements Exception {
  final String message;
  LocationServiceDisabledException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when location permission is permanently denied
class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);

  @override
  String toString() => message;
}
