import 'dart:convert';
import 'dart:html' as html;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({Key? key}) : super(key: key);

  @override
  _DownloadScreenState createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final TextEditingController _urlTextFieldController = TextEditingController();
  String videoTitle = '';
  String videoPublishDate = '';
  String videoID = '';
  bool _downloading = false;
  double progress = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _urlTextFieldController,
                onChanged: (val) {
                  getVideoInfo(val);
                },
                decoration: const InputDecoration(label: Text('Paste youtube video url here')),
              ),
            ),
            SizedBox(
              height: 250,
              child: Image.network(videoID != ''
                  ? 'https://img.youtube.com/vi/$videoID/0.jpg'
                  : 'https://play-lh.googleusercontent.com/vA4tG0v4aasE7oIvRIvTkOYTwom07DfqHdUPr6k7jmrDwy_qA_SonqZkw6KX0OXKAdk'),
            ),
            Text(videoTitle),
            Text(videoPublishDate),
            TextButton.icon(
                onPressed: () {
                  downloadVideo(_urlTextFieldController.text);
                },
                icon: const Icon(Icons.download),
                label: const Text('Start download')),
            _downloading
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.blueAccent,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  //functions
  Future<void> getVideoInfo(url) async {
    var youtubeInfo = YoutubeExplode();
    var video = await youtubeInfo.videos.get(url);
    setState(() {
      videoTitle = video.title;
      videoPublishDate = video.publishDate.toString();
      videoID = video.id.toString();
    });
  }

  Future<void> downloadVideo(id) async {
    if (!kIsWeb) {
      var permisson = await Permission.storage.request();
      if (permisson.isGranted) {
        if (_urlTextFieldController.text != '') {
          setState(() => _downloading = true);

          //download video
          setState(() => progress = 0);
          var _youtubeExplode = YoutubeExplode();
          //get video metadata
          var video = await _youtubeExplode.videos.get(id);
          var manifest = await _youtubeExplode.videos.streamsClient.getManifest(id);
          var streams = manifest.muxed.withHighestBitrate();
          var audio = streams;
          var audioStream = _youtubeExplode.videos.streamsClient.get(audio);

          //create a directory
          Directory appDocDir = await getApplicationDocumentsDirectory();
          String appDocPath = appDocDir.path;
          var file = File('$appDocPath/${video.id}.mp4');
          //delete file if exists
          if (file.existsSync()) {
            file.deleteSync();
          }
          var output = file.openWrite(mode: FileMode.writeOnlyAppend);
          var size = audio.size.totalBytes;
          var count = 0;

          await for (final data in audioStream) {
            count += data.length;

            double val = ((count / size));
            // var msg = '${video.title} Downloaded to $appDocPath/${video.id}.mp4';
            for (val; val == 1.0; val++) {
              GallerySaver.saveVideo(file.path).then((value) {
                (value!);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('saved video')));
              });
            }
            setState(() => progress = val);
            output.add(data);
          }
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('add youtube video url first!')));
          setState(() => _downloading = false);
        }
      } else {
        await Permission.storage.request();
      }
    } else {
      Directory directory = Directory('/storage/emulated/0/Download');
      print(directory.path);
      File file = File('${directory.path}/${"lolo"}.mp4');

//      var pngBytes = file.readAsBytesSync().buffer.asUint8List();

      // downloadImage(base64Encode(pngBytes));
      // GallerySaver.saveVideo(file.path);
      // GallerySaver.saveVideo(url).then((value) {
      //   (value!);
      //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('saved video')));
      // });
    }
  }
}

Future<File> get _localFile async {
  final path = await _localPath;
  return File('$path/counter.txt');
}

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

Future<void> writeToFile(ByteData data, String path) async {
  final buffer = data.buffer;
  File(path)
      .writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes))
      .then((value) => {
            GallerySaver.saveVideo(value.path).then((value) {
              (value!);
            })
          });
}

Future<void> downloadImage(String imageUrl) async {
  try {
    final a = html.AnchorElement(href: 'data:image/jpeg;base64,$imageUrl');
    a.download = 'download.jpg';
    a.click();
    a.remove();
  } catch (e) {
    print(e);
  }
}
