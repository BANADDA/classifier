import 'package:classifier/models/PredictionDatabaseHelper.dart';

class Prediction {
  int? id;
  String imagePath;
  String prediction;
  List<String> symptoms;
  List<String> remedies;
  String date;

  Prediction({
    this.id,
    required this.imagePath,
    required this.prediction,
    required this.symptoms,
    required this.remedies,
    required this.date,
  });

  Future<void> save() async {
    final Map<String, dynamic> predictionMap = toMap();
    id =
        await PredictionDatabaseHelper.instance.insertPrediction(predictionMap);
  }

  static Future<List<Prediction>> retrieveAll() async {
    final List<Map<String, dynamic>> predictionMaps =
        await PredictionDatabaseHelper.instance.queryAllPredictions();
    return predictionMaps.map((map) => fromMap(map)).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'prediction': prediction,
      'symptoms': symptoms.join(','), // Convert list to comma-separated string
      'remedies': remedies.join(','), // Convert list to comma-separated string
      'date': date,
    };
  }

  static Prediction fromMap(Map<String, dynamic> map) {
    return Prediction(
      id: map['id'],
      imagePath: map['imagePath'],
      prediction: map['prediction'],
      symptoms:
          map['symptoms'].split(','), // Convert comma-separated string to list
      remedies:
          map['remedies'].split(','), // Convert comma-separated string to list
      date: map['date'],
    );
  }
}
