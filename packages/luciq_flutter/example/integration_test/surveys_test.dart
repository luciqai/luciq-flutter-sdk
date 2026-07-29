import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'utils/utils.dart';

void main() {
  group('Surveys tests', () {
    patrolTest(
      'Show Surveys Screen',
      ($) async {
        await init($);

        await wait(second: 2);

        final title = await showManualSurveyUntilVisible($);

        expect(isAndroid ? title.androidViews.length : title.iosViews.length,
            equals(1));
      },
    );
  });
}
