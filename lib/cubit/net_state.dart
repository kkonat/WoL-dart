part of 'net_cubit.dart';

enum aState { checkingWifi, noWifi, waking, pinging, online, sensing }

class NetState {
  aState nState;

  NetState({this.nState = aState.noWifi});
}
