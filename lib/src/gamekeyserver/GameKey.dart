import 'dart:async';
import 'dart:io';
import 'dart:convert';


/**
 *  Implementation of the client connection to the GameKey Server
 *
 */

/*
  Contains the GameKey REST API for BrickGame
 */
class GameKey{

  //Uri of the GameKey Service
  Uri _uri;

  //Id of the Game
  //need to set after registration with kratzkes server
  String _gameid = "92d5e770-ff13-46dd-9d4c-09fb300bc240";

  //Secret of the game, need to authenticate the current game with the GameKey service
  String _secret = "DontWorryAboutaThing";

  //Name of the Game
  String _nameofGame = "BrickGame";

 /*
    Uri of GameKey REST API
  */
  Uri get uri => this._uri;

  /*
    Game ID of the current Game
   */
  String get getGameId => this._gameid;

  /*
    Game secret of the current Game
   */
  String get getSecret => this._secret;

  /*
    Helper method to generate parameter body for REST requests
   */
  static String parameter(Map<String, String> p) => (new Uri(queryParameters: p)).query;

  //Constructor
  GameKey(String host, int port){
    _uri = new Uri.http("$host:$port","/");
  }

  /*
    Registers a non existing game with the GameKey service
    Returns a map with the new registered game on succes
    Return null on failure
   */
  Future<Map> registerGame(String secret, String name) async{
    final Map newGame = {
      "name":"$name",
      "secret":"$secret",
    };
    try {
      final client = await new HttpClient().post(uri.host, uri.port, "/game");
      client.write(parameter(newGame));
      HttpClientResponse response = await client.close();
      final body = await response.transform(UTF8.decoder).join("\n");
      return response.statusCode == 200 ? JSON.decode(body) : body;
    } catch (error) {
      print("GameKey.registerGame() caused an error: '$error'");
      return null;
    }
  }

  /*
    Registers a non existing user with the GameKey service
    Returns a map with the new registered users on succes
    Returns null on failure
   */
  Future<Map> registerUser(String name, String password) async{
    final Map newUser = {
      "name":"$name",
      "pwd":"$password",
    };
    try {
      final client = await new HttpClient().post(uri.host, uri.port, "/user");
      client.write(parameter(newUser));
      HttpClientResponse response = await client.close();
      final body = await response.transform(UTF8.decoder).join("\n");
      return response.statusCode == 200 ? JSON.decode(body) : body;
    } catch (error) {
      print("GameKey.registerUser() caused an error: '$error'");
      return null;
    }
  }

  /*
    Returns a map with all information about the given user on succes
    Returns null on failure
   */
  Future<Map> getUser(String name, String password) async{
    final link = uri.resolve("/user/$name").resolveUri(new Uri(queryParameters:{'id':"$name",'pwd' : "$password",'byname':"true"}));
    try {
      final client = await new HttpClient().getUrl(link);
      HttpClientResponse response = await client.close();
      var body = await response.transform(UTF8.decoder).join("\n");
      //body = body.replaceAll(new RegExp('\c_'),"");
      body = body.replaceAll("\r","");
      body = body.replaceAll("\n","");
      return response.statusCode == 200 ? JSON.decode(body) : null;
    } catch (error) {
      print("GameKey.getUser() caused an error: '$error'");
      return null;
    }
  }

  /*
    This method can be used to authenticate the current game
    and to check weather the gamekey service
    is available or not
   */
  Future<bool> authenticate() async{
    final link = uri.resolve("/gamestate/$getGameId").resolveUri(new Uri(queryParameters:{'secret':"$getSecret"}));
    try {
      final client = await new HttpClient().getUrl(link);
      HttpClientResponse response = await client.close();
      return response.statusCode == 200 ? true : false;
    } catch (error) {
      print("GameKey.authenticate() caused an error: '$error");
      return false;
    }
  }

  /*
    Returns the user id of the given name
    Returns null on failure
   */
  Future<String> getUserId(String name) async{
    try {
      final listusers = await listUsers();
      if (listusers == null) return null;
      final user = listusers.firstWhere((user) => user['name'] == name, orElse : null );
      return user == null ? null :user['id'];
    } catch (error) {
      print("GameKey.getUserId() caused an error: '$error'");
      return null;
    }
  }

  /*
    Returns a JSON list with all registered users with the GameKey service
    Returns null on failure
   */
  Future<List<Map>> listUsers() async{
    try {
      final client = await new HttpClient().get(uri.host, uri.port, "/users");
      HttpClientResponse response = await client.close();
      var body = await response.transform(UTF8.decoder).join("\n");
      //body = body.replaceAll(new RegExp('\c_'),"");
      body = body.replaceAll("\r","");
      body = body.replaceAll("\n","");
      return response.statusCode == 200 ? JSON.decode(body) : null;
    } catch (error) {
      print("GameKey.listUsers() caused an error: '$error'");
      return null;
    }
  }

  /*
    Returns a JSON list with all registered games with the GameKey service
    Returns null on failure
   */
  Future<List<Map>> listGames() async{
    try {
      final client = await new HttpClient().get(uri.host, uri.port, "/games");
      HttpClientResponse response = await client.close();
      var body = await response.transform(UTF8.decoder).join("\n");
      //body = body.replaceAll(new RegExp('\c_'),"");
      body = body.replaceAll("\r","");
      body = body.replaceAll("\n","");
      return response.statusCode == 200 ? JSON.decode(body) : null;
    } catch (error) {
      print("GameKey.listGames() caused an error: '$error'");
      return null;
    }
  }

  /*
    Returns a JSON list with all stored states for this game
    Returns null if no game states exist for this game
   */
  Future<List<Map>> getStates() async{
    final link = uri.resolve("/gamestate/$getGameId").resolveUri(new Uri(queryParameters:{'secret':"$getSecret"}));
    try {
      final client = await new HttpClient().getUrl(link);
      HttpClientResponse response = await client.close();
      var body = await response.transform(UTF8.decoder).join("\n");
      //body = body.replaceAll(new RegExp('\c_'),"");
      //body = body.replaceAll("\r","");
      //body = body.replaceAll("\n","");
      //the empty body.length is 4
      //it doesn't work with body.isEmpty or body.length != null etc
      if (body.length>4) return JSON.decode(body);
      return null;
    } catch (error) {
      print("GameKey.getStates() caused an error: '$error'");
      return null;
    }
  }

  /*
    Returns a JSON list with the saved states of this user
   */
  Future<bool> storeState(String id, Map state) async{
    final link = uri.resolve("/gamestate/$getGameId/$id").resolveUri(new Uri(queryParameters:{'secret':"$getSecret",
      'state':"${JSON.encode(state)}"}));
    try {
      final client = await new HttpClient().postUrl(link);
      HttpClientResponse response = await client.close();
      var body = await response.transform(UTF8.decoder).join("\n");
      return response.statusCode == 200 ? true : false;
    } catch (error) {
      print("GameKey.storeState() caught an error: '$error'");
      return false;
    }
  }
}