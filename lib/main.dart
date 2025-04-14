import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'tags_provider.dart';
import 'tag_combinations_service.dart';
import 'user_info_provider.dart'; // We'll create this file next

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
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Selector'),
      ),
      body: const CombinedScreen(),
    );
  }
}

// Combined Screen with User Info and Tag Selection
class CombinedScreen extends ConsumerWidget {
  const CombinedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(userInfoProvider);
    final tagsState = ref.watch(tagsProvider);
    final selectedTags = ref.watch(selectedTagsProvider);

    // Calculate if any selections have been made
    bool hasSelections = selectedTags.values.any((tag) => tag != null);

    return tagsState.isLoading
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
                child: Form(
                  key: ref.read(userInfoProvider.notifier).formKey,
                  child: ListView(
                    children: [
                      // Personal Information Section
                      Text(
                        'Personal Information',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),

                      // First Name
                      TextFormField(
                        initialValue: userInfo.firstName,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                        onChanged: (value) => ref.read(userInfoProvider.notifier).updateFirstName(value),
                      ),
                      const SizedBox(height: 16),

                      // Surname
                      TextFormField(
                        initialValue: userInfo.surname,
                        decoration: const InputDecoration(
                          labelText: 'Surname',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your surname';
                          }
                          return null;
                        },
                        onChanged: (value) => ref.read(userInfoProvider.notifier).updateSurname(value),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        initialValue: userInfo.email,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email address';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                        onChanged: (value) => ref.read(userInfoProvider.notifier).updateEmail(value),
                      ),
                      const SizedBox(height: 16),

                      // Country
                      TextFormField(
                        initialValue: userInfo.country,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your country';
                          }
                          return null;
                        },
                        onChanged: (value) => ref.read(userInfoProvider.notifier).updateCountry(value),
                      ),
                      const SizedBox(height: 16),

                      // Group Size
                      TextFormField(
                        initialValue: userInfo.groupSize?.toString() ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Group Size',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                          helperText: 'Maximum group size is 12',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the group size';
                          }
                          final groupSize = double.tryParse(value);
                          if (groupSize == null || groupSize <= 0) {
                            return 'Please enter a valid group size';
                          }
                          if (groupSize > 12) {
                            return 'Group size cannot be larger than 12';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          final groupSize = double.tryParse(value);
                          if (groupSize != null) {
                            ref.read(userInfoProvider.notifier).updateGroupSize(groupSize);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Start Date
                      GestureDetector(
                        onTap: () => _selectStartDate(context, ref),
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: TextEditingController(
                              text: userInfo.startDate != null ? DateFormat('dd MMM yyyy').format(userInfo.startDate!) : '',
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Start Date',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                              hintText: 'Select date',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a start date';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      const Divider(),
                      const SizedBox(height: 10),

                      // Tour Selection Section
                      Text(
                        'Tour Selection',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),

                      // Tour selection dropdowns
                      for (int i = 1; i <= 6; i++)
                        if (tagsState.shouldShowCategory(i)) _buildTagDropdown(context, i, tagsState, ref),

                      const SizedBox(height: 30),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: !hasSelections ? null : () => _submitSelections(context, ref),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Submit Request'),
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
    // Check if user info is valid
    if (!ref.read(userInfoProvider.notifier).validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your personal information first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final tagsState = ref.read(tagsProvider);
    final selectedTags = ref.read(selectedTagsProvider);
    final userInfo = ref.read(userInfoProvider);

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

      // Create the full request payload including user info
      final requestPayload = {
        'userInfo': {
          'firstName': userInfo.firstName,
          'surname': userInfo.surname,
          'email': userInfo.email,
          'country': userInfo.country,
          'groupSize': userInfo.groupSize,
          'startDate': userInfo.startDate?.toIso8601String(),
        },
        'combinations': scoredCombinations,
      };

      // Log the full request payload
      print('Full request payload:');
      print(jsonEncode(requestPayload));

      // Send to API endpoint (commented out for now)
      try {
        // final response = await _sendToApi(requestPayload);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submitted ${scoredCombinations.length} combinations successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Show results in a dialog
        _showResultsDialog(context, scoredCombinations, userInfo);
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

  Future<http.Response> _sendToApi(Map<String, dynamic> requestPayload) async {
    // Replace with your actual API endpoint
    const String apiUrl = 'https://your-api-endpoint.com/combinations';

    // Send the data to your API
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestPayload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit request: ${response.body}');
    }

    return response;
  }

  void _showResultsDialog(BuildContext context, List<Map<String, dynamic>> combinations, UserInfo userInfo) {
    final DateFormat dateFormatter = DateFormat('dd MMM yyyy');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Summary'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500, // Increased height for the dialog content
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${userInfo.firstName} ${userInfo.surname}'),
              Text('Email: ${userInfo.email}'),
              Text('Country: ${userInfo.country}'),
              Text('Group Size: ${userInfo.groupSize}'),
              if (userInfo.startDate != null) Text('Start Date: ${dateFormatter.format(userInfo.startDate!)}'),
              const Divider(),
              const Text('Top Tag Combinations:', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
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
            ],
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

  Future<void> _selectStartDate(BuildContext context, WidgetRef ref) async {
    final DateTime now = DateTime.now();
    final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: ref.read(userInfoProvider).startDate ?? tomorrow,
      firstDate: tomorrow, // Can't select past dates
      lastDate: DateTime(now.year + 2), // Can select up to 2 years in the future
    );

    if (picked != null) {
      ref.read(userInfoProvider.notifier).updateStartDate(picked);
    }
  }
}
