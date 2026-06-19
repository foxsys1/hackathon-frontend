class ScamAnalysisDto {
  const ScamAnalysisDto({
    required this.isScamSuspected,
    required this.reason,
  });

  final bool isScamSuspected;
  final String reason;

  factory ScamAnalysisDto.fromJson(Map<String, dynamic> json) {
    return ScamAnalysisDto(
      isScamSuspected: json['is_scam_suspected'] as bool? ?? false,
      reason: json['reason'] as String? ?? '',
    );
  }
}
