import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAccountStub extends Fake implements GoogleSignInAccount {
  @override
  GoogleSignInAuthentication get authentication =>
      const GoogleSignInAuthentication(idToken: 'google-id-token');
}
