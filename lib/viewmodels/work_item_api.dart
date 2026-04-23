import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:ottersync/viewmodels/work_item_models.dart';
import 'package:ottersync_openapi/api.dart' as openapi;

class WorkItemApiException implements Exception {
  const WorkItemApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WorkItemApi {
  WorkItemApi({openapi.ApiClient? apiClient})
    : _workItemsApi = openapi.WorkItemsApi(
        apiClient ??
            openapi.ApiClient(
              basePath: _resolveBaseUrl(),
            ),
      ) {
    debugPrint('WorkItemApi basePath=${_resolveBaseUrl()}');
  }

  final openapi.WorkItemsApi _workItemsApi;

  Future<List<LookupOption>> listWorkItems({String query = ''}) async {
    return _guard(
      () async =>
          await _workItemsApi.listWorkItemsApiWorkItemsGet(q: query) ?? const [],
    );
  }

  Future<CreateWorkItemLookups> loadCreateLookups() async {
    return _guard(() async {
      final workspaces =
          await _workItemsApi.listWorkspacesApiLookupsWorkspacesGet() ??
          const [];
      debugPrint('loadCreateLookups workspaces=${workspaces.length}');

      final workTypes =
          await _workItemsApi.listWorkTypesApiLookupsWorkTypesGet() ?? const [];
      debugPrint('loadCreateLookups workTypes=${workTypes.length}');

      final users = await _workItemsApi.listUsersApiLookupsUsersGet() ?? const [];
      debugPrint('loadCreateLookups users=${users.length}');

      final teams = await _workItemsApi.listTeamsApiLookupsTeamsGet() ?? const [];
      debugPrint('loadCreateLookups teams=${teams.length}');

      final labels =
          await _workItemsApi.listLabelsApiLookupsLabelsGet() ?? const [];
      debugPrint('loadCreateLookups labels=${labels.length}');

      return CreateWorkItemLookups(
        workspaces: workspaces,
        workTypes: workTypes,
        users: users,
        teams: teams,
        labels: labels,
      );
    });
  }

  Future<List<LookupOption>> listParentItems({
    String query = '',
    int? workspaceId,
  }) async {
    return _guard(
      () async =>
          await _workItemsApi.listParentItemsApiLookupsParentItemsGet(
            q: query,
            workspaceId: workspaceId,
          ) ??
          const [],
    );
  }

  Future<WorkItemResponse> createWorkItem(WorkItemCreateRequest payload) async {
    return _guard(() async {
      final result = await _workItemsApi.createWorkItemApiWorkItemsPost(payload);
      if (result == null) {
        throw const WorkItemApiException('创建失败，服务端没有返回数据。');
      }
      return result;
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on openapi.ApiException catch (error, stackTrace) {
      debugPrint('WorkItemApi ApiException: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw WorkItemApiException(error.message ?? '请求失败，请检查后端服务。');
    } catch (error, stackTrace) {
      debugPrint('WorkItemApi unknown error: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw WorkItemApiException('$error');
    }
  }

  static String _resolveBaseUrl() {
    final baseUrl = dotenv.env['OTTERSYNC_API_BASE_URL'] ?? '';
    if (baseUrl.isEmpty) {
      throw const WorkItemApiException(
        'Missing OTTERSYNC_API_BASE_URL in .env.',
      );
    }
    return baseUrl;
  }
}
