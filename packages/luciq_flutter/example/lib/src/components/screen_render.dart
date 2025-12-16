part of '../../main.dart';

class ScreenRender extends StatelessWidget {
  const ScreenRender({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionTitle('Screen Render'),
        LuciqButton(
          text: 'Screen Render',
          onPressed: () => _navigateToScreenRender(context),
        ),
      ],
    );
  }

  _navigateToScreenRender(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LuciqCaptureScreenLoading(
          screenName: ScreenRenderPage.screenName,
          child: ScreenRenderPage(),
        ),
        settings: const RouteSettings(name: ScreenRenderPage.screenName),
      ),
    );
  }
}
