part of ridemate_ai;

class SegmentedSwitch extends StatelessWidget {
  const SegmentedSwitch({
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<String> values;
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                child: TextButton(
                  onPressed: () => onChanged(values[i]),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    backgroundColor: selected == values[i]
                        ? AppColors.primary
                        : Colors.transparent,
                    foregroundColor:
                        selected == values[i] ? Colors.white : AppColors.muted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(labels[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
