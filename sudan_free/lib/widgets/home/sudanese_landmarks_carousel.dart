import 'package:flutter/material.dart';

class SudaneseLandmarksCarousel extends StatefulWidget {
  const SudaneseLandmarksCarousel({super.key});

  @override
  State<SudaneseLandmarksCarousel> createState() =>
      _SudaneseLandmarksCarouselState();
}

class _SudaneseLandmarksCarouselState extends State<SudaneseLandmarksCarousel> {
  final List<String> _images = [
    'assets/images/landmarks/meroe_pyramids.png',
    'assets/images/landmarks/corinthia_hotel.png',
    'assets/images/landmarks/sudan_desert.png',
    'assets/images/landmarks/nile_river.png',
    'assets/images/landmarks/custom_landmark_3.jpg',
    'assets/images/landmarks/custom_landmark_4.jpg',
    'assets/images/landmarks/custom_landmark_5.jpg',
    'assets/images/landmarks/custom_landmark_6.jpg',
    'assets/images/landmarks/custom_landmark_7.jpg',
    'assets/images/landmarks/custom_landmark_8.jpg',
    'assets/images/landmarks/custom_landmark_9.jpg',
  ];

  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _images.isEmpty ? 0 : (DateTime.now().millisecondsSinceEpoch % _images.length);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          _images[_currentIndex],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.4),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
