import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SearchAnimationWidget extends StatelessWidget {
  final int usersCount;
  final bool hasActiveFilters;

  const SearchAnimationWidget({
    Key? key,
    required this.usersCount,
    required this.hasActiveFilters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // أنيميشن الدوائر المتحركة
        Stack(
          alignment: Alignment.center,
          children: [
            // الدائرة الخارجية
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.3, 1.3),
              duration: 2000.ms,
              curve: Curves.easeInOut,
            )
                .fadeOut(begin: 0.3),

            // الدائرة الوسطى
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.2, 1.2),
              duration: 1500.ms,
              curve: Curves.easeInOut,
            )
                .fadeOut(begin: 0.5),

            // الدائرة الداخلية مع الأيقونة
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.search,
                color: Colors.white,
                size: 30,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .rotate(duration: 3000.ms)
                .then()
                .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.1, 1.1),
              duration: 1000.ms,
              curve: Curves.easeInOut,
            )
                .then()
                .scale(
              begin: const Offset(1.1, 1.1),
              end: const Offset(1.0, 1.0),
              duration: 1000.ms,
              curve: Curves.easeInOut,
            ),
          ],
        ),

        const SizedBox(height: 30),

        // النص المتحرك
        Text(
          'جاري البحث عن مستخدمين',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .fadeIn(duration: 800.ms)
            .then(delay: 1000.ms)
            .fadeOut(duration: 800.ms)
            .then(delay: 500.ms),

        const SizedBox(height: 20),

        // النقاط المتحركة
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) =>
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .fadeIn(
                delay: (index * 200).ms,
                duration: 600.ms,
              )
                  .then()
                  .fadeOut(duration: 600.ms)
          ),
        ),

        const SizedBox(height: 30),

        // معلومات الانتظار
        _buildWaitingInfo(),

        // الفلاتر النشطة
        if (hasActiveFilters)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: _buildActiveFiltersCard(),
          ),
      ],
    );
  }

  Widget _buildWaitingInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'المستخدمون في الانتظار: $usersCount',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
      duration: 2000.ms,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildActiveFiltersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list_rounded,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'الفلاتر نشطة',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'قد يؤدي استخدام الفلاتر إلى زيادة وقت الانتظار',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms)
        .slideY(begin: 0.3, end: 0);
  }
}
