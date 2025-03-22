import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int index = 0;
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> chatHistory = [];

  final GlobalKey<ContactPageState> _chatKey = GlobalKey<ContactPageState>();

  void _startNewChat() {
    setState(() {
      index = 0; // Go to Home (Chat) page
    });
    _pageController.jumpToPage(0);
    _chatKey.currentState?.clearChat();
  }

  String capitalizeEachWord(String sentence) {
    return sentence
        .split(' ')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startNewChat,
            tooltip: 'Generate New Chat',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            DrawerHeader(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(
                      'https://cdn-icons-png.flaticon.com/512/11865/11865326.png',
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'CHAT GPT',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const Text(
                    'TALK TO US ',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              decoration: const BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              title: const Text('Home'),
              onTap: () => _pageController.jumpToPage(0),
            ),
            ListTile(
              title: const Text('History'),
              onTap: () => _pageController.jumpToPage(1),
            ),
            ListTile(
              title: const Text('Introduction'),
              onTap: () => _pageController.jumpToPage(2),
            ),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        children: [
          ContactPage(
            key: _chatKey,
            onChatFinished: (history) {
              setState(() {
                history['question'] = capitalizeEachWord(history['question']);
                chatHistory.add(history);
              });
            },
          ),
          ChatHistoryPage(
            chatHistory: chatHistory,
            onDelete: (index) {
              setState(() {
                chatHistory.removeAt(index);
              });
            },
            onFavoriteToggle: (index) {
              setState(() {
                chatHistory[index]['isFavorite'] =
                    !chatHistory[index]['isFavorite'];
              });
            },
          ),
          IntroductionPage(), // Added IntroductionPage
        ],
      ),
    );
  }
}

// Introduction Page
class IntroductionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Welcome to the Chat App!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 10),
              Text(
                "Enjoy using the app!",
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 70),
              Text("If you have any problem", style: TextStyle(fontSize: 15)),
              Text(
                "Please Contact: huy.work132@gmail.com",
                style: TextStyle(fontSize: 5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onChatFinished;

  ContactPage({required Key key, required this.onChatFinished})
    : super(key: key);

  @override
  ContactPageState createState() => ContactPageState();
}

class ContactPageState extends State<ContactPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> chatMessages = [];
  bool isLoading = false;
  final String apiKey =
      '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'; // Replace with your OpenAI API key

  Future<String> getChatGPTResponse(String input) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': input},
        ],
        'max_tokens': 150,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content']?.toString()?.trim() ??
          "No response";
    } else {
      throw Exception(
        'Failed to load response from ChatGPT: ${response.statusCode}',
      );
    }
  }

  void sendMessage() async {
    final input = _controller.text;
    if (input.isNotEmpty) {
      setState(() {
        chatMessages.add({"text": input, "isUser": true});
        isLoading = true;
      });
      _controller.clear();

      try {
        final response = await getChatGPTResponse(input);
        setState(() {
          chatMessages.add({"text": response, "isUser": false});
          isLoading = false;
        });
        saveChatHistory();
      } catch (error) {
        setState(() {
          chatMessages.add({
            "text": "Error: Could not receive response",
            "isUser": false,
          });
          isLoading = false;
        });
      }
    }
  }

  void clearChat() {
    setState(() {
      chatMessages.clear();
    });
  }

  void saveChatHistory() {
    widget.onChatFinished({
      "question": chatMessages.firstWhere((msg) => msg['isUser'])['text'],
      "messages": List.from(chatMessages),
      "isFavorite": false, // Default to not favorite
    });
  }

  @override
  void dispose() {
    if (chatMessages.isNotEmpty) {
      saveChatHistory();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child:
                chatMessages.isEmpty
                    ? Center(
                      child: Text(
                        "What can I help you with?",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    )
                    : ListView.builder(
                      itemCount: chatMessages.length,
                      itemBuilder: (context, index) {
                        bool isUser = chatMessages[index]['isUser'];
                        return Row(
                          mainAxisAlignment:
                              isUser
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                          children: [
                            if (!isUser)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Image.asset(
                                  'assets/chatgpt.jpg', // Use the correct asset path for the logo
                                  height: 30,
                                  width: 30,
                                ),
                              ),
                            Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.6,
                              ),
                              decoration: BoxDecoration(
                                color: isUser ? Colors.blue : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.all(12),
                              margin: EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              child: Text(
                                chatMessages[index]['text'],
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black87,
                                ),
                                softWrap: true,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                    ),
                    onSubmitted: (value) => sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatHistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> chatHistory;
  final Function(int) onDelete;
  final Function(int) onFavoriteToggle;

  ChatHistoryPage({
    required this.chatHistory,
    required this.onDelete,
    required this.onFavoriteToggle,
  });

  void _showChat(BuildContext context, Map<String, dynamic> chat) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Chat History"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  chat['messages'].map<Widget>((message) {
                    return Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "${message['isUser'] ? 'You' : 'Bot'}: ${message['text']}",
                        style: TextStyle(
                          color: message['isUser'] ? Colors.blue : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: chatHistory.length,
        itemBuilder: (context, index) {
          final chat = chatHistory[index];
          return ListTile(
            title: Text(chat['question']),
            subtitle: Text(
              chat['isFavorite'] ? " Favorited" : " Not Favorited",
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    chat['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                  ),
                  onPressed: () => onFavoriteToggle(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(index),
                ),
              ],
            ),
            onTap: () => _showChat(context, chat),
          );
        },
      ),
    );
  }
}
