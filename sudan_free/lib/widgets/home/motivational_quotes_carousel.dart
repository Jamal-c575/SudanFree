import 'dart:async';
import 'package:flutter/material.dart';
import '../common/glass_container.dart';
import '../../providers/locale_provider.dart';
import 'package:provider/provider.dart';

class MotivationalQuotesCarousel extends StatefulWidget {
  const MotivationalQuotesCarousel({super.key});

  @override
  State<MotivationalQuotesCarousel> createState() =>
      _MotivationalQuotesCarouselState();
}

class _MotivationalQuotesCarouselState
    extends State<MotivationalQuotesCarousel> {
  final List<Map<String, String>> _quotes = [
    {
      'ar': 'الثقة هي العملة التي لا تفقد قيمتها أبداً، وبها نبني مجتمعنا',
      'en': 'Trust is the currency that never loses its value; with it we build our community'
    },
    {
      'ar': 'في سودان فري، كلمتك هي عقدك، والمصداقية هي رأس مالك',
      'en': 'In Sudan Free, your word is your contract, and credibility is your capital'
    },
    {
      'ar': 'الخوة بتبدأ بالثقة، والعمل الناجح بيكبر بالصدق',
      'en': 'Brotherhood begins with trust, and successful work grows with honesty'
    },
    {
      'ar': 'نبني جسوراً من الثقة، ليعبر عليها طموح شبابنا نحو النجاح',
      'en': 'We build bridges of trust for our youth\'s ambition to cross towards success'
    },
    {
      'ar': 'اليد الواحدة ما بتصفق، بس بالثقة والتعاون بنصنع المستحيل',
      'en': 'One hand doesn\'t clap, but with trust and cooperation, we make the impossible'
    },
    {
      'ar': 'سودان فري: حيث تلتقي الأصالة السودانية مع الاحترافية والمصداقية',
      'en': 'Sudan Free: Where Sudanese authenticity meets professionalism and credibility'
    },
    {
      'ar': 'سمعتك هي ظلك، تسبقك دائماً وتدوم بعدك، فاحرص عليها',
      'en': 'Your reputation is your shadow; it precedes you and outlasts you, so protect it'
    },
    {
      'ar': 'الجود بالموجود، والثقة بيناتنا بتزيد المردود',
      'en': 'Generosity is giving what you have, and trust between us increases the yield'
    },
    {
      'ar': 'المصداقية ليست مجرد خيار، بل هي الأساس الذي ننهض به معاً',
      'en': 'Credibility is not just an option; it\'s the foundation upon which we rise together'
    },
    {
      'ar': 'الزول السمح دايماً موثوق، وفي مجتمعنا بنجمع السمحين',
      'en': 'A good person is always trusted, and in our community, we bring good people together'
    },
    {
      'ar': 'تعاوننا يثمر حين نزرع الثقة، ونجني معاً أطيب الثمار',
      'en': 'Our cooperation bears fruit when we plant trust, reaping the best harvest together'
    },
    {
      'ar': 'سودان فري.. مساحة حرة، ميزانها الثقة، ووقودها شغفكم',
      'en': 'Sudan Free.. a free space, weighed by trust, fueled by your passion'
    },
    {
      'ar': 'الكلمة الطيبة مفتاح، والثقة بتفتح كل الأبواب المقفولة',
      'en': 'A kind word is a key, and trust opens all closed doors'
    },
    {
      'ar': 'في هذا المجتمع، كلنا شركاء في صناعة بيئة عمل آمنة وموثوقة',
      'en': 'In this community, we are all partners in creating a safe and reliable workspace'
    },
    {
      'ar': 'النية زاملة سيدا، وبالنوايا الصادقة نبني سودان الغد',
      'en': 'Intention guides its owner; with honest intentions, we build the Sudan of tomorrow'
    },
    {
      'ar': 'النجاح المشترك يبدأ بخطوة إيمان بقدرات بعضنا البعض',
      'en': 'Shared success begins with a step of faith in each other\'s abilities'
    },
    {
      'ar': 'أخلاقنا السودانية السمحة هي بوصلتنا نحو التفوق والتميز',
      'en': 'Our beautiful Sudanese morals are our compass towards excellence and distinction'
    },
    {
      'ar': 'الضامن هو الله، وثقتنا في بعضنا بتخلي الشغل أسهل وأبرك',
      'en': 'God is the guarantor, and our trust in each other makes work easier and more blessed'
    },
    {
      'ar': 'خليك واضح وصريح، تلقى دروب النجاح قدامك ممهدة',
      'en': 'Be clear and honest, and you will find the paths to success paved before you'
    },
    {
      'ar': 'نشيل هم بعض بصدق، عشان نصل كلنا للقمة بثقة وأمان',
      'en': 'We genuinely carry each other\'s burdens, to reach the top together in trust and safety'
    },
  ];

  static int _globalCurrentPage = -1;
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_globalCurrentPage == -1) {
      // Start at a random index when the app opens
      _globalCurrentPage = DateTime.now().millisecondsSinceEpoch % _quotes.length;
    }
    _pageController = PageController(initialPage: _globalCurrentPage);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 15), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = _globalCurrentPage + 1;
        if (nextPage >= _quotes.length) {
          nextPage = 0;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 1600),
            curve: Curves.fastOutSlowIn,
          );
        } else {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 1600),
            curve: Curves.fastOutSlowIn,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        context.watch<LocaleProvider>().locale.languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(30),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        enableBlur: true,
        blur: 10,
        child: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (int index) {
            setState(() {
              _globalCurrentPage = index;
            });
          },
          itemCount: _quotes.length,
          itemBuilder: (context, index) {
            return Center(
              child: Text(
                isArabic ? _quotes[index]['ar']! : _quotes[index]['en']!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
