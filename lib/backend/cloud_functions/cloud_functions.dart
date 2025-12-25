import 'package:cloud_functions/cloud_functions.dart';
import '/utils/app_logger.dart';

Future<Map<String, dynamic>> makeCloudCall(
  String callName,
  Map<String, dynamic> input,
) async {
  try {
    final response = await FirebaseFunctions.instance
        .httpsCallable(callName, options: HttpsCallableOptions())
        .call(input);
    return response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : {};
  } on FirebaseFunctionsException catch (e) {
    AppLogger.e(
      'Cloud call error: $callName - Code: ${e.code}, Details: ${e.details}, Message: ${e.message}',
      error: e,
      tag: 'CloudFunctions',
    );
  } catch (e) {
    AppLogger.e('Cloud call error: $callName', error: e, tag: 'CloudFunctions');
  }
  return {};
}
