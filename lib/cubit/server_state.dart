part of 'server_cubit.dart';

enum sState { offline, online, booting, shuttingDown }

class ServerState {
  sState srv;

  ServerState({this.srv = sState.offline});

  sState get ofSrv => srv;
}
