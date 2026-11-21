// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/api/dio_error_message.dart';

DioException _error(Map<String, dynamic> data) => DioException(
  requestOptions: RequestOptions(path: '/users/@me/personas/settings'),
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: '/users/@me/personas/settings'),
    statusCode: 400,
    data: data,
  ),
);

// The shapes upstream's INVALID_FORM_BODY message does not read
// (tyne-chat/tyne#445): the message is shown without the field's path.
void main() {
  test('errors nested under data show the message without its path', () {
    final DioException error = _error(<String, dynamic>{
      'code': 'VALIDATION_ERROR',
      'message': 'Validation failed.',
      'data': <String, dynamic>{
        'errors': <Map<String, dynamic>>[
          <String, dynamic>{
            'path': 'settings.display_tag_text',
            'message': 'Must be 32 characters or fewer.',
          },
          <String, dynamic>{
            'path': 'settings.display_tag_icon',
            'message': 'Not an image.',
          },
        ],
      },
    });

    expect(
      apiMessageFromDioException(error),
      'Must be 32 characters or fewer.',
    );
    expect(
      userFacingErrorMessage(error, 'fallback'),
      'Must be 32 characters or fewer.',
    );
  });

  test('errors under another code show the message without its field', () {
    final DioException error = _error(<String, dynamic>{
      'code': 'PERSONA_TAG_COLLISION',
      'message': 'Tag collision.',
      'errors': <Map<String, dynamic>>[
        <String, dynamic>{
          'field': 'persona_tags',
          'message': 'Another persona already uses this tag.',
        },
      ],
    });

    expect(
      apiMessageFromDioException(error),
      'Another persona already uses this tag.',
    );
  });

  test('an error without a message falls back to the top-level one', () {
    final DioException error = _error(<String, dynamic>{
      'message': 'Validation failed.',
      'data': <String, dynamic>{
        'errors': <Map<String, dynamic>>[
          <String, dynamic>{'path': 'name'},
        ],
      },
    });

    expect(apiMessageFromDioException(error), 'Validation failed.');
  });
}
