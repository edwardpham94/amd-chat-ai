import 'package:amd_chat_ai/presentation/screens/chat-ai/email_chat.dart';
import 'package:amd_chat_ai/presentation/screens/knowledge/datasource_screen.dart';
import 'package:amd_chat_ai/presentation/screens/knowledge/update_knowledge_screen.dart';
import 'package:amd_chat_ai/presentation/screens/splash_screen.dart';
import 'package:amd_chat_ai/presentation/screens/authentication/enter_otp_screen.dart';
import 'package:amd_chat_ai/presentation/screens/authentication/forget_password_screen.dart';
import 'package:amd_chat_ai/presentation/screens/authentication/login_screen_v1.dart';
import 'package:amd_chat_ai/presentation/screens/authentication/reset_password_screen.dart';
import 'package:amd_chat_ai/presentation/screens/authentication/signup_screen_v1.dart';
import 'package:amd_chat_ai/presentation/screens/chat-ai/chat_ai_screen.dart';
import 'package:amd_chat_ai/presentation/screens/knowledge/create_knowledge_screen.dart';
import 'package:amd_chat_ai/presentation/screens/knowledge/knowledge_screen.dart';
import 'package:amd_chat_ai/presentation/screens/profile/profile.dart';
import 'package:amd_chat_ai/presentation/screens/prompt/create_prompt_screen.dart';
import 'package:amd_chat_ai/presentation/screens/prompt/prompt_screen.dart';
import 'package:amd_chat_ai/presentation/screens/prompt/update_prompt_screen.dart';
import 'package:amd_chat_ai/presentation/screens/assistant/assistant_screen.dart';
import 'package:amd_chat_ai/presentation/screens/assistant/create_assistant_screen.dart';
import 'package:amd_chat_ai/presentation/screens/assistant/update_assistant_screen.dart';
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
      initialRoute: '/login',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/knowledge': (context) => const KnowledgeScreen(),
        '/create-knowledge': (context) => const CreateKnowledgeScreen(),
        '/update-knowledge': (context) => const UpdateKnowledgeScreen(),
        '/datasource': (context) => const DatasourceScreen(),
        '/prompt': (context) => const PromptScreen(),
        '/create-prompt': (context) => const CreatePromptScreen(),
        '/update-prompt': (context) => const UpdatePromptScreen(),
        '/assistant': (context) => const AssistantScreen(),
        '/create-assistant': (context) => const CreateAssistantScreen(),
        '/update-assistant': (context) => const UpdateAssistantScreen(),
        '/chat-ai': (context) => const ChatAIScreen(),
        '/email': (context) => const EmailChatScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/forget-password': (context) => const ForgetPasswordScreen(),
        '/enter-otp': (context) => const EnterOTPScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
      },
    );
  }
}
