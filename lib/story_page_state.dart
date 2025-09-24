import 'dart:convert'; // for jsonEncode, jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';

/// SCREEN 2: Story Generator with Cartoon Background
class StoryPage extends StatefulWidget {
  final String storyTitle;
  const StoryPage({super.key, required this.storyTitle});

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  final FlutterTts _tts = FlutterTts();
  String _story = '';
  bool _loading = false;

  static const String API_ENDPOINT =
      'https://api-inference.huggingface.co/models/gpt2';
  static const String API_KEY = ''; // optional

  Future<String> _generateStory(String prompt) async {
    final uri = Uri.parse(API_ENDPOINT);
    final body = jsonEncode({
      'inputs': prompt,
      'parameters': {'max_new_tokens': 300, 'temperature': 0.8},
    });

    final headers = {
      'Content-Type': 'application/json',
      if (API_KEY.isNotEmpty) 'Authorization': 'Bearer $API_KEY',
    };

    final resp = await http.post(uri, headers: headers, body: body);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body);

      if (data is List &&
          data.isNotEmpty &&
          data[0]['generated_text'] != null) {
        return data[0]['generated_text'] as String;
      }

      if (data is Map && data['generated_text'] != null) {
        return data['generated_text'] as String;
      }

      return resp.body;
    } else {
      throw Exception('API error ${resp.statusCode}: ${resp.body}');
    }
  }

  Future<void> _fetchStory() async {
    final prompt =
        'Write a gentle, imaginative bedtime story in English titled "${widget.storyTitle}". '
        'Keep it short (3–5 paragraphs), easy for kids, and end with a clear moral.';

    setState(() {
      _loading = true;
      _story = '';
    });

    try {
      final generated = await _generateStory(prompt);
      String clean = generated;

      if (clean.startsWith(widget.storyTitle)) {
        clean = clean.replaceFirst(widget.storyTitle, '').trim();
      }

      final paras = clean
          .split(RegExp(r'\n+'))
          .where((p) => p.trim().isNotEmpty)
          .toList();
      final display = paras.take(6).join('\n\n');

      setState(() {
        _story = display + '\n\nMoral: Always be kind and brave.';
      });

      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.speak(_story);
    } catch (e) {
      setState(() {
        _story = 'Error generating story: ${e.toString()}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchStory();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storyTitle),
        backgroundColor: Colors.purple[200],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              "https://i.ibb.co/ZhM9mZq/bedtime-cartoon-bg.jpg", // Cartoon background
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.3), // Dark overlay
          child: SafeArea(
            child: _loading
                ? Center(
                    child: Lottie.network(
                      'https://assets1.lottiefiles.com/packages/lf20_myejiggj.json',
                      width: 200,
                      height: 200,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.storyTitle,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _story,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 10,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                await _tts.stop();
                                await _tts.speak(_story);
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Play'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await _tts.stop();
                              },
                              icon: const Icon(Icons.stop),
                              label: const Text('Stop'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.black,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Share.share(
                                  '${widget.storyTitle}\n\n$_story',
                                );
                              },
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[50],
                                foregroundColor: Colors.purple[800],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
