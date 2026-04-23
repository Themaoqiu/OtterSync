import 'package:ottersync_openapi/api.dart' as openapi;

typedef LookupOption = openapi.LookupResponse;
typedef AttachmentCreateRequest = openapi.AttachmentCreateRequest;
typedef WorkItemCreateRequest = openapi.WorkItemCreateRequest;
typedef WorkItemResponse = openapi.WorkItemResponse;
typedef AttachmentKind = openapi.AttachmentKind;

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
