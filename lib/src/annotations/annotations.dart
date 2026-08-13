/// Public annotation surface for describing REST APIs and models.
///
/// Field-level JSON mapping uses [JsonKey] from `package:json_annotation`
/// (re-exported below). No custom field annotation is provided.
library;

export 'package:json_annotation/json_annotation.dart' show JsonKey;

export 'api/api_annotations.dart';
export 'cache/cache_annotation.dart';
export 'configuration/configuration_annotations.dart';
export 'form/form_annotations.dart';
export 'http/http_annotations.dart';
export 'http/streaming_annotation.dart';

export 'models/rest_model.dart';
export 'multipart/multipart_annotations.dart';
export 'parameters/parameter_annotations.dart';
