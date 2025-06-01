import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class AIChatBotScreen extends StatefulWidget {
  const AIChatBotScreen({super.key});

  @override
  State<AIChatBotScreen> createState() => _AIChatBotScreenState();
}

class _AIChatBotScreenState extends State<AIChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Legal knowledge base with scraping endpoints
  final Map<String, Map<String, String>> _legalTopics = {
    'contract': {
      'url': 'https://www.lawnet.lk/contract-law-in-sri-lanka/',
      'selector': 'div.article-content',
    },
    'property': {
      'url': 'https://www.srilankalaw.lk/property-law/',
      'selector': 'div.post-content',
    },
    'criminal': {
      'url': 'https://www.attorneygeneral.gov.lk/criminal-law/',
      'selector': 'div.content-section',
    },
    'marriage': {
      'url': 'https://www.attorneygeneral.gov.lk/marriage-laws/',
      'selector': 'div.main-content',
    },
    'employment': {
      'url': 'https://www.labourdept.gov.lk/employment-laws/',
      'selector': 'div.content-area',
    },
  };

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text: "Hello! I'm your Sri Lankan legal assistant. Ask me about contracts, property, criminal, marriage, or employment laws.",
      isUser: false,
    ));
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    try {
      final response = await _getLegalAnswer(text);
      setState(() {
        _messages.insert(0, ChatMessage(text: response, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.insert(0, ChatMessage(
          text: "I couldn't find information on that topic. Please ask about Sri Lankan contract, property, criminal, marriage, or employment laws.",
          isUser: false,
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _messageController.clear();
    }
  }

  Future<String> _getLegalAnswer(String query) async {
    final lowerQuery = query.toLowerCase();
    
    // Find matching legal topic
    for (final topic in _legalTopics.entries) {
      if (lowerQuery.contains(topic.key)) {
        final content = await _scrapeLegalContent(topic.value['url']!, topic.value['selector']!);
        return _formatLegalAnswer(topic.key, content);
      }
    }
    
    return "I specialize in Sri Lankan legal matters. Please ask about:\n\n• Contracts\n• Property Law\n• Criminal Law\n• Marriage Laws\n• Employment Laws";
  }

  Future<String> _scrapeLegalContent(String url, String selector) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final element = document.querySelector(selector);
        return element?.text
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim() 
            ?? "Information is available but couldn't be extracted.";
      }
      throw Exception('Failed to load page');
    } catch (e) {
      throw Exception('Error accessing legal resources');
    }
  }

  String _formatLegalAnswer(String topic, String content) {
    // Extract the most relevant part (first 2-3 sentences)
    final sentences = content.split('. ');
    final summary = sentences.take(3).join('. ') + (sentences.length > 3 ? '...' : '');
    
    return "Under Sri Lankan $topic law:\n\n$summary";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF353E55),
      appBar: AppBar(
        title: const Text(
          'Legal Assistant',
          style: TextStyle(
            color: Color(0xFFD0A554),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF353E55),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD0A554)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _messages[index],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Color(0xFFD0A554)),
            ),
          Container(
            color: const Color(0xFFD9D9D9),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ask about Sri Lankan law...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(color: Color(0xFF353E55)),
                    onSubmitted: _handleSubmitted,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFD0A554)),
                  onPressed: () => _handleSubmitted(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isUser ? const Color(0xFFD0A554) : const Color(0xFFD9D9D9),
            child: Icon(
              isUser ? Icons.person : Icons.psychology,
              size: 18,
              color: const Color(0xFF353E55),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? 'You' : 'Legal Assistant',
                  style: TextStyle(
                    color: isUser ? const Color(0xFFD0A554) : const Color(0xFFD9D9D9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(color: Color(0xFFD9D9D9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
