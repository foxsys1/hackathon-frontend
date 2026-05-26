import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:kos_gdgoc/core/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroSection(onAnalyze: () => context.push('/analyze')),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Kenapa perlu cek risiko?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _InfoCardGrid(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onAnalyze});
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // House background illustration
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.25, 0.7, 1.0],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: Opacity(
                    opacity: 0.45,
                    child: SvgPicture.asset(
                      'assets/icons/house_bg.svg',
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
            ),
            // Foreground content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/koscheck_logo.svg',
                        height: 24,
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 100),
                  const Text(
                    'Cek Risiko Kos\nSebelum Bayar DP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Jangan transfer dulu.\nAnalisis listing dari mana saja dan lihat indikator\nrisikonya.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onAnalyze,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_scanner, size: 20),
                      label: const Text(
                        'Analisis Risiko Sekarang',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCardGrid extends StatelessWidget {
  const _InfoCardGrid();

  static const _cards = [
    _CardData(
      icon: Icons.warning_amber_rounded,
      iconBgColor: Color(0xFFFEE2E2),
      iconColor: Color(0xFFEF4444),
      title: 'Cek Kelengkapan',
      subtitle: 'Alamat, foto, atau identitas pemilik belum lengkap.',
    ),
    _CardData(
      icon: Icons.shield_outlined,
      iconBgColor: Color(0xFFD1FAE5),
      iconColor: Color(0xFF10B981),
      title: 'DP Lebih Aman',
      subtitle: 'Pastikan semuanya jelas sebelum transfer.',
    ),
    _CardData(
      icon: Icons.trending_up_rounded,
      iconBgColor: Color(0xFFEDE9FE),
      iconColor: Color(0xFF7C3AED),
      title: 'Harga Wajar',
      subtitle: 'Bandingkan harga listing dengan rata-rata area.',
    ),
    _CardData(
      icon: Icons.chat_outlined,
      iconBgColor: Color(0xFFFEF3C7),
      iconColor: Color(0xFFD97706),
      title: 'Analisis Chat',
      subtitle: 'Deteksi pola komunikasi mencurigakan dari pemilik.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        final mainAxisExtent = (cardWidth * 1.15).clamp(150.0, 220.0);
        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: mainAxisExtent,
          ),
          itemCount: _cards.length,
          itemBuilder: (context, i) => _InfoCard(data: _cards[i]),
        );
      },
    );
  }
}

class _CardData {
  const _CardData({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.data});
  final _CardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            data.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              data.subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
