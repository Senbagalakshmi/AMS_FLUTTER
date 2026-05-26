import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart'; // For ApiService.baseUrl and headers

// ─────────────────────────────────────────────────────────────────────────────
// DTOs
// ─────────────────────────────────────────────────────────────────────────────

class LocationCountry {
  final int countryid;
  final String countrycode;
  final String countryname;
  final String callcode;

  const LocationCountry({
    required this.countryid,
    required this.countrycode,
    required this.countryname,
    required this.callcode,
  });

  factory LocationCountry.fromJson(Map<String, dynamic> j) => LocationCountry(
        countryid: _int(j['countryid']),
        countrycode: j['countrycode']?.toString() ?? '',
        countryname: j['countryname']?.toString() ?? '',
        callcode: j['callcode']?.toString() ?? '',
      );

  /// Display label shown in the dropdown list.
  String get displayName => countryname;

  /// Country dial-code prefix e.g. "+91"
  String get dialCode => callcode.startsWith('+') ? callcode : '+$callcode';
}

class LocationState {
  final int stateid;
  final String statecode;
  final String statename;

  const LocationState({
    required this.stateid,
    required this.statecode,
    required this.statename,
  });

  factory LocationState.fromJson(Map<String, dynamic> j) => LocationState(
        stateid: _int(j['stateid']),
        statecode: j['statecode']?.toString() ?? '',
        statename: j['statename']?.toString() ?? '',
      );

  String get displayName => statename;
}

class LocationDistrict {
  final int cityid;
  final String cityname;

  const LocationDistrict({required this.cityid, required this.cityname});

  factory LocationDistrict.fromJson(Map<String, dynamic> j) => LocationDistrict(
        cityid: _int(j['cityid']),
        cityname: j['cityname']?.toString() ?? '',
      );

  String get displayName => cityname;
}

class LocationPincode {
  final int pincodeid;
  final String pincode;
  final String areaname;

  const LocationPincode({
    required this.pincodeid,
    required this.pincode,
    required this.areaname,
  });

  factory LocationPincode.fromJson(Map<String, dynamic> j) => LocationPincode(
        pincodeid: _int(j['pincodeid']),
        pincode: j['pincode']?.toString() ?? '',
        areaname: j['areaname']?.toString() ?? '',
      );

  /// Shows "600001 - T Nagar" style in pincode dropdown.
  String get displayName =>
      areaname.isNotEmpty ? '$pincode - $areaname' : pincode;
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class LocationApiService {
  /// Derives the location base-URL from the same host as the finance API.
  /// e.g. if ApiService.baseUrl == "https://host/api"
  ///      then locationBase    == "https://host/api/location"
  ///
  /// Adjust the segment below if your gateway mounts the location service
  /// at a different path (e.g. "/api/location" or "/location").
  String get _base => '${ApiService.baseUrl}/location';

  // Re-use the same auth token already stored in the singleton apiService.
  Map<String, String> get _headers => apiService.headers;

  // ── Simple JSON-list helper ──────────────────────────────────────────────

  Future<List<T>> _getList<T>(
    String url,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final dynamic body = jsonDecode(res.body);
        if (body is List) {
          return body.whereType<Map<String, dynamic>>().map(fromJson).toList();
        }
      }
    } catch (e) {
      // Surface errors to the developer console; caller handles gracefully.
      print('LocationApiService error [$url]: $e');
    }
    return [];
  }

  // ── Public API calls ─────────────────────────────────────────────────────

  /// GET /api/location/countries
  Future<List<LocationCountry>> getCountries() =>
      _getList('$_base/countries', LocationCountry.fromJson);

  /// GET /api/location/states/{countryId}
  Future<List<LocationState>> getStates(int countryId) =>
      _getList('$_base/states/$countryId', LocationState.fromJson);

  /// GET /api/location/districts/{countryId}/{stateId}
  Future<List<LocationDistrict>> getDistricts(int countryId, int stateId) =>
      _getList(
          '$_base/districts/$countryId/$stateId', LocationDistrict.fromJson);

  /// GET /api/location/pincodes/{countryId}/{stateId}/{cityId}
  Future<List<LocationPincode>> getPincodes(
          int countryId, int stateId, int cityId) =>
      _getList('$_base/pincodes/$countryId/$stateId/$cityId',
          LocationPincode.fromJson);
}

/// Singleton — import this everywhere you need location data.
final locationApiService = LocationApiService();

// ─────────────────────────────────────────────────────────────────────────────
// Internal helper
// ─────────────────────────────────────────────────────────────────────────────

int _int(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}
