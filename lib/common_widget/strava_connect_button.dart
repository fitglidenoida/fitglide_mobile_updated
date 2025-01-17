import 'dart:async';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:fitglide_mobile_application/common/colo_extension.dart';
import 'package:fitglide_mobile_application/services/strava_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:strava_client/strava_client.dart';
import 'package:url_launcher/url_launcher.dart';

class StravaConnectButton extends StatefulWidget {
  const StravaConnectButton({super.key});

  @override
  _StravaConnectButtonState createState() => _StravaConnectButtonState();
}

class _StravaConnectButtonState extends State<StravaConnectButton> {
  final TextEditingController _textEditingController = TextEditingController();
  final DateFormat dateFormatter = DateFormat("HH:mm:ss");

  // Define your client ID and secret here as constants or variables
  static const String _clientSecret = 'f745c3921d32c355143d001e177b9d717ceb201d';
  static const int _clientId = 117285;

  late final StravaClient stravaClient;

  bool isLoggedIn = false;
  TokenResponse? token;

  @override
  void initState() {
    stravaClient = StravaClient(secret: _clientSecret, clientId: _clientId.toString());
    super.initState();
  }

  FutureOr<Null> showErrorMessage(dynamic error, dynamic stackTrace) {
    if (error is Fault) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Did Receive Fault"),
              content: Text(
                  "Message: ${error.message}\n-----------------\nErrors:\n${(error.errors ?? []).map((e) => "Code: ${e.code}\nResource: ${e.resource}\nField: ${e.field}\n").toList().join("\n----------\n")}"),
            );
          });
    }
  }

  // This method initiates the Strava authentication flow for mobile apps
  void initiateAuthentication() async {
    final redirectUri = "https://fitglide.in/callback"; // Custom scheme for mobile callback
    final scope = "activity:read_all,profile:read_all,read";

    final Uri uri = Uri.parse('https://www.strava.com/oauth/mobile/authorize')
        .replace(queryParameters: {
      'client_id': _clientId.toString(),
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'approval_prompt': 'auto',
      'scope': scope,
    });

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $uri';
    }
  }

  // Here, you would typically handle the callback. For Flutter, you'd need a method to handle 
  // the redirect back from Strava, which could involve registering for a custom URL scheme
  // in your Android/iOS setup and handling it in your app.

  void testDeauth() {
    StravaAuth(stravaClient).testDeauthorize().then((value) {
      setState(() {
        isLoggedIn = false;
        token = null;
        _textEditingController.clear();
      });
    }).catchError(showErrorMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter Strava Plugin"),
        actions: [
          Icon(
            isLoggedIn
                ? Icons.radio_button_checked_outlined
                : Icons.radio_button_off,
            color: isLoggedIn ? Colors.white : Colors.red,
          ),
          SizedBox(
            width: 8,
          )
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_stravalogin()],
        ),
      ),
    );
  }

  Widget _stravalogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomAnimatedToggleSwitch<bool>(
          current: isLoggedIn,
          values: const [false, true],
          animationDuration: const Duration(milliseconds: 200),
          animationCurve: Curves.easeInOut,
          onChanged: (value) {
            setState(() {
              isLoggedIn = value;
            });
            if (value) {
              // If toggled to "on", initiate login
              initiateAuthentication();
            } else {
              // If toggled to "off", initiate deauthorization
              testDeauth();
            }
          },
          iconBuilder: (context, local, global) => SizedBox(), // Empty for now
          wrapperBuilder: (context, global, child) => Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 10.0,
                right: 10.0,
                height: 30.0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: TColor.secondaryG),
                    borderRadius: BorderRadius.circular(50.0),
                  ),
                ),
              ),
              child,
            ],
          ),
          foregroundIndicatorBuilder: (context, global) => SizedBox.fromSize(
            size: const Size(10, 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: TColor.white,
                borderRadius: BorderRadius.circular(50.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    spreadRadius: 0.05,
                    blurRadius: 1.1,
                    offset: Offset(0.0, 0.8),
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          minLines: 1,
          maxLines: 3,
          controller: _textEditingController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            label: const Text("Access Token"),
            suffixIcon: TextButton(
              child: const Text("Copy"),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _textEditingController.text))
                    .then((_) => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Copied!")),
                        ));
              },
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }
}