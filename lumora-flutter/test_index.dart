import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'lib/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MaterialApp(home: DefaultTarget()));
}

class DefaultTarget extends StatefulWidget {
  const DefaultTarget({Key? key}) : super(key: key);
  @override
  State<DefaultTarget> createState() => _DefaultTargetState();
}
class _DefaultTargetState extends State<DefaultTarget> {
  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('anoPosts')
        .where('category', isEqualTo: 'Struggling Today')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get()
        .then((_) => print('SUCCESS'))
        .catchError((e) => print('ERROR_FETCHING: $e'));
  }
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Test')));
}
