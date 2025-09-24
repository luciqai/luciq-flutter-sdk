part of '../../main.dart';

class CorePage extends StatefulWidget {
  static const screenName = 'core';

  const CorePage({Key? key}) : super(key: key);

  @override
  _CorePageState createState() => _CorePageState();
}

class _CorePageState extends State<CorePage> {
  List<InvocationOption> invocationOptions = [];

  final userDataController = TextEditingController();
  final userEventController = TextEditingController();
  final userEmailController = TextEditingController();
  final userNameController = TextEditingController();
  final userIdController = TextEditingController();
  final tagController = TextEditingController();
  final userAttributeKeyController = TextEditingController();
  final userAttributeValueController = TextEditingController();
  final logMessageController = TextEditingController();

  final _formUserAttributeKey = GlobalKey<FormState>();

  CallbackHandlersProvider? callbackHandlerProvider;

  void identifyUser(String email, String name, String id) {
    Luciq.identifyUser(email, name, id);
  }

  void addUserData() {
    if (userDataController.text.isNotEmpty) {
      Luciq.setUserData(userDataController.text);
    }
    userDataController.text = '';
  }

  void addUserEvent() {
    if (userEventController.text.isNotEmpty) {
      Luciq.logUserEvent(userEventController.text);
    }
    userEventController.text = '';
  }

  void addTag() {
    if (tagController.text.isNotEmpty) {
      Luciq.appendTags([tagController.text]);
    }
    tagController.text = '';
  }

  void addLogDebug() {
    if (logMessageController.text.isNotEmpty) {
      LuciqLog.logDebug(logMessageController.text);
    }
    logMessageController.text = '';
  }

  void addLogError() {
    if (logMessageController.text.isNotEmpty) {
      LuciqLog.logError(logMessageController.text);
    }
    logMessageController.text = '';
  }

  void addLogInfo() {
    if (logMessageController.text.isNotEmpty) {
      LuciqLog.logInfo(logMessageController.text);
    }
    logMessageController.text = '';
  }

  void addLogVerbose() {
    if (logMessageController.text.isNotEmpty) {
      LuciqLog.logVerbose(logMessageController.text);
    }
    logMessageController.text = '';
  }

  void addLogWarn() {
    if (logMessageController.text.isNotEmpty) {
      LuciqLog.logWarn(logMessageController.text);
    }
    logMessageController.text = '';
  }

  void setInvocationEvent(InvocationEvent invocationEvent) {
    BugReporting.setInvocationEvents([invocationEvent]);
  }

  void _navigateToCallbackHandler() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CallbackScreen(),
        settings: RouteSettings(name: CallbackScreen.screenName),
      ),
    );
  }

  @override
  void dispose() {
    userDataController.dispose();
    userEventController.dispose();
    userEmailController.dispose();
    userNameController.dispose();
    userIdController.dispose();
    tagController.dispose();
    userAttributeKeyController.dispose();
    userAttributeValueController.dispose();
    logMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    callbackHandlerProvider = context.read<CallbackHandlersProvider>();

    return Page(
      title: 'Core',
      children: [
        const SectionTitle('Set User Attribute'),
        Form(
          key: _formUserAttributeKey,
          child: Column(
            children: [
              Row(
                children: <Widget>[
                  Expanded(
                    child: LuciqTextField(
                      label: "User Attribute Key",
                      symanticLabel: 'user_attribute_key_input',
                      key: const Key("user_attribute_key_textfield"),
                      controller: userAttributeKeyController,
                      validator: (value) {
                        if (value?.trim().isNotEmpty == true) return null;
                        return 'This field is required';
                      },
                    ),
                  ),
                  Expanded(
                    child: LuciqTextField(
                      label: "User Attribute Value",
                      symanticLabel: 'user_attribute_value_input',
                      key: const Key("user_attribute_value_textfield"),
                      controller: userAttributeValueController,
                      validator: (value) {
                        if (value?.trim().isNotEmpty == true) return null;
                        return 'This field is required';
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LuciqButton(
                text: 'Set User Attribute',
                symanticLabel: 'set_user_attribute',
                key: const Key('set_user_data_btn'),
                onPressed: () {
                  if (_formUserAttributeKey.currentState?.validate() == true) {
                    Luciq.setUserAttribute(
                      userAttributeKeyController.text,
                      userAttributeValueController.text,
                    );
                  }
                },
              ),
              LuciqButton(
                text: 'Remove User Attribute',
                symanticLabel: 'remove_user_attribute',
                key: const Key('remove_user_data_btn'),
                onPressed: () {
                  if (_formUserAttributeKey.currentState?.validate() == true) {
                    Luciq.removeUserAttribute(
                      userAttributeKeyController.text,
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('User Data'),
        LuciqTextField(
          controller: userDataController,
          label: 'Enter user data',
          symanticLabel: 'user_data_input',
        ),
        LuciqButton(
          text: 'Set User Data',
          symanticLabel: 'set_user_data_btn',
          onPressed: addUserData,
        ),
        const SizedBox(height: 20),
        const SectionTitle('User Event'),
        LuciqTextField(
          controller: userEventController,
          label: 'Enter event name',
          symanticLabel: 'user_event_input',
        ),
        LuciqButton(
          text: 'Log User Event',
          symanticLabel: 'log_user_event_btn',
          onPressed: addUserEvent,
        ),
        const SizedBox(height: 20),
        const SectionTitle('Tags'),
        LuciqTextField(
          controller: tagController,
          label: 'Enter tag',
          symanticLabel: 'tag_input',
        ),
        LuciqButton(
          text: 'Add tag',
          symanticLabel: 'add_tag_btn',
          onPressed: addTag,
        ),
        const SizedBox(height: 20),
        const SectionTitle('Identify User'),
        LuciqTextField(
          controller: userIdController,
          label: 'User ID',
          symanticLabel: 'user_id_input',
        ),
        LuciqTextField(
          controller: userEmailController,
          label: 'User Email',
          symanticLabel: 'user_email_input',
        ),
        LuciqTextField(
          controller: userNameController,
          label: 'User Name',
          symanticLabel: 'user_name_input',
        ),
        LuciqButton(
          text: 'Identify User',
          symanticLabel: 'identify_user_btn',
          onPressed: () => identifyUser(
            userEmailController.text,
            userNameController.text,
            userIdController.text,
          ),
        ),
        LuciqButton(
          text: 'Logout User',
          symanticLabel: 'logout_user_btn',
          onPressed: () {
            Luciq.logOut();
          },
        ),
        LuciqButton(
          onPressed: _navigateToCallbackHandler,
          text: 'Callback Page',
          symanticLabel: 'open_callback_page',
        ),
        const SizedBox(height: 20),
        const SectionTitle('Logs'),
        LuciqTextField(
          controller: logMessageController,
          label: 'Enter log message',
          symanticLabel: 'log_message_input',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            LuciqButton(
              text: 'Debug',
              symanticLabel: 'log_debug_btn',
              onPressed: addLogDebug,
            ),
            LuciqButton(
              text: 'Error',
              symanticLabel: 'log_error_btn',
              onPressed: addLogError,
            ),
            LuciqButton(
              text: 'Info',
              symanticLabel: 'log_info_btn',
              onPressed: addLogInfo,
            ),
            LuciqButton(
              text: 'Verbose',
              symanticLabel: 'log_verbose_btn',
              onPressed: addLogVerbose,
            ),
            LuciqButton(
              text: 'Warn',
              symanticLabel: 'log_warn_btn',
              onPressed: addLogWarn,
            ),
          ],
        ),
        const SizedBox(height: 20),
        LuciqButton(
          text: 'Enable session profiler',
          symanticLabel: 'enable_session_profiler',
          key: const Key('enable_session_profiler_btn'),
          onPressed: () {
            Luciq.setSessionProfilerEnabled(true);
          },
        ),
        LuciqButton(
          text: 'Disable session profiler',
          symanticLabel: 'disable_session_profiler',
          key: const Key('disable_session_profiler_btn'),
          onPressed: () {
            Luciq.setSessionProfilerEnabled(false);
          },
        ),
        LuciqButton(
          text: 'Welcome Message LIVE',
          symanticLabel: 'welcome_message_live',
          key: const Key('welcome_msg_live_btn'),
          onPressed: () {
            Luciq.showWelcomeMessageWithMode(WelcomeMessageMode.live);
          },
        ),
        LuciqButton(
          text: 'Welcome Message BETA',
          symanticLabel: 'welcome_message_beta',
          key: const Key('welcome_msg_beta_btn'),
          onPressed: () {
            Luciq.showWelcomeMessageWithMode(WelcomeMessageMode.beta);
          },
        ),
        const SectionTitle('Invocation Events'),
        OverflowBar(
          alignment: MainAxisAlignment.start,
          children: <Widget>[
            ElevatedButton(
              key: const Key('invocation_event_none'),
              onPressed: () => setInvocationEvent(InvocationEvent.none),
              child: const Text('None'),
            ).withSemanticsLabel('invocation_event_none'),
            ElevatedButton(
              key: const Key('invocation_event_shake'),
              onPressed: () => setInvocationEvent(InvocationEvent.shake),
              child: const Text('Shake'),
            ).withSemanticsLabel('invocation_event_shake'),
            ElevatedButton(
              key: const Key('invocation_event_screenshot'),
              onPressed: () => setInvocationEvent(InvocationEvent.screenshot),
              child: const Text('Screenshot'),
            ).withSemanticsLabel('invocation_event_screenshot'),
          ],
        ),
        OverflowBar(
          alignment: MainAxisAlignment.start,
          children: <Widget>[
            ElevatedButton(
              key: const Key('invocation_event_floating'),
              onPressed: () =>
                  setInvocationEvent(InvocationEvent.floatingButton),
              child: const Text('Floating Button'),
            ).withSemanticsLabel('invocation_event_floating'),
            ElevatedButton(
              key: const Key('invocation_event_two_fingers'),
              onPressed: () =>
                  setInvocationEvent(InvocationEvent.twoFingersSwipeLeft),
              child: const Text('Two Fingers Swipe Left'),
            ).withSemanticsLabel('invocation_event_two_fingers'),
          ],
        ),
      ],
    );
  }
}
