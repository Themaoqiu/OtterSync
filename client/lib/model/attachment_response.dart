//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AttachmentResponse {
  /// Returns a new [AttachmentResponse] instance.
  AttachmentResponse({
    required this.name,
    required this.kind,
    required this.uri,
    this.mimeType,
  });

  String name;

  AttachmentKind kind;

  String uri;

  String? mimeType;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AttachmentResponse &&
    other.name == name &&
    other.kind == kind &&
    other.uri == uri &&
    other.mimeType == mimeType;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (kind.hashCode) +
    (uri.hashCode) +
    (mimeType == null ? 0 : mimeType!.hashCode);

  @override
  String toString() => 'AttachmentResponse[name=$name, kind=$kind, uri=$uri, mimeType=$mimeType]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'kind'] = this.kind;
      json[r'uri'] = this.uri;
    if (this.mimeType != null) {
      json[r'mime_type'] = this.mimeType;
    } else {
      json[r'mime_type'] = null;
    }
    return json;
  }

  /// Returns a new [AttachmentResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AttachmentResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "AttachmentResponse[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "AttachmentResponse[name]" has a null value in JSON.');
        assert(json.containsKey(r'kind'), 'Required key "AttachmentResponse[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "AttachmentResponse[kind]" has a null value in JSON.');
        assert(json.containsKey(r'uri'), 'Required key "AttachmentResponse[uri]" is missing from JSON.');
        assert(json[r'uri'] != null, 'Required key "AttachmentResponse[uri]" has a null value in JSON.');
        return true;
      }());

      return AttachmentResponse(
        name: mapValueOfType<String>(json, r'name')!,
        kind: AttachmentKind.fromJson(json[r'kind'])!,
        uri: mapValueOfType<String>(json, r'uri')!,
        mimeType: mapValueOfType<String>(json, r'mime_type'),
      );
    }
    return null;
  }

  static List<AttachmentResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AttachmentResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AttachmentResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AttachmentResponse> mapFromJson(dynamic json) {
    final map = <String, AttachmentResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AttachmentResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AttachmentResponse-objects as value to a dart map
  static Map<String, List<AttachmentResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AttachmentResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AttachmentResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'kind',
    'uri',
  };
}

