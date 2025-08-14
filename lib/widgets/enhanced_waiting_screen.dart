import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EnhancedWaitingScreen extends StatefulWidget {
  final int usersInWaitingRoom;
  final VoidCallback onCancel;
  final bool isFiltersEnabled;

  const EnhancedWaitingScreen({
    Key? key,
    required this.usersInWaitingRoom,
    required this.onCancel,
    this.isFiltersEnabled = false,
  }) : super(key: key);

  @override
  State<EnhancedWaitingScreen> createState() => _EnhancedWaitingScreenState();
}

class _EnhancedWaitingScreenState extends State<EnhancedWaitingScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _scaleController;
  late List<String> _waitingMessages;
  int _currentMessageIndex = 0;
  int _animationCycles = 0;
  final Random _random = Random();
  int _secondsElapsed = 0;
  late Timer _waitingTimer;

  @override
  void initState() {
    super.initState();

    // تهيئة رسائل الانتظار الجذابة
    _waitingMessages = [
      'جاري البحث عن شخص مميز للدردشة معك...',
      'نبحث عن أفضل مطابقة لك...',
      'سنجد لك محادثة رائعة قريباً...',
      'جاري تحضير محادثة مميزة...',
      'لحظات وستبدأ المحادثة...',
    ];

    // إنشاء وتشغيل المحرك الرسومي للدوران
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // إنشاء controller للتكبير والتصغير
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationCycles++;

        // تغيير الرسالة بعد كل دورتين من الرسوم المتحركة
        if (_animationCycles % 2 == 0) {
          setState(() {
            _currentMessageIndex = (_currentMessageIndex + 1) % _waitingMessages.length;
          });
        }

        _controller.reset();
        _controller.forward();
      }
    });

    // بدء التحريك المتكرر للـ scale
    _scaleController.repeat(reverse: true);
    _controller.forward();

    // إضافة مؤقت لعرض وقت الانتظار
    _waitingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  @override
  void dispose() {
    _waitingTimer.cancel();
    _controller.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // أضف هذه الدالة المساعدة لتنسيق الوقت
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.secondary,
            Colors.black,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // رسوم متحركة دائرية للانتظار مع التكبير والتصغير
          AnimatedBuilder(
            animation: Listenable.merge([_controller, _scaleController]),
            builder: (context, child) {
              double scale = 0.95 + (_scaleController.value * 0.1); // من 0.95 إلى 1.05

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // حلقة متحركة خارجية
                      Transform.rotate(
                        angle: _controller.value * 2 * pi,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.3, 0.6, 1.0],
                              startAngle: 0,
                              endAngle: 2 * pi,
                            ),
                          ),
                        ),
                      ),
                      // حلقة متحركة داخلية
                      Transform.rotate(
                        angle: -_controller.value * 2 * pi,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      // دائرة مركزية
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.sensors,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // رسالة الانتظار المتغيرة
          SizedBox(
            height: 60,
            child: Text(
              _waitingMessages[_currentMessageIndex],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ).animate(
              onPlay: (controller) => controller.repeat(),
            ).fadeIn(
              duration: 800.ms,
            ).then().fadeOut(
              delay: 2500.ms,
              duration: 700.ms,
            ),
          ),

          const SizedBox(height: 20),

          // عرض عدد المستخدمين في غرفة الانتظار
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.people,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'عدد المستخدمين النشطين: ${widget.usersInWaitingRoom}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // عرض وقت البحث
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              'وقت البحث: ${_formatDuration(_secondsElapsed)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // عرض معلومات عن الفلاتر النشطة
          if (widget.isFiltersEnabled)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.filter_list,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'الفلاتر نشطة - قد يزيد وقت الانتظار',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // نصائح عشوائية أثناء الانتظار
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'نصيحة للدردشة',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getRandomTip(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // زر إلغاء البحث
          ElevatedButton.icon(
            onPressed: widget.onCancel,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.close),
            label: const Text(
              'إلغاء البحث',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // نصائح عشوائية للعرض أثناء الانتظار
  String _getRandomTip() {
    final tips = [
      'ابدأ المحادثة بتحية ودية لكسر الجليد 👋',
      'احترام خصوصية الآخرين يجعل التجربة أفضل للجميع 🤝',
      'يمكنك استخدام فلاتر الفيديو لإضافة لمسة من المرح ✨',
      'إذا واجهت محتوى غير لائق، استخدم زر الإبلاغ 🚩',
      'كن نفسك واستمتع بالدردشة مع أشخاص جدد من حول العالم 🌍',
      'اضغط على زر التالي إذا أردت الانتقال لمحادثة جديدة ⏭',
      'يمكنك الضغط مرتين على الشاشة لتبديل الكاميرا الأمامية والخلفية 📱',
      'تذكر أن المحادثة الجيدة تبدأ بالاستماع الجيد 👂',
    ];

    return tips[_random.nextInt(tips.length)];
  }
}