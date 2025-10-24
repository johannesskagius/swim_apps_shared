// In your swim_session.dart or a common enums file
enum SessionSlot {
  morning('AM', 'Morning'),
  afternoon('PM', 'Evening'),
  undefined('', '');

  final String short;
  final String description;

  const SessionSlot(this.short, this.description);
}
