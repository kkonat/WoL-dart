part of 'server_cubit.dart';

enum sState { offline, online, booting, shuttingDown, ready }

class ServerState {
  sState srv;

  ServerState({this.srv = sState.offline});
}
