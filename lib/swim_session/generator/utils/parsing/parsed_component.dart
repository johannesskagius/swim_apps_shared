import 'package:swim_apps_shared/swim_apps_shared.dart';

class ParsedItemComponents {
  // Simplified from previous if description is removed
  final SwimWay swimWay;
  final Stroke? stroke;

  // String? description; // Optional if you decide to keep it

  ParsedItemComponents(this.swimWay, this.stroke /*, {this.description}*/);
}
