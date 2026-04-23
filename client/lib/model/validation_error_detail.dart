//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ValidationErrorDetail {
  /// Returns a new [ValidationErrorDetail] instance.
  ValidationErrorDetail({
    this.loc = const [],
    required this.msg,
    required this.type,
    this.input,
    this.ctx = const {},
  });

  List<String> loc;

  String msg;

  String type;

  String? input;

  Map<String, String>? ctx;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ValidationErrorDetail &&
    _deepEquality.equals(other.loc, loc) &&
    other.msg == msg &&
    other.type == type &&
    other.input == input &&
    _deepEquality.equals(other.ctx, ctx);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (loc.hashCode) +
    (msg.hashCode) +
    (type.hashCode) +
    (input == null ? 0 : input!.hashCode) +
    (ctx == null ? 0 : ctx!.hashCode);

  @override
  String toString() => 'ValidationErrorDetail[loc=$loc, msg=$msg, type=$type, input=$input, ctx=$ctx]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'loc'] = this.loc;
      json[r'msg'] = this.msg;
      json[r'type'] = this.type;
    if (this.input != null) {
      json[r'input'] = this.input;
    } else {
      json[r'input'] = null;
    }
    if (this.ctx != null) {
      json[r'ctx'] = this.ctx;
    } else {
      json[r'ctx'] = null;
    }
    return json;
  }

  /// Returns a new [ValidationErrorDetail] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ValidationErrorDetail? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'loc'), 'Required key "ValidationErrorDetail[loc]" is missing from JSON.');
        assert(json[r'loc'] != null, 'Required key "ValidationErrorDetail[loc]" has a null value in JSON.');
        assert(json.containsKey(r'msg'), 'Required key "ValidationErrorDetail[msg]" is missing from JSON.');
        assert(json[r'msg'] != null, 'Required key "ValidationErrorDetail[msg]" has a null value in JSON.');
        assert(json.containsKey(r'type'), 'Required key "ValidationErrorDetail[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "ValidationErrorDetail[type]" has a null value in JSON.');
        return true;
      }());

      return ValidationErrorDetail(
        loc: json[r'loc'] is Iterable
            ? (json[r'loc'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        msg: mapValueOfType<String>(json, r'msg')!,
        type: mapValueOfType<String>(json, r'type')!,
        input: mapValueOfType<String>(json, r'input'),
        ctx: mapCastOfType<String, String>(json, r'ctx') ?? const {},
      );
    }
    return null;
  }

  static List<ValidationErrorDetail> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ValidationErrorDetail>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ValidationErrorDetail.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ValidationErrorDetail> mapFromJson(dynamic json) {
    final map = <String, ValidationErrorDetail>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ValidationErrorDetail.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ValidationErrorDetail-objects as value to a dart map
  static Map<String, List<ValidationErrorDetail>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ValidationErrorDetail>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ValidationErrorDetail.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'loc',
    'msg',
    'type',
  };
}

