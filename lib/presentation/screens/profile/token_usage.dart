import 'package:amd_chat_ai/model/subscription.dart';
import 'package:amd_chat_ai/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/base_screen.dart';

class TokenUsageScreen extends StatefulWidget {
  const TokenUsageScreen({super.key});

  @override
  State<TokenUsageScreen> createState() => _TokenUsageScreenState();
}

class _TokenUsageScreenState extends State<TokenUsageScreen> {
  final UserService _userService = UserService();
  Subscription? _subscription;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionInfo();
  }

  Future<void> _fetchSubscriptionInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final subscription = await _userService.getSubscriptionInfo();

      if (subscription == null) {
        setState(() {
          _errorMessage =
              'Failed to load subscription information. Please try again.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _subscription = subscription;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load subscription information: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Token Usage',
      showBackButton: true,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchSubscriptionInfo,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchSubscriptionInfo,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubscriptionCard(),
                        const SizedBox(height: 24),
                        _buildTokensCard(
                          'Daily Tokens',
                          _subscription?.dailyTokens ?? 0,
                        ),
                        const SizedBox(height: 16),
                        _buildTokensCard(
                          'Monthly Tokens',
                          _subscription?.monthlyTokens ?? 0,
                        ),
                        const SizedBox(height: 16),
                        _buildTokensCard(
                          'Annually Tokens',
                          _subscription?.annuallyTokens ?? 0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.card_membership, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      'Plan: ${_formatPlanName(_subscription?.name ?? 'Unknown')}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    final Uri url = Uri.parse('https://dev.jarvis.cx/pricing');
                    if (!await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    )) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not launch URL')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Subscribe',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokensCard(String title, int tokens) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.token, color: Colors.amber),
                const SizedBox(width: 12),
                Text(
                  tokens.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPlanName(String name) {
    if (name.isEmpty) return 'Unknown';
    return name.substring(0, 1).toUpperCase() + name.substring(1);
  }
}
