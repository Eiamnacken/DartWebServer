import 'dart:async';
import 'package:GameKeyServer/src/gameKey/GameKey.dart';






//Just for testing till class gamekeyserver
main() async {
  //GameKeyServer apfel = await new GameKeyServer("127.0.0.1", 4000);

  // pause(const Duration(milliseconds: 500));

  //client();

  //GameKey test = new GameKey("212.201.22.169",50001);
  GameKey test = new GameKey("127.0.0.1", 4000);

  Future<Map> registergame = test.registerGame(
      "DontWorryAboutaThing", "BrickGame");
  registergame.then((content) {
    print(content);
  });

  Future<Map> registereduser = test.registerUser("aa", "dasdsads");
  registereduser.then((content) {
    print(content);
  });

  Future<Map> getUser = test.getUser("aan", "dasdsads");
  getUser.then((content) {
    print(content);
  });

  Future<List> getUsers = test.listUsers();
  getUsers.then((content) {
    print(content);
  });

  Future<List> getGames = test.listGames();
  getGames.then((content) {
    print(content);
  });

  Future<String> getUserId = test.getUserId("aan");
  getUserId.then((content) {
    print(content);
  });

  final state = {
    'state':"50"
  };
  Future<bool> storestate = test.storeState("791781819",state);
  storestate.then((content) {
    print(content);
  });

  Future<List> getstates = test.getStates();
  getstates.then((content) {
    print(content);
  });

  Future<bool> authenticate = test.authenticate();
  authenticate.then((content) {
    print(content);
  });
}
