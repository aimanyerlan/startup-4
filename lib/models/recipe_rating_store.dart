import 'package:my_app/models/recipe.dart';

class RecipeRatingStore {
  static const int _baseVotes = 40;

  static final Map<int, double> _ratingTotals = {};
  static final Map<int, int> _ratingCounts = {};
  static final Map<int, int> _userRatings = {};

  static void _ensureInitialized(Recipe recipe) {
    if (_ratingTotals.containsKey(recipe.id)) return;

    _ratingTotals[recipe.id] = recipe.rating * _baseVotes;
    _ratingCounts[recipe.id] = _baseVotes;
  }

  static double getAverage(Recipe recipe) {
    _ensureInitialized(recipe);
    final total = _ratingTotals[recipe.id]!;
    final count = _ratingCounts[recipe.id]!;
    return total / count;
  }

  static int getVotes(Recipe recipe) {
    _ensureInitialized(recipe);
    return _ratingCounts[recipe.id]!;
  }

  static int getUserRating(int recipeId) {
    return _userRatings[recipeId] ?? 0;
  }

  static double setUserRating(Recipe recipe, int rating) {
    _ensureInitialized(recipe);

    final previous = _userRatings[recipe.id];

    if (previous == null) {
      _ratingTotals[recipe.id] = _ratingTotals[recipe.id]! + rating;
      _ratingCounts[recipe.id] = _ratingCounts[recipe.id]! + 1;
    } else {
      _ratingTotals[recipe.id] = _ratingTotals[recipe.id]! - previous + rating;
    }

    _userRatings[recipe.id] = rating;
    return getAverage(recipe);
  }
}
