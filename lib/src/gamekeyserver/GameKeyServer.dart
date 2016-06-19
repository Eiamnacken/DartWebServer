library server;

import 'dart:io';
import 'dart:async';
import 'dart:convert' show UTF8, JSON;
import 'User.dart';


/**
 *  Implementation of GameKey Server REST API in Dart
 *
 */

/*
  TOP-Level Method because of handling the Isolates
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
//Just for testing till class gamekeyserver
main() async{
  GameKeyServer apfel = new GameKeyServer("127.0.0.1",4000);

  pause(const Duration(milliseconds: 500));

  client();

  //GameKey test = new GameKey("212.201.22.161", 50001);
  //GameKey test = new GameKey("127.0.0.1", 4000);
/*
  Future<Map> registergame = test.registerGame("DontWorryAboutaThing","BrickGame");
  registergame.then((content) {
    print(content);
  });

  Future<Map> registereduser = test.registerUser("aan","dasdsads");
  pause(const Duration(milliseconds: 500));
  registereduser.then((content) {
    print(content);
  });

  pause(const Duration(milliseconds: 500));
  Future<Map> getUser = test.getUser("aan", "dasdsads");
  getUser.then((content) {
    print(content);
  });

  pause(const Duration(milliseconds: 500));
  Future<List> getUsers = test.listUsers();
  getUsers.then((content) {
    print(content);
  });

  pause(const Duration(milliseconds: 500));
  Future<List> getGames = test.listGames();
  getGames.then((content) {
    print(content);
  });

  pause(const Duration(milliseconds: 500));
  Future<String> getUserId = test.getUserId("aan");
  getUserId.then((content) {
    print(content);
  });

  pause(const Duration(milliseconds: 500));
  Future<List> getstates = test.getStates();
  getstates.then((content) {
    print(content);
  });

  pause(const Duration(milliseconds: 500));
  final state = {
    'state':"50"
  };
  Future<bool> storestate = test.storeState("87d24038-0277-4b61-a413-09613f0b44da",state);
  storestate.then((content) {
    print(content);
  });

  pause(const Duration(milliseconds: 500));
  Future<bool> authenticate = test.authenticate();
  authenticate.then((content) {
    print(content);
  });
  */
}

Future pause(Duration d) => new Future.delayed(d);

client() async{
  Map jsonData = {
    "name":"ananana",
    "password":"titten58",
  };
  String json = "name=ananana&pwd=apfel";

  var request = await new HttpClient().post(
      "127.0.0.1", 4000, '/user');
  request.headers.contentType = ContentType.parse('application/x-www-form-urlencoded');
  request.write(json);
  HttpClientResponse response = await request.close();
  await for (var contents in response.transform(UTF8.decoder)) {
    print(contents);
  }
}

/*
  This server handles the GameKey Service
 */
class GameKeyServer {

  //holding the server
  HttpServer server;

  //Holding all registered user since register
  Map allOldUser;

  //Holding all registered games since register
  Map allOldGames;

  //Holding all registered gamestates since register
  Map allOldGamestates;

  //Holding all new registered users since running the server
  List<User> allUser = new List();

  //Holding all new registered games since running the server
  List allGames = new List();

  //Holding all new registered gamestates since running the server
  List allGamestates = new List();

  //Holding the uri of the server
  Uri _uri;

  /*
    Returns the Uri of the server
   */
  Uri get getUri => this._uri;

  /*
    Returns a map with all registered User
   */
  Map get getallOldUser => this.allOldUser;

  /*
    Returns a map with all registered Games
   */
  Map get getallOldGames => this.allOldGames;

  /*
    Returns a map with all registered gamestsates
   */
  Map get getallOldGamestates => this.allOldGamestates;

  List get getallUser => this.allUser;

  List get getallGames => this.allGames;

  List get getallGamestates => this.allGamestates;

  /*
    Constructor
    - read all registered user from textfile
    - read all registered games from textfile
    - read all registered gamestates from textfile
    - set up the server and waiting for clients
   */
  GameKeyServer(String host, int port){
    this._uri = new Uri.http("$host:$port", "/");


    readConfig();
    print("Config loaded ...");
    pause(const Duration(milliseconds: 400));

    initServer(host, port);
    print("Server running on ");
    print(getUri);
    pause(const Duration(milliseconds: 400));

    print("List of all old User :");
    print(getallOldUser);
  }

  /*
    Read all registered users, games and gamestates from textfile
    - these textfiles have to exist in the root file of the project although
      they have to be in JSON format
   */
  readConfig() {
    try {
      var memoryuser = new File("memoryofallusers.json").readAsStringSync();
      var memorygames = new File("memoryofallgames.json").readAsStringSync();
      var memorygamestates = new File("memoryofallgamestates.json").readAsStringSync();
      allOldUser = JSON.decode(memoryuser);
      allOldGames = JSON.decode(memorygames);
      allOldGamestates = JSON.decode(memorygamestates);
    } catch(error){
      print("Config could not read. " + error);
      exit(1);
    }
  }

  /*
    Update all txt files with the new registered users, games and gamestates
    - i Which List was updated (-1=all,0=user,1=games,2=gamestates)
   */
  bool updateConfig(int i) {
    try {
      switch(i) {
        case -1:
          var memoryusers = new File("memoryofallusers.json");
          var memorygames = new File("memoryofallgames.json");
          var memorygamestates = new File("memoryofallgamestates.json");
          int sizeusers = getallOldUser.keys.length + getallUser.length;
          int sizegames = getallOldGames.keys.length + getallGames.length;
          int sizegamestates = getallOldGamestates.keys.length + getallGamestates.length;
          final writeuser = memoryusers.openWrite();
          final writegames = memorygames.openWrite();
          final writegamestates = memorygamestates.openWrite();
          writeuser.write("{");
          getallOldUser.forEach((value, key) {
            writeuser.write('"$sizeusers":');
            writeuser.write(JSON.encode(key));
            writeuser.write(",");
            sizeusers--;
          });
          getallUser.forEach((user) {
            writeuser.write('"$sizeusers":');
            writeuser.write(user.toString());
            if (sizeusers != 1)
              writeuser.write(",");
            sizeusers--;
          });
          writeuser.write("}");

          writegames.write("{");
          getallOldGames.forEach((value, key) {
            writegames.write('"$sizegames":');
            writegames.write(JSON.encode(key));
            writegames.write(",");
            sizegames--;
          });
          getallGames.forEach((user) {
            writegames.write('"$sizegames":');
            writegames.write(user.toString());
            if (sizegames != 1)
              writegames.write(",");
            sizegames--;
          });
          writegames.write("}");

          writegamestates.write("{");
          getallOldGamestates.forEach((value, key) {
            writegamestates.write('"$sizegamestates":');
            writegamestates.write(JSON.encode(key));
            writegamestates.write(",");
            sizegamestates--;
          });
          getallGamestates.forEach((user) {
            writegamestates.write('"$sizegamestates":');
            writegamestates.write(user.toString());
            if (sizegamestates != 1)
              writegamestates.write(",");
            sizegamestates--;
          });
          writegamestates.write("}");
          return true;
        case 0:
          var memoryusers = new File("memoryofallusers.json");
          int sizeusers = getallOldUser.keys.length + getallUser.length;
          final writeuser = memoryusers.openWrite();
          writeuser.write("{");
          getallOldUser.forEach((value, key) {
            writeuser.write('"$sizeusers":');
            writeuser.write(JSON.encode(key));
            writeuser.write(",");
            sizeusers--;
          });
          getallUser.forEach((user) {
            writeuser.write('"$sizeusers":');
            writeuser.write(user.toString());
            if (sizeusers != 1)
              writeuser.write(",");
            sizeusers--;
          });
          writeuser.write("}");
          return true;
        case 1:
          var memorygames = new File("memoryofallgames.json");
          int sizegames = getallOldGames.keys.length + getallGames.length;
          final writegames = memorygames.openWrite();
          writegames.write("{");
          getallOldGames.forEach((value, key) {
            writegames.write('"$sizegames":');
            writegames.write(JSON.encode(key));
            writegames.write(",");
            sizegames--;
          });
          getallGames.forEach((user) {
            writegames.write('"$sizegames":');
            writegames.write(user.toString());
            if (sizegames != 1)
              writegames.write(",");
            sizegames--;
          });
          writegames.write("}");
          return true;
        case 2:
          var memorygamestates = new File("memoryofallgamestates.json");
          int sizegamestates = getallOldGamestates.keys.length + getallGamestates.length;
          final writegamestates = memorygamestates.openWrite();
          writegamestates.write("{");
          getallOldGamestates.forEach((value, key) {
            writegamestates.write('"$sizegamestates":');
            writegamestates.write(JSON.encode(key));
            writegamestates.write(",");
            sizegamestates--;
          });
          getallGamestates.forEach((user) {
            writegamestates.write('"$sizegamestates":');
            writegamestates.write(user.toString());
            if (sizegamestates != 1)
              writegamestates.write(",");
            sizegamestates--;
          });
          writegamestates.write("}");
          return true;
      }
      return false;
    } catch (exception) {
      print("Could not update the config.");
      print(exception);
      return false;
    }
  }

  /*
    Method to initialize the server on the given host and port
    After initialization the server will listen on the same host and port for incoming requests
   */
  initServer(String host, int port) async{
    try{
      //binds the server on given host and port
      this.server = await HttpServer.bind(host,port);
      //the server waits for incoming messages to handle
      await for (var Httpreq in server) {
        handleMessages(Httpreq);
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
      closeTheServer();
    } catch (exception) {
      print("Server could not start. ");
      print(exception);
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
    Sets CORS headers for responses
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
    All incoming messages from the client handles this method
    //- called only by 'handleIsolates()'
    //- Returns a string of what kind of messages came in
   */
  handleMessages(HttpRequest msg) async {
    enableCors(msg.response);

    //which request is it ? ...

    //Request for create an user
    if (msg.method == 'POST' && msg.uri.toString() == '//user' || msg.uri.toString() == '/user'){
      try {
        var incmsg = await msg.transform(UTF8.decoder).join();
        var nameandpasswordandmail = incmsg.split("&");
        var name = nameandpasswordandmail.first.replaceAll("name=","");
        var password = nameandpasswordandmail.last.replaceAll("pwd=","");
        var mail = null;
        if (nameandpasswordandmail.toString().contains("mail"))
          mail = nameandpasswordandmail.first.replaceAll("mail=","");
        if (name.isNotEmpty && password.isNotEmpty) {
          User newuser = addUser(name,password,mail);
          if (newuser!=null) {
            msg.response
              ..statusCode = HttpStatus.OK
              ..write(JSON.encode(newuser.toMap())) //JSON.encode(newuser.toMap()) || JSON.encode(newuser.toString())
              ..close();
          } else {
            msg.response
              ..statusCode = 401
              ..write("Some User mind exist with that name.")
              ..close();
          }
        } else {
          msg.response
              ..statusCode = 400
              ..write("Name and password must be set.")
              ..close();
        }
      } catch (e) {
        msg.response
          ..statusCode = HttpStatus.INTERNAL_SERVER_ERROR
          ..close();
      }
    } else {
      msg.response
        ..statusCode = HttpStatus.NOT_FOUND
        ..close();
    }
  }

  //TODO
  /*
    Remove a registered user
   */
  bool removeUser(Map o){
    allUser.forEach((user) {
      if (user.name == o['name']) {
        if(allUser.remove(user)) {
          updateConfig(0);
          return true;
        }
        return false;
      }
    });
    return false;
  }

  /*
    Add a user to the allUser List
   */
  User addUser(String name, String password, mail) {
    bool isinList = false;
    getallOldUser.forEach((key,value) {
      if (value['name']==name)
        isinList = true;
    });
    allUser.forEach((user) {
      if (user.getName == name) {
        isinList = true;
      }
    });
    if(!isinList) {
      User newuser = new User(name, password, mail);
      allUser.add(newuser);
      updateConfig(0);
      return newuser;
    }
    return null;
  }

  /*
    Save all updates to textfile and close the program
    - only calls
   */
  closeTheServer() async{
    if (updateConfig(-1)) {
      //await server.close();
      print("Server succesfull shutting down ...");
      exit(0);
    }
    else {
      print("Error at closing the server.");
      exit(1);
    }
  }
}