part of '../../main.dart';

class CrashesPage extends StatelessWidget {
  static const screenName = 'crashes';

  const CrashesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Page(title: 'Crashes', children: [
      const SectionTitle('Non-Fatal Crashes'),
      const NonFatalCrashesContent(),
      const SectionTitle('Fatal Crashes'),
      const Text('Fatal Crashes can only be tested in release mode'),
      const Text('Most of these buttons will crash the application'),
      if (Platform.isAndroid) ...[
        FatalCrashesContent(),
        SectionTitle('NDK Crashes'),
        Text(
            'NDK crashes are native C/C++ crashes that occur in Android applications.'),
        Text(
            'These crashes can only be tested on Android devices with NDK support.',
            style: TextStyle(color: Colors.orange)),
        NdkCrashesContent(),
      ],
    ]);
  }
}
