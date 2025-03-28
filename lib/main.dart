import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'tags_provider.dart';

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
                      for (int i = 1; i <= 6; i++) _buildTagDropdown(context, i, tagsState, ref),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTagDropdown(BuildContext context, int index, TagsNotifierState state, WidgetRef ref) {
    final tagEntries = state.getTagsForIndex(index);
    final selectedTag = ref.watch(selectedTagsProvider)[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category $index',
            style: Theme.of(context).textTheme.titleMedium,
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

                      print('Selected Tag for Category $index: ${tagInfo.displayName} (${tagInfo.devName})');

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
}
