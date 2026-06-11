import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ottersync/viewmodels/jira_models.dart';

enum AttachmentKind { photo, video, document }

class LookupOption {
  const LookupOption({
    required this.id,
    required this.title,
    this.subtitle,
    this.status,
  });

  factory LookupOption.fromMap(Map<String, dynamic> map) {
    return LookupOption(
      id: (map['id'] as num).toInt(),
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String?,
      status: map['status'] as String?,
    );
  }

  final int id;
  final String title;
  final String? subtitle;
  final String? status;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
    };
  }
}

class AttachmentCreateRequest {
  const AttachmentCreateRequest({
    required this.name,
    required this.kind,
    required this.uri,
    this.mimeType,
  });

  factory AttachmentCreateRequest.fromMap(Map<String, dynamic> map) {
    return AttachmentCreateRequest(
      name: map['name'] as String? ?? '',
      kind: _attachmentKindFromString(map['kind'] as String?),
      uri: map['uri'] as String? ?? '',
      mimeType: map['mimeType'] as String?,
    );
  }

  final String name;
  final AttachmentKind kind;
  final String uri;
  final String? mimeType;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'kind': kind.name,
      'uri': uri,
      'mimeType': mimeType,
    };
  }
}

class WorkItemCreateRequest {
  const WorkItemCreateRequest({
    required this.workspaceId,
    required this.workTypeId,
    required this.summary,
    required this.reporterId,
    this.bucket = WorkItemBucket.backlog,
    this.status = WorkItemStatus.todo,
    this.description,
    this.assigneeId,
    this.parentId,
    this.teamId,
    this.sprintId,
    this.dueDate,
    this.startDate,
    this.labelIds = const [],
    this.newLabelNames = const [],
    this.attachments = const [],
  });

  final int workspaceId;
  final int workTypeId;
  final String summary;
  final WorkItemBucket bucket;
  final WorkItemStatus status;
  final String? description;
  final int reporterId;
  final int? assigneeId;
  final int? parentId;
  final int? teamId;
  final int? sprintId;
  final DateTime? dueDate;
  final DateTime? startDate;
  final List<int> labelIds;
  final List<String> newLabelNames;
  final List<AttachmentCreateRequest> attachments;
}

class WorkspaceCreateRequest {
  const WorkspaceCreateRequest({
    required this.name,
    required this.key,
    required this.template,
    this.invitedEmails = const [],
  });

  final String name;
  final String key;
  final String template;
  final List<String> invitedEmails;
}

class WorkspaceInvite {
  const WorkspaceInvite({
    required this.id,
    required this.workspaceId,
    required this.workspaceName,
    required this.workspaceKey,
    required this.inviterUid,
    required this.invitedEmail,
    required this.status,
    this.createdAt,
  });

  factory WorkspaceInvite.fromMap(Map<String, dynamic> map) {
    return WorkspaceInvite(
      id: map['id'] as String? ?? '',
      workspaceId: (map['workspaceId'] as num).toInt(),
      workspaceName: map['workspaceName'] as String? ?? '',
      workspaceKey: map['workspaceKey'] as String? ?? '',
      inviterUid: map['inviterUid'] as String? ?? '',
      invitedEmail: map['invitedEmail'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: _dateTimeOrNull(map['createdAt']),
    );
  }

  final String id;
  final int workspaceId;
  final String workspaceName;
  final String workspaceKey;
  final String inviterUid;
  final String invitedEmail;
  final String status;
  final DateTime? createdAt;
}

class WorkItemResponse {
  const WorkItemResponse({
    required this.id,
    required this.summary,
    required this.workspace,
    required this.workType,
    required this.reporter,
    required this.labels,
    required this.attachments,
    required this.key,
    required this.bucket,
    required this.status,
    this.description,
    this.assignee,
    this.parent,
    this.team,
    this.sprint,
    this.dueDate,
    this.startDate,
    this.createdAt,
    this.lastViewedAt,
  });

  factory WorkItemResponse.fromMap(Map<String, dynamic> map) {
    return WorkItemResponse(
      id: (map['id'] as num).toInt(),
      summary: map['summary'] as String? ?? '',
      key: map['key'] as String? ?? '',
      description: map['description'] as String?,
      workspace: LookupOption.fromMap(Map<String, dynamic>.from(map['workspace'] as Map)),
      workType: LookupOption.fromMap(Map<String, dynamic>.from(map['workType'] as Map)),
      reporter: LookupOption.fromMap(Map<String, dynamic>.from(map['reporter'] as Map)),
      bucket: _workItemBucketFromString(map['bucket'] as String?),
      status: _workItemStatusFromString(map['status'] as String?),
      assignee: _lookupOrNull(map['assignee']),
      parent: _lookupOrNull(map['parent']),
      team: _lookupOrNull(map['team']),
      sprint: _lookupOrNull(map['sprint']),
      dueDate: _dateTimeOrNull(map['dueDate']),
      startDate: _dateTimeOrNull(map['startDate']),
      createdAt: _dateTimeOrNull(map['createdAt']),
      lastViewedAt: _dateTimeOrNull(map['lastViewedAt']),
      labels: (map['labels'] as List<dynamic>? ?? const [])
          .map((item) => LookupOption.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      attachments: (map['attachments'] as List<dynamic>? ?? const [])
          .map((item) => AttachmentCreateRequest.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  final int id;
  final String summary;
  final String key;
  final String? description;
  final LookupOption workspace;
  final LookupOption workType;
  final LookupOption reporter;
  final WorkItemBucket bucket;
  final WorkItemStatus status;
  final LookupOption? assignee;
  final LookupOption? parent;
  final LookupOption? team;
  final LookupOption? sprint;
  final DateTime? dueDate;
  final DateTime? startDate;
  final DateTime? createdAt;
  final DateTime? lastViewedAt;
  final List<LookupOption> labels;
  final List<AttachmentCreateRequest> attachments;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'summary': summary,
      'key': key,
      'description': description,
      'workspace': workspace.toMap(),
      'workType': workType.toMap(),
      'reporter': reporter.toMap(),
      'bucket': bucket.name,
      'status': status.name,
      'assignee': assignee?.toMap(),
      'parent': parent?.toMap(),
      'team': team?.toMap(),
      'sprint': sprint?.toMap(),
      'dueDate': dueDate,
      'startDate': startDate,
      'createdAt': createdAt,
      'lastViewedAt': lastViewedAt,
      'labels': labels.map((item) => item.toMap()).toList(),
      'attachments': attachments.map((item) => item.toMap()).toList(),
    };
  }
}

class CreateWorkItemLookups {
  const CreateWorkItemLookups({
    required this.workspaces,
    required this.workTypes,
    required this.users,
    required this.teams,
    required this.labels,
  });

  final List<LookupOption> workspaces;
  final List<LookupOption> workTypes;
  final List<LookupOption> users;
  final List<LookupOption> teams;
  final List<LookupOption> labels;
}

enum SprintStatus { planned, active, completed }

class Sprint {
  const Sprint({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.status,
    this.goal,
    this.startDate,
    this.endDate,
    this.completedAt,
  });

  factory Sprint.fromMap(Map<String, dynamic> map) {
    return Sprint(
      id: (map['id'] as num).toInt(),
      workspaceId: (map['workspaceId'] as num).toInt(),
      name: map['name'] as String? ?? '',
      goal: map['goal'] as String?,
      status: _sprintStatusFromString(map['status'] as String?),
      startDate: _dateTimeOrNull(map['startDate']),
      endDate: _dateTimeOrNull(map['endDate']),
      completedAt: _dateTimeOrNull(map['completedAt']),
    );
  }

  final int id;
  final int workspaceId;
  final String name;
  final String? goal;
  final SprintStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? completedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workspaceId': workspaceId,
      'name': name,
      'goal': goal,
      'status': status.name,
      'startDate': startDate,
      'endDate': endDate,
      'completedAt': completedAt,
    };
  }

  LookupOption toLookup() {
    return LookupOption(
      id: id,
      title: name,
      subtitle: status == SprintStatus.active
          ? '进行中'
          : status == SprintStatus.planned
              ? '计划中'
              : '已结束',
      status: status.name,
    );
  }
}

SprintStatus _sprintStatusFromString(String? value) {
  return SprintStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => SprintStatus.planned,
  );
}

class SprintCreateRequest {
  const SprintCreateRequest({
    required this.workspaceId,
    required this.name,
    this.goal,
    this.startDate,
    this.endDate,
  });

  final int workspaceId;
  final String name;
  final String? goal;
  final DateTime? startDate;
  final DateTime? endDate;
}

LookupOption? _lookupOrNull(Object? value) {
  if (value is! Map) {
    return null;
  }
  return LookupOption.fromMap(Map<String, dynamic>.from(value));
}

DateTime? _dateTimeOrNull(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

AttachmentKind _attachmentKindFromString(String? value) {
  return AttachmentKind.values.firstWhere(
    (kind) => kind.name == value,
    orElse: () => AttachmentKind.document,
  );
}

WorkItemBucket _workItemBucketFromString(String? value) {
  return WorkItemBucket.values.firstWhere(
    (bucket) => bucket.name == value,
    orElse: () => WorkItemBucket.backlog,
  );
}

WorkItemStatus _workItemStatusFromString(String? value) {
  return WorkItemStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => WorkItemStatus.todo,
  );
}
