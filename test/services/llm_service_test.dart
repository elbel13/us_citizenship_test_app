import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:us_citizenship_test_app/services/llm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LlmService', () {
    test(
      'should load model successfully',
      () async {
        final service = LlmService();

        // This should either succeed or give us a detailed error
        await service.initialize();

        expect(service.isInitialized, true);
      },
      // Skip on desktop platforms - TFLite requires manual DLL setup
      // This test should be run on Android/iOS where TFLite is fully supported
      skip: Platform.isWindows || Platform.isLinux || Platform.isMacOS
          ? 'TFLite tests require Android/iOS platform. '
                'Desktop platforms need manual library setup. '
                'See: https://pub.dev/packages/tflite_flutter#windows'
          : false,
    );
  });
}
