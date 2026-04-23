# ottersync_openapi.model.WorkItemResponse

## Load the model package
```dart
import 'package:ottersync_openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **int** |  | 
**summary** | **String** |  | 
**description** | **String** |  | [optional] 
**workspace** | [**LookupResponse**](LookupResponse.md) |  | 
**workType** | [**LookupResponse**](LookupResponse.md) |  | 
**reporter** | [**LookupResponse**](LookupResponse.md) |  | 
**assignee** | [**LookupResponse**](LookupResponse.md) |  | [optional] 
**parent** | [**LookupResponse**](LookupResponse.md) |  | [optional] 
**team** | [**LookupResponse**](LookupResponse.md) |  | [optional] 
**dueDate** | [**DateTime**](DateTime.md) |  | [optional] 
**startDate** | [**DateTime**](DateTime.md) |  | [optional] 
**labels** | [**List<LookupResponse>**](LookupResponse.md) |  | [default to const []]
**attachments** | [**List<AttachmentResponse>**](AttachmentResponse.md) |  | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


