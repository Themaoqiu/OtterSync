# ottersync_openapi.api.DefaultApi

## Load the API package
```dart
import 'package:ottersync_openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**healthcheckHealthGet**](DefaultApi.md#healthcheckhealthget) | **GET** /health | Healthcheck


# **healthcheckHealthGet**
> Map<String, String> healthcheckHealthGet()

Healthcheck

### Example
```dart
import 'package:ottersync_openapi/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.healthcheckHealthGet();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->healthcheckHealthGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Map<String, String>**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

