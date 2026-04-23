# ottersync_openapi.model.WorkItemCreateRequest

## Load the model package
```dart
import 'package:ottersync_openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**workspaceId** | **int** |  | 
**workTypeId** | **int** |  | 
**summary** | **String** |  | 
**description** | **String** |  | [optional] 
**reporterId** | **int** |  | 
**assigneeId** | **int** |  | [optional] 
**parentId** | **int** |  | [optional] 
**teamId** | **int** |  | [optional] 
**dueDate** | [**DateTime**](DateTime.md) |  | [optional] 
**startDate** | [**DateTime**](DateTime.md) |  | [optional] 
**labelIds** | **List<int>** |  | [optional] [default to const []]
**newLabelNames** | **List<String>** |  | [optional] [default to const []]
**attachments** | [**List<AttachmentCreateRequest>**](AttachmentCreateRequest.md) |  | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


