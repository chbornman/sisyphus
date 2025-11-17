/// Time filter options for memorable moments
enum TimeFilter {
  pastWeek(7, 'Past Week'),
  pastMonth(30, 'Past Month'),
  pastYear(365, 'Past Year');

  final int days;
  final String label;
  const TimeFilter(this.days, this.label);
}
