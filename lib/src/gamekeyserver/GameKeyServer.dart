import 'dart:io';
import 'dart:async';

//import 'dart:isolate';
import 'dart:convert' show UTF8, JSON;
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:core';

/**
 *  Implementation of GameKey Server REST API in Dart
 *  by Markus Krebs
 */

main() async {
  GameKeyServer apfel = await new GameKeyServer("127.0.0.1", 4000);
}
/*
  TOP-Level Method: handling the Isolates
  NOTE: Not in use because it is not possible to send a HttpRequest over to an Isolate
 */
/*
void handleIsolates(SendPort initialReplyTo){

  var port = new ReceivePort();
  initialReplyTo.send(port.sendPort);
  port.listen((msg) {
    var data = msg[0];
    SendPort replyTo = msg[1];
    replyTo.send(msg[1]);
    if (data == "close") { replyTo.send("closedreal");port.close(); }
  });

}
*/

/*
  This server handles the GameKey Service
 */
class GameKeyServer {

  //Holding the server
  HttpServer server;

  //Holding all registered user since register
  List textfileUsers;

  //Holding all registered games since register
  List textfileGames;

  //Holding all registered gamestates since register
  List textfileGamestates;

  //Holding the uri of the server
  Uri _uri;

  /*
    Returns the Uri of the server
   */
  Uri get getUri => this._uri;

  /*
    Returns a list with all registered User
   */
  List get gettextfileUsers => this.textfileUsers;

  /*
    Returns a list with all registered Games
   */
  List get gettextfileGames => this.textfileGames;

  /*
    Returns a list with all registered gamestsates
   */
  List get gettextfileGamestates => this.textfileGamestates;

  /*
    Constructor
    - read all registered user from textfile
    - read all registered games from textfile
    - read all registered gamestates from textfile
    - set up the server and waiting for clients
   */
  GameKeyServer(String host, int port) {
    this._uri = new Uri.http("$host:$port", "/");
    initServer(host, port);
    print("Server running on ... ${getUri.toString()}");
  }

  /*
    Read all registered users, games and gamestates from textfile
    - these textfiles have to exist in the root file of the project although
      they have to be in JSON format, at least "{}"
   */
  Future<bool> readConfig() async {
    try {
      final memoryuser = new File("memoryofallusers.json").readAsStringSync();
      final memorygames = new File("memoryofallgames.json").readAsStringSync();
      final memorygamestates = new File("memoryofallgamestates.json")
          .readAsStringSync();
      textfileUsers = JSON.decode(memoryuser);
      textfileGames = JSON.decode(memorygames);
      textfileGamestates = JSON.decode(memorygamestates);
      return true;
    } catch (error, stacktrace) {
      print("Config could not read. " + error);
      print(stacktrace);
      exit(1);
    }
  }

  /*
    Update all txt files with the new registered users, games and gamestates
    - i Which List was updated (0=user,1=games,2=gamestates)
   */
  Future<bool> updateConfig(int i) async {
    try {
      switch (i) {
        case 1:
          final writeuser = new File("memoryofallusers.json");
          writeuser.writeAsStringSync(JSON.encode(gettextfileUsers));
          return true;
        case 2:
          final writegames = new File("memoryofallgames.json");
          writegames.writeAsStringSync(JSON.encode(gettextfileGames));
          return true;
        case 3:
          final writegamestates = new File("memoryofallgamestates.json");
          writegamestates.writeAsStringSync(JSON.encode(gettextfileGamestates));
          return true;
      }
      return false;
    } catch (error, stacktrace) {
      print("Could not update the config.");
      print(error);
      print(stacktrace);
      return false;
    }
  }

  /*
    Method to initialize the server on the given host and port
    After initialization the server will listen on the same host and port for incoming requests
    After handling the request the config will be updated if necessary
   */
  initServer(String host, int port) async {
    if (await readConfig()) {
      print("Config loaded ...");
      print("All existing User: ${gettextfileUsers}");
      print("All existing Games: ${gettextfileGames}");
      print("All existing Gamestates: ${gettextfileGamestates}");
    }
    try {
      //binds the server on given host and port
      this.server = await HttpServer.bind(host, port);
      //the server waits for incoming requests to handle
      await for (var Httpreq in server) {
        enableCors(Httpreq.response);
        var isHandled = await handleMessages(Httpreq);
        switch (isHandled) {
          case 0 :
            break;
          case 1 :
            await updateConfig(1);
            break;
          case 2 :
            await updateConfig(2);
            break;
          case 3 :
            await updateConfig(3);
            break;
          case 4 :
            await updateConfig(1);
            await updateConfig(3);
            break;
          case 5 :
            await updateConfig(2);
            await updateConfig(3);
        }
        Httpreq.response.close();

        /*
        //var httpRequest = [Httpreq.method, Httpreq.headers.contentType,
        //                  Httpreq.headers.contentType.mimeType];
        //var test = Httpreq.toList();
        //print(test);
        //var response = new ReceivePort();
        //ReceivePort response = new ReceivePort();
        //port.send([msg, response.sendPort]);

        ///Isolates replace Threads in Dart
        Future<Isolate> remote = Isolate.spawn(
            handleIsolates, response.sendPort);
        remote.then((_) => response.first).then((sendPort) {
          sendReceive(sendPort, "close").then((msg) {
            print("received: $msg");
            return sendReceive(sendPort, "close");
          }).then((msg) {
            print("received another: $msg");
          });
        });
        */

      }
      await closeTheServer();
    } catch (error, stacktrace) {
      print("Server could not start.");
      print(error);
      print(stacktrace);
      exit(1);
    }
  }

  /*
    This method will send messages between the Isolates
   */
  /*
  Future sendReceive(SendPort port, msg) {
    ReceivePort response = new ReceivePort();
    port.send([msg, response.sendPort]);
    return response.first;
  }
  */

  /*
    Sets CORS headers for response
   */
  void enableCors(HttpResponse response) {
    response.headers.add(
        "Access-Control-Allow-Origin",
        "*"
    );
    response.headers.add(
        "Access-Control-Allow-Methods",
        "POST, GET, DELETE, PUT, OPTIONS"
    );
    response.headers.add(
        "Access-Control-Allow-Headers",
        "Origin, X-Requested-With, Content-Type, Accept, Charset"
    );
  }

  /*
    All incoming requests will be handled here
    //- called only by 'handleIsolates()'
    - return an int for which list was updatet : 0 no update,
      1 users was updated, 2 games was updated, 3 gamestates was updated,
      4 users and gamestates was updated, 5 games and gamestates was updated
   */
  Future<int> handleMessages(HttpRequest msg) async {
    try {
      //body of incomming message
      var msg1 = await msg.transform(UTF8.decoder).join();
      var parameter = await Uri
          .parse("?$msg1")
          .queryParameters;

      //which request is it ? ...

      //Request for create an user
      RegExp postuser = new RegExp("/user");
      if (msg.method == 'POST' && postuser.hasMatch(msg.requestedUri.path)) {
        final name = parameter["name"];
        final password = parameter["pwd"];
        final mail = parameter["mail"];
        if (name != null && name != "" && password != null && password != "") {
          Map newuser = await addUser(name, password, mail);
          if (newuser != null) {
            msg.response
              ..statusCode = 200
              ..write(JSON.encode(newuser));
            return 1;
          } else {
            msg.response
              ..statusCode = 409
              ..write("Some User might exist with that name.");
            return 0;
          }
        } else {
          msg.response
            ..statusCode = 400
            ..write("Name and password must be set.");
          return 0;
        }
      }

      //Request for get a user
      RegExp getuser = new RegExp(r'/user/(\d+)\/?');
      if (msg.method == 'GET' && getuser.hasMatch(msg.requestedUri.path)) {
        final id = msg.requestedUri.pathSegments[1];
        final password = parameter["pwd"];
        final checkbyname = parameter["byname"];
        if (checkbyname != null && checkbyname != "true" &&
            checkbyname != "false") {
          msg.response
            ..statusCode = 400
            ..write("Byname must be set [true|false|''].");
          return 1;
        }
        bool byname = false;
        if (parameter["byname"] == true)
          byname = true;
        if (id != null && password != null) {
          Map getuser = await getUser(id, password, byname);
          if (getuser != null) {
            if (getuser.length>0) {
              msg.response
                ..statusCode = 200
                ..write(JSON.encode(getuser));
              return 0;
            } else {
              msg.response
                ..statusCode = 401
                ..write("Authentication problem, check ID and Password.");
              return 0;
            }
          } else {
            msg.response
              ..statusCode = 401
              ..write("No existing user with that id.");
            return 0;
          }
        } else {
          msg.response
            ..statusCode = 401
            ..write("Name and Password must be set.");
          return 0;
        }
      }

      //Request for delete an user && all stored gamestates for this user
      RegExp removeuser = new RegExp(r'/user/(\d+)\/?');
      if (msg.method == 'DELETE' &&
          removeuser.hasMatch(msg.requestedUri.path)) {
        final password = parameter["pwd"];
        final id = msg.requestedUri.pathSegments[1];
        if (id != null && password != null) {
          bool remuser = await removeUser(id, password);
          if (remuser != null) {
            if (remuser) {
              msg.response
                ..statusCode = 200
                ..write("User with id=$id was removed");
              return 4;
            } else {
              msg.response
                ..statusCode = 401
                ..write(
                    "Authentication problem, please check ID and Password.");
              return 0;
            }
          } else {
            msg.response
              ..statusCode = 404
              ..write("No existing user with that id.");
            return 0;
          }
        } else {
          msg.response
            ..statusCode = 401
            ..write("ID and Password must be set.");
          return 0;
        }
      }

      //Request for get all users
      if (msg.method == 'GET' && (msg.requestedUri.path == '/users')) {
        await readConfig();
        msg.response
          ..statusCode = HttpStatus.OK
          ..write(JSON.encode(gettextfileUsers));
        return 0;
      }

      //Request for update an user
      RegExp updateuser = new RegExp(r'/user/(\d+)\/?');
      if (msg.method == 'PUT' && updateuser.hasMatch(msg.requestedUri.path)) {
        RegExp user = new RegExp(r'(\d+)\/?');
        final id = user.stringMatch(msg.requestedUri.path);
        final password = parameter["pwd"];
        final newpassword = parameter["newpwd"];
        final newname = parameter["name"];
        final newmail = parameter["mail"];
        Map updateduser = await updateUser(
            id, password, newname, newpassword, newmail);
        if (id != null && password != null) {
          if (updateduser != null) {
            if (updateduser.length > 0) {
              msg.response
                ..statusCode = 200
                ..write(JSON.encode(updateduser));
              return 1;
            } else {
              msg.response
                ..statusCode = 401
                ..write("Authentication problem, check ID and Password");
              return 0;
            }
          } else {
            msg.response
              ..statusCode = 404
              ..write("No existing user with that id.");
            return 0;
          }
        } else {
          msg.response
            ..statusCode = 401
            ..write("ID and Password must be set.");
          return 0;
        }
      }

      //Request for create a game
      if (msg.method == 'POST' && msg.uri.path == '/game') {
        final name = parameter["name"];
        final secret = parameter["secret"];
        final uri = parameter["uri"];
        if (name != null && secret != null) {
          Map newgame = await addGame(name, secret, uri);
          if (newgame != null) {
            msg.response
              ..statusCode = HttpStatus.OK
              ..write(JSON.encode(newgame));
            return 2;
          } else {
            msg.response
              ..statusCode = 409
              ..write("Some Game might exist with that name.");
            return 0;
          }
        } else {
          msg.response
            ..statusCode = 400
            ..write("Name and Secret must be set.");
          return 0;
        }
      }

      //Request for get a game
      RegExp getgame = new RegExp(r'/game/(\d+)\/?');
      if (msg.method == 'GET' && getgame.hasMatch(msg.requestedUri.path)) {
        final id = msg.requestedUri.pathSegments[1];
        final password = parameter["secret"];
        if (id != null && password != null) {
          Map getgame = await getGame(id, password);
          if (getgame != null) {
            if (getgame.length > 0) {
              msg.response
                ..statusCode = 200
                ..write(JSON.encode(getgame));
              return 0;
            } else {
              msg.response
                ..statusCode = 401
                ..write("Authentication problem, check ID and Password");
              return 0;
            }
          } else {
            msg.response
              ..statusCode = 404
              ..write("No existing game with that id.");
            return 0;
          }
        } else {
          msg.response
            ..statusCode = 401
            ..write("ID and Password must be set.");
          return 0;
        }
      }

      //Request for get all games
      if (msg.method == 'GET' && msg.uri.toString() == '/games') {
        await readConfig();
        msg.response
          ..statusCode = HttpStatus.OK
          ..write(JSON.encode(gettextfileGames));
        return 0;
      }

      //Request for update a game
      RegExp updategame = new RegExp(r'/game/(\d+)\/?');
      if (msg.method == 'PUT' && updategame.hasMatch(msg.requestedUri.path)) {
        final id = msg.requestedUri.pathSegments[1];
        final password = parameter["secret"];
        final newpassword = parameter["newsecret"];
        final newname = parameter["name"];
        final newuri = parameter["url"];
        if (id != null && password != null) {
          Map updatedgame = await updateGame(
              id, password, newname, newpassword, newuri);
          if (updatedgame != null) {
            if (updatedgame.length > 0) {
              msg.response
                ..statusCode = 200
                ..write(JSON.encode(updatedgame));
              return 2;
            } else {
              msg.response
                ..statusCode = 401
                ..write("No existing game with that id.");
              return 0;
            }
          } else {
            msg.response
              ..statusCode = 401
              ..write("Authentication problem, please check ID and Password.");
            return 0;
          }
        } else {
          msg.response
            ..statusCode = 401
            ..write("ID and Password must be set.");
          return 0;
        }
      }

      //Request for delete a game && all stored gamestates for this game
      RegExp removegame = new RegExp(r'/game/(\d+)\/?');
      if (msg.method == 'DELETE' &&
          removegame.hasMatch(msg.requestedUri.path)) {
        final password = parameter["secret"];
        final id = msg.requestedUri.pathSegments[1];
        if (id != null && password != null) {
          bool remgame = await removeGame(id, password);
          if (remgame != null) {
            if (remgame) {
              msg.response
                ..statusCode = 200
                ..write("Game with id=$id was removed.");
              return 5;
            } else {
              msg.response
                ..statusCode = 401
                ..write(
                    "Authentication problem, please check ID and Password.");
              return 0;
            }
          } else {
            msg.response
              ..statusCode = 401
              ..write("No existing game with that ID.");
            return 0;
          }
        } else {
          msg.response
            ..statusCode = 401
            ..write("ID and Password must be set.");
          return 0;
        }
      }

      //Request for storing gamestate for a game and a user
      RegExp postgamestate = new RegExp(r'/gamestate/(\d+)\/?');
      if (msg.method == 'POST' &&
          postgamestate.hasMatch(msg.requestedUri.path) &&
          msg.requestedUri.pathSegments.length > 2) {
        final password = parameter["secret"];
        final state = parameter["state"];
        final gid = msg.requestedUri.pathSegments[1];
        final uid = msg.requestedUri.pathSegments[2];
        if (gid != null && uid != null && password != null) {
          Map newgamestate = await addGameState(gid, uid, password, state);
          if (newgamestate != null) {
            if (newgamestate.length > 0) {
              msg.response
                ..statusCode = 200
                ..write(JSON.encode(newgamestate));
              return 3;
            } else {
              msg.response
                ..statusCode = 401
                ..write(
                    "Authentication problem, please check ID and Password.");
              return 0;
            }
          } else {
            msg.response
              ..statusCode = 404
              ..write("No existing game or user with that ID.");
            return 0;
          }
        }
        msg.response
          ..statusCode = 401
          ..write("GameID, UserID and Password must be set.");
        return 0;
      }

      //Request for get a gamestore with given game and user
      RegExp getgsgamestate = new RegExp(r'/gamestate/(\d+)\/?');
      if (msg.method == 'GET' &&
          getgsgamestate.hasMatch(msg.requestedUri.path) &&
          msg.requestedUri.pathSegments.length > 2) {
        final password = parameter["secret"];
        final gid = msg.requestedUri.pathSegments[1];
        final uid = msg.requestedUri.pathSegments[2];
        if (gid != null && uid != null && password != null) {
          final getgamestate = await getGameState(gid, uid, password);
          if (getgamestate != null) {
            msg.response
              ..statusCode = 200
              ..write(JSON.encode(getgamestate));
            return 0;
          } else {
            msg.response
              ..statusCode = 401
              ..write(
                  "No existing game or user with that ID or authentication problem, please check ID and Password.");
            return 0;
          }
        } else {
          msg.response
            ..statusCode = 401
            ..write("GameID, UserID and Password must be set.");
          return 0;
        }
      }

      //Request for get a gamestore with given game
      RegExp getggamestate = new RegExp(r'/gamestate/(\d+)\/?');
      if (msg.method == 'GET' &&
          getggamestate.hasMatch(msg.requestedUri.path)) {
        final password = parameter["secret"];
        final gid = msg.requestedUri.pathSegments[1];
        if (gid != null && password != null) {
          final getgamestate = await getGameStatewithGame(gid, password);
          if (getgamestate != null) {
            msg.response
              ..statusCode = 200
              ..write(JSON.encode(getgamestate));
            return 0;
          } else {
            msg.response
              ..statusCode = 401
              ..write(
                  "No existing game or user with that ID or authentication problem, please check ID and Password.");
            return 0;
          }
        } else {
          msg.response
            ..statusCode = 401
            ..write("GameID and Secret must be set.");
          return 0;
        }
      }

      msg.response.statusCode = 404;
      msg.response.write("Not found");
      return 1;
    } catch (e, stacktrace) {
      print(e);
      print(stacktrace);
    }
  }

  /*
    Updates an user
    - returns the updated user on succes
    - return empty map on authentication problem
    - return null on finding none user with given id
   */
  Future<Map> updateUser(String id, password, newname, newpassword,
      newmail) async {
    Map emptymap = new Map();
    String oldsignature = BASE64
        .encode(sha256
        .convert(UTF8.encode("$id,$password"))
        .bytes);
    Map existinguser = new Map.from(
        gettextfileUsers.firstWhere((user) => user['id'] == id));
    if (existinguser != null) {
      if (existinguser["signature"] == oldsignature) {
        existinguser["name"] = newname;
        existinguser["pwd"] = newpassword;
        existinguser["signature"] = BASE64
            .encode(sha256
            .convert(UTF8.encode("$id,$newpassword"))
            .bytes);
        if (newmail != null && newmail
            .toString()
            .isNotEmpty)
          existinguser["mail"] = newmail;
        gettextfileUsers.removeWhere((user) => user['id'] == id);
        gettextfileUsers.add(existinguser);
        return existinguser;
      } else
        return emptymap;
    } else
      return null;
  }

  /*
    Retrieves all data about an user
    - return user on succes
    - return empty map on authentication problem
    - return null on finding none user with given id
   */
  Future<Map> getUser(String id, password, bool byname) async {
    //Map emptymap = new Map();
    String signature = BASE64.encode(sha256
        .convert(UTF8.encode("$id,$password"))
        .bytes);
      Map existinguser;
      if (byname)
        existinguser = new Map.from(
            gettextfileUsers.firstWhere((user) => user["name"] == id));
      else
        existinguser =
        new Map.from(gettextfileUsers.firstWhere((user) => user["id"] == id));
      if (existinguser["signature"] == signature) {
          existinguser["games"] = new List();
          gettextfileGamestates.forEach((gamestate) {
            if (gamestate["userid"] == id) {
              existinguser["games"].add(gamestate["gameid"]);
            }
          });
          return existinguser;
        } else {
          return null;
      }
  }

  /*
    Retrieves a gamestate stored for a game and a user
    - return gamestate on succes
    - return empty map on authentication problem
    - return null on finding none user or game with given id
   */
  Future<List> getGameState(String gameid, userid, secret) async {
    String signature = BASE64
        .encode(sha256
        .convert(UTF8.encode("$gameid,$secret"))
        .bytes);
    if (!gettextfileUsers.any((user) => user["id"] == userid))
      return null;
    if (!gettextfileGames.any((game) => game["id"] == gameid))
      return null;
    if (!(gettextfileGames.any((game) => game["id"] == gameid &&
        game["signature"] == signature)))
      return null;
    final gamestate = gettextfileGamestates.where((gamestate) =>
    gamestate["gameid"] == gameid && gamestate["userid"] == userid);
    List allstates = gamestate.toList();
    allstates.sort((a, b) =>
        DateTime.parse(b["created"]).compareTo(DateTime.parse(a["created"])));
    return allstates;
  }

  /*
    Retrieves a gamestate stored for a game
    - return gamestate on succes
    - returns empty map on authentication problem
    - return null on finding none gamestate with given id
   */
  Future<List> getGameStatewithGame(String gameid, secret) async {
    String signature = BASE64
        .encode(sha256
        .convert(UTF8.encode("$gameid,$secret"))
        .bytes);
    if (gettextfileGames.any((game) => game["id"] == gameid &&
        game["signature"] == signature)) {
      final gamestate = gettextfileGamestates.where((gamestate) =>
      gamestate["gameid"] == gameid);
      List allstates = gamestate.toList();
      allstates.sort((a, b) => DateTime.parse(b["created"]).compareTo(
          DateTime.parse(a["created"])));
      return allstates;
    } else
      return null;
  }

  /*
    Retrieves all data about a game
    - return game on succes
    - return empty map on authentication problem
    - return null on finding none game with given id
   */
  Future<Map> getGame(String id, password) async {
    Map emptymap = new Map();
    String signature = BASE64.encode(sha256
        .convert(UTF8.encode("$id,$password"))
        .bytes);
    try {
      Map existinggame = new Map.from(
          gettextfileGames.firstWhere((game) => game["id"] ==
              id));
      if (existinggame["signature"] == signature) {
        if (existinggame != null) {
          existinggame["users"] = new List();
          gettextfileGamestates.forEach((gamestate) {
            if (gamestate["gameid"] == id) {
              existinggame["users"].add(gamestate["userid"]);
            }
          });
          return existinggame;
        } else
          return null;
      } else
        return emptymap;
    } catch (error) {
      return null;
    }
  }

  /*
    Updates a game
    - returns the updated game on succes
    - returns null on authentication problem
    - return an empty map if no game is stored with given id
   */
  Future<Map> updateGame(String id, secret, newname, newsecret, newuri) async {
    Map emptymap = new Map();
    String oldsignature = BASE64
        .encode(sha256
        .convert(UTF8.encode("$id,$secret"))
        .bytes);
    try {
      Map existinggame = new Map.from(
          gettextfileGames.firstWhere((game) => game["id"] == id));
      if (existinggame != null) {
        if (existinggame["signature"] == oldsignature) {
          existinggame["name"] = newname;
          existinggame["pwd"] = newsecret;
          existinggame["signature"] = BASE64
              .encode(sha256
              .convert(UTF8.encode("$id,$newsecret"))
              .bytes);
          if (newuri != null && newuri
              .toString()
              .isNotEmpty)
            existinggame["url"] = newuri;
          gettextfileGames.removeWhere((game) => game['id'] == id);
          gettextfileGames.add(existinggame);
          return existinggame;
        } else
          return null;
      } else
        return emptymap;
    } catch (error) {
      return null;
    }
  }

  /*
    Store a gamestate for a game and a user
    - returns the current stored gamestate on succes
    - returns an empty map on authentication problem
    - returns null on finding none game or user
   */
  Future<Map> addGameState(String gameid, userid, secret, String state) async {
    Map emptymap = new Map();
    String signature = BASE64
        .encode(sha256
        .convert(UTF8.encode("$gameid,$secret"))
        .bytes);
    if (gettextfileGames.any((game) => game["id"] == gameid) &&
        gettextfileUsers.any((user) => user["id"] == userid)) {
      if (gettextfileGames.any((game) => game["id"] == gameid &&
          game["signature"] == signature)) {
        final nameofgame = gettextfileGames.firstWhere((game) => game["id"] ==
            gameid)["name"];
        final nameofuser = gettextfileUsers.firstWhere((user) => user["id"] ==
            userid)["name"];
        Map newstate = {
          "type":"gamestate",
          "gamename":"$nameofgame",
          "username":"$nameofuser",
          "gameid":"$gameid",
          "userid":"$userid",
          "created":"${new DateTime.now().toUtc().toIso8601String()}",
          "state":"${JSON.decode(state)}"
        };
        textfileGamestates.add(newstate);
        return newstate;
      } else {
        return emptymap;
      }
    }
    return null;
  }

  /*
    Register a game
    - return the current registered game on success
    - return null  on failure
   */
  Future<Map> addGame(String name, secret, uri) async
  {
    bool isinList = gettextfileGames.any((game) => game["name"] == "$name");

    if (!isinList) {
      final id = new Random.secure().hashCode.toString();
      Map newgame = {
        "type":"game",
        "name":"$name",
        "id":"$id",
        "url":"",
        "created":"${new DateTime.now().toUtc().toIso8601String()}",
        "signature":"${BASE64
            .encode(sha256
            .convert(UTF8.encode("$id,$secret"))
            .bytes)}"
      };
      gettextfileGames.add(newgame);
      return newgame;
    } else
      return null;
  }

  /*
    Remove a registered user and all registered highscores for that user
    - return true on success
    - return false on unauthorized
    - return null on no existing user with given id
   */
  Future<bool> removeUser(String id, password) async {
    String signature = BASE64
        .encode(sha256
        .convert(UTF8.encode("$id,$password"))
        .bytes);
    if (gettextfileUsers.any((user) => user["id"] == id)) {
      Map user = gettextfileUsers.firstWhere((user) => user["id"] == id);
      if (user["signature"] == signature) {
        gettextfileUsers.removeWhere((user) => user["id"] == id);
        gettextfileGamestates.removeWhere((gamestate) => gamestate["userid"] ==
            id);
        return true;
      } else {
        return false;
      }
    } else {
      return null;
    }
  }

  /*
    Remove a registered game and all registered highscores for that game
    - return true on success
    - return false on unauthorized
    - return null on no existing user with given id
   */
  Future<bool> removeGame(String id, password) async {
    String signature = BASE64
        .encode(sha256
        .convert(UTF8.encode("$id,$password"))
        .bytes);
    if (gettextfileGames.any((game) => game["id"] == id)) {
      Map game = gettextfileGames.firstWhere((game) => game["id"] == id);
      if (game["signature"] == signature) {
        gettextfileGames.removeWhere((game) => game["id"] == id);
        gettextfileGamestates.removeWhere((gamestate) => gamestate["gameid"] ==
            id);
        return true;
      } else {
        return false;
      }
    } else {
      return null;
    }
  }

  /*
    Register an user
    - returns the current registered user on success
    - returns null  on failure
   */
  Future<Map> addUser(String name, password, mail) async {
    bool isinList = gettextfileUsers.any((game) => game["name"] == "$name");

    if (!isinList) {
      final id = new Random.secure().hashCode.toString();
      Map newuser = {
        "type":"user",
        "name":"$name",
        "pwd" :"$password",
        "id":"$id",
        "created":"${new DateTime.now().toUtc().toIso8601String()}",
        "signature":"${BASE64
            .encode(sha256
            .convert(UTF8.encode("$id,$password"))
            .bytes)}"
      };
      gettextfileUsers.add(newuser);
      return newuser;
    } else
      return null;
  }

  /*
    Save all updates to textfile and close the server
    - only calls once after awaits for incoming messages from client
   */
  closeTheServer() async {
    if (await updateConfig(0) && await updateConfig(1) &&
        await updateConfig(2)) {
      print("Server succesfull shutting down ...");
      exit(0);
    }
    else {
      print("Error at closing the server.");
      exit(1);
    }
  }
}