part of 'app_cubit.dart';

enum aState { noWifi, WifiOn, inactive, resumed }

class AppState {
  aState app;

  AppState({this.app = aState.noWifi});
}
