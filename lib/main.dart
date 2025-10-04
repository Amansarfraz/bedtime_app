import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const PollinationsFeedApp());

class PollinationsFeedApp extends StatelessWidget {
  const PollinationsFeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ImageFeedScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ImageFeedScreen extends StatefulWidget {
  const ImageFeedScreen({super.key});

  @override
  State<ImageFeedScreen> createState() => _ImageFeedScreenState();
}

class _ImageFeedScreenState extends State<ImageFeedScreen> {
  List<dynamic> images = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchFeed();
  }

  Future<void> fetchFeed() async {
    final response = await http.get(Uri.parse('https://image.pollinations.ai/feed'));
    if (response.statusCode == 200) {
      setState(() {
        images = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pollinations Feed"), backgroundColor: Colors.blueAccent),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final img = images[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    img['url'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const Icon(Icons.error),
                  ),
                );
              },
            ),
    );
  }
}
