import 'dart:core';

import 'postgrest_builder.dart';
import 'postgrest_filter_builder.dart';

/// The query builder class provides a convenient interface to creating request queries.
///
/// Allows the user to stack the filter functions before they call any of
/// * select() - "get"
/// * insert() - "post"
/// * update() - "patch"
/// * delete() - "delete"
/// Once any of these are called the filters are passed down to the Request.
class PostgrestQueryBuilder extends PostgrestBuilder {
  PostgrestQueryBuilder(
    String url, {
    Map<String, String>? headers,
    String? schema,
  }) : super(
          url: Uri.parse(url),
          headers: headers ?? {},
          schema: schema,
        );

  /// Performs horizontal filtering with SELECT.
  ///
  /// ```dart
  /// postgrest.from('users').select('id, messages');
  /// ```
  PostgrestFilterBuilder select([String columns = '*']) {
    method = 'GET';

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
    return PostgrestFilterBuilder(this);
  }

  /// Performs an INSERT into the table.
  ///
  /// ```dart
  /// postgrest.from('messages').insert({'message': 'foo', 'username': 'supabot', 'channel_id': 1})
  /// ```
  PostgrestBuilder insert(
    dynamic values, {
    @Deprecated('Use `upsert()` method instead') bool upsert = false,
    @Deprecated('Use `upsert()` method instead') String? onConflict,
  }) {
    method = 'POST';
    headers['Prefer'] =
        upsert ? 'return=representation,resolution=merge-duplicates' : 'return=representation';
    if (onConflict != null) {
      url = url.replace(queryParameters: {'on_conflict': onConflict, ...url.queryParameters});
    }
    body = values;
    return this;
  }

  /// Performs an UPSERT into the table.
  ///
  /// ```dart
  /// postgrest.from('messages').upsert({'id': 3, message: 'foo', 'username': 'supabot', 'channel_id': 2})
  /// ```
  PostgrestBuilder upsert(
    dynamic values, {
    String? onConflict,
  }) {
    method = 'POST';
    headers['Prefer'] = 'return=representation,resolution=merge-duplicates';
    if (onConflict != null) {
      url = url.replace(queryParameters: {'on_conflict': onConflict, ...url.queryParameters});
    }
    body = values;
    return this;
  }

  /// Performs an UPDATE on the table.
  ///
  /// ```dart
  /// postgrest.from('messages').update({'channel_id': 2}).eq('message', 'foo')
  /// ```
  PostgrestFilterBuilder update(Map values) {
    method = 'PATCH';
    headers['Prefer'] = 'return=representation';
    body = values;
    return PostgrestFilterBuilder(this);
  }

  /// Performs a DELETE on the table.
  ///
  /// ```dart
  /// postgrest.from('messages').delete().eq('message', 'foo')
  /// ```
  PostgrestFilterBuilder delete() {
    method = 'DELETE';
    headers['Prefer'] = 'return=representation';
    return PostgrestFilterBuilder(this);
  }
}
