import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sac_practices/signin_page.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class FilmList extends StatefulWidget {
  @override
  _FilmListState createState() => _FilmListState();
}

class _FilmListState extends State<FilmList> {
  bool isLoggedIn;
  @override
  void initState() {
    isLoggedIn = false;
    FirebaseAuth.instance.authStateChanges().listen((User user) {
      if(user != null) {
        setState(() {
          isLoggedIn = true;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    Query query = FirebaseFirestore.instance.collection('sac-practices-app');

    return isLoggedIn ? Scaffold(
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
        actions: [
          Builder(builder: (BuildContext context) {
            return FlatButton(onPressed: () async {
              final User user = _auth.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No one signed in'))
                );
                return;
              }

              await _signOut();
            },
                child: const Text('Sign Out')
            );
          })
        ],
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
    ): new SigninPage();
  }

  Future<void> _signOut() async {
    setState(() {
      isLoggedIn = false;
    });
    await _auth.signOut();
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