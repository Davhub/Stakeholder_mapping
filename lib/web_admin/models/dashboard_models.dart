/// Model for Dashboard KPI metrics
class DashboardKPIs {
  final int totalStakeholders;
  final int totalLGAs;
  final int totalWards;
  final int recentlyAdded;
  final double? growthPercentage;

  DashboardKPIs({
    required this.totalStakeholders,
    required this.totalLGAs,
    required this.totalWards,
    required this.recentlyAdded,
    this.growthPercentage,
  });

  factory DashboardKPIs.empty() {
    return DashboardKPIs(
      totalStakeholders: 0,
      totalLGAs: 0,
      totalWards: 0,
      recentlyAdded: 0,
      growthPercentage: null,
    );
  }
}

/// Model for chart data points
class ChartDataPoint {
  final String label;
  final int value;
  final String? sublabel;

  ChartDataPoint({
    required this.label,
    required this.value,
    this.sublabel,
  });
}

/// Model for time series data
class TimeSeriesDataPoint {
  final DateTime date;
  final int value;

  TimeSeriesDataPoint({
    required this.date,
    required this.value,
  });
}

/// Model for pagination state
class PaginationState {
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final int totalItems;

  PaginationState({
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.totalItems,
  });

  factory PaginationState.initial() {
    return PaginationState(
      currentPage: 1,
      totalPages: 1,
      itemsPerPage: 50,
      totalItems: 0,
    );
  }
}

/// Model for table filter state
class TableFilterState {
  final String? lgaFilter;
  final String? wardFilter;
  final String searchQuery;
  final String sortBy;
  final bool ascending;

  TableFilterState({
    this.lgaFilter,
    this.wardFilter,
    this.searchQuery = '',
    this.sortBy = 'fullName',
    this.ascending = true,
  });

  TableFilterState copyWith({
    String? lgaFilter,
    String? wardFilter,
    String? searchQuery,
    String? sortBy,
    bool? ascending,
  }) {
    return TableFilterState(
      lgaFilter: lgaFilter ?? this.lgaFilter,
      wardFilter: wardFilter ?? this.wardFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }

  bool get hasFilters =>
      (lgaFilter != null && lgaFilter!.isNotEmpty) ||
      (wardFilter != null && wardFilter!.isNotEmpty) ||
      searchQuery.isNotEmpty;
}
