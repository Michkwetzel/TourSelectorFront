import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TagEntry {
  final String devName;
  final String displayName;
  final int order;

  TagEntry({
    required this.devName,
    required this.displayName,
    required this.order,
  });

  factory TagEntry.fromFirestore(String key, dynamic value) {
    String displayName;
    int order = 9999; // Default high value for unsorted tags

    if (value is Map) {
      displayName = value['display'] as String? ?? '';
      order = value['order'] as int? ?? 9999;
    } else if (value is String) {
      // Legacy support for old data format
      displayName = value;
    } else {
      displayName = '';
    }

    return TagEntry(
      devName: key,
      displayName: displayName,
      order: order,
    );
  }
}

class TagsNotifierState {
  final Map<String, Map<String, dynamic>> rawTagData;
  final bool isLoading;
  final String? error;

  TagsNotifierState({
    required this.rawTagData,
    this.isLoading = false,
    this.error,
  });

  TagsNotifierState copyWith({
    Map<String, Map<String, dynamic>>? rawTagData,
    bool? isLoading,
    String? error,
  }) {
    return TagsNotifierState(
      rawTagData: rawTagData ?? this.rawTagData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  factory TagsNotifierState.initial() {
    return TagsNotifierState(
      rawTagData: {
        'tags1': {},
        'tags2': {},
        'tags3': {},
        'tags4': {},
        'tags5': {},
        'tags6': {},
      },
      isLoading: true,
    );
  }

  // Helper method to get tag lists for specific indices
  List<TagEntry> getTagsForIndex(int index) {
    final docName = 'tags$index';
    final data = rawTagData[docName] ?? {};

    final List<TagEntry> entries = [];

    data.forEach((key, value) {
      entries.add(TagEntry.fromFirestore(key, value));
    });

    // Sort entries by order
    entries.sort((a, b) => a.order.compareTo(b.order));

    return entries;
  }

  // Get tag entries as map entries (for backward compatibility)
  List<MapEntry<String, String>> getTagEntriesForIndex(int index) {
    final tags = getTagsForIndex(index);
    return tags.map((tag) => MapEntry(tag.devName, tag.displayName)).toList();
  }
}

class TagsNotifier extends StateNotifier<TagsNotifierState> {
  TagsNotifier() : super(TagsNotifierState.initial()) {
    // Initialize by starting streams for all tag documents
    for (int i = 1; i <= 6; i++) {
      _listenToTagDocument(i);
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _listenToTagDocument(int index) {
    final docName = 'tags$index';

    _firestore.collection('tags').doc(docName).snapshots().listen(
      (DocumentSnapshot snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;

          // Update state with new data
          final updatedTagMaps = Map<String, Map<String, dynamic>>.from(state.rawTagData);
          updatedTagMaps[docName] = data;

          state = state.copyWith(
            rawTagData: updatedTagMaps,
            isLoading: false,
          );
        } else {
          // Document doesn't exist, set empty map
          final updatedTagMaps = Map<String, Map<String, dynamic>>.from(state.rawTagData);
          updatedTagMaps[docName] = {};

          state = state.copyWith(
            rawTagData: updatedTagMaps,
            isLoading: false,
          );
        }
      },
      onError: (error) {
        state = state.copyWith(
          error: 'Error fetching $docName: $error',
          isLoading: false,
        );
      },
    );
  }
}

// Provider for the Tags state
final tagsProvider = StateNotifierProvider<TagsNotifier, TagsNotifierState>((ref) {
  return TagsNotifier();
});

// Provider to manage selected tags
class SelectedTagsNotifier extends StateNotifier<Map<int, String?>> {
  SelectedTagsNotifier()
      : super({
          1: null,
          2: null,
          3: null,
          4: null,
          5: null,
          6: null,
        });

  void selectTag(int categoryIndex, String devName) {
    state = {...state, categoryIndex: devName};
  }

  void clearSelection(int categoryIndex) {
    state = {...state, categoryIndex: null};
  }

  void clearAllSelections() {
    state = {
      1: null,
      2: null,
      3: null,
      4: null,
      5: null,
      6: null,
    };
  }
}

final selectedTagsProvider = StateNotifierProvider<SelectedTagsNotifier, Map<int, String?>>((ref) {
  return SelectedTagsNotifier();
});
