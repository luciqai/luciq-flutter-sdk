part of '../../main.dart';

class NdkCrashesContent extends StatelessWidget {
  const NdkCrashesContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (Platform.isAndroid)
          Column(
            children: [
              LuciqButton(
                text: 'Trigger NDK Crash',
                onPressed: LuciqFlutterExampleMethodChannel.causeNdkCrash,
              ),
              LuciqButton(
                text: 'Trigger NDK SIGSEGV Crash',
                onPressed: LuciqFlutterExampleMethodChannel.causeNdkSigsegv,
              ),
              LuciqButton(
                text: 'Trigger NDK SIGABRT Crash',
                onPressed: LuciqFlutterExampleMethodChannel.causeNdkSigabrt,
              ),
              LuciqButton(
                text: 'Trigger NDK SIGFPE Crash',
                onPressed: LuciqFlutterExampleMethodChannel.causeNdkSigfpe,
              ),
              LuciqButton(
                text: 'Trigger NDK SIGILL Crash',
                onPressed: LuciqFlutterExampleMethodChannel.causeNdkSigill,
              ),
              LuciqButton(
                text: 'Trigger NDK SIGBUS Crash',
                onPressed: LuciqFlutterExampleMethodChannel.causeNdkSigbus,
              ),
              LuciqButton(
                text: 'Trigger NDK SIGTRAP Crash',
                onPressed: LuciqFlutterExampleMethodChannel.causeNdkSigtrap,
              ),
            ],
          )
        else
          const Text(
            'NDK crashes are only available on Android',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }
}
