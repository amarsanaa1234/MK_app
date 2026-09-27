import 'package:flutter/foundation.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

/// True while the user is off paying in the browser. The billing page watches it and
/// re-syncs the plan when the app comes back to the foreground.
final ValueNotifier<bool> paymentPending = ValueNotifier<bool>(false);

/// Opens Stripe Checkout in the browser for a paid plan. The browser does the paying (card,
/// Apple Pay or Google Pay); the plan updates when the user returns to the app.
Future<void> startPaidCheckout({
  required AuthResult session,
  required String plan,
  required bool yearly,
}) async {
  final checkout = await ApiClient.startCheckout(
    token: session.token,
    adminId: session.userId,
    plan: plan,
    yearly: yearly,
  );
  final opened = await launchUrl(Uri.parse(checkout.url), mode: LaunchMode.externalApplication);
  if (!opened) throw ApiException('Could not open the payment page.');
  paymentPending.value = true;
}
