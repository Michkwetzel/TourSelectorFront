import 'tags_provider.dart';

class TagCombinationsService {
  /// Generates all possible tag combinations and scores them based on user selection
  List<Map<String, dynamic>> generateScoredCombinations({
    required TagsNotifierState tagsState,
    required Map<int, String?> selectedTags,
  }) {
    // Get all visible categories with tags
    final visibleCategories = <int>[];
    for (int i = 1; i <= 6; i++) {
      if (tagsState.shouldShowCategory(i)) {
        visibleCategories.add(i);
      }
    }

    // Get all possible tags for each category
    final Map<int, List<String>> allCategoryTags = {};
    for (final categoryIndex in visibleCategories) {
      final tags = tagsState.getTagsForIndex(categoryIndex);
      if (tags.isNotEmpty) {
        allCategoryTags[categoryIndex] = tags.map((tag) => tag.devName).toList();
      }
    }

    // Generate all possible combinations
    final List<Map<int, String>> allCombinations = _generateAllCombinations(allCategoryTags);

    // Score each combination
    final List<Map<String, dynamic>> scoredCombinations = [];
    for (final combination in allCombinations) {
      int score = 0;
      final List<String> tagsList = [];

      // Calculate score for this combination
      combination.forEach((categoryIndex, tagName) {
        // Add tag to the list
        tagsList.add(tagName);
        
        // Add category weight to score if tag matches user selection
        if (selectedTags[categoryIndex] == tagName) {
          final categoryWeight = tagsState.getCategoryConfig(categoryIndex).weight;
          score += categoryWeight;
        }
      });

      // Add combination and score to result list
      scoredCombinations.add({
        'tags': tagsList,
        'score': score,
      });
    }

    // Sort by score (descending)
    scoredCombinations.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return scoredCombinations;
  }

  /// Recursively generates all possible combinations of tags from all categories
  List<Map<int, String>> _generateAllCombinations(Map<int, List<String>> categoryTags) {
    List<Map<int, String>> result = [];
    
    void _generateCombinationsRecursive(
      int currentIndex,
      List<int> categories,
      Map<int, String> currentCombination
    ) {
      // Base case: if we've processed all categories
      if (currentIndex >= categories.length) {
        result.add(Map<int, String>.from(currentCombination));
        return;
      }
      
      // Get current category and its tags
      final categoryId = categories[currentIndex];
      final tags = categoryTags[categoryId] ?? [];
      
      // For each tag in the current category
      for (final tag in tags) {
        // Add this tag to the current combination
        currentCombination[categoryId] = tag;
        
        // Recursively generate combinations for the next category
        _generateCombinationsRecursive(
          currentIndex + 1,
          categories,
          currentCombination,
        );
      }
    }
    
    // Start the recursive generation
    _generateCombinationsRecursive(
      0, 
      categoryTags.keys.toList(),
      {},
    );
    
    return result;
  }
}