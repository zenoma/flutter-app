import 'dart:convert';

JsonConversor jsonConversorFromJson(String str) =>
    JsonConversor.fromJson(json.decode(str));

String jsonConversorToJson(JsonConversor data) => json.encode(data.toJson());

class JsonConversor {
  JsonConversor({
    this.result,
    this.status,
  });

  Result result;
  Status status;

  factory JsonConversor.fromJson(Map<String, dynamic> json) => JsonConversor(
        result: Result.fromJson(json["result"]),
        status: Status.fromJson(json["status"]),
      );

  Map<String, dynamic> toJson() => {
        "result": result.toJson(),
        "status": status.toJson(),
      };
}

class Result {
  Result({
    this.croppings,
  });

  List<Cropping> croppings;

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        croppings: List<Cropping>.from(
            json["croppings"].map((x) => Cropping.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "croppings": List<dynamic>.from(croppings.map((x) => x.toJson())),
      };
}

class Cropping {
  Cropping({
    this.targetHeight,
    this.targetWidth,
    this.x1,
    this.x2,
    this.y1,
    this.y2,
  });

  int targetHeight;
  int targetWidth;
  int x1;
  int x2;
  int y1;
  int y2;

  factory Cropping.fromJson(Map<String, dynamic> json) => Cropping(
        targetHeight: json["target_height"],
        targetWidth: json["target_width"],
        x1: json["x1"],
        x2: json["x2"],
        y1: json["y1"],
        y2: json["y2"],
      );

  Map<String, dynamic> toJson() => {
        "target_height": targetHeight,
        "target_width": targetWidth,
        "x1": x1,
        "x2": x2,
        "y1": y1,
        "y2": y2,
      };
}

class Status {
  Status({
    this.text,
    this.type,
  });

  String text;
  String type;

  factory Status.fromJson(Map<String, dynamic> json) => Status(
        text: json["text"],
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "text": text,
        "type": type,
      };
}
