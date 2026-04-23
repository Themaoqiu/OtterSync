//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class WorkItemCreateRequest {
  /// Returns a new [WorkItemCreateRequest] instance.
  WorkItemCreateRequest({
    required this.workspaceId,
    required this.workTypeId,
    required this.summary,
    this.description,
    required this.reporterId,
    this.assigneeId,
    this.parentId,
    this.teamId,
    this.dueDate,
    this.startDate,
    this.labelIds = const [],
    this.newLabelNames = const [],
    this.attachments = const [],
  });

  int workspaceId;

  int workTypeId;

  String summary;

  String? description;

  int reporterId;

  int? assigneeId;

  int? parentId;

  int? teamId;

  DateTime? dueDate;

  DateTime? startDate;

  List<int> labelIds;

  List<String> newLabelNames;

  List<AttachmentCreateRequest> attachments;

  @override
  bool operator ==(Object other) => identical(this, other) || other is WorkItemCreateRequest &&
    other.workspaceId == workspaceId &&
    other.workTypeId == workTypeId &&
    other.summary == summary &&
    other.description == description &&
    other.reporterId == reporterId &&
    other.assigneeId == assigneeId &&
    other.parentId == parentId &&
    other.teamId == teamId &&
    other.dueDate == dueDate &&
    other.startDate == startDate &&
    _deepEquality.equals(other.labelIds, labelIds) &&
    _deepEquality.equals(other.newLabelNames, newLabelNames) &&
    _deepEquality.equals(other.attachments, attachments);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (workspaceId.hashCode) +
    (workTypeId.hashCode) +
    (summary.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (reporterId.hashCode) +
    (assigneeId == null ? 0 : assigneeId!.hashCode) +
    (parentId == null ? 0 : parentId!.hashCode) +
    (teamId == null ? 0 : teamId!.hashCode) +
    (dueDate == null ? 0 : dueDate!.hashCode) +
    (startDate == null ? 0 : startDate!.hashCode) +
    (labelIds.hashCode) +
    (newLabelNames.hashCode) +
    (attachments.hashCode);

  @override
  String toString() => 'WorkItemCreateRequest[workspaceId=$workspaceId, workTypeId=$workTypeId, summary=$summary, description=$description, reporterId=$reporterId, assigneeId=$assigneeId, parentId=$parentId, teamId=$teamId, dueDate=$dueDate, startDate=$startDate, labelIds=$labelIds, newLabelNames=$newLabelNames, attachments=$attachments]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'workspace_id'] = this.workspaceId;
      json[r'work_type_id'] = this.workTypeId;
      json[r'summary'] = this.summary;
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
      json[r'reporter_id'] = this.reporterId;
    if (this.assigneeId != null) {
      json[r'assignee_id'] = this.assigneeId;
    } else {
      json[r'assignee_id'] = null;
    }
    if (this.parentId != null) {
      json[r'parent_id'] = this.parentId;
    } else {
      json[r'parent_id'] = null;
    }
    if (this.teamId != null) {
      json[r'team_id'] = this.teamId;
    } else {
      json[r'team_id'] = null;
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
      json[r'label_ids'] = this.labelIds;
      json[r'new_label_names'] = this.newLabelNames;
      json[r'attachments'] = this.attachments;
    return json;
  }

  /// Returns a new [WorkItemCreateRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WorkItemCreateRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'workspace_id'), 'Required key "WorkItemCreateRequest[workspace_id]" is missing from JSON.');
        assert(json[r'workspace_id'] != null, 'Required key "WorkItemCreateRequest[workspace_id]" has a null value in JSON.');
        assert(json.containsKey(r'work_type_id'), 'Required key "WorkItemCreateRequest[work_type_id]" is missing from JSON.');
        assert(json[r'work_type_id'] != null, 'Required key "WorkItemCreateRequest[work_type_id]" has a null value in JSON.');
        assert(json.containsKey(r'summary'), 'Required key "WorkItemCreateRequest[summary]" is missing from JSON.');
        assert(json[r'summary'] != null, 'Required key "WorkItemCreateRequest[summary]" has a null value in JSON.');
        assert(json.containsKey(r'reporter_id'), 'Required key "WorkItemCreateRequest[reporter_id]" is missing from JSON.');
        assert(json[r'reporter_id'] != null, 'Required key "WorkItemCreateRequest[reporter_id]" has a null value in JSON.');
        return true;
      }());

      return WorkItemCreateRequest(
        workspaceId: mapValueOfType<int>(json, r'workspace_id')!,
        workTypeId: mapValueOfType<int>(json, r'work_type_id')!,
        summary: mapValueOfType<String>(json, r'summary')!,
        description: mapValueOfType<String>(json, r'description'),
        reporterId: mapValueOfType<int>(json, r'reporter_id')!,
        assigneeId: mapValueOfType<int>(json, r'assignee_id'),
        parentId: mapValueOfType<int>(json, r'parent_id'),
        teamId: mapValueOfType<int>(json, r'team_id'),
        dueDate: mapDateTime(json, r'due_date', r''),
        startDate: mapDateTime(json, r'start_date', r''),
        labelIds: json[r'label_ids'] is Iterable
            ? (json[r'label_ids'] as Iterable).cast<int>().toList(growable: false)
            : const [],
        newLabelNames: json[r'new_label_names'] is Iterable
            ? (json[r'new_label_names'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        attachments: AttachmentCreateRequest.listFromJson(json[r'attachments']),
      );
    }
    return null;
  }

  static List<WorkItemCreateRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WorkItemCreateRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WorkItemCreateRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WorkItemCreateRequest> mapFromJson(dynamic json) {
    final map = <String, WorkItemCreateRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WorkItemCreateRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WorkItemCreateRequest-objects as value to a dart map
  static Map<String, List<WorkItemCreateRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<WorkItemCreateRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WorkItemCreateRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'workspace_id',
    'work_type_id',
    'summary',
    'reporter_id',
  };
}

