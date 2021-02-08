import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:sac_practices/register_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final FirebaseAuth _auth = FirebaseAuth.instance;

class SigninPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign in'),
      ),
      body: Builder(builder: (BuildContext context) {
        return ListView(
          padding: const EdgeInsets.all(8),
          children: <Widget>[emailPassForm(), anonymousForm(), googleForm()],
        );
      }),
    );
  }
}

class emailPassForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _emailPassFormState();
}

class _emailPassFormState extends State<emailPassForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.center,
                  child: const Text(
                    'Sign in with email and password',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (String value) {
                    if (value.isEmpty) {
                      return 'Please enter email';
                    }
                    print('hi');
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (String value) {
                    if (value.isEmpty) return 'Please enter password';
                    return null;
                  },
                  obscureText: true,
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: SignInButton(
                    Buttons.Email,
                    text: 'Sign In',
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        await signInEmailPass();
                      }
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  alignment: Alignment.center,
                  child: GestureDetector(
                    child: Text('Register'),
                    onTap: () async {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterPage(),
                          ));
                    },
                  ),
                )
              ],
            ),
          ),
        ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> signInEmailPass() async {
    try {
      final User user = (await _auth.signInWithEmailAndPassword(
              email: _emailController.text, password: _passController.text))
          .user;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.email} signed in'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to sign in with email and password'),
      ));
    }
  }
}

class anonymousForm extends StatefulWidget {
  @override
  _anonymousFormState createState() => _anonymousFormState();
}

class _anonymousFormState extends State<anonymousForm> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              child: const Text(
                'Sign in anonymously',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 16),
              alignment: Alignment.center,
              child: SignInButtonBuilder(
                text: 'Sign In',
                icon: Icons.person_outline,
                backgroundColor: Colors.indigo,
                onPressed: signInAnonmously,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> signInAnonmously() async {
    try {
      final User user = (await _auth.signInAnonymously()).user;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.uid} signed in')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to sign in with anonmously'),
      ));
    }
  }
}

class googleForm extends StatefulWidget {
  @override
  _googleFormState createState() => _googleFormState();
}

class _googleFormState extends State<googleForm> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              child: const Text(
                'Sign in Google',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 16),
              alignment: Alignment.center,
              child: SignInButton(
                Buttons.GoogleDark,
                text: 'Sign In',
                onPressed: () async {
                  signInGoogle();
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> signInGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final GoogleAuthCredential googleAuthCredential =
            GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(googleAuthCredential);
      }

      final user = userCredential.user;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.displayName} signed in')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to sign in with google')),
      );
    }
  }
}
