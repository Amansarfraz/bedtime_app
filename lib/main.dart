import 'package:flutter/material.dart';

void main() => runApp(const PollinationsImageApp());

class PollinationsImageApp extends StatelessWidget {
  const PollinationsImageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ImageSearchScreen(),
    );
  }
}

class ImageSearchScreen extends StatefulWidget {
  const ImageSearchScreen({super.key});

  @override
  State<ImageSearchScreen> createState() => _ImageSearchScreenState();
}

class _ImageSearchScreenState extends State<ImageSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String? imageUrl;
  bool isLoading = false;

  void _searchImage() {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      isLoading = true;
      imageUrl = null;
    });

    final url =
        'https://image.pollinations.ai/prompt/${Uri.encodeComponent(prompt)}';
    // Since Pollinations returns direct image, no need to fetch JSON
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        imageUrl = url;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Image Generator'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter something like "cute panda on skateboard"',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchImage,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const CircularProgressIndicator()
            else if (imageUrl != null)
              Expanded(
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) =>
                      const Text('Error loading image'),
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text(
                    'Type something and tap search to generate an image!',
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
