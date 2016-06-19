library user;

import 'dart:math';

/*
  This class holds all information about a stored user
 */
class User {
  String type;
  String id;
  String name;
  String password;
  String timestamp;
  String signature;
  String mail;

  String get getName => this.name;

  String get getPassword => this.password;

  /*
    Constructor
   */
  User(String name, String password, [String mail]) {
    this.type = "User";
    this.id = new Random.secure().nextDouble().toString();
    this.name = name;
    this.password = password;
    this.timestamp = new DateTime.now().toUtc().toIso8601String();
    this.signature = "$id$password".hashCode.toString();
    if (mail != null) {
      this.mail = mail;
    } else {
      this.mail = "";
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
      "pwd":"$password",
      "created":"$timestamp",
      "signature":"$signature"};
  }

  /*
    Representation as a string
   */
  String toString(){
    return '{"type":"$type","name":"$name","id":"$id","pwd":"$password","created":"$timestamp","signature":"$signature"}';
  }
}