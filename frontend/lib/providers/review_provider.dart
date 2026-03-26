import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../services/upload_service.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewService _reviewService = ReviewService();
  
  List<Review> _reviews = [];
  RatingSummary? _ratingSummary;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // Getters
  List<Review> get reviews => _reviews;
  RatingSummary? get ratingSummary => _ratingSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // Load reviews
  Future<void> loadReviews({
    String? providerId,
    String? customerId,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _reviews = [];
    }

    if (_isLoading || !_hasMore) return;

    _setLoading(true);
    _error = null;

    try {
      final response = await _reviewService.getReviews(
        providerId: providerId,
        customerId: customerId,
        page: _currentPage,
        limit: AppConstants.defaultPageSize,
      );

      if (response.success) {
        final newReviews = response.data ?? [];
        
        if (refresh) {
          _reviews = newReviews;
        } else {
          _reviews.addAll(newReviews);
        }

        _hasMore = newReviews.length >= AppConstants.defaultPageSize;
        _currentPage++;
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = ErrorMessages.genericError;
    } finally {
      _setLoading(false);
    }
  }

  // Get rating summary
  Future<void> getRatingSummary(String providerId) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _reviewService.getProviderRatingSummary(providerId);

      if (response.success) {
        _ratingSummary = response.data;
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = ErrorMessages.genericError;
    } finally {
      _setLoading(false);
    }
  }

  // Create review
  Future<bool> createReview({
    required String bookingId,
    required String providerId,
    required int rating,
    String? comment,
    List<XFile> images = const [],
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // 1. Upload images if any
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        imageUrls = await UploadService.uploadImages(
          xFiles: images,
          bucket: 'reviews',
          userId: providerId, // Store under provider's folder for better organization
          folderPrefix: 'rev_${bookingId.substring(0, 8)}',
        );
      }

      // 2. Create review record
      final response = await _reviewService.createReview(
        bookingId: bookingId,
        providerId: providerId,
        rating: rating,
        comment: comment,
        images: imageUrls,
      );

      if (response.success) {
        _reviews.insert(0, response.data!);
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = ErrorMessages.genericError;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Respond to review
  Future<bool> respondToReview({
    required String reviewId,
    required String response,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final apiResponse = await _reviewService.updateReview(
        id: reviewId,
        providerResponse: response,
      );

      if (apiResponse.success) {
        // Update local list
        final index = _reviews.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          _reviews[index] = apiResponse.data!;
        }
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = apiResponse.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = ErrorMessages.genericError;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset
  void reset() {
    _reviews = [];
    _ratingSummary = null;
    _isLoading = false;
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
