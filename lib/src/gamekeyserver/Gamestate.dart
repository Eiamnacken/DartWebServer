import 'package:DartWeb/src/gamekeyserver/User.dart';
import 'package:DartWeb/src/gamekeyserver/Game.dart';

/*
  This class holds all information about a stored gamestate
 */
class Gamestate {
  Game gameid;
  User userid;
  Map state;

  /*
    Constructor
   */
  Gamestate(Game game, User user, Map state) {
    this.gameid = game;
    this.userid = user;
    this.state = new Map();
    state.addAll(state);
  }
}