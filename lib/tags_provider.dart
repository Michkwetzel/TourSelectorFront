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

class CategoryConfig {
  final String title;
  final int weight;
  final bool isVisible;

  CategoryConfig({
    required this.title,
    required this.weight,
    required this.isVisible,
  });

  factory CategoryConfig.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) {
      return CategoryConfig(
        title: 'Category',
        weight: 1,
        isVisible: true,
      );
    }
    return CategoryConfig(
      title: data['title'] as String? ?? 'Category',
      weight: data['weight'] as int? ?? 1,
      isVisible: data['isVisible'] as bool? ?? true,
    );
  }
}

class TagsNotifierState {
  final Map<String, Map<String, dynamic>> rawTagData;
  final Map<int, CategoryConfig> categoryConfigs;
  final bool isLoading;
  final String? error;

  TagsNotifierState({
    required this.rawTagData,
    required this.categoryConfigs,
    this.isLoading = false,
    this.error,
  });

  TagsNotifierState copyWith({
    Map<String, Map<String, dynamic>>? rawTagData,
    Map<int, CategoryConfig>? categoryConfigs,
    bool? isLoading,
    String? error,
  }) {
    return TagsNotifierState(
      rawTagData: rawTagData ?? this.rawTagData,
      categoryConfigs: categoryConfigs ?? this.categoryConfigs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  factory TagsNotifierState.initial() {
    final defaultCategories = {
      1: CategoryConfig(title: 'Category 1', weight: 2, isVisible: true),
      2: CategoryConfig(title: 'Category 2', weight: 2, isVisible: true),
      3: CategoryConfig(title: 'Category 3', weight: 2, isVisible: true),
      4: CategoryConfig(title: 'Category 4', weight: 2, isVisible: true),
      5: CategoryConfig(title: 'Category 5', weight: 1, isVisible: true),
      6: CategoryConfig(title: 'Category 6', weight: 1, isVisible: true),
    };

    return TagsNotifierState(
      rawTagData: {
        'tags1': {},
        'tags2': {},
        'tags3': {},
        'tags4': {},
        'tags5': {},
        'tags6': {},
      },
      categoryConfigs: defaultCategories,
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

  // Get category configuration for a specific index
  CategoryConfig getCategoryConfig(int index) {
    return categoryConfigs[index] ?? CategoryConfig(title: 'Category $index', weight: 1, isVisible: true);
  }

  // Check if a category should be visible in the user frontend
  bool shouldShowCategory(int index) {
    final config = getCategoryConfig(index);
    final hasTags = getTagsForIndex(index).isNotEmpty;
    return config.isVisible && hasTags;
  }
}

class TagsNotifier extends StateNotifier<TagsNotifierState> {
  TagsNotifier() : super(TagsNotifierState.initial()) {
    // Initialize by listening to category config
    _listenToCategoryConfig();

    // Initialize by starting streams for all tag documents
    for (int i = 1; i <= 6; i++) {
      _listenToTagDocument(i);
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _listenToCategoryConfig() {
    _firestore.collection('config').doc('categories').snapshots().listen(
      (DocumentSnapshot snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          final updatedConfigs = Map<int, CategoryConfig>.from(state.categoryConfigs);

          // Update each category config from Firestore
          for (int i = 1; i <= 6; i++) {
            final categoryData = data['category$i'] as Map<String, dynamic>?;
            if (categoryData != null) {
              updatedConfigs[i] = CategoryConfig.fromFirestore(categoryData);
            }
          }

          state = state.copyWith(
            categoryConfigs: updatedConfigs,
            isLoading: false,
          );
        }
      },
      onError: (error) {
        state = state.copyWith(
          error: 'Error fetching category config: $error',
          isLoading: false,
        );
      },
    );
  }

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
