import 'package:strava_client/strava_client.dart';

class StravaAuth {
  final StravaClient stravaClient;
  StravaAuth(this.stravaClient);

  Future<TokenResponse> testAuthentication(
      List<AuthenticationScope> scopes, String redirectUrl) {
    return stravaClient.authentication.authenticate(
        scopes: scopes,
        redirectUrl: redirectUrl,
        forceShowingApproval: false,
        callbackUrlScheme: "http",
        preferEphemeral: true);
  }

  Future<void> testDeauthorize() {
    return stravaClient.authentication.deAuthorize();
  }
}