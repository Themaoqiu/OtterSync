//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LookupResponse {
  /// Returns a new [LookupResponse] instance.
  LookupResponse({
    required this.id,
    required this.title,
    this.subtitle,
  });

  int id;

  String title;

  String? subtitle;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LookupResponse &&
    other.id == id &&
    other.title == title &&
    other.subtitle == subtitle;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (title.hashCode) +
    (subtitle == null ? 0 : subtitle!.hashCode);

  @override
  String toString() => 'LookupResponse[id=$id, title=$title, subtitle=$subtitle]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'title'] = this.title;
    if (this.subtitle != null) {
      json[r'subtitle'] = this.subtitle;
    } else {
      json[r'subtitle'] = null;
    }
    return json;
  }

  /// Returns a new [LookupResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LookupResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "LookupResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "LookupResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'title'), 'Required key "LookupResponse[title]" is missing from JSON.');
        assert(json[r'title'] != null, 'Required key "LookupResponse[title]" has a null value in JSON.');
        return true;
      }());

      return LookupResponse(
        id: mapValueOfType<int>(json, r'id')!,
        title: mapValueOfType<String>(json, r'title')!,
        subtitle: mapValueOfType<String>(json, r'subtitle'),
      );
    }
    return null;
  }

  static List<LookupResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LookupResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LookupResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LookupResponse> mapFromJson(dynamic json) {
    final map = <String, LookupResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LookupResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LookupResponse-objects as value to a dart map
  static Map<String, List<LookupResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LookupResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LookupResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'title',
  };
}

