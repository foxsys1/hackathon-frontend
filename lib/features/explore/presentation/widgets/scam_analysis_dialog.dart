import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kos_gdgoc/core/network/api_service.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';
import 'package:kos_gdgoc/features/explore/data/models/scam_analysis_dto.dart';
import 'package:kos_gdgoc/features/explore/domain/kos_detail.dart';

class ScamAnalysisDialog extends ConsumerStatefulWidget {
  const ScamAnalysisDialog({super.key, required this.kosId, required this.detail});
  final String kosId;
  final KosDetail detail;

  @override
  ConsumerState<ScamAnalysisDialog> createState() => _ScamAnalysisDialogState();
}

class _ScamAnalysisDialogState extends ConsumerState<ScamAnalysisDialog> {
  bool _isLoading = true;
  ScamAnalysisDto? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyzeScam();
  }

  Future<void> _analyzeScam() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final facilities = [...widget.detail.roomFacilities, ...widget.detail.sharedFacilities];
      final response = await apiService.analyzeReviews(
        kosId: widget.kosId,
        facilities: facilities,
        price: widget.detail.pricePerMonth,
      );
      if (mounted) {
        setState(() {
          _result = ScamAnalysisDto.fromJson(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_isLoading) ...[
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'AI sedang melakukan Cross-Examination...',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ] else if (_error != null) ...[
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Gagal: $_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              )
            ] else if (_result != null) ...[
              Icon(
                _result!.isScamSuspected ? Icons.warning_rounded : Icons.verified_user_rounded,
                color: _result!.isScamSuspected ? Colors.red : Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _result!.isScamSuspected ? 'Indikasi Scam Ditemukan!' : 'Kos Aman dari Scam',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _result!.isScamSuspected ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _result!.reason,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _result!.isScamSuspected ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
