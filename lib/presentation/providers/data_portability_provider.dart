import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/themes/data/models/app_payload_model.dart';

/// State representation for Data Portability & Sync workflows.
class DataPortabilityState {
  final AppPayloadModel? parsedImportPayload;
  final String? importErrorMessage;
  final String? exportSuccessMessage;
  final bool isProcessing;

  const DataPortabilityState({
    this.parsedImportPayload,
    this.importErrorMessage,
    this.exportSuccessMessage,
    this.isProcessing = false,
  });

  DataPortabilityState copyWith({
    AppPayloadModel? Function()? parsedImportPayload,
    String? Function()? importErrorMessage,
    String? Function()? exportSuccessMessage,
    bool? isProcessing,
  }) {
    return DataPortabilityState(
      parsedImportPayload: parsedImportPayload != null
          ? parsedImportPayload()
          : this.parsedImportPayload,
      importErrorMessage: importErrorMessage != null
          ? importErrorMessage()
          : this.importErrorMessage,
      exportSuccessMessage: exportSuccessMessage != null
          ? exportSuccessMessage()
          : this.exportSuccessMessage,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

/// Auto-disposing notifier orchestrating JSON export, import, and validation.
class DataPortabilityNotifier
    extends AutoDisposeNotifier<DataPortabilityState> {
  @override
  DataPortabilityState build() {
    return const DataPortabilityState();
  }

  void setExportSuccess(String message) {
    state = state.copyWith(
      exportSuccessMessage: () => message,
      importErrorMessage: () => null,
    );
  }

  void setImportError(String message) {
    state = state.copyWith(
      importErrorMessage: () => message,
      parsedImportPayload: () => null,
    );
  }

  void clearImportStatus() {
    state = state.copyWith(
      importErrorMessage: () => null,
      parsedImportPayload: () => null,
    );
  }

  void setParsedImportPayload(AppPayloadModel payload) {
    state = state.copyWith(
      parsedImportPayload: () => payload,
      importErrorMessage: () => null,
    );
  }

  void validateAndParseJson(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      clearImportStatus();
      return;
    }
    try {
      final payload = AppPayloadModel.fromRawJson(trimmed);
      setParsedImportPayload(payload);
    } catch (e) {
      setImportError('Invalid JSON database format: $e');
    }
  }

  void setProcessing(bool isProcessing) {
    state = state.copyWith(isProcessing: isProcessing);
  }
}

/// Provider exposing the reactive state for the Data Portability modal.
final dataPortabilityProvider =
    AutoDisposeNotifierProvider<DataPortabilityNotifier, DataPortabilityState>(
      DataPortabilityNotifier.new,
    );
