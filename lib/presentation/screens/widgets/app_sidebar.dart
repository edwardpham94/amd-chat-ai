import 'package:amd_chat_ai/service/auth_service.dart';
import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Menu',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Chat AI'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/chat-ai');
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Knowledge Base'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/knowledge');
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.add_circle_outline),
            //   title: const Text('Create Knowledge'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     Navigator.pushNamed(context, '/create-knowledge');
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: const Text('Prompt'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/prompt');
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.add_comment),
            //   title: const Text('Create Prompt'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     Navigator.pushNamed(context, '/create-prompt');
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text('Assistant'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/assistant');
              },
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email Assistant'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/email');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await AuthService().logout();
                if (!context.mounted) return;
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Rak-GPT v1.0', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
