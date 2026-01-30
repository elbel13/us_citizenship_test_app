import 'package:flutter/material.dart';
import '../services/llm_service.dart';

/// Test screen for LLM model inference
/// MVP implementation to verify model loading and basic functionality
class LlmTestScreen extends StatefulWidget {
  const LlmTestScreen({super.key});

  @override
  State<LlmTestScreen> createState() => _LlmTestScreenState();
}

class _LlmTestScreenState extends State<LlmTestScreen> {
  final LlmService _llmService = LlmService();
  final TextEditingController _promptController = TextEditingController();

  String _status = 'Not initialized';
  String _response = '';
  bool _isLoading = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _promptController.text = 'That is correct.';
  }

  @override
  void dispose() {
    _llmService.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _initializeModel() async {
    setState(() {
      _isLoading = true;
      _status = 'Loading model...';
    });

    try {
      await _llmService.initialize();
      setState(() {
        _status = 'Model loaded successfully!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading model: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateText() async {
    if (!_llmService.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please initialize the model first')),
      );
      return;
    }

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a prompt')));
      return;
    }

    setState(() {
      _isGenerating = true;
      _response = '';
    });

    try {
      final result = await _llmService.generate(prompt);
      setState(() {
        _response = result;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LLM Test (MVP)')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _llmService.isInitialized
                                ? Icons.check_circle
                                : Icons.info_outline,
                            color: _llmService.isInitialized
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _status,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                      if (!_llmService.isInitialized) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _initializeModel,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download),
                          label: Text(_isLoading ? 'Loading...' : 'Load Model'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Prompt input
              TextField(
                controller: _promptController,
                decoration: const InputDecoration(
                  labelText: 'Prompt',
                  hintText: 'Enter interviewer response prompt...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                enabled: _llmService.isInitialized && !_isGenerating,
              ),
              const SizedBox(height: 8),

              // Generate button
              ElevatedButton.icon(
                onPressed: _isGenerating || !_llmService.isInitialized
                    ? null
                    : _generateText,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isGenerating ? 'Generating...' : 'Generate'),
              ),
              const SizedBox(height: 16),

              // Response output
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: _response.isEmpty
                        ? Text(
                            'Response will appear here...',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                          )
                        : SelectableText(
                            _response,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
