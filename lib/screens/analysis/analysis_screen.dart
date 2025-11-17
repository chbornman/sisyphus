import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/spacing.dart';
import 'widgets/heatmap_widget.dart';
import 'widgets/moments_carousel.dart';
import 'widgets/moments_controls.dart';
import 'widgets/section_header.dart';
import 'widgets/time_filter.dart';

/// Analysis screen - Heatmap and insights view
/// Visualizes happiness patterns and highlights top/bottom moments
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  // Moments toggle (true = top moments, false = bottom moments)
  bool _showTopMoments = true;

  // Time filter for memorable moments
  TimeFilter _selectedTimeFilter = TimeFilter.pastMonth;

  // Carousel auto-advance
  late PageController _pageController;
  Timer? _carouselTimer;
  int _currentCarouselPage = 0;

  // Heatmap scroll controller
  late ScrollController _heatmapScrollController;
  bool _hasScrolledToToday = false;

  @override
  void initState() {
    super.initState();
    // Start in the middle of a large virtual page count for infinite scroll effect
    _pageController = PageController(initialPage: 5000);
    _currentCarouselPage = 5000;
    _heatmapScrollController = ScrollController();
    _startCarouselAutoAdvance();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _heatmapScrollController.dispose();
    super.dispose();
  }

  /// Start carousel auto-advance timer (every 5 seconds)
  void _startCarouselAutoAdvance() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        if (_pageController.hasClients) {
          // Simply advance to next page - infinite scroll handles wrap-around smoothly
          final nextPage = _currentCarouselPage + 1;

          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          setState(() {
            _currentCarouselPage = nextPage;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        // Stronger tinted background with accent color
        backgroundColor: Color.alphaBlend(
          theme.colorScheme.primary.withValues(alpha: 0.08),
          theme.colorScheme.surface,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heatmap section
            const SectionHeader(title: 'Happiness Patterns'),
            SizedBox(height: AppSpacing.spacing3),
            HeatmapWidget(
              scrollController: _heatmapScrollController,
              hasScrolledToToday: _hasScrolledToToday,
              onScrollComplete: () {
                _hasScrolledToToday = true;
              },
            ),
            SizedBox(height: AppSpacing.spacing2),

            // Moments carousel section
            const SectionHeader(title: 'Memorable Moments'),
            SizedBox(height: AppSpacing.spacing3),
            MomentsCarousel(
              showTopMoments: _showTopMoments,
              selectedTimeFilter: _selectedTimeFilter,
              pageController: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentCarouselPage = index;
                });
              },
            ),
            SizedBox(height: AppSpacing.spacing3),
            MomentsControls(
              showTopMoments: _showTopMoments,
              selectedTimeFilter: _selectedTimeFilter,
              onMomentsToggleChanged: (value) {
                setState(() {
                  _showTopMoments = value;
                });
              },
              onTimeFilterChanged: (filter) {
                setState(() {
                  _selectedTimeFilter = filter;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
