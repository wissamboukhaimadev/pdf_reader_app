import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PdfViewerController _pdfViewerController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  FlutterTts flutterTts = FlutterTts();
  String language = 'en-US';
  var hello;
  bool searchState = false;
  String searchValue = "";
  Uint8List? _pdfBytes;
  bool scrollDirectionBool = false;
  int pageNumber = 0;
  UndoHistoryController _undoHistoryController = UndoHistoryController();
  bool isPlaying = false;

  @override
  void initState() {
    _pdfViewerController = PdfViewerController();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('PDF Viewer App'),
          backgroundColor: Colors.black12,
          actions: <Widget>[
            PopupMenuButton(itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  child: IconButton(
                      onPressed: () {
                        _undoHistoryController.value.canUndo
                            ? _undoHistoryController.undo()
                            : null;
                      },
                      icon: Row(
                        children: [
                          const Icon(Icons.undo),
                          Container(
                            padding: const EdgeInsets.only(left: 5.0),
                            child: const Text("undo"),
                          )
                        ],
                      )),
                ),
                PopupMenuItem(
                  child: IconButton(
                      onPressed: () {
                        setState(() {
                          scrollDirectionBool = !scrollDirectionBool;
                        });
                      },
                      icon: Row(
                        children: [
                          scrollDirectionBool
                              ? const Icon(Icons.horizontal_distribute)
                              : const Icon(Icons.grid_3x3),
                          Container(
                            padding: const EdgeInsets.only(left: 5.0),
                            child: const Text("change layout"),
                          )
                        ],
                      )),
                ),
                PopupMenuItem(
                  child: IconButton(
                      onPressed: _openFile,
                      icon: Row(
                        children: [
                          const Icon(Icons.folder_open),
                          Container(
                            padding: const EdgeInsets.only(left: 5.0),
                            child: const Text("open file"),
                          )
                        ],
                      )),
                ),
                PopupMenuItem(
                  child: IconButton(
                    icon: Row(
                      children: [
                        const Icon(Icons.play_arrow),
                        Container(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: const Text("speak"),
                        )
                      ],
                    ),
                    tooltip: "select text to be read",
                    onPressed: _speak,
                  ),
                ),
                PopupMenuItem(
                  child: IconButton(
                    icon: Row(
                      children: [
                        const Icon(Icons.pause),
                        Container(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: const Text("pause"),
                        )
                      ],
                    ),
                    tooltip: "pause reading",
                    onPressed: _pause,
                  ),
                ),
              ];
            })
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showCupertinoDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Go to page"),
                    content: _pdfBytes != null
                        ? TextField(
                            decoration: const InputDecoration(
                                hintText: "enter page number"),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                pageNumber = int.parse(value);
                              });
                            },
                          )
                        : const Text("open a pdf file first"),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: _pdfBytes != null
                              ? const Text("cancel")
                              : const Text("close")),
                      _pdfBytes != null
                          ? ElevatedButton(
                              onPressed: () {
                                _pdfViewerController.jumpToPage(pageNumber);
                                Navigator.of(context).pop();
                              },
                              child: const Text("navigate"))
                          : const Text("")
                    ],
                  );
                });
          },
          child: const Icon(Icons.navigate_next),
        ),
        body: _pdfBytes != null
            ? SfPdfViewer.memory(
                _pdfBytes!,
                key: _pdfViewerKey,
                undoController: _undoHistoryController,
                controller: _pdfViewerController,
                scrollDirection: scrollDirectionBool
                    ? PdfScrollDirection.horizontal
                    : PdfScrollDirection.vertical,
                enableTextSelection: true,
                canShowTextSelectionMenu: true,
                onTextSelectionChanged:
                    (PdfTextSelectionChangedDetails details) {
                  if (details.selectedText != null) {
                    hello = details.selectedText;
                  }
                },
              )
            : Center(
                child: ElevatedButton(
                    onPressed: _openFile,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: const Text("Chose a pdf file"),
                    ))));
  }

  Future _speak() async {
    if (isPlaying) {
      await flutterTts.pause();
    } else {
      if (hello != null) {
        await flutterTts.speak(hello);
      }
    }
  }

  Future _pause() async {
    setState(() {
      isPlaying = false;
    });
    await flutterTts.pause();
  }

  Future<void> _openFile() async {
    FilePickerResult? filePickerResult = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

    if (filePickerResult != null) {
      _pdfBytes = await File(filePickerResult.files.single.path!).readAsBytes();
    }
    setState(() {});
  }
}
