import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'firebase_options.dart';
import 'tags_provider.dart';
import 'tag_combinations_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tour Selector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TagSelectorScreen(),
    );
  }
}

class TagSelectorScreen extends ConsumerWidget {
  const TagSelectorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsState = ref.watch(tagsProvider);
    final selectedTags = ref.watch(selectedTagsProvider);
    
    // Calculate if any selections have been made
    bool hasSelections = selectedTags.values.any((tag) => tag != null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Selector'),
      ),
      body: tagsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tagsState.error != null
              ? Center(
                  child: Text(
                    'Error: ${tagsState.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            for (int i = 1; i <= 6; i++)
                              if (tagsState.shouldShowCategory(i)) _buildTagDropdown(context, i, tagsState, ref),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: !hasSelections ? null : () => _submitSelections(context, ref),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Submit Selections'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTagDropdown(BuildContext context, int index, TagsNotifierState state, WidgetRef ref) {
    final tagEntries = state.getTagsForIndex(index);
    final selectedTag = ref.watch(selectedTagsProvider)[index];
    final categoryConfig = state.getCategoryConfig(index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  categoryConfig.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Weight: ${categoryConfig.weight}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedTag,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: tagEntries.isEmpty ? 'No tags available' : 'Select a tag',
            ),
            items: tagEntries.isEmpty
                ? null
                : tagEntries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.devName,
                      child: Text(entry.displayName),
                    );
                  }).toList(),
            onChanged: tagEntries.isEmpty
                ? null
                : (value) {
                    if (value != null) {
                      ref.read(selectedTagsProvider.notifier).selectTag(index, value);

                      // Find the selected tag
                      final tagInfo = tagEntries.firstWhere((entry) => entry.devName == value);

                      print('Selected Tag for ${categoryConfig.title}: ${tagInfo.displayName} (${tagInfo.devName})');

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Selected: ${tagInfo.displayName} (${tagInfo.devName})'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }

  Future<void> _submitSelections(BuildContext context, WidgetRef ref) async {
    final tagsState = ref.read(tagsProvider);
    final selectedTags = ref.read(selectedTagsProvider);
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Generate all possible tag combinations and calculate scores
      final combinationsService = TagCombinationsService();
      final scoredCombinations = combinationsService.generateScoredCombinations(
        tagsState: tagsState,
        selectedTags: selectedTags,
      );
      
      print(scoredCombinations);
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Send to API endpoint
      try {
        // final response = await _sendToApi(scoredCombinations);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submitted ${scoredCombinations.length} combinations successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Show results in a dialog
        _showResultsDialog(context, scoredCombinations);
        
      } catch (e) {
        // Show error if API call fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating combinations: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<http.Response> _sendToApi(List<Map<String, dynamic>> combinations) async {
    // Replace with your actual API endpoint
    const String apiUrl = 'https://your-api-endpoint.com/combinations';
    
    // Send the data to your API
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'combinations': combinations}),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to submit combinations: ${response.body}');
    }
    
    return response;
  }
  
  void _showResultsDialog(BuildContext context, List<Map<String, dynamic>> combinations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tag Combinations'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400, // Fixed height for the dialog content
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: combinations.length > 10 ? 10 : combinations.length,
            itemBuilder: (context, index) {
              final combination = combinations[index];
              final List<String> tagList = List<String>.from(combination['tags']);
              final score = combination['score'];
              
              return ListTile(
                title: Text('Score: $score'),
                subtitle: Text('Tags: ${tagList.join(", ")}'),
                tileColor: index % 2 == 0 ? Colors.grey.shade100 : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}