import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Service for fetching government officials data
///
/// Uses a hybrid approach:
/// - Static JSON for President, VP, and Governors (updated with app releases)
/// - whoismyrepresentative.com API for Senators and Representatives (no auth required)
///
/// Benefits:
/// - No API keys needed
/// - Works offline for governors
/// - Up-to-date senators and representatives
/// - No quota limits or DOS concerns (free public API)
class GovernmentOfficialsApiService {
  static const String _baseUrl = 'https://whoismyrepresentative.com';
  static Map<String, dynamic>? _cachedStaticData;

  /// Load and cache the static government officials data from assets
  Future<Map<String, dynamic>> _loadStaticData() async {
    if (_cachedStaticData != null) {
      return _cachedStaticData!;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/government_officials.json',
      );
      _cachedStaticData = json.decode(jsonString) as Map<String, dynamic>;
      return _cachedStaticData!;
    } catch (e) {
      throw Exception('Failed to load government officials data: $e');
    }
  }

  /// Fetch senators by state from whoismyrepresentative.com API
  /// Returns list of senator names
  Future<List<String>> _fetchSenatorsByState(String stateAbbr) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/getall_sens_bystate.php?state=$stateAbbr&output=json',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('results')) {
          final results = data['results'] as List<dynamic>;
          return results.map((s) => s['name'] as String).toList();
        } else if (data is List) {
          return data.map((s) => s['name'] as String).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching senators: $e');
      return [];
    }
  }

  /// Fetch representatives by zip code from whoismyrepresentative.com API
  /// Returns list of representative names
  Future<List<String>> _fetchRepresentativesByZip(String zipCode) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/getall_reps_byzip.php?zip=$zipCode&output=json',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('results')) {
          final results = data['results'] as List<dynamic>;
          return results.map((r) => r['name'] as String).toList();
        } else if (data is List) {
          return data.map((r) => r['name'] as String).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching representatives: $e');
      return [];
    }
  }

  /// Fetch government officials by state name and optional zip code
  ///
  /// Returns a map containing:
  /// - president: String (from static data)
  /// - vicePresident: String (from static data)
  /// - governor: String (from static data)
  /// - senators: List<String> (from API)
  /// - representatives: List<String> (from API if zip provided)
  /// - state: String (the state name provided)
  /// - lastUpdated: String (when static data was last updated)
  Future<Map<String, dynamic>> getOfficialsByState(
    String state, {
    String? zipCode,
  }) async {
    final staticData = await _loadStaticData();
    final governors = staticData['governors'] as Map<String, dynamic>?;

    if (governors == null) {
      throw Exception('Invalid government officials data format');
    }

    // Normalize state name (handle case variations)
    final normalizedState = _findStateKey(governors.keys.toList(), state);

    if (normalizedState == null) {
      throw Exception('State not found: $state');
    }

    // Get state abbreviation for API calls
    final stateAbbr = _getStateAbbreviation(normalizedState);

    // Fetch senators from API
    final senators = await _fetchSenatorsByState(stateAbbr);

    // Fetch representatives if zip code provided
    List<String> representatives = [];
    if (zipCode != null && zipCode.isNotEmpty) {
      representatives = await _fetchRepresentativesByZip(zipCode);
    }

    return {
      'president': staticData['president'] as String? ?? '',
      'vicePresident': staticData['vicePresident'] as String? ?? '',
      'governor': governors[normalizedState] as String? ?? '',
      'senators': senators,
      'representatives': representatives,
      'state': normalizedState,
      'stateAbbr': stateAbbr,
      'lastUpdated': staticData['lastUpdated'] as String? ?? '',
    };
  }

  /// Fetch officials by zip code
  /// This will attempt to derive the state from zip code
  Future<Map<String, dynamic>> getOfficialsByZipCode(
    String state,
    String zipCode,
  ) async {
    return await getOfficialsByState(state, zipCode: zipCode);
  }

  /// Find the correct state key from available keys (case-insensitive)
  String? _findStateKey(List<String> availableStates, String searchState) {
    final searchLower = searchState.toLowerCase().trim();

    for (final state in availableStates) {
      if (state.toLowerCase() == searchLower) {
        return state;
      }
    }

    return null;
  }

  /// Get state abbreviation from full state name
  String _getStateAbbreviation(String stateName) {
    const stateAbbreviations = {
      'Alabama': 'AL',
      'Alaska': 'AK',
      'Arizona': 'AZ',
      'Arkansas': 'AR',
      'California': 'CA',
      'Colorado': 'CO',
      'Connecticut': 'CT',
      'Delaware': 'DE',
      'Florida': 'FL',
      'Georgia': 'GA',
      'Hawaii': 'HI',
      'Idaho': 'ID',
      'Illinois': 'IL',
      'Indiana': 'IN',
      'Iowa': 'IA',
      'Kansas': 'KS',
      'Kentucky': 'KY',
      'Louisiana': 'LA',
      'Maine': 'ME',
      'Maryland': 'MD',
      'Massachusetts': 'MA',
      'Michigan': 'MI',
      'Minnesota': 'MN',
      'Mississippi': 'MS',
      'Missouri': 'MO',
      'Montana': 'MT',
      'Nebraska': 'NE',
      'Nevada': 'NV',
      'New Hampshire': 'NH',
      'New Jersey': 'NJ',
      'New Mexico': 'NM',
      'New York': 'NY',
      'North Carolina': 'NC',
      'North Dakota': 'ND',
      'Ohio': 'OH',
      'Oklahoma': 'OK',
      'Oregon': 'OR',
      'Pennsylvania': 'PA',
      'Rhode Island': 'RI',
      'South Carolina': 'SC',
      'South Dakota': 'SD',
      'Tennessee': 'TN',
      'Texas': 'TX',
      'Utah': 'UT',
      'Vermont': 'VT',
      'Virginia': 'VA',
      'Washington': 'WA',
      'West Virginia': 'WV',
      'Wisconsin': 'WI',
      'Wyoming': 'WY',
      'District of Columbia': 'DC',
    };

    return stateAbbreviations[stateName] ?? stateName;
  }

  /// Get the date when the static officials data was last updated
  Future<String> getLastUpdatedDate() async {
    final data = await _loadStaticData();
    return data['lastUpdated'] as String? ?? 'Unknown';
  }
}
