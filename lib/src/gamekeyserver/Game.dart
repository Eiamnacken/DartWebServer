library game;
import 'dart:math';

/*
  This Class holds all information about a stored game
*/
class Game {
  String type;
  String id;
  String name;
  String timestamp;
  String signature;
  String uri;

  String get getName => this.name;

  String get getSecret => this.signature;

  /*
    Constructor
   */
  Game(String name, String secret, [String uri]) {
    this.type = "Game";
    this.id = new Random.secure().nextDouble().toString();
    this.name = name;
    this.timestamp = new DateTime.now().toUtc().toIso8601String();
    this.signature = "$name$secret".hashCode.toString();
    if (uri != null) {
      this.uri = uri;
    } else {
      this.uri = "";
    }
  }

  /*
    Representation as a map
   */
  Map toMap(){
    return {
      "type":"$type",
      "name":"$name",
      "id":"$id",
      "created":"$timestamp",
      "signature":"$signature"};
  }

  /*
    Representation as a string
   */
  String toString(){
    return '{"type":"$type","name":"$name","id":"$id","created":"$timestamp","signature":"$signature"}';
  }
}