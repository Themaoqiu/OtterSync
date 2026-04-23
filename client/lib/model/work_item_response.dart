//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class WorkItemResponse {
  /// Returns a new [WorkItemResponse] instance.
  WorkItemResponse({
    required this.id,
    required this.summary,
    this.description,
    required this.workspace,
    required this.workType,
    required this.reporter,
    this.assignee,
    this.parent,
    this.team,
    this.dueDate,
    this.startDate,
    this.labels = const [],
    this.attachments = const [],
  });

  int id;

  String summary;

  String? description;

  LookupResponse workspace;

  LookupResponse workType;

  LookupResponse reporter;

  LookupResponse? assignee;

  LookupResponse? parent;

  LookupResponse? team;

  DateTime? dueDate;

  DateTime? startDate;

  List<LookupResponse> labels;

  List<AttachmentResponse> attachments;

  @override
  bool operator ==(Object other) => identical(this, other) || other is WorkItemResponse &&
    other.id == id &&
    other.summary == summary &&
    other.description == description &&
    other.workspace == workspace &&
    other.workType == workType &&
    other.reporter == reporter &&
    other.assignee == assignee &&
    other.parent == parent &&
    other.team == team &&
    other.dueDate == dueDate &&
    other.startDate == startDate &&
    _deepEquality.equals(other.labels, labels) &&
    _deepEquality.equals(other.attachments, attachments);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (summary.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (workspace.hashCode) +
    (workType.hashCode) +
    (reporter.hashCode) +
    (assignee == null ? 0 : assignee!.hashCode) +
    (parent == null ? 0 : parent!.hashCode) +
    (team == null ? 0 : team!.hashCode) +
    (dueDate == null ? 0 : dueDate!.hashCode) +
    (startDate == null ? 0 : startDate!.hashCode) +
    (labels.hashCode) +
    (attachments.hashCode);

  @override
  String toString() => 'WorkItemResponse[id=$id, summary=$summary, description=$description, workspace=$workspace, workType=$workType, reporter=$reporter, assignee=$assignee, parent=$parent, team=$team, dueDate=$dueDate, startDate=$startDate, labels=$labels, attachments=$attachments]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'summary'] = this.summary;
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
      json[r'workspace'] = this.workspace;
      json[r'work_type'] = this.workType;
      json[r'reporter'] = this.reporter;
    if (this.assignee != null) {
      json[r'assignee'] = this.assignee;
    } else {
      json[r'assignee'] = null;
    }
    if (this.parent != null) {
      json[r'parent'] = this.parent;
    } else {
      json[r'parent'] = null;
    }
    if (this.team != null) {
      json[r'team'] = this.team;
    } else {
      json[r'team'] = null;
    }
    if (this.dueDate != null) {
      json[r'due_date'] = _dateFormatter.format(this.dueDate!.toUtc());
    } else {
      json[r'due_date'] = null;
    }
    if (this.startDate != null) {
      json[r'start_date'] = _dateFormatter.format(this.startDate!.toUtc());
    } else {
      json[r'start_date'] = null;
    }
      json[r'labels'] = this.labels;
      json[r'attachments'] = this.attachments;
    return json;
  }

  /// Returns a new [WorkItemResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WorkItemResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "WorkItemResponse[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "WorkItemResponse[id]" has a null value in JSON.');
        assert(json.containsKey(r'summary'), 'Required key "WorkItemResponse[summary]" is missing from JSON.');
        assert(json[r'summary'] != null, 'Required key "WorkItemResponse[summary]" has a null value in JSON.');
        assert(json.containsKey(r'workspace'), 'Required key "WorkItemResponse[workspace]" is missing from JSON.');
        assert(json[r'workspace'] != null, 'Required key "WorkItemResponse[workspace]" has a null value in JSON.');
        assert(json.containsKey(r'work_type'), 'Required key "WorkItemResponse[work_type]" is missing from JSON.');
        assert(json[r'work_type'] != null, 'Required key "WorkItemResponse[work_type]" has a null value in JSON.');
        assert(json.containsKey(r'reporter'), 'Required key "WorkItemResponse[reporter]" is missing from JSON.');
        assert(json[r'reporter'] != null, 'Required key "WorkItemResponse[reporter]" has a null value in JSON.');
        assert(json.containsKey(r'labels'), 'Required key "WorkItemResponse[labels]" is missing from JSON.');
        assert(json[r'labels'] != null, 'Required key "WorkItemResponse[labels]" has a null value in JSON.');
        assert(json.containsKey(r'attachments'), 'Required key "WorkItemResponse[attachments]" is missing from JSON.');
        assert(json[r'attachments'] != null, 'Required key "WorkItemResponse[attachments]" has a null value in JSON.');
        return true;
      }());

      return WorkItemResponse(
        id: mapValueOfType<int>(json, r'id')!,
        summary: mapValueOfType<String>(json, r'summary')!,
        description: mapValueOfType<String>(json, r'description'),
        workspace: LookupResponse.fromJson(json[r'workspace'])!,
        workType: LookupResponse.fromJson(json[r'work_type'])!,
        reporter: LookupResponse.fromJson(json[r'reporter'])!,
        assignee: LookupResponse.fromJson(json[r'assignee']),
        parent: LookupResponse.fromJson(json[r'parent']),
        team: LookupResponse.fromJson(json[r'team']),
        dueDate: mapDateTime(json, r'due_date', r''),
        startDate: mapDateTime(json, r'start_date', r''),
        labels: LookupResponse.listFromJson(json[r'labels']),
        attachments: AttachmentResponse.listFromJson(json[r'attachments']),
      );
    }
    return null;
  }

  static List<WorkItemResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WorkItemResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WorkItemResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WorkItemResponse> mapFromJson(dynamic json) {
    final map = <String, WorkItemResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WorkItemResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WorkItemResponse-objects as value to a dart map
  static Map<String, List<WorkItemResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<WorkItemResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WorkItemResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'summary',
    'workspace',
    'work_type',
    'reporter',
    'labels',
    'attachments',
  };
}

