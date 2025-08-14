import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../models/filter_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FilterSettingsScreen extends StatefulWidget {
  const FilterSettingsScreen({Key? key}) : super(key: key);

  @override
  State<FilterSettingsScreen> createState() => _FilterSettingsScreenState();
}

class _FilterSettingsScreenState extends State<FilterSettingsScreen> {
  late bool _filterByGender;
  late String _preferredGender;
  late bool _filterByCountry;
  late String _preferredCountry;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final prefs = authProvider.filterPreferences;

    _filterByGender = prefs.filterByGender;
    _preferredGender = prefs.preferredGender;
    _filterByCountry = prefs.filterByCountry;
    _preferredCountry = prefs.preferredCountry;
  }

  void _saveFilters() {
    final authProvider = context.read<AuthProvider>();

    final newPrefs = FilterPreferences(
      filterByGender: _filterByGender,
      preferredGender: _preferredGender,
      filterByCountry: _filterByCountry,
      preferredCountry: _preferredCountry,
      useVideoFilters: authProvider.filterPreferences.useVideoFilters,
      activeFilter: authProvider.filterPreferences.activeFilter,
    );

    authProvider.updateFilterPreferences(newPrefs);

    // العودة إلى الشاشة السابقة
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // استخدام ترجمات التطبيق
    final localizations = AppLocalizations.of(context)!;

    // الحصول على قائمة البلدان والجنس المترجمة
    final List<String> _genders = [localizations.all, localizations.male, localizations.female];

    // قائمة البلدان المترجمة بناءً على الترجمات المتوفرة في ملف الترجمة
    final List<String> _countries = [
      localizations.all,
      localizations.india,
      localizations.usa,
      localizations.brazil,
      localizations.indonesia,
      localizations.russia,
      localizations.mexico,
      localizations.nigeria,
      localizations.turkey,
      localizations.pakistan,
      localizations.germany,
      localizations.bangladesh,
      localizations.philippines,
      localizations.france,
      localizations.united_states,
      localizations.italy,
      localizations.egypt,
      localizations.saudiArabia,
      localizations.uae,
      localizations.southAfrica,
      localizations.canada,
      localizations.spain,
      localizations.argentina,
      localizations.thailand,
      localizations.vietnam,
      localizations.colombia,
      localizations.iran,
      localizations.koreaSouth,
      localizations.ukraine,
      localizations.japan,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.filterSettings),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.userInfo,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  // فلترة حسب الجنس
                  SwitchListTile(
                    title: Text(localizations.filterByGender),
                    subtitle: Text(localizations.showUsersByGender),
                    value: _filterByGender,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (bool value) {
                      setState(() {
                        _filterByGender = value;
                      });
                    },
                  ),

                  if (_filterByGender)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom: 8,
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _preferredGender,
                        decoration: InputDecoration(
                          labelText: localizations.preferredGender,
                          border: const OutlineInputBorder(),
                        ),
                        items: _genders.map((String gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _preferredGender = newValue!;
                          });
                        },
                      ),
                    ),

                  const Divider(),

                  // فلترة حسب البلد
                  SwitchListTile(
                    title: Text(localizations.filterByCountry),
                    subtitle: Text(localizations.showUsersByCountry),
                    value: _filterByCountry,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (bool value) {
                      setState(() {
                        _filterByCountry = value;
                      });
                    },
                  ),

                  if (_filterByCountry)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom: 8,
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _preferredCountry,
                        decoration: InputDecoration(
                          labelText: localizations.preferredCountry,
                          border: const OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: _countries.map((String country) {
                          return DropdownMenuItem<String>(
                            value: country,
                            child: Text(country),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _preferredCountry = newValue!;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // نصائح للمستخدم
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.filterTips,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.filterTipsContent,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // زر حفظ الإعدادات
          ElevatedButton(
            onPressed: _saveFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              localizations.saveSettings,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
