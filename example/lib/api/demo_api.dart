import 'package:rest_client_builder/rest_client_builder.dart';

import '../core/interceptors.dart';
import '../models/user.dart';

import '../rest_client_builder/api/demo_api.rest.g.dart';
export '../rest_client_builder/api/demo_api.rest.g.dart';

/// Example CRUD + multipart REST API.
///
/// Demonstrates path/query/body/headers, form login, multipart upload with
/// [CancelToken] / progress, and interceptor use/exclude annotations.
@RestApi(baseUrl: 'https://api.example.com')
@Headers({'Accept': 'application/json'})
@UseInterceptor([AuthInterceptor])
@Tag('users')
abstract class DemoApi {
  /// Read one user by id.
  @GET('/users/{id}')
  Future<RestResult<User>> getUser(
    @Path('id') String id, {
    @Query('expand') String? expand,
    @Header('X-Request-Id') String? requestId,
  });

  /// List users with arbitrary filters.
  @GET('/users')
  Future<RestResult<List<User>>> listUsers(
    @QueryMap() Map<String, Object?> filters,
  );

  /// Create a user (JSON body).
  @POST('/users')
  Future<RestResult<User>> createUser(@Body() User user);

  /// Full replace.
  @PUT('/users/{id}')
  Future<RestResult<User>> replaceUser(
    @Path('id') String id,
    @Body() User user,
  );

  /// Partial update.
  @PATCH('/users/{id}')
  Future<RestResult<User>> patchUser(
    @Path('id') String id,
    @Body() Map<String, Object?> patch,
  );

  /// Delete a user.
  @DELETE('/users/{id}')
  Future<RestResult<void>> deleteUser(@Path('id') String id);

  /// Form-urlencoded login (auth interceptor excluded).
  @POST('/login')
  @FormUrlEncoded()
  @ExcludeInterceptor([AuthInterceptor])
  Future<RestResult<User>> login(
    @Field('email') String email,
    @Field('password') String password,
  );

  /// Multipart avatar upload with cancel + progress.
  @POST('/avatar')
  @Multipart()
  @UseInterceptor([UploadInterceptor])
  Future<RestResult<User>> uploadAvatar(
    @Part(name: 'file') RestPart file,
    @Part(name: 'label') String label, {
    @Cancel() CancelToken? cancelToken,
    RestProgressCallback? onSendProgress,
    RestProgressCallback? onReceiveProgress,
  });

  /// Custom header map.
  @GET('/secure')
  Future<RestResult<User>> secure(
    @HeaderMap() Map<String, String> headers,
  );

  // ── New: Custom verb via @HTTP ────────────────────────────────────────────

  /// Sends a WebDAV REPORT request to query collection analytics.
  ///
  /// Demonstrates `@HTTP` with a non-standard HTTP verb.
  @HTTP('REPORT', '/users/analytics')
  Future<RestResult<Map<String, dynamic>>> reportAnalytics(
    @Body() Map<String, dynamic> query,
  );

  /// Purges a cached resource using a custom CDN verb.
  @HTTP('PURGE', '/cache/{key}')
  Future<RestResult<void>> purgeCache(@Path('key') String key);

  // ── New: Streaming download via @Streaming ────────────────────────────────

  /// Downloads a file as a raw byte stream without buffering it in RAM.
  ///
  /// Demonstrates `@Streaming` — the response body is returned as a
  /// `Stream<List<int>>` so you can pipe it directly to disk or a sink.
  @Streaming()
  @GET('/files/{id}')
  Future<RestResult<Stream<List<int>>>> downloadFile(
    @Path('id') String id, {
    @Query('format') String? format,
    @Cancel() CancelToken? cancelToken,
    RestProgressCallback? onReceiveProgress,
  });
}
