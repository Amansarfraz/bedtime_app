// Flutter single-file app: Bedtime Story Generator (AI-powered)
// Save as `main.dart` inside a Flutter project (e.g. created with `flutter create bedtime_app`).
// Add to pubspec.yaml under dependencies:
//   http: ^0.13.6
//   lottie: ^2.3.0
//   flutter_tts: ^3.6.0
//   share_plus: ^6.3.0
//   animated_text_kit: ^4.2.2
// Then run: flutter pub get && flutter run

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

void main() => runApp(BedtimeApp());

class BedtimeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raat Ki Kahani — AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: StoryHomePage(),
    );
  }
}

class StoryHomePage extends StatefulWidget {
  @override
  _StoryHomePageState createState() => _StoryHomePageState();
}

class _StoryHomePageState extends State<StoryHomePage> {
  final TextEditingController _titleController = TextEditingController(
    text: 'Chota Sher aur Sitara',
  );
  final TextEditingController _notesController = TextEditingController();
  String _ageRange = '6-8';
  String _story = '';
  bool _loading = false;
  final FlutterTts _tts = FlutterTts();

  // --- CONFIG: Replace these with your real API endpoint and key ---
  // Example: Hugging Face Inference endpoint, or your own server endpoint.
  // If using Hugging Face Inference API, set API_ENDPOINT to: https://api-inference.huggingface.co/models/<your-model>
  // and set API_KEY to your Hugging Face token. If you use a custom server, adapt body/headers accordingly.
  static const String API_ENDPOINT =
      'https://api-inference.huggingface.co/models/gpt2';
  static const String API_KEY =
      ''; // e.g. 'Bearer xxxxx' or just token depending on service
  // ------------------------------------------------------------------

  // Simple method to call AI API and get generated story text
  Future<String> _generateStory(String prompt) async {
    // Example request format for Hugging Face Inference API JSON input
    final uri = Uri.parse(API_ENDPOINT);
    final body = jsonEncode({
      'inputs': prompt,
      'parameters': {'max_new_tokens': 300, 'temperature': 0.8},
    });

    final headers = {
      'Content-Type': 'application/json',
      if (API_KEY.isNotEmpty) 'Authorization': 'Bearer $API_KEY',
    };

    final resp = await http
        .post(uri, headers: headers, body: body)
        .timeout(Duration(seconds: 30));

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body);
      // Hugging Face sometimes returns a list with generated_text
      if (data is List &&
          data.isNotEmpty &&
          data[0]['generated_text'] != null) {
        return data[0]['generated_text'] as String;
      }
      if (data is Map && data['generated_text'] != null)
        return data['generated_text'] as String;
      // Fallback: return raw body
      return resp.body;
    } else {
      throw Exception('API error ${resp.statusCode}: ${resp.body}');
    }
  }

  Future<void> _onGeneratePressed() async {
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();
    final age = _ageRange;

    final prompt =
        'Write a gentle, imaginative bedtime story in Urdu titled "$title". Target age: $age. Keep it warm, short (3-6 short paragraphs), with simple language and a clear moral at the end. Additional notes: $notes';

    setState(() {
      _loading = true;
      _story = '';
    });

    try {
      final generated = await _generateStory(prompt);

      // Basic cleanup: remove repeated title if model echoes it
      String clean = generated;
      // If generated contains the title at start, remove duplicate occurrence
      if (clean.startsWith(title)) {
        clean = clean.replaceFirst(title, '').trim();
      }

      // Split into paragraphs and keep a few
      final paras = clean
          .split(RegExp(r'\n+'))
          .where((p) => p.trim().isNotEmpty)
          .toList();
      final display = paras.take(6).join('\n\n');

      setState(() {
        _story = display + '\n\nMoral: Pyar aur himmat se kaam lo.';
      });

      // Auto-speak short stories for kids (optional)
      await _tts.setLanguage('ur-PK');
      await _tts.setSpeechRate(0.45);
      await _tts.speak(_story);
    } catch (e) {
      setState(() {
        _story = 'Kahani generate karte waqt error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _tts.stop();
    super.dispose();
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Lottie.network(
          'https://assets5.lottiefiles.com/packages/lf20_jtbfg2nb.json',
          width: 110,
          height: 110,
          fit: BoxFit.cover,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Raat Ki Kahani',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 6),
              Text(
                'AI se banai gayi pyari kahaniyan — bachon ke liye',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Story ka naam',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _ageRange,
                decoration: InputDecoration(
                  labelText: 'Age range',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: ['3-5', '6-8', '9-12']
                    .map(
                      (a) => DropdownMenuItem(value: a, child: Text('Age $a')),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _ageRange = v ?? _ageRange),
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _loading ? null : _onGeneratePressed,
              icon: _loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.auto_awesome),
              label: Text(_loading ? 'Generating...' : 'Kahani Banao'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: 'Koi khas note (optional)',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          minLines: 1,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildStoryCard() {
    if (_story.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            DefaultTextStyle(
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              child: AnimatedTextKit(
                pause: Duration(milliseconds: 800),
                animatedTexts: [
                  TyperAnimatedText(
                    'Yahan aapki kahani nazar aayegi — "Kahani Banao" par click karen.',
                    speed: Duration(milliseconds: 40),
                  ),
                ],
                isRepeatingAnimation: true,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _titleController.text,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10),
          Text(
            _story,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.justify,
          ),
          SizedBox(height: 18),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await _tts.stop();
                  await _tts.speak(_story);
                },
                icon: Icon(Icons.play_arrow),
                label: Text('Play'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await _tts.stop();
                },
                icon: Icon(Icons.stop),
                label: Text('Stop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await Share.share('${_titleController.text}\n\n$_story');
                },
                icon: Icon(Icons.share),
                label: Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[50],
                  foregroundColor: Colors.pink[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left panel: form
                    Flexible(
                      flex: 4,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: _buildForm(),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    // Right panel: story output
                    Flexible(
                      flex: 6,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          child: _buildStoryCard(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Tip: API_ENDPOINT aur API_KEY ko code mein set karen. Hugging Face ya apna server use kar sakte hain.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
