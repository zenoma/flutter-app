import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/JsonConversor.dart';
import 'package:http/http.dart' as http;

class JsonProvider extends ChangeNotifier {
  String imagePath;

  String getImagePath() {
    return imagePath;
  }

  void setImagePath(String imagePath) {
    this.imagePath = imagePath;
    notifyListeners();
  }

  Future<JsonConversor> sendPost() async {
    final response =
        await http.post("https://api.imagga.com/v2/croppings", headers: {
      HttpHeaders.authorizationHeader:
          "Basic YWNjXzE1MGQ4MGJmNGY4Y2VlYjo4OTM2NDZiYTk1YmI5MDE0OGMwN2RkY2U5MzlmNGM0MA=="
    }, body: {
      "image_base64": base64Encode(File(imagePath).readAsBytesSync()),
    });

    if (response.statusCode == 200) {
      return jsonConversorFromJson(response.body);
    }
    return null;
  }
}
