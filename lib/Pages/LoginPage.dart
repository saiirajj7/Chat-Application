import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:telegramchatapp/Pages/HomePage.dart';
import 'package:telegramchatapp/Widgets/ProgressWidget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginScreen extends StatefulWidget {

  @override
  LoginScreenState createState() => LoginScreenState();
}
class LoginScreenState extends State<LoginScreen> {

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences preferences;
  bool isLoggedIn = false;
  bool isLoading = false;
  FirebaseUser currentUser;
  @override
  void initState(){
    super.initState();
    isSignedIn();
  }
  void isSignedIn() async{
    this.setState(() {
      isLoggedIn = true;
    });
    preferences = await SharedPreferences.getInstance();
    isLoggedIn = await googleSignIn.isSignedIn();
    if(isLoggedIn)
      {
        Navigator.push(context,MaterialPageRoute(builder: (context) => HomeScreen(currentUserId : preferences.getString("id"))));
      }
    this.setState(() {
      isLoading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.black, Colors.teal],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
                "ChatApp",
                style: TextStyle(fontSize: 50.0, color: Colors.white)
            ),
            GestureDetector(
              onTap: controlSignIn,
              child: Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 270.0,
                      height: 65.0,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                              "assets/images/google_signin_button.png"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(1.0),
                      child: circularProgress(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Null>controlSignIn() async
  {
    this.setState(() {
      isLoading = true;
    });
    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuthentication = await googleUser
        .authentication;

    final AuthCredential credential = GoogleAuthProvider
        .getCredential(idToken: googleAuthentication.idToken, accessToken: googleAuthentication.accessToken);

    FirebaseUser firebaseUser = (await firebaseAuth.signInWithCredential(
        credential)).user;

//Signin Success
    if (firebaseUser != null) {
      //check if already signed Up
      final QuerySnapshot resultQuery = await Firestore.instance.collection("Users").where("id", isEqualTo : firebaseUser.uid).getDocuments();
      final List<DocumentSnapshot> documentSnapshots =resultQuery.documents;
      //Save data to firestore
      if (documentSnapshots.length == 0)
      {
      Firestore.instance.collection("Users").document(firebaseUser.uid).setData({
        "User":firebaseUser.displayName,
        "PhotoUrl":firebaseUser.photoUrl,
        "id":firebaseUser.uid,
        "aboutMe":"Chillin MAX",
        "createdAt" : DateTime.now().millisecondsSinceEpoch.toString(),
        "Chattingwith" : null,
      });
      currentUser = firebaseUser;
      await preferences.setString("id",currentUser.uid);
      await preferences.setString("nickname",currentUser.displayName);
      await preferences.setString("photourl",currentUser.photoUrl);

      }
      else
        {
        currentUser = firebaseUser;
        await preferences.setString("id", documentSnapshots[0]["id"]);
        await preferences.setString("nickname", documentSnapshots[0]["nickname"]);
        await preferences.setString("photourl", documentSnapshots[0]["photourl"]);
        await preferences.setString("aboutMe", documentSnapshots[0]["aboutMe"]);
        }
       Fluttertoast.showToast(msg: "Congratulation, Sign In Success");
        this.setState(() {
        isLoading=false;
      });
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(currentUserId: firebaseUser.uid)));
    }

//Signin Not Success ~ Signin Failed
      else
        {
          Fluttertoast.showToast(msg: "Try Again, Sign in Failed.");
          this.setState(() {
          isLoading=false;
      });
    }
  }
}