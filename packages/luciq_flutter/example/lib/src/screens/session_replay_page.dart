part of '../../main.dart';

class SessionReplayPage extends StatefulWidget {
  static const screenName = 'SessionReplay';

  const SessionReplayPage({Key? key}) : super(key: key);

  @override
  State<SessionReplayPage> createState() => _SessionReplayPageState();
}

class _SessionReplayPageState extends State<SessionReplayPage> {
  @override
  Widget build(BuildContext context) {
    return Page(
      title: 'Session Replay',
      children: [
        const SectionTitle('Enabling Session Replay'),
        LuciqButton(
          key: const Key('luciq_sesssion_replay_disable'),
          onPressed: () => SessionReplay.setEnabled(false),
          text: "Disable Session Replay",
          symanticLabel: 'luciq_sesssion_replay_disable',
        ),
        LuciqButton(
          key: const Key('luciq_sesssion_replay_enable'),
          onPressed: () => SessionReplay.setEnabled(true),
          text: "Enable Session Replay",
          symanticLabel: 'luciq_sesssion_replay_enable',
        ),
        const SectionTitle('Enabling Session Replay Network'),
        LuciqButton(
          key: const Key('luciq_sesssion_replay_network_disable'),
          onPressed: () => SessionReplay.setNetworkLogsEnabled(false),
          text: "Disable Session Replay Network",
          symanticLabel: 'luciq_sesssion_replay_network_disable',
        ),
        LuciqButton(
          key: const Key('luciq_sesssion_replay_network_enable'),
          onPressed: () => SessionReplay.setNetworkLogsEnabled(true),
          text: "Enable Session Replay Network",
          symanticLabel: 'luciq_sesssion_replay_network_enable',
        ),
        const SectionTitle('Enabling Session Replay User Steps'),
        LuciqButton(
          key: const Key('luciq_sesssion_replay_user_steps_disable'),
          onPressed: () => SessionReplay.setUserStepsEnabled(false),
          text: "Disable Session Replay User Steps",
          symanticLabel: 'luciq_sesssion_replay_user_steps_disable',
        ),
        LuciqButton(
          key: const Key('luciq_sesssion_replay_user_steps_enable'),
          onPressed: () => SessionReplay.setUserStepsEnabled(true),
          text: "Enable Session Replay User Steps",
          symanticLabel: 'luciq_sesssion_replay_user_steps_enable',
        ),
        const SectionTitle('Enabling Session Replay Logs'),
        LuciqButton(
          key: const Key('luciq_sesssion_replay_logs_disable'),
          onPressed: () => SessionReplay.setLuciqLogsEnabled(false),
          text: "Disable Session Replay Logs",
          symanticLabel: 'luciq_sesssion_replay_logs_disable',
        ),
        LuciqButton(
          key: const Key('luciq_sesssion_replay_logs_enable'),
          onPressed: () => SessionReplay.setLuciqLogsEnabled(true),
          text: "Enable Session Replay Logs",
          symanticLabel: 'luciq_sesssion_replay_logs_enable',
        ),
        const SectionTitle('Enabling Session Replay Repro steps'),
        LuciqButton(
          key: const Key('luciq_sesssion_replay_repro_steps_disable'),
          onPressed: () => Luciq.setReproStepsConfig(
            sessionReplay: ReproStepsMode.disabled,
          ),
          text: "Disable Session Replay Repro steps",
          symanticLabel: 'luciq_sesssion_replay_repro_steps_disable',
        ),
        LuciqButton(
          key: const Key('luciq_sesssion_replay_repro_steps_enable'),
          onPressed: () =>
              Luciq.setReproStepsConfig(sessionReplay: ReproStepsMode.enabled),
          text: "Enable Session Replay Repro steps",
          symanticLabel: 'luciq_sesssion_replay_repro_steps_enable',
        ),
        LuciqButton(
          key: const Key('luciq_sesssion_replay_tab_screen'),
          onPressed: () =>
              Navigator.of(context).pushNamed(TopTabBarScreen.route),
          text: 'Open Tab Screen',
          symanticLabel: 'luciq_sesssion_replay_tab_screen',
        ),
      ],
    );
  }
}

class TopTabBarScreen extends StatelessWidget {
  static const String route = "/tap";

  const TopTabBarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Top TabBar with 4 Tabs'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Home', icon: Icon(Icons.home)),
              Tab(text: 'Search', icon: Icon(Icons.search)),
              Tab(text: 'Alerts', icon: Icon(Icons.notifications)),
              Tab(text: 'Profile', icon: Icon(Icons.person)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('Home Screen')),
            Center(child: Text('Search Screen')),
            Center(child: Text('Alerts Screen')),
            Center(child: Text('Profile Screen')),
          ],
        ),
      ),
    );
  }
}
