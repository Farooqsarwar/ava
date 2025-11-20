import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _chatSessions = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchChatHistory();
  }

  Future<void> _fetchChatHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final response = await _supabase
          .from('chat_sessions')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _chatSessions = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching chat history: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today, ${_formatTime(date)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday, ${_formatTime(date)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cosmetics':
        return Icons.auto_awesome_rounded;
      case 'medical':
        return Icons.health_and_safety_rounded;
      case 'financial':
        return Icons.account_balance_wallet_rounded;
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'tech support':
        return Icons.computer_rounded;
      case 'legal':
        return Icons.gavel_rounded;
      default:
        return Icons.chat_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'cosmetics':
        return const Color(0xFFFCE7F3);
      case 'medical':
        return const Color(0xFFD1FAE5);
      case 'financial':
        return const Color(0xFFFEF3C7);
      case 'travel':
        return const Color(0xFFEDE9FE);
      case 'tech support':
        return const Color(0xFFDBEAFE);
      case 'legal':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _getCategoryIconColor(String category) {
    switch (category.toLowerCase()) {
      case 'cosmetics':
        return const Color(0xFFEC4899);
      case 'medical':
        return const Color(0xFF10B981);
      case 'financial':
        return const Color(0xFFF59E0B);
      case 'travel':
        return const Color(0xFF8B5CF6);
      case 'tech support':
        return const Color(0xFF3B82F6);
      case 'legal':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _truncateMessage(String message, {int maxLength = 50}) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength)}...';
  }

  void _navigateToConversationDetail(String sessionId, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationDetailScreen(
          sessionId: sessionId,
          category: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4BA1AE),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4BA1AE), Color(0xFF73B5C1)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4BA1AE).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Chat History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (!_isLoading && _chatSessions.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      onPressed: _fetchChatHistory,
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4BA1AE),
                      Color(0xFF73B5C1),
                      Color(0xFF82BDC8),
                      Color(0xFF92C6CF),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : _hasError
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load history',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your connection and try again',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchChatHistory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4BA1AE),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                    : _chatSessions.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_toggle_off_rounded,
                        size: 64,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No chat history',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your conversations will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: _fetchChatHistory,
                  color: Colors.white,
                  backgroundColor: const Color(0xFF4BA1AE),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _chatSessions.length,
                    itemBuilder: (context, index) {
                      final session = _chatSessions[index];
                      final sessionId = session['session_id']?.toString() ?? '';
                      final category = session['category']?.toString() ?? 'Unknown';
                      final message = session['message']?.toString() ?? '';
                      final createdAt = session['created_at']?.toString() ?? '';
                      final hasPdf = session['has_pdf'] == true;
                      final pdfName = session['pdf_name']?.toString();
                      final sender = session['sender']?.toString() ?? '';

                      return GestureDetector(
                        onTap: () => _navigateToConversationDetail(sessionId, category),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(category),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(category),
                                    color: _getCategoryIconColor(category),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            category,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          if (hasPdf) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.picture_as_pdf,
                                                    size: 12,
                                                    color: const Color(0xFF10B981),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    'PDF',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF10B981),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${sender == 'user' ? 'You' : 'AVA'}: ${_truncateMessage(message)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7280),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (pdfName != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'File: $pdfName',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: const Color(0xFF6B7280).withOpacity(0.7),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatDate(createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class ConversationDetailScreen extends StatefulWidget {
  final String sessionId;
  final String category;

  const ConversationDetailScreen({
    super.key,
    required this.sessionId,
    required this.category,
  });

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _conversationMessages = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchConversationDetail();
  }

  Future<void> _fetchConversationDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final response = await _supabase
          .from('chat_sessions')
          .select()
          .eq('session_id', widget.sessionId)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _conversationMessages = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching conversation detail: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['sender'] == 'user';
    final msg = message['message']?.toString() ?? '';
    final time = message['created_at']?.toString() ?? '';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.white : const Color(0xFF4BA1AE),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? const Color(0xFF374151) : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(time),
              style: TextStyle(
                fontSize: 10,
                color: isUser ? const Color(0xFF9CA3AF) : Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4BA1AE),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4BA1AE), Color(0xFF73B5C1)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4BA1AE).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Session: ${widget.sessionId.substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: _fetchConversationDetail,
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4BA1AE),
                      Color(0xFF73B5C1),
                      Color(0xFF82BDC8),
                      Color(0xFF92C6CF),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : _hasError
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load conversation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchConversationDetail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4BA1AE),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                    : _conversationMessages.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 64,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No messages found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: _fetchConversationDetail,
                  color: Colors.white,
                  backgroundColor: const Color(0xFF4BA1AE),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    itemCount: _conversationMessages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_conversationMessages[index]);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}