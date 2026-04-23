//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class WorkspaceCreateRequest {
  /// Returns a new [WorkspaceCreateRequest] instance.
  WorkspaceCreateRequest({
    required this.name,
    required this.key,
  });

  String name;

  String key;

  @override
  bool operator ==(Object other) => identical(this, other) || other is WorkspaceCreateRequest &&
    other.name == name &&
    other.key == key;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (key.hashCode);

  @override
  String toString() => 'WorkspaceCreateRequest[name=$name, key=$key]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'key'] = this.key;
    return json;
  }

  /// Returns a new [WorkspaceCreateRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WorkspaceCreateRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "WorkspaceCreateRequest[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "WorkspaceCreateRequest[name]" has a null value in JSON.');
        assert(json.containsKey(r'key'), 'Required key "WorkspaceCreateRequest[key]" is missing from JSON.');
        assert(json[r'key'] != null, 'Required key "WorkspaceCreateRequest[key]" has a null value in JSON.');
        return true;
      }());

      return WorkspaceCreateRequest(
        name: mapValueOfType<String>(json, r'name')!,
        key: mapValueOfType<String>(json, r'key')!,
      );
    }
    return null;
  }

  static List<WorkspaceCreateRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WorkspaceCreateRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WorkspaceCreateRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WorkspaceCreateRequest> mapFromJson(dynamic json) {
    final map = <String, WorkspaceCreateRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WorkspaceCreateRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WorkspaceCreateRequest-objects as value to a dart map
  static Map<String, List<WorkspaceCreateRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<WorkspaceCreateRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WorkspaceCreateRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'key',
  };
}

