import 'package:amd_chat_ai/presentation/screens/authentication/login_screen_v1.dart';
import 'package:amd_chat_ai/presentation/screens/authentication/signup_screen_v1.dart';
import 'package:amd_chat_ai/presentation/screens/authentication/unauthorize_screen.dart';
import 'package:amd_chat_ai/presentation/screens/knowledge/create_knowledge_screen.dart';
import 'package:amd_chat_ai/presentation/screens/knowledge/knowledge_screen.dart';
import 'package:amd_chat_ai/presentation/screens/prompt/create_prompt_screen.dart';
import 'package:amd_chat_ai/presentation/screens/prompt/prompt_screen.dart';
import 'package:amd_chat_ai/presentation/screens/prompt/update_prompt_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const UnauthorizeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/knowledge': (context) => const KnowledgeScreen(),
        '/create-knowledge': (context) => const CreateKnowledgeScreen(),
        '/prompt': (context) => const PromptScreen(),
        '/create-prompt': (context) => const CreatePromptScreen(),
        '/update-prompt': (context) => const UpdatePromptScreen(),
      },
    );
  }
}
