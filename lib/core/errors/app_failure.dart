/// A normalized, user-safe representation of anything that can go wrong
/// talking to the API. UI code should only ever render [message] — never a
/// raw exception — so students never see a stack trace or technical jargon.
class AppFailure {
  const AppFailure(this.message, {this.fieldErrors, this.statusCode});

  final String message;
  final Map<String, List<String>>? fieldErrors;
  final int? statusCode;

  bool get isValidation => fieldErrors != null && fieldErrors!.isNotEmpty;

  bool get isUnauthenticated => statusCode == 401;

  factory AppFailure.network() => const AppFailure(
    'Unable to connect to IST. Please check your internet connection and try again.',
  );

  factory AppFailure.timeout() => const AppFailure(
    'The connection to IST timed out. Please try again.',
  );

  factory AppFailure.server() => const AppFailure(
    'Something went wrong on our end. Please try again shortly.',
  );

  factory AppFailure.unknown() => const AppFailure(
    'Something unexpected happened. Please try again.',
  );
}
