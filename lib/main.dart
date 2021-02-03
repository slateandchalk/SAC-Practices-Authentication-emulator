import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;

// ignore: non_constant_identifier_names
bool USE_EMULATORS = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  String host = '';

  if(kIsWeb){
    host = '10.1.81.182:8080';
  } else if(Platform.isAndroid){
    host = '10.0.2.2:8080';
  } else if(Platform.isIOS){
    host = '10.1.81.182:8080';
  }

  if(USE_EMULATORS){
    FirebaseFirestore.instance.settings = Settings(
      host: host, sslEnabled: false
    );
  }

  runApp(SacPracticesApp());
}

class SacPracticesApp extends StatelessWidget {
  
  MaterialApp withMaterialApp(Widget body){
    return MaterialApp(
      title: 'SAC Practices App',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: body,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return withMaterialApp(Center(child: FilmList()));
  }
}

class FilmList extends StatefulWidget {
  @override
  _FilmListState createState() => _FilmListState();
}

class _FilmListState extends State<FilmList> {
  @override
  Widget build(BuildContext context) {
    
    Query query = FirebaseFirestore.instance.collection('sac-practices-app');
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'SAC Practices: Movies'
            ),
            StreamBuilder(
              stream: FirebaseFirestore.instance.snapshotsInSync(),
              builder: (context, _) {
                return Text(
                  'Latest Snapshot: ${DateTime.now()}',
                  style: Theme.of(context).textTheme.caption,
                );
              },
            )
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, stream) {
          if (stream.connectionState == ConnectionState.waiting){
            return Center(child: CircularProgressIndicator());
          }
          
          if(stream.hasError) {
            return Center(child: Text(stream.error.toString()));
          }
          
          QuerySnapshot querySnapshot = stream.data;
          
          return ListView.builder(
            itemCount: querySnapshot.size,
            itemBuilder: (context, index) => Movie(querySnapshot.docs[index]),
          );
        },
      ),
    );
  }
}

class Movie extends StatelessWidget {
  
  final DocumentSnapshot snapshot;
  
  Movie(this.snapshot);
  
  Map<String, dynamic> get movie {
    return snapshot.data();
  }
  
  Widget get poster {
    return Container(
      width: 100,
      child: Center(child: Image.network(movie['poster']),),
    );
  }
  
  Widget get title {
    return Text("${movie['title']}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }
  
  Widget get details {
    return Padding(
        padding: EdgeInsets.only(left: 8, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          Likes(
            reference: snapshot.reference,
            currentLikes: movie['likes'],
          )
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4, top: 4),
      child: Container(
        child: Row(
          children: [poster, Flexible(child: details)],
        ),
      ),
    );
  }
}

class Likes extends StatefulWidget {

  final DocumentReference reference;

  final num currentLikes;

  Likes({Key key, this.reference, this.currentLikes}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _Likes();
  }
}

class _Likes extends State<Likes> {

  int _likes;

  _onLike(int current) async {
    setState(() {
      _likes = current + 1;
    });

    try {
      int newLikes  = await FirebaseFirestore.instance.runTransaction<int>((transaction) async {
        DocumentSnapshot txSnapshot = await transaction.get(widget.reference);

        if(!txSnapshot.exists){
          throw Exception("Document does not exist!");
        }

        int updatedLikes = (txSnapshot.data()['likes'] ?? 0) + 1;

        transaction.update(widget.reference, {'likes': updatedLikes});

        return updatedLikes;
      });

      setState(() {
        _likes = newLikes;
      });
    } catch (e, s) {
      print(s);
      print("Failed to update likes for document! $e");

      setState(() {
        _likes = current;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    int currentLikes = _likes ?? widget.currentLikes ?? 0;

    return Row(
      children: [
        IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              _onLike(currentLikes);
            }
        ),
        Text("$currentLikes likes"),
      ],
    );
  }
}

