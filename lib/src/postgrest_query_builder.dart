part of 'postgrest_builder.dart';

/// The query builder class provides a convenient interface to creating request queries.
///
/// Allows the user to stack the filter functions before they call any of
/// * select() - "get"
/// * insert() - "post"
/// * update() - "patch"
/// * delete() - "delete"
/// Once any of these are called the filters are passed down to the Request.
class PostgrestQueryBuilder<T> extends PostgrestBuilder<T, T> {
  PostgrestQueryBuilder(
    String url, {
    Map<String, String>? headers,
    String? schema,
    Client? httpClient,
    FetchOptions? options,
  }) : super(
          url: Uri.parse(url),
          headers: headers ?? {},
          schema: schema,
          httpClient: httpClient,
          options: options,
        );

  /// Performs horizontal filtering with SELECT.
  ///
  /// ```dart
  /// postgrest.from('users').select<PostgrestList>('id, messages');
  /// ```
  ///
  /// ```dart
  /// postgrest.from('users').select<PostgrestListResponse>('id, messages', FetchOptions(count: CountOption.exact));
  /// ```
  /// By setting [FetchOptions.count] to non null or [FetchOptions.forceResponse] to `true`, the return type is `PostgrestResponse<T>`.
  ///
  /// Allowed types for [R] are:
  /// - [List<Map<String, dynamic>>]
  /// - [Map<String, dynamic>]
  /// - [Map<String, dynamic>?]
  /// - [PostgrestResponse<List<Map<String, dynamic>>>]
  /// - [PostgrestResponse<Map<String, dynamic>>]
  /// - [PostgrestResponse<Map<String, dynamic>?>]
  PostgrestFilterBuilder<R> select<R>([
    String columns = '*',
    FetchOptions options = const FetchOptions(),
  ]) {
    _assertCorrectGeneric(R);
    _method = METHOD_GET;

    // Remove whitespaces except when quoted
    var quoted = false;
    final re = RegExp(r'\s');
    final cleanedColumns = columns.split('').map((c) {
      if (re.hasMatch(c) && !quoted) {
        return '';
      }
      if (c == '"') {
        quoted = !quoted;
      }
      return c;
    }).join();

    appendSearchParams('select', cleanedColumns);
    _options = options;
    return PostgrestFilterBuilder<R>(
      PostgrestQueryBuilder(
        _url.toString(),
        headers: _headers,
        schema: _schema,
        httpClient: _httpClient,
        options: _options,
      ).._method = _method,
    );
  }

  /// Performs an INSERT into the table.
  ///
  /// By default no data is returned. Use a trailing `select` to return data.
  ///
  /// Default (not returning data):
  /// ```dart
  /// postgrest.from('messages').insert({'message': 'foo', 'username': 'supabot', 'channel_id': 1})
  /// ```
  ///
  /// Returning data:
  /// ```dart
  /// postgrest.from('messages').insert({'message': 'foo', 'username': 'supabot', 'channel_id': 1}).select()
  /// ```
  PostgrestFilterBuilder<T> insert(dynamic values) {
    _method = METHOD_POST;
    _headers['Prefer'] = '';
    _body = values;
    return PostgrestFilterBuilder<T>(this);
  }

  /// Performs an UPSERT into the table.
  ///
  /// By specifying the [onConflict] query parameter, you can make UPSERT work on a column(s) that has a UNIQUE constraint.
  /// [ignoreDuplicates] Specifies if duplicate rows should be ignored and not inserted.
  /// ```dart
  /// postgrest.from('messages').upsert({'id': 3, message: 'foo', 'username': 'supabot', 'channel_id': 2})
  /// ```
  PostgrestFilterBuilder<T> upsert(
    dynamic values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    FetchOptions options = const FetchOptions(),
  }) {
    _method = METHOD_POST;
    _headers['Prefer'] =
        'resolution=${ignoreDuplicates ? 'ignore' : 'merge'}-duplicates';
    if (onConflict != null) {
      _url = _url.replace(
        queryParameters: {
          'on_conflict': onConflict,
          ..._url.queryParameters,
        },
      );
    }
    _body = values;
    _options = options.ensureNotHead();
    return PostgrestFilterBuilder<T>(this);
  }

  /// Performs an UPDATE on the table.
  ///
  /// ```dart
  /// postgrest.from('messages').update({'channel_id': 2}).eq('message', 'foo')
  /// ```
  PostgrestFilterBuilder<T> update(
    Map values, {
    FetchOptions options = const FetchOptions(),
  }) {
    _method = METHOD_PATCH;
    _headers['Prefer'] = '';
    _body = values;
    _options = options.ensureNotHead();
    return PostgrestFilterBuilder<T>(this);
  }

  /// Performs a DELETE on the table.
  ///
  /// By default the deleted record(s) will be returned. Set [returning] to minimal if you don't need this value.
  /// ```dart
  /// postgrest.from('messages').delete().eq('message', 'foo')
  /// ```
  PostgrestFilterBuilder<T> delete({
    ReturningOption returning = ReturningOption.representation,
    FetchOptions options = const FetchOptions(),
  }) {
    _method = METHOD_DELETE;
    _headers['Prefer'] = 'return=${returning.name()}';
    _options = options.ensureNotHead();
    return PostgrestFilterBuilder<T>(this);
  }
}
