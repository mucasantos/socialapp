import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:socialoo/global/global.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:socialoo/layouts/navigationbar/navigation_bar.dart';

import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

// ignore: must_be_immutable
class UploadVideoScreen extends StatefulWidget {
  final String caption;
  File video;
  final String userimage;
  final String userName;

  UploadVideoScreen({
    this.caption,
    this.video,
    this.userimage,
    this.userName,
  });

  @override
  _UploadVideoScreenState createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  var _locationController;
  var _captionController;
  VideoPlayerController _videoPlayerController;

  final dio = new Dio();

  @override
  void initState() {
    _pickVideo();
    super.initState();
    _locationController = TextEditingController();
    _captionController = TextEditingController();
  }

  _pickVideo() async {
    _videoPlayerController = VideoPlayerController.file(widget.video)
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController.play();
      });
  }

  @override
  void dispose() {
    super.dispose();
    _locationController?.dispose();
    _captionController?.dispose();
  }

  bool _visibility = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Theme.of(context).primaryColorDark,
                  Theme.of(context).primaryColor
                ]),
          ),
        ),
        title: Text(
          'Create Video Post',
          style: Theme.of(context).textTheme.headline5.copyWith(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        elevation: 1.0,
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.all(10),
            width: MediaQuery.of(context).size.width * 0.25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.red.shade500, Colors.red.shade900])),
            child: const Text(
              'Share',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ).onTap(() {
            uploadData();
          })
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: widget.userimage == null || widget.userimage.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF003a54),
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Image.asset(
                          'assets/images/defaultavatar.png',
                          width: 50,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: widget.userimage,
                        height: 50.0,
                        width: 50.0,
                        fit: BoxFit.cover,
                      ),
              ),
              title: Text(
                widget.userName.capitalize(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              child: widget.video != null
                  ? _videoPlayerController.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _videoPlayerController.value.aspectRatio,
                          child: VideoPlayer(_videoPlayerController),
                        )
                      : Container(child: Text("Null"))
                  : GestureDetector(
                      onTap: () {
                        _pickVideo();
                      },
                      child: CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              AssetImage('assets/images/ic_add.png'),
                          backgroundColor: Colors.transparent),
                    ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                    child: TextField(
                      controller: _captionController,
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: (widget.caption != null)
                            ? '${widget.caption}'
                            : 'Write a caption...',
                      ),
                    ),
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Add location',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: Offstage(
                child: CircularProgressIndicator(),
                offstage: _visibility,
              ),
            )
          ],
        ),
      ),
    );
  }

  uploadData() {
    VideoThumbnail.thumbnailFile(
      video: widget.video.absolute.path,
      imageFormat: ImageFormat.JPEG,
      quality: 100,
    ).then((value) => apiCall(value));
  }

  apiCall(String value) async {
    print(value);
    setState(() {
      _videoPlayerController.setVolume(0);
      _videoPlayerController.pause();
    });
    LoaderDialog().showIndicator(context);
    var url = '${baseUrl()}/add_post';

    print(url);
    String name = DateTime.now().millisecondsSinceEpoch.toString();

    FormData formData = new FormData();

    formData = FormData.fromMap({
      'user_id': userID,
      'text': (widget.caption != null)
          ? '${widget.caption}'
          : _captionController.text,
      'location': _locationController.text,
      'video': MultipartFile.fromFileSync(widget.video.absolute.path,
          filename: name + ".mp4"),
      'video_thumbnail': MultipartFile.fromFileSync(
        value,
      ),
    });

    dio.options.contentType = Headers.jsonContentType;

    final response = await dio.post(url,
        data: formData,
        options: Options(method: 'POST', responseType: ResponseType.json));
    print(response.data.toString());

    LoaderDialog().hideIndicator(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => NavBar()),
      (Route<dynamic> route) => false,
    );
  }
}
