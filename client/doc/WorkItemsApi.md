# ottersync_openapi.api.WorkItemsApi

## Load the API package
```dart
import 'package:ottersync_openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createTeamApiTeamsPost**](WorkItemsApi.md#createteamapiteamspost) | **POST** /api/teams | Create Team
[**createUserApiUsersPost**](WorkItemsApi.md#createuserapiuserspost) | **POST** /api/users | Create User
[**createWorkItemApiWorkItemsPost**](WorkItemsApi.md#createworkitemapiworkitemspost) | **POST** /api/work-items | Create Work Item
[**createWorkspaceApiWorkspacesPost**](WorkItemsApi.md#createworkspaceapiworkspacespost) | **POST** /api/workspaces | Create Workspace
[**listLabelsApiLookupsLabelsGet**](WorkItemsApi.md#listlabelsapilookupslabelsget) | **GET** /api/lookups/labels | List Labels
[**listParentItemsApiLookupsParentItemsGet**](WorkItemsApi.md#listparentitemsapilookupsparentitemsget) | **GET** /api/lookups/parent-items | List Parent Items
[**listTeamsApiLookupsTeamsGet**](WorkItemsApi.md#listteamsapilookupsteamsget) | **GET** /api/lookups/teams | List Teams
[**listUsersApiLookupsUsersGet**](WorkItemsApi.md#listusersapilookupsusersget) | **GET** /api/lookups/users | List Users
[**listWorkItemsApiWorkItemsGet**](WorkItemsApi.md#listworkitemsapiworkitemsget) | **GET** /api/work-items | List Work Items
[**listWorkTypesApiLookupsWorkTypesGet**](WorkItemsApi.md#listworktypesapilookupsworktypesget) | **GET** /api/lookups/work-types | List Work Types
[**listWorkspacesApiLookupsWorkspacesGet**](WorkItemsApi.md#listworkspacesapilookupsworkspacesget) | **GET** /api/lookups/workspaces | List Workspaces


# **createTeamApiTeamsPost**
> LookupResponse createTeamApiTeamsPost(teamCreateRequest)

Create Team

### Example
```dart
import 'package:ottersync_openapi/api.dart';

final api_instance = WorkItemsApi();
final teamCreateRequest = TeamCreateRequest(); // TeamCreateRequest | 

try {
    final result = api_instance.createTeamApiTeamsPost(teamCreateRequest);
    print(result);
} catch (e) {
    print('Exception when calling WorkItemsApi->createTeamApiTeamsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **teamCreateRequest** | [**TeamCreateRequest**](TeamCreateRequest.md)|  | 

### Return type

[**LookupResponse**](LookupResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createUserApiUsersPost**
> LookupResponse createUserApiUsersPost(userCreateRequest)

Create User

### Example
```dart
import 'package:ottersync_openapi/api.dart';

final api_instance = WorkItemsApi();
final userCreateRequest = UserCreateRequest(); // UserCreateRequest | 

try {
    final result = api_instance.createUserApiUsersPost(userCreateRequest);
    print(result);
} catch (e) {
    print('Exception when calling WorkItemsApi->createUserApiUsersPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userCreateRequest** | [**UserCreateRequest**](UserCreateRequest.md)|  | 

### Return type

[**LookupResponse**](LookupResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createWorkItemApiWorkItemsPost**
> WorkItemResponse createWorkItemApiWorkItemsPost(workItemCreateRequest)

Create Work Item

### Example
```dart
import 'package:ottersync_openapi/api.dart';

final api_instance = WorkItemsApi();
final workItemCreateRequest = WorkItemCreateRequest(); // WorkItemCreateRequest | 

try {
    final result = api_instance.createWorkItemApiWorkItemsPost(workItemCreateRequest);
    print(result);
} catch (e) {
    print('Exception when calling WorkItemsApi->createWorkItemApiWorkItemsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **workItemCreateRequest** | [**WorkItemCreateRequest**](WorkItemCreateRequest.md)|  | 

### Return type

[**WorkItemResponse**](WorkItemResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createWorkspaceApiWorkspacesPost**
> LookupResponse createWorkspaceApiWorkspacesPost(workspaceCreateRequest)

Create Workspace

### Example
```dart
import 'package:ottersync_openapi/api.dart';

final api_instance = WorkItemsApi();
final workspaceCreateRequest = WorkspaceCreateRequest(); // WorkspaceCreateRequest | 

try {
    final result = api_instance.createWorkspaceApiWorkspacesPost(workspaceCreateRequest);
    print(result);
} catch (e) {
    print('Exception when calling WorkItemsApi->createWorkspaceApiWorkspacesPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **workspaceCreateRequest** | [**WorkspaceCreateRequest**](WorkspaceCreateRequest.md)|  | 

### Return type

[**LookupResponse**](LookupResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listLabelsApiLookupsLabelsGet**
> List<LookupResponse> listLabelsApiLookupsLabelsGet(q)

List Labels

### Example
```dart
import 'package:ottersync_openapi/api.dart';

final api_instance = WorkItemsApi();
final q = q_example; // String | 

try {
    final result = api_instance.listLabelsApiLookupsLabelsGet(q);
    print(result);
} catch (e) {
    print('Exception when calling WorkItemsApi->listLabelsApiLookupsLabelsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional] [default to '']

### Return type

[**List<LookupResponse>**](LookupResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listParentItemsApiLookupsParentItemsGet**
> List<LookupResponse> listParentItemsApiLookupsParentItemsGet(q, workspaceId)

List Parent Items

### Example
```dart
import 'package:ottersync_openapi/api.dart';

final api_instance = WorkItemsApi();
final q = q_example; // String | 
final workspaceId = 56; // int | 

try {
    final result = api_instance.listParentItemsApiLookupsParentItemsGet(q, workspaceId);
    print(result);
} catch (e) {
    print('Exception when calling WorkItemsApi->listParentItemsApiLookupsParentItemsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional] [default to '']
 **workspaceId** | **int**|  | [optional] 

### Return type

[**List<LookupResponse>**](LookupResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listTeamsApiLookupsTeamsGet**
> List<LookupResponse> listTeamsApiLookupsTeamsGet(q)

List Teams

### Example
```dart
import 'package:ottersync_openapi/api.dart';

final api_instance = WorkItemsApi();
final q = q_example; // String | 

try {
    final result = api_instance.listTeamsApiLookupsTeamsGet(q);
    print(result);
} catch (e) {
    print('Exception when calling WorkItemsApi->listTeamsApiLookupsTeamsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional] [default to '']

### Return type

[**List<LookupResponse>**](LookupResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listUsersApiLookupsUsersGet**
> List<LookupResponse> listUsersApiLookupsUsersGet(q)

List Users

### Example
```dart
import 'package:ottersync_openapi/api.dart';

final api_instance = WorkItemsApi();
final q = q_example; // String | 

try {
    final result = api_instance.listUsersApiLookupsUsersGet(q);
    print(result);
} catch (e) {
    print('Exception when calling WorkItemsApi->listUsersApiLookupsUsersGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional] [default to '']

### Return type

[**List<LookupResponse>**](LookupResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listWorkItemsApiWorkItemsGet**
> List<LookupResponse> listWorkItemsApiWorkItemsGet(q)

List Work Items

### Example
```dart
import 'package:ottersync_openapi/api.dart';

final api_instance = WorkItemsApi();
final q = q_example; // String | 

try {
    final result = api_instance.listWorkItemsApiWorkItemsGet(q);
    print(result);
} catch (e) {
    print('Exception when calling WorkItemsApi->listWorkItemsApiWorkItemsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional] [default to '']

### Return type

[**List<LookupResponse>**](LookupResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listWorkTypesApiLookupsWorkTypesGet**
> List<LookupResponse> listWorkTypesApiLookupsWorkTypesGet(q)

List Work Types

### Example
```dart
import 'package:ottersync_openapi/api.dart';

final api_instance = WorkItemsApi();
final q = q_example; // String | 

try {
    final result = api_instance.listWorkTypesApiLookupsWorkTypesGet(q);
    print(result);
} catch (e) {
    print('Exception when calling WorkItemsApi->listWorkTypesApiLookupsWorkTypesGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional] [default to '']

### Return type

[**List<LookupResponse>**](LookupResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listWorkspacesApiLookupsWorkspacesGet**
> List<LookupResponse> listWorkspacesApiLookupsWorkspacesGet(q)

List Workspaces

### Example
```dart
import 'package:ottersync_openapi/api.dart';

final api_instance = WorkItemsApi();
final q = q_example; // String | 

try {
    final result = api_instance.listWorkspacesApiLookupsWorkspacesGet(q);
    print(result);
} catch (e) {
    print('Exception when calling WorkItemsApi->listWorkspacesApiLookupsWorkspacesGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional] [default to '']

### Return type

[**List<LookupResponse>**](LookupResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

