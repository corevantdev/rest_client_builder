/// Core domain contracts and shared primitives for rest_client_builder.
///
/// This layer is transport-agnostic: no Dio, no networking. It provides result
/// types, errors, logging, constants, and utilities used by annotations,
/// runtime, and generators.
library;

import 'constants/rest_constants.dart';

export 'constants/rest_constants.dart';
export 'error/rest_error.dart';
export 'logger/rest_logger.dart';
export 'result/rest_result.dart';
export 'utils/json_utils.dart';
export 'utils/map_utils.dart';
export 'utils/string_utils.dart';
export 'utils/type_utils.dart';
export 'utils/validation_utils.dart';

/// Package identity used for smoke tests and diagnostics.
const String restApiBuilderPackage = RestConstants.packageName;
