import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/localized_digits.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/stay_range.dart';

/// Inline month-by-month range calendar (`16 · Stay dates & available rooms`).
///
/// Matches the reference: centered month/year headings, short weekday names, a
/// continuous blush band across the selected range with filled circular
/// endpoints, and a soft ring on "today". [monthCount] months forward from
/// [firstDay]; selection is driven by [onSelectDay] taps.
class StayRangeCalendar extends StatelessWidget {
  const StayRangeCalendar({
    super.key,
    required this.firstDay,
    required this.checkIn,
    required this.checkOut,
    required this.onSelectDay,
    this.today,
    this.monthCount = 4,
  });

  final DateTime firstDay;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final ValueChanged<DateTime> onSelectDay;
  final DateTime? today;
  final int monthCount;

  @override
  Widget build(BuildContext context) {
    final DateTime start = DateTime(firstDay.year, firstDay.month);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _WeekdayHeader(),
        const SizedBox(height: AppSpacing.sm),
        for (int i = 0; i < monthCount; i++) ...<Widget>[
          _MonthGrid(
            month: DateTime(start.year, start.month + i),
            firstSelectableDay: dateOnly(firstDay),
            checkIn: checkIn,
            checkOut: checkOut,
            today: today == null ? null : dateOnly(today!),
            onSelectDay: onSelectDay,
          ),
          if (i != monthCount - 1) const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }
}

List<int> _weekdayOrder(BuildContext context) {
  final int first = MaterialLocalizations.of(context).firstDayOfWeekIndex;
  return <int>[for (int i = 0; i < 7; i++) (first + i) % 7];
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> names = context.l10n.calendarWeekdays.split(',');
    return Row(
      children: <Widget>[
        for (final int weekday in _weekdayOrder(context))
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Text(names[weekday], style: theme.textTheme.bodySmall),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.firstSelectableDay,
    required this.checkIn,
    required this.checkOut,
    required this.today,
    required this.onSelectDay,
  });

  final DateTime month;
  final DateTime firstSelectableDay;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final DateTime? today;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations ml = MaterialLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    final int daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final List<int> order = _weekdayOrder(context);
    final int firstWeekday = DateTime(month.year, month.month).weekday % 7;
    final int leadingBlanks = order.indexOf(firstWeekday);

    final List<Widget> cells = <Widget>[
      for (int i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
      for (int day = 1; day <= daysInMonth; day++)
        _DayCell(
          date: DateTime(month.year, month.month, day),
          firstSelectableDay: firstSelectableDay,
          checkIn: checkIn,
          checkOut: checkOut,
          today: today,
          onSelectDay: onSelectDay,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Text(
            ml.formatMonthYear(month),
            style: theme.textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.xs,
          childAspectRatio: 1.0,
          children: cells,
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.firstSelectableDay,
    required this.checkIn,
    required this.checkOut,
    required this.today,
    required this.onSelectDay,
  });

  final DateTime date;
  final DateTime firstSelectableDay;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final DateTime? today;
  final ValueChanged<DateTime> onSelectDay;

  static const double _circle = 36;

  bool get _isDisabled => date.isBefore(firstSelectableDay);
  bool _isSame(DateTime? other) =>
      other != null && DateUtils.isSameDay(date, other);
  bool get _isCheckIn => _isSame(checkIn);
  bool get _isCheckOut => _isSame(checkOut);
  bool get _isEndpoint => _isCheckIn || _isCheckOut;
  bool get _hasRange => checkIn != null && checkOut != null;
  bool get _inRange =>
      _hasRange && date.isAfter(checkIn!) && date.isBefore(checkOut!);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MaterialLocalizations ml = MaterialLocalizations.of(context);
    // A soft warm band connecting the two endpoints (the "range" fill).
    final Color band = theme.colorScheme.primary.withValues(alpha: 0.16);

    // Band halves. Dates increase toward the row's `end` (GridView fills in
    // reading order), so check-in bleeds toward `end` and check-out toward
    // `start`.
    final bool fillStartHalf = _inRange || (_isCheckOut && _hasRange);
    final bool fillEndHalf = _inRange || (_isCheckIn && _hasRange);

    final Color foreground = _isEndpoint
        ? theme.colorScheme.onPrimary
        : _isDisabled
        ? theme.disabledColor
        : theme.colorScheme.onSurface;

    return InkWell(
      onTap: _isDisabled ? null : () => onSelectDay(date),
      child: Semantics(
        selected: _isEndpoint,
        label: ml.formatFullDate(date),
        button: !_isDisabled,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // The band is as tall as the endpoint circles and centred, so it
            // reads as one continuous strip joining them. `stretch` matters:
            // childless ColoredBoxes would otherwise collapse to 0px tall.
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  height: _circle,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        child: ColoredBox(
                          color: fillStartHalf ? band : Colors.transparent,
                        ),
                      ),
                      Expanded(
                        child: ColoredBox(
                          color: fillEndHalf ? band : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isEndpoint)
              Container(
                width: _circle,
                height: _circle,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            else if (_isSame(today))
              Container(
                width: _circle,
                height: _circle,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.outline),
                ),
              ),
            Text(
              context.digits(date.day),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: _isEndpoint ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
