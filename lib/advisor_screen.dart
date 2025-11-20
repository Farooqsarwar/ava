import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------- API KEY ----------
const String _GEMINI_API_KEY =
    'AIzaSyB7o5s2qyhm9T-w1Y8s9vfUdnoNvYzAv30';
const String _GEMINI_API_URL =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

void _validateApiKey() {
  if (_GEMINI_API_KEY.isEmpty) {
    debugPrint('[${DateTime.now()}] ERROR: Gemini API key not configured!');
  } else {
    debugPrint('[${DateTime.now()}] API Key initialized');
  }
}

// ---------- MAIN SCREEN ----------
class AdvisorScreen extends StatefulWidget {
  final String category;
  const AdvisorScreen({super.key, required this.category});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen>
    with SingleTickerProviderStateMixin {
  // ---------- Animation ----------
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ---------- State ----------
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _isLoadingVoices = false;
  bool _isRecording = false;
  final List<double> _waveformHeights = [0.4, 0.7, 1.0, 0.7, 0.4];

  // ---------- Voice ----------
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  String _transcribedText = '';
  String _currentStatus = 'Idle State';
  String _selectedVoice = 'en-US';
  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;
  List<Map<String, String>> _availableVoices = [];
  bool _showVoiceSetting = false;

  // ---------- PDF ----------
  String _scannedPdfContent = '';
  bool _isPdfLoaded = false;
  String _pdfFileName = '';

  // ---------- Chat ----------
  List<Map<String, dynamic>> _chatHistory = [];

  // ---------- Conversation Context ----------
  String _conversationContext = '';

  // ---------- Input ----------
  late TextEditingController _textInputController;
  bool _useVoiceInput = true;

  // ---------- Drag-to-cancel ----------
  late Offset _recordingStartPos;
  bool _shouldCancel = false;

  // ---------- Supabase ----------
  final SupabaseClient _supabase = Supabase.instance.client;

  // ---------- Session ----------
  String _sessionId = '';
  int _recordingDuration = 0;
  Timer? _recordingTimer;

  // --------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _textInputController = TextEditingController();
    _validateApiKey();
    _initializeVoiceServices();
    _setupAnimations();
    _loadAvailableVoices();
    _startNewSession();
  }

  void _startNewSession() {
    _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _conversationContext = ''; // Reset context for new session
  }

  // --------------------------------------------------------------
  void _initializeVoiceServices() async {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();

    await _flutterTts.setLanguage(_selectedVoice);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(_pitch);

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentStatus = 'Idle State';
        });
      }
    });
    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentStatus = 'TTS Error';
        });
      }
    });
    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = true;
          _currentStatus = 'Speaking...';
        });
      }
    });
  }

  // --------------------------------------------------------------
  Future<List<Map<String, String>>> _parseVoices(List<dynamic> voices) async {
    return compute((List<dynamic> voiceList) {
      final List<Map<String, String>> parsed = [];
      for (var v in voiceList) {
        if (v is Map) {
          final name = v['name']?.toString() ?? 'Unknown';
          final locale = v['locale']?.toString() ?? '';
          if (locale.isNotEmpty) parsed.add({'name': name, 'locale': locale});
        }
      }
      return parsed;
    }, voices);
  }

  void _loadAvailableVoices() async {
    setState(() => _isLoadingVoices = true);
    try {
      final voices = await _flutterTts.getVoices;
      if (voices != null && mounted) {
        final parsed = await _parseVoices(voices);
        setState(() {
          _availableVoices = parsed;
          _isLoadingVoices = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingVoices = false;
        _availableVoices = [
          {'name': 'English (US)', 'locale': 'en-US'},
          {'name': 'English (UK)', 'locale': 'en-GB'},
        ];
      });
    }
  }

  // --------------------------------------------------------------
  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _startWaveformAnimation();
  }

  void _startWaveformAnimation() {
    if (!_isListening || !mounted) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _isListening) {
        setState(() {
          _waveformHeights[0] = 0.4;
          _waveformHeights[1] = 1.0;
          _waveformHeights[2] = 0.4;
          _waveformHeights[3] = 1.0;
          _waveformHeights[4] = 0.4;
        });
      }
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && _isListening) {
          setState(() {
            _waveformHeights[0] = 1.0;
            _waveformHeights[1] = 0.4;
            _waveformHeights[2] = 1.0;
            _waveformHeights[3] = 0.4;
            _waveformHeights[4] = 1.0;
          });
        }
        if (_isListening && mounted) _startWaveformAnimation();
      });
    });
  }

  // --------------------------------------------------------------
  Future<void> _pickAndParsePDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _isProcessing = true;
          _currentStatus = 'Scanning PDF...';
        });

        _pdfFileName = result.files.single.name;

        // Simulate PDF content extraction (in real app, use a PDF parsing library)
        // For demo purposes, we'll create a simulated PDF content
        _scannedPdfContent = '''
PDF Document: $_pdfFileName
Extracted Content:
- This is a sample document about ${widget.category}
- Contains important information and data
- Ready for analysis and question answering
- Document has been successfully loaded and processed
''';

        setState(() {
          _isPdfLoaded = true;
          _currentStatus = 'PDF Loaded • Ready to analyze';

          // Add PDF context to conversation context
          _updateConversationContext();
        });
      }
    } catch (e) {
      debugPrint('PDF error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // Update conversation context with PDF and chat history
  void _updateConversationContext() {
    String context = '';

    // Add PDF context if loaded
    if (_isPdfLoaded && _scannedPdfContent.isNotEmpty) {
      context += 'DOCUMENT CONTEXT:\n$_scannedPdfContent\n\n';
    }

    // Add recent conversation history (last 4-5 exchanges to keep context manageable)
    if (_chatHistory.isNotEmpty) {
      context += 'CONVERSATION HISTORY:\n';
      final startIndex = _chatHistory.length > 8 ? _chatHistory.length - 8 : 0;
      for (int i = startIndex; i < _chatHistory.length; i++) {
        final msg = _chatHistory[i];
        final sender = msg['sender'] == 'user' ? 'User' : 'Assistant';
        context += '$sender: ${msg['message']}\n';
      }
    }

    _conversationContext = context;
  }

  // --------------------------------------------------------------
  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      debugPrint('Microphone permission denied');
    }
  }

  // ---------- MIC PRESS DOWN (ONLY ONE) ----------
  void _onMicPressDown(TapDownDetails details) async {
    if (_isSpeaking || _isProcessing) return;

    _recordingStartPos = details.globalPosition;
    _shouldCancel = false;

    await _requestMicrophonePermission();

    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _recordingDuration = t.tick);
    });

    final available = await _speech.initialize(
      onStatus: (s) => debugPrint('Speech status: $s'),
      onError: (e) {
        debugPrint('Speech error: $e');
        if (mounted) {
          setState(() {
            _isRecording = false;
            _currentStatus = 'Error';
          });
        }
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
        _currentStatus = 'Recording...';
        _transcribedText = '';
      });
      _startWaveformAnimation();
      _speech.listen(
        onResult: (r) => setState(() => _transcribedText = r.recognizedWords),
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5),
      );
    }
  }

  void _onMicDragUpdate(DragUpdateDetails details) {
    if (!_isRecording) return;
    final deltaY = details.globalPosition.dy - _recordingStartPos.dy;
    setState(() => _shouldCancel = deltaY < -50);
  }

  Future<void> _onMicPressUp() async {
    if (!_isRecording) return;

    _recordingTimer?.cancel();
    _recordingTimer = null;

    setState(() {
      _isRecording = false;
      _isListening = false;
    });

    await _speech.stop();

    if (_shouldCancel) {
      setState(() {
        _transcribedText = '';
        _currentStatus = 'Cancelled';
        _shouldCancel = false;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _currentStatus = 'Idle State');
      });
      return;
    }

    if (_transcribedText.isNotEmpty) {
      _addToChat('user', _transcribedText);

      // Force voice input mode and process (will trigger speech)
      setState(() => _useVoiceInput = true);
      await _processWithGemini(_transcribedText);
    } else {
      setState(() => _currentStatus = 'No speech detected');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _currentStatus = 'Idle State');
      });
    }
  }

  // --------------------------------------------------------------
  void _addToChat(String sender, String message) {
    setState(() {
      _chatHistory.add({
        'sender': sender,
        'message': message,
        'timestamp': DateTime.now(),
      });
    });

    // Update conversation context after adding new message
    _updateConversationContext();
  }

  Future<void> _saveToSupabase(Map<String, dynamic> chatData) async {
    try {
      await _supabase.from('chat_sessions').insert({
        'session_id': _sessionId,
        'user_id': _supabase.auth.currentUser?.id ?? 'anonymous',
        'category': widget.category,
        'sender': chatData['sender'],
        'message': chatData['message'],
        'voice_settings': {
          'selected_voice': _selectedVoice,
          'speech_rate': _speechRate,
          'pitch': _pitch,
          'volume': _volume,
        },
        'recording_duration': _recordingDuration,
        'has_pdf': _isPdfLoaded,
        'pdf_name': _isPdfLoaded ? _pdfFileName : null,
        'pdf_content': _isPdfLoaded ? _scannedPdfContent : null, // This line needs the column
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase save error: $e');
    }
  }
  // --------------------------------------------------------------
  Future<void> _processWithGemini(String userInput) async {
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _currentStatus = 'Processing...';
    });

    try {
      final response = await _callGeminiAPI(userInput);
      _addToChat('luna', response);

      if (_chatHistory.length >= 2) {
        await _saveToSupabase(_chatHistory[_chatHistory.length - 2]);
        await _saveToSupabase(_chatHistory[_chatHistory.length - 1]);
      }

      // Only speak the response if the input was voice
      if (_useVoiceInput && mounted) {
        await _speakResponse(response);
      } else {
        // For text input, just update status (no speech)
        setState(() {
          _currentStatus = 'Response received';
        });
        // Reset status after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _currentStatus = 'Idle State');
        });
      }

    } catch (e) {
      final msg = e.toString().contains('API Key')
          ? 'API Key error'
          : e.toString().contains('timeout')
          ? 'Request timeout'
          : 'Failed to get response';
      setState(() => _currentStatus = 'Error: $msg');
      _addToChat('system', 'Error: $msg');
      await _saveToSupabase({'sender': 'system', 'message': 'Error: $msg'});
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          if (!_isSpeaking) _currentStatus = 'Idle State';
        });
      }
    }
  }

  Future<String> _callGeminiAPI(String userInput) async {
    if (_GEMINI_API_KEY.isEmpty) throw Exception('Invalid API Key');

    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_GEMINI_API_KEY');
    final headers = {'Content-Type': 'application/json'};

    // Build comprehensive prompt with context
    String systemPrompt = '''
You are Luna, a helpful ${widget.category} advisor. 
Provide concise, helpful responses while maintaining context from our conversation.

IMPORTANT: Remember and reference previous parts of our conversation and any document context provided.
''';

    String fullPrompt = '''
$systemPrompt

${_conversationContext.isNotEmpty ? _conversationContext : ''}

Current question: $userInput

Please provide a helpful response that considers:
1. The current question
2. Any document context provided
3. Our conversation history
4. Your role as a ${widget.category} advisor

Response:
''';

    final body = jsonEncode({
      'contents': [
        {'parts': [{'text': fullPrompt}]}
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        }
      ]
    });

    final resp = await http
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      final err = jsonDecode(resp.body);
      throw Exception(
          'API ${resp.statusCode}: ${err['error']?['message'] ?? 'unknown'}');
    }
  }

  // --------------------------------------------------------------
  Future<void> _speakResponse(String text) async {
    if (!mounted || text.isEmpty) return;
    setState(() {
      _isSpeaking = true;
      _currentStatus = 'Speaking...';
    });
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      setState(() {
        _isSpeaking = false;
        _currentStatus = 'Speech Error';
      });
    }
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _currentStatus = 'Idle State';
      });
    }
  }

  void _clearChat() {
    setState(() {
      _chatHistory.clear();
      _conversationContext = ''; // Clear context when clearing chat
    });
    _startNewSession();
  }

  void _submitTextInput() async {
    final txt = _textInputController.text.trim();
    if (txt.isEmpty) return;
    _textInputController.clear();

    _addToChat('user', txt);

    // Stop any ongoing speech when switching to text input
    if (_isSpeaking) {
      await _stopSpeaking();
    }

    // Force text input mode and process (won't trigger speech)
    setState(() => _useVoiceInput = false);
    await _processWithGemini(txt);
  }

  // --------------------------------------------------------------
  void _showVoiceSettings() {
    setState(() => _showVoiceSetting = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border:
                  Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Voice Settings',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() => _showVoiceSetting = false);
                        },
                        icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Voice Selection',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _isLoadingVoices
                          ? const Center(child: CircularProgressIndicator())
                          : Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: _availableVoices.map((v) {
                            final selected = v['locale'] == _selectedVoice;
                            return ListTile(
                              title: Text(v['name'] ?? 'Unknown'),
                              subtitle: Text(v['locale'] ?? ''),
                              trailing: selected
                                  ? const Icon(Icons.check_circle,
                                  color: Color(0xFF2563EB))
                                  : null,
                              onTap: () async {
                                setModal(() => _selectedVoice =
                                    v['locale'] ?? 'en-US');
                                setState(() => _selectedVoice =
                                    v['locale'] ?? 'en-US');
                                await _flutterTts
                                    .setLanguage(_selectedVoice);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                          'Speech Rate: ${(_speechRate * 2).toStringAsFixed(1)}x',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      Slider(
                          value: _speechRate,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          onChanged: (v) async {
                            setModal(() => _speechRate = v);
                            setState(() => _speechRate = v);
                            await _flutterTts.setSpeechRate(_speechRate);
                          }),
                      const SizedBox(height: 16),
                      Text('Pitch: ${_pitch.toStringAsFixed(1)}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      Slider(
                          value: _pitch,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          onChanged: (v) async {
                            setModal(() => _pitch = v);
                            setState(() => _pitch = v);
                            await _flutterTts.setPitch(_pitch);
                          }),
                      const SizedBox(height: 16),
                      Text('Volume: ${(_volume * 100).toInt()}%',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      Slider(
                          value: _volume,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          onChanged: (v) async {
                            setModal(() => _volume = v);
                            setState(() => _volume = v);
                            await _flutterTts.setVolume(_volume);
                          }),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _flutterTts.speak(
                            "Hello! I'm Luna, your ${widget.category} advisor."),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Test Voice'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  Widget _buildStatusIndicator() {
    final Map<bool, Color> colorMap = {
      _isSpeaking: const Color(0xFF10B981),
      _isProcessing: const Color(0xFFF59E0B),
      _isListening: const Color(0xFF2563EB),
    };
    final color = colorMap.entries
        .firstWhere((e) => e.key, orElse: () => MapEntry(false, const Color(0xFF6B7280)))
        .value;
    final icon = _isSpeaking
        ? Icons.volume_up
        : _isProcessing
        ? Icons.psychology
        : _isListening
        ? Icons.mic
        : Icons.mic_none;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(_currentStatus,
              style:
              TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg) {
    final isUser = msg['sender'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(12),
        constraints:
        BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
            color: isUser ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12)),
        child: Text(msg['message']?.toString() ?? '',
            style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF374151),
                fontSize: 14)),
      ),
    );
  }

  Widget _buildTextInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textInputController,
              decoration: InputDecoration(
                hintText: 'Type your question...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
              ),
              enabled: !_isProcessing && !_isSpeaking,
              onSubmitted: (_) => _submitTextInput(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF2563EB)),
              onPressed: _isProcessing || _isSpeaking ? null : _submitTextInput),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    _flutterTts.stop();
    _recordingTimer?.cancel();
    _textInputController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final small = size.width < 360;

    return Scaffold(
      body: Container(
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4BA1AE),
              Color(0xFF73B5C1),
              Color(0xFF82BDC8),
              Color(0xFF92C6CF)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(small ? 12 : 16),
                child: Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context)),
                    Expanded(
                        child: Text('AVA • ${widget.category}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white))),
                    IconButton(
                        icon: const Icon(Icons.settings_voice,
                            color: Colors.white),
                        onPressed: _showVoiceSettings),
                  ],
                ),
              ),

              // Voice / Text toggle
              Padding(
                padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                        value: true,
                        label: Text('Voice'),
                        icon: Icon(Icons.mic, size: 16)),
                    ButtonSegment(
                        value: false,
                        label: Text('Text'),
                        icon: Icon(Icons.message, size: 16)),
                  ],
                  selected: {_useVoiceInput},
                  onSelectionChanged: (s) =>
                      setState(() => _useVoiceInput = s.first),
                  style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(height: 12),

              // Status
              _buildStatusIndicator(),
              const SizedBox(height: 12),

              // PDF indicator with context info
              if (_isPdfLoaded)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        border: Border.all(color: const Color(0x8610B981)),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PDF: $_pdfFileName',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis),
                                Text('Context loaded & remembered',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                              ],
                            )),
                        IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setState(() {
                              _isPdfLoaded = false;
                              _pdfFileName = '';
                              _scannedPdfContent = '';
                              _updateConversationContext(); // Update context after removing PDF
                              _currentStatus = 'Idle State';
                            })),
                      ],
                    ),
                  ),
                ),
              if (_isPdfLoaded) const SizedBox(height: 12),

              // Chat
              Expanded(
                child: _chatHistory.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white24,
                          child: Image.network(
                              'https://lh3.googleusercontent.com/...',
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, size: 40))),
                      const SizedBox(height: 16),
                      const Text('Luna',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Your ${widget.category} Advisor',
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 24),
                      Text(
                          _useVoiceInput
                              ? 'Hold mic to speak'
                              : 'Type below',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 14)),
                      if (_isPdfLoaded) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PDF context is loaded and will be remembered',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _chatHistory.length,
                  itemBuilder: (_, i) => _buildChatBubble(_chatHistory[i]),
                ),
              ),

              // Bottom controls (PDF / Clear)
              if (!_isListening && !_isProcessing && _useVoiceInput)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16),
                  child: Row(
                    children: [
                      Expanded(
                          child: OutlinedButton.icon(
                              onPressed: _pickAndParsePDF,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Scan PDF'))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: OutlinedButton.icon(
                              onPressed: _chatHistory.isEmpty ? null : _clearChat,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Clear Chat'))),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Mic / Text input
              Padding(
                padding: EdgeInsets.all(small ? 12 : 16),
                child: Column(
                  children: [
                    if (_isSpeaking)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Color(0xFFEF4444),
                                  spreadRadius: 10,
                                  blurRadius: 10)
                            ]),
                        child: IconButton(
                            icon: const Icon(Icons.stop,
                                color: Colors.white, size: 36),
                            onPressed: _stopSpeaking),
                      )
                    else if (_useVoiceInput)
                      GestureDetector(
                        onTapDown: _onMicPressDown,
                        onPanUpdate: _onMicDragUpdate,
                        onLongPressEnd: (_) => _onMicPressUp(),
                        onLongPressCancel: () => _onMicPressUp(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                              color: _isRecording
                                  ? const Color(0xFFEF4444)
                                  : _shouldCancel
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF2563EB),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: (_isRecording
                                        ? const Color(0xFFEF4444)
                                        : _shouldCancel
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF2563EB))
                                        .withOpacity(0.5),
                                    spreadRadius:
                                    _isRecording ? 10 : _shouldCancel ? 5 : 0,
                                    blurRadius: 10)
                              ]),
                          child: Center(
                            child: _isListening
                                ? SizedBox(
                                width: 40,
                                height: 40,
                                child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: List.generate(
                                        5,
                                            (i) => AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            width: 3,
                                            height: 40 *
                                                _waveformHeights[i],
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                BorderRadius.circular(
                                                    2))))))
                                : Icon(
                                _isRecording ? Icons.stop : Icons.mic,
                                color: Colors.white,
                                size: 36),
                          ),
                        ),
                      )
                    else
                      _buildTextInput(),
                    const SizedBox(height: 8),
                    Text(
                        _isSpeaking
                            ? 'Tap to stop'
                            : _shouldCancel
                            ? 'Release to cancel'
                            : _isRecording
                            ? 'Slide up to cancel'
                            : _useVoiceInput
                            ? 'Hold to record'
                            : 'Type your question',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}