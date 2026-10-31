import 'package:in_app_review/in_app_review.dart';

import '../../../core/constants/app_links.dart';

/// Thin seam over the store review APIs so the prompt logic can be tested
/// without Google Play.
abstract interface class ReviewGateway {
  /// Whether the native in-app review sheet can be shown on this device.
  Future<bool> isAvailable();

  Future<void> requestReview();

  /// Opens the app's store page, where the user can write a review.
  Future<void> openStoreListing();
}

class InAppReviewGateway implements ReviewGateway {
  const InAppReviewGateway();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();

  @override
  Future<void> openStoreListing() => InAppReview.instance.openStoreListing(
        appStoreId: AppLinks.appStoreId.isEmpty ? null : AppLinks.appStoreId,
      );
}
