import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedCountry;
  String? _selectedGender;

  // تهيئة القيم الافتراضية في initState
  @override
  void initState() {
    super.initState();
    // سيتم تعيين القيم الافتراضية عند بناء الواجهة
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();

      authProvider.registerUser(
        name: _nameController.text.trim(),
        country: _selectedCountry!,
        gender: _selectedGender!,
      );

      // الانتقال إلى الشاشة الرئيسية
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // تعيين القيم الافتراضية عند بناء الواجهة إذا كانت فارغة (أول مرة)
    _selectedCountry ??= localizations.egypt;
    _selectedGender ??= localizations.male;

    // بناء قائمة الدول باستخدام الترجمات
    final Map<String, String> _countryMap = {
      'egypt': localizations.egypt,
      'saudiArabia': localizations.saudiArabia,
      'uae': localizations.uae,
      'kuwait': localizations.kuwait,
      'qatar': localizations.qatar,
      'bahrain': localizations.bahrain,
      'oman': localizations.oman,
      'jordan': localizations.jordan,
      'lebanon': localizations.lebanon,
      'syria': localizations.syria,
      'iraq': localizations.iraq,
      'palestine': localizations.palestine,
      'morocco': localizations.morocco,
      'algeria': localizations.algeria,
      'tunisia': localizations.tunisia,
      'libya': localizations.libya,
      'sudan': localizations.sudan,
      'somalia': localizations.somalia,
      'djibouti': localizations.djibouti,
      'comoros': localizations.comoros,
      'mauritania': localizations.mauritania,
      'yemen': localizations.yemen,
      'afghanistan': localizations.afghanistan,
      'albania': localizations.albania,
      'andorra': localizations.andorra,
      'angola': localizations.angola,
      'antiguaAndBarbuda': localizations.antiguaAndBarbuda,
      'argentina': localizations.argentina,
      'armenia': localizations.armenia,
      'australia': localizations.australia,
      'austria': localizations.austria,
      'azerbaijan': localizations.azerbaijan,
      'bahamas': localizations.bahamas,
      'bangladesh': localizations.bangladesh,
      'barbados': localizations.barbados,
      'belarus': localizations.belarus,
      'belgium': localizations.belgium,
      'belize': localizations.belize,
      'benin': localizations.benin,
      'bhutan': localizations.bhutan,
      'bolivia': localizations.bolivia,
      'bosniaAndHerzegovina': localizations.bosniaAndHerzegovina,
      'botswana': localizations.botswana,
      'brazil': localizations.brazil,
      'brunei': localizations.brunei,
      'bulgaria': localizations.bulgaria,
      'canada': localizations.canada,
      'china': localizations.china,
      'france': localizations.france,
      'germany': localizations.germany,
      'india': localizations.india,
      'indonesia': localizations.indonesia,
      'italy': localizations.italy,
      'japan': localizations.japan,
      'usa': localizations.usa,
      // يمكن إضافة المزيد من الدول هنا حسب الحاجة
    };

    // ترتيب الدول حسب ترتيب معين (الدول العربية أولاً)
    final List<String> arabCountries = [
      'egypt', 'saudiArabia', 'uae', 'kuwait', 'qatar', 'bahrain', 'oman',
      'jordan', 'lebanon', 'syria', 'iraq', 'palestine', 'morocco',
      'algeria', 'tunisia', 'libya', 'sudan', 'somalia', 'djibouti',
      'comoros', 'mauritania', 'yemen'
    ];

    final List<String> otherCountries = _countryMap.keys.where((key) => !arabCountries.contains(key)).toList();

    // ترتيب الدول: الدول العربية أولاً ثم باقي الدول
    final List<String> orderedCountryKeys = [...arabCountries, ...otherCountries];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_rounded,
                      size: 80,
                      color: Colors.white,
                    )
                        .animate()
                        .fade(duration: 800.ms)
                        .scale(delay: 300.ms),

                    const SizedBox(height: 24),

                    Text(
                      localizations.createNewAccount,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fade(delay: 400.ms, duration: 800.ms),

                    const SizedBox(height: 40),

                    // اسم المستخدم
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: localizations.name,
                          labelStyle: const TextStyle(color: Colors.white),
                          border: InputBorder.none,
                          icon: const Icon(Icons.person, color: Colors.white),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return localizations.pleaseEnterName;
                          }
                          return null;
                        },
                      ),
                    )
                        .animate()
                        .fade(delay: 600.ms, duration: 800.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 20),

                    // اختيار البلد
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: DropdownButtonFormField<String>(
                        value: _selectedCountry,
                        decoration: InputDecoration(
                          labelText: localizations.country,
                          labelStyle: const TextStyle(color: Colors.white),
                          border: InputBorder.none,
                          icon: const Icon(Icons.public, color: Colors.white),
                        ),
                        dropdownColor: Theme.of(context).colorScheme.primary,
                        style: const TextStyle(color: Colors.white),
                        items: orderedCountryKeys.map((String countryKey) {
                          return DropdownMenuItem<String>(
                            value: _countryMap[countryKey],
                            child: Text(_countryMap[countryKey] ?? countryKey),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCountry = newValue!;
                          });
                        },
                      ),
                    )
                        .animate()
                        .fade(delay: 800.ms, duration: 800.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 20),

                    // اختيار الجنس
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: localizations.gender,
                          labelStyle: const TextStyle(color: Colors.white),
                          border: InputBorder.none,
                          icon: const Icon(Icons.people, color: Colors.white),
                        ),
                        dropdownColor: Theme.of(context).colorScheme.primary,
                        style: const TextStyle(color: Colors.white),
                        items: [
                          DropdownMenuItem<String>(
                            value: localizations.male,
                            child: Text(localizations.male),
                          ),
                          DropdownMenuItem<String>(
                            value: localizations.female,
                            child: Text(localizations.female),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedGender = newValue!;
                          });
                        },
                      ),
                    )
                        .animate()
                        .fade(delay: 1000.ms, duration: 800.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 40),

                    // زر التسجيل
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        localizations.register,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                        .animate()
                        .fade(delay: 1200.ms, duration: 800.ms)
                        .slideY(begin: 0.3, end: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
