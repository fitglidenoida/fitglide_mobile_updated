import 'package:fitglide_mobile_application/services/storage_service.dart';
import 'package:fitglide_mobile_application/view/home/home_view.dart';
import 'package:flutter/material.dart';

// Remove unused import if HomeView is not used

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  String? _savedToken;

  Future<void> _saveTestToken() async {
    const testToken = 'your_test_token';
    await StorageService.saveToken(testToken);
    setState(() {
      _savedToken = testToken;
    });
  }

  Future<void> _getToken() async {
    final token = await StorageService.getToken();
    setState(() {
      _savedToken = token;
    });
  }

  Future<void> _clearToken() async {
    await StorageService.clearToken();
    setState(() {
      _savedToken = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Saved Token: $_savedToken'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _saveTestToken,
                  child: const Text('Save Test Token'),
                ),
                SizedBox(
                  height: media.width * 0.4,
                ), // Consistent spacing
                ElevatedButton(
                  onPressed: _getToken,
                  child: const Text('Get Token'),
                ),
                SizedBox(
                  height: media.width * 0.4,
                ), // Consistent spacing
                ElevatedButton(
                  onPressed: _clearToken,
                  child: const Text('Clear Token'),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                // Use HomeView if intended, otherwise remove
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeView()),
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}