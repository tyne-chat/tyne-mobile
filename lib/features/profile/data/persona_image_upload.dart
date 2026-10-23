// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fluxer_app/shared/utils/image_utils.dart';

/// Fork: the two images a persona has, named as the server's endpoints and
/// fields name them.
enum PersonaImageKind { avatar, banner }

/// Fork: stores an image picked in the persona editor and returns its hash
/// (and, for an avatar, its colour). The editor calls it on Save, as
/// upstream's profile editor sends a picked image with the profile, so an
/// image picked and then discarded is never uploaded.
Future<({String hash, int? avatarColor})> uploadPersonaImage(
  Dio dio,
  PersonaImageKind kind,
  Uint8List bytes,
) async {
  final String field = kind.name;
  final Response<dynamic> response = await dio.post<dynamic>(
    '/users/@me/personas/$field',
    data: <String, dynamic>{field: ImageUtils.toDataUri(bytes)},
  );
  final dynamic data = response.data;
  final Object? hash = data is Map ? data['${field}_hash'] : null;
  if (hash is! String || hash.isEmpty) {
    throw DioException.badResponse(
      statusCode: response.statusCode ?? 0,
      requestOptions: response.requestOptions,
      response: response,
    );
  }
  final Object? color = data is Map ? data['avatar_color'] : null;
  return (hash: hash, avatarColor: color is num ? color.toInt() : null);
}
