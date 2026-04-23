//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class WorkItemsApi {
  WorkItemsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create Team
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [TeamCreateRequest] teamCreateRequest (required):
  Future<Response> createTeamApiTeamsPostWithHttpInfo(TeamCreateRequest teamCreateRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/teams';

    // ignore: prefer_final_locals
    Object? postBody = teamCreateRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create Team
  ///
  /// Parameters:
  ///
  /// * [TeamCreateRequest] teamCreateRequest (required):
  Future<LookupResponse?> createTeamApiTeamsPost(TeamCreateRequest teamCreateRequest,) async {
    final response = await createTeamApiTeamsPostWithHttpInfo(teamCreateRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LookupResponse',) as LookupResponse;
    
    }
    return null;
  }

  /// Create User
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [UserCreateRequest] userCreateRequest (required):
  Future<Response> createUserApiUsersPostWithHttpInfo(UserCreateRequest userCreateRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/users';

    // ignore: prefer_final_locals
    Object? postBody = userCreateRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create User
  ///
  /// Parameters:
  ///
  /// * [UserCreateRequest] userCreateRequest (required):
  Future<LookupResponse?> createUserApiUsersPost(UserCreateRequest userCreateRequest,) async {
    final response = await createUserApiUsersPostWithHttpInfo(userCreateRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LookupResponse',) as LookupResponse;
    
    }
    return null;
  }

  /// Create Work Item
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [WorkItemCreateRequest] workItemCreateRequest (required):
  Future<Response> createWorkItemApiWorkItemsPostWithHttpInfo(WorkItemCreateRequest workItemCreateRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/work-items';

    // ignore: prefer_final_locals
    Object? postBody = workItemCreateRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create Work Item
  ///
  /// Parameters:
  ///
  /// * [WorkItemCreateRequest] workItemCreateRequest (required):
  Future<WorkItemResponse?> createWorkItemApiWorkItemsPost(WorkItemCreateRequest workItemCreateRequest,) async {
    final response = await createWorkItemApiWorkItemsPostWithHttpInfo(workItemCreateRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'WorkItemResponse',) as WorkItemResponse;
    
    }
    return null;
  }

  /// Create Workspace
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [WorkspaceCreateRequest] workspaceCreateRequest (required):
  Future<Response> createWorkspaceApiWorkspacesPostWithHttpInfo(WorkspaceCreateRequest workspaceCreateRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/workspaces';

    // ignore: prefer_final_locals
    Object? postBody = workspaceCreateRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create Workspace
  ///
  /// Parameters:
  ///
  /// * [WorkspaceCreateRequest] workspaceCreateRequest (required):
  Future<LookupResponse?> createWorkspaceApiWorkspacesPost(WorkspaceCreateRequest workspaceCreateRequest,) async {
    final response = await createWorkspaceApiWorkspacesPostWithHttpInfo(workspaceCreateRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LookupResponse',) as LookupResponse;
    
    }
    return null;
  }

  /// List Labels
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] q:
  Future<Response> listLabelsApiLookupsLabelsGetWithHttpInfo({ String? q, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/lookups/labels';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (q != null) {
      queryParams.addAll(_queryParams('', 'q', q));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// List Labels
  ///
  /// Parameters:
  ///
  /// * [String] q:
  Future<List<LookupResponse>?> listLabelsApiLookupsLabelsGet({ String? q, }) async {
    final response = await listLabelsApiLookupsLabelsGetWithHttpInfo( q: q, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<LookupResponse>') as List)
        .cast<LookupResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// List Parent Items
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] q:
  ///
  /// * [int] workspaceId:
  Future<Response> listParentItemsApiLookupsParentItemsGetWithHttpInfo({ String? q, int? workspaceId, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/lookups/parent-items';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (q != null) {
      queryParams.addAll(_queryParams('', 'q', q));
    }
    if (workspaceId != null) {
      queryParams.addAll(_queryParams('', 'workspace_id', workspaceId));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// List Parent Items
  ///
  /// Parameters:
  ///
  /// * [String] q:
  ///
  /// * [int] workspaceId:
  Future<List<LookupResponse>?> listParentItemsApiLookupsParentItemsGet({ String? q, int? workspaceId, }) async {
    final response = await listParentItemsApiLookupsParentItemsGetWithHttpInfo( q: q, workspaceId: workspaceId, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<LookupResponse>') as List)
        .cast<LookupResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// List Teams
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] q:
  Future<Response> listTeamsApiLookupsTeamsGetWithHttpInfo({ String? q, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/lookups/teams';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (q != null) {
      queryParams.addAll(_queryParams('', 'q', q));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// List Teams
  ///
  /// Parameters:
  ///
  /// * [String] q:
  Future<List<LookupResponse>?> listTeamsApiLookupsTeamsGet({ String? q, }) async {
    final response = await listTeamsApiLookupsTeamsGetWithHttpInfo( q: q, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<LookupResponse>') as List)
        .cast<LookupResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// List Users
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] q:
  Future<Response> listUsersApiLookupsUsersGetWithHttpInfo({ String? q, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/lookups/users';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (q != null) {
      queryParams.addAll(_queryParams('', 'q', q));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// List Users
  ///
  /// Parameters:
  ///
  /// * [String] q:
  Future<List<LookupResponse>?> listUsersApiLookupsUsersGet({ String? q, }) async {
    final response = await listUsersApiLookupsUsersGetWithHttpInfo( q: q, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<LookupResponse>') as List)
        .cast<LookupResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// List Work Items
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] q:
  Future<Response> listWorkItemsApiWorkItemsGetWithHttpInfo({ String? q, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/work-items';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (q != null) {
      queryParams.addAll(_queryParams('', 'q', q));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// List Work Items
  ///
  /// Parameters:
  ///
  /// * [String] q:
  Future<List<LookupResponse>?> listWorkItemsApiWorkItemsGet({ String? q, }) async {
    final response = await listWorkItemsApiWorkItemsGetWithHttpInfo( q: q, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<LookupResponse>') as List)
        .cast<LookupResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// List Work Types
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] q:
  Future<Response> listWorkTypesApiLookupsWorkTypesGetWithHttpInfo({ String? q, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/lookups/work-types';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (q != null) {
      queryParams.addAll(_queryParams('', 'q', q));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// List Work Types
  ///
  /// Parameters:
  ///
  /// * [String] q:
  Future<List<LookupResponse>?> listWorkTypesApiLookupsWorkTypesGet({ String? q, }) async {
    final response = await listWorkTypesApiLookupsWorkTypesGetWithHttpInfo( q: q, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<LookupResponse>') as List)
        .cast<LookupResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// List Workspaces
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] q:
  Future<Response> listWorkspacesApiLookupsWorkspacesGetWithHttpInfo({ String? q, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/lookups/workspaces';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (q != null) {
      queryParams.addAll(_queryParams('', 'q', q));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// List Workspaces
  ///
  /// Parameters:
  ///
  /// * [String] q:
  Future<List<LookupResponse>?> listWorkspacesApiLookupsWorkspacesGet({ String? q, }) async {
    final response = await listWorkspacesApiLookupsWorkspacesGetWithHttpInfo( q: q, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<LookupResponse>') as List)
        .cast<LookupResponse>()
        .toList(growable: false);

    }
    return null;
  }
}
