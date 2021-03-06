import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flute_music_player/flute_music_player.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Music',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Music'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //Variables

  List _songAll = [];
  Map tempData;
  Directory dir;
  File testFile;
  int _currentSongIndex;
  String songURL;
  Duration _currentPosition;
  AudioPlayer audioPlayer = new AudioPlayer();
  bool _isMusicAvailable = true;

  @override
  void initState() {
    // _getMusic();
    listSongs();
    super.initState();
  }

//  Playing Audio (Calling Function to audioPlayer)

  Future _playLocal(String songName) async {
    if (songName == null) {
      print("Method is calling on Null");
    } else {
      playMusic(songName);
      _music_Playing(context);
    }
  }

//Listing Songs
  void listSongs() async {
    _songAll = [];
    await FirebaseStorage.instance
        .ref()
        .child('song')
        .listAll()
        .then((result) => {
              tempData = result['items'],
            });
    tempData.forEach((itemMainName, valueInsideMain) {
      setState(() {
        _songAll.add(valueInsideMain['name']);
      });
      // print(valueInsideMain['name']);
    });
  }

//  Loading Song From Firebase

  static Future<dynamic> loadSongFromFirebase(
      BuildContext context, String songName) async {
    return await FirebaseStorage.instance
        .ref()
        .child('song')
        .child(songName)
        .getDownloadURL();
  }

//   Downloading the Song

  void downloadSong(BuildContext context) async {
    Dio dio = Dio();
    var dir = await getExternalStorageDirectory();
    await dio.download(
        songURL, "${dir.path}/${_songAll[_currentSongIndex]}.mp3");
  }

//  Function to play Music using Plugin audioPlayer

  Future<void> playMusic(String songName) async {
    //  Getting Download URL from the Firebase
    await loadSongFromFirebase(context, songName).then((value) => {
          print(value),
          songURL = value,
        });
    //
    await audioPlayer.release();
    await audioPlayer.play(songURL);
    audioPlayer.onAudioPositionChanged.listen((Duration p) {
      setState(() {
        _currentPosition = p;
        print(p);
      });
    });
  }

  //   Getting Music From Mobile Phone

  // void _getMusic() async {
  //   MusicFinder _musicFinder = new MusicFinder();
  //   var songs = await MusicFinder.allSongs();
  //   setState(() {
  //     _songAll = songs;
  //     _isMusicAvailable = true;
  //   });
  // }

  //   Retruns Bottom Sheet While Music is running able to pause, resume,stop music

  Widget _music_Playing(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            height: 180,
            child: Column(
              children: <Widget>[
                Container(
                    height: 100, child: Image.asset("images/audioPlaying.gif")),
                Text(
                  _songAll[_currentSongIndex],
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      fontStyle: FontStyle.italic),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    IconButton(
                      tooltip: 'Reverse Song',
                      icon: Icon(Icons.replay_10),
                      onPressed: () async {
                        //Subtract 10 sec extra to current postion of song and pass to seek method
                        Duration _seekPosition =
                            _currentPosition - Duration(milliseconds: 1000);
                        await audioPlayer.seek(_seekPosition);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.stop),
                      tooltip: 'Stop',
                      onPressed: () async {
                        await audioPlayer.stop();
                        Navigator.pop(context);
                      },
                    ),
                    IconButton(
                      tooltip: 'Pause',
                      icon: Icon(Icons.pause),
                      onPressed: () async {
                        await audioPlayer.pause();
                      },
                    ),
                    IconButton(
                      tooltip: 'Resume',
                      icon: Icon(Icons.play_arrow),
                      onPressed: () async {
                        await audioPlayer.resume();
                        setState(() {});
                      },
                    ),
                    IconButton(
                      tooltip: 'Forward Song',
                      icon: Icon(Icons.forward_10),
                      onPressed: () async {
                        //Add 10 sec extra to current postion of song and pass to seek method
                        Duration _seekPosition =
                            _currentPosition + Duration(milliseconds: 1000);
                        await audioPlayer.seek(_seekPosition);
                      },
                    ),
                    IconButton(
                      tooltip: 'Download Song',
                      icon: Icon(Icons.file_download),
                      onPressed: () {
                        downloadSong(context);
                      },
                    ),
                  ],
                )
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.redAccent,
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.refresh), onPressed: listSongs)
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: listSongs,
          child: Icon(Icons.account_balance),
        ),
        body: _isMusicAvailable
            ? ListView.builder(
                itemCount: _songAll.length,
                itemBuilder: (context, int index) {
                  return ListTile(
                    onTap: () => {
                      _currentSongIndex = index,
                      _playLocal(_songAll[index]),
                    },
                    leading: CircleAvatar(
                      backgroundColor: Colors.orangeAccent,
                      child: Image.asset('images/MusicIcon.png'),
                    ),
                    title: Text(_songAll[index]),
                  );
                })
            : Center(child: Image.asset('images/waitPlease.gif')));
  }
}
