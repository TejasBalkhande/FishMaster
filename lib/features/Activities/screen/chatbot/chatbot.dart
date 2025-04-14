import 'secrets.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  ChatbotPageState createState() => ChatbotPageState();
}

class ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  late GenerativeModel _model;
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestions = [
    "Best fishing spots in Rameswaram",
    "Ideal fishing seasons for Seer Fish (Vanjaram)",
    "Government-approved fishing methods in TN",
    "Latest weather alerts for Bay of Bengal",
    "Where to sell today's catch for best price?"
  ];

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: geminiapiKEY,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': _controller.text});
    });
    _scrollToBottom();

    final userMessage = _controller.text;
    _controller.clear();

    try {
      final response = await _model.generateContent([Content.text(userMessage)]);
      final aiResponse = response.text ?? "I couldn't understand. Try again!";

      setState(() {
        _messages.add({'sender': 'ai', 'text': aiResponse});
      });
      _scrollToBottom();
    } catch (e) {
      print("API Error: $e");
      setState(() {
        _messages.add({'sender': 'ai', 'text': 'Error: $e'});
      });
      _scrollToBottom();
    }
  }

  void _handleSuggestionTap(String suggestion) {
    _controller.text = suggestion;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/logos/applogo.png',
          height: 60,
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                bool isUser = message['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Color.fromRGBO(16, 81, 171, 1.0) : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomLeft: isUser ? Radius.circular(15) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : Radius.circular(15),
                      ),
                    ),
                    child: Text(
                      message['text']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            margin: EdgeInsets.only(bottom: 4),
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _handleSuggestionTap(_suggestions[index]),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(51, 108, 138, 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color.fromRGBO(16, 81, 171, 1.0),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _suggestions[index],
                          style: TextStyle(
                            color: Color.fromRGBO(16, 81, 171, 1.0),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask me about fishing...',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (text) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: CircleAvatar(
                    backgroundColor: Color.fromRGBO(16, 81, 171, 1.0),
                    radius: 24,
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}