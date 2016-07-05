####README for the GameKeyServer####

###Important
memoryofallusers.json must exist in the root folder of the project and must min. contain '[]'
memoryufallgames.json must exist in the root folder of the project and must min. contain '[]'
memoryofallgamestates.json must exist in the root folder of the project and must min. contain '[]'

###How to use
Start the server by calling the constructor with a host and port. (Normal: 127.0.0.1:4000)
Then the server is reading from the textfiles(see above) and make them representable for the incomming requests.
The Server is watching on that host and port for incomming requests from any client.
Only requests with the correct format[httpmethod && httpresource] will be handled,
for more information look into the Documentation of DartWeb or into GameKey Client of DartWeb.

Games, user and gamestates are saved differently. So it's necessary to register a game and a user. Then it is
possible to save a gamestate for a game and an user.

#Register a Game
Send a correct request (see above) to the server. That request has to include the name and the secret ot the game. What
kind of secret and name depends on you. Remind that the id and secret of the game is used to authenticate the game.
The id'll only once represented after registration.

#Register a User
Send a correct request (see above) to the server. That request has to include the name and the password of the user.
What kind of name and password depends on you. Remind that the id and password of the user is used to authenticate the user.
The id'll only once represented after registration.

#Gamestate
If a gamestate should be saved, then you have to send a correct request (see above) to the server. The gamestate
can be called for a specific game or for an specific game and user.

###Usage

#Start server
var gamekeyserver = new GameKeyServer("127.0.0.1",4000);

The Server is waiting on that host and port for incomming requests.

#Stop server
gamekeyserver.closeTheServer();

The current data structures will be written to .json file, afterwards the server's shutting down.

###Future
The server should implement the master/slave principle for incomming messages.
 Therefore, the start with the isolates is implemented, but in the current state it's not in use.
The server should be interact with the command line. Therefore, nothing is implemented at the current state.

###Changelog
version 1.0