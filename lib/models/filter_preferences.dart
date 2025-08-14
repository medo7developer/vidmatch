class FilterPreferences {
  final bool filterByGender;
  final String preferredGender;
  final bool filterByCountry;
  final String preferredCountry;
  final bool useVideoFilters;
  final String activeFilter;

  FilterPreferences({
    this.filterByGender = false,
    this.preferredGender = 'الكل',
    this.filterByCountry = false,
    this.preferredCountry = 'الكل',
    this.useVideoFilters = false,
    this.activeFilter = 'none',
  });

  factory FilterPreferences.fromMap(Map<String, dynamic> map) {
    return FilterPreferences(
      filterByGender: map['filterByGender'] ?? false,
      preferredGender: map['preferredGender'] ?? 'الكل',
      filterByCountry: map['filterByCountry'] ?? false,
      preferredCountry: map['preferredCountry'] ?? 'الكل',
      useVideoFilters: map['useVideoFilters'] ?? false,
      activeFilter: map['activeFilter'] ?? 'none',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'filterByGender': filterByGender,
      'preferredGender': preferredGender,
      'filterByCountry': filterByCountry,
      'preferredCountry': preferredCountry,
      'useVideoFilters': useVideoFilters,
      'activeFilter': activeFilter,
    };
  }

  FilterPreferences copyWith({
    bool? filterByGender,
    String? preferredGender,
    bool? filterByCountry,
    String? preferredCountry,
    bool? useVideoFilters,
    String? activeFilter,
  }) {
    return FilterPreferences(
      filterByGender: filterByGender ?? this.filterByGender,
      preferredGender: preferredGender ?? this.preferredGender,
      filterByCountry: filterByCountry ?? this.filterByCountry,
      preferredCountry: preferredCountry ?? this.preferredCountry,
      useVideoFilters: useVideoFilters ?? this.useVideoFilters,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}
