String formatDuration(Duration duration) {
  if (duration.isNegative) {
    // Or handle negative durations differently, e.g., throw an error or return "-MM:SS"
    return "N/A";
  }

  String twoDigits(int n) => n.toString().padLeft(2, '0');

  final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  final String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

  if (duration.inHours > 0) {
    return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
  } else {
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
