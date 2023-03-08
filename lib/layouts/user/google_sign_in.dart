import 'dart:convert';
import 'package:socialoo/global/global.dart';
import 'package:socialoo/models/social_model.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialoo/shared_preferences/preferencesKey.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();

String name;
String email;
String imageUrl;
String userId;
String data = "";
Future<String> signInWithGoogle(BuildContext context) async {
  final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
  final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;

  final AuthCredential credential = GoogleAuthProvider.getCredential(
    accessToken: googleSignInAuthentication.accessToken,
    idToken: googleSignInAuthentication.idToken,
  );

  final AuthResult authResult = await _auth.signInWithCredential(credential);
  final FirebaseUser user = authResult.user;

  // Checking if email and name is null
  assert(user.email != null);
  assert(user.displayName != null);
  assert(user.photoUrl != null);

  name = user.displayName;
  email = user.email;
  imageUrl = user.photoUrl;
  userId = user.uid;

  print(name);
  print(email);
  print(imageUrl);

  assert(!user.isAnonymous);
  assert(await user.getIdToken() != null);

  final FirebaseUser currentUser = await _auth.currentUser();
  assert(user.uid == currentUser.uid);

  if (user.uid != null) {
    FirebaseMessaging().getToken().then((token) {
      _userDataPost(context, token);
    });
  }

  return 'signInWithGoogle succeeded: $user';
}

void signOutGoogle() async {
  await googleSignIn.signOut();

  print("User Sign Out");
}

_userDataPost(BuildContext context, token) async {
  SocialModel socialModel;

  var uri = Uri.parse('${baseUrl()}/social_login');
  var request = new http.MultipartRequest("Post", uri);
  Map<String, String> headers = {
    "Accept": "application/json",
  };
  request.headers.addAll(headers);
  request.fields.addAll({
    'username': name.toString(),
    'email': email.toString(),
    'type': 'google',
    'google_id': userId.toString(),
    'image_url': imageUrl.toString(),
    "device_token": token
  });
  var response = await request.send();
  print(response.statusCode);
  String responseData = await response.stream.transform(utf8.decoder).join();
  var userData = json.decode(responseData);
  socialModel = SocialModel.fromJson(userData);

  if (socialModel.responseCode == "1") {
    String userResponseStr = json.encode(userData);
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setString(
        SharedPreferencesKey.LOGGED_IN_USERRDATA, userResponseStr);
    Navigator.of(context).pushReplacementNamed('/Pages', arguments: 0);
    // Navigator.of(context).pushAndRemoveUntil(
    //   MaterialPageRoute(
    //     builder: (context) => BottomTabbar(),
    //   ),
    //   (Route<dynamic> route) => false,
    // );
  } else {
    Flushbar(
      title: "Failure",
      message: "Google login fail!",
      duration: Duration(seconds: 3),
      icon: Icon(
        Icons.error,
        color: Colors.red,
      ),
    )..show(context);
  }
  print(responseData);
}
