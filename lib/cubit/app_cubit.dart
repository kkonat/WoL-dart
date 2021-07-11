import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wol/cubit/server_cubit.dart';

part 'app_state.dart';

// NetCubit is the network state cubit

class AppCubit extends Cubit<AppState> {
  late final Timer _timer;
  late final Connectivity _connectivity;
  late final StreamSubscription<ConnectivityResult> _connectivitySubscription;
  final ServerCubit sc;

  AppCubit(this.sc) : super(AppState()) {
    _connectivity = Connectivity();
  }

  void _newAppState(aState s) => emit(AppState(app: s)); //

  // startup code, called from widget state InitState()
  void initialize() {
    _starttimer();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _checkwifi();
  }

  // housekeeping
  void cleanup() {
    _connectivitySubscription.cancel();
    _timer.cancel();
  }

// listener to monitor connectivity changes
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.wifi) {
      // WiFi is on, will be sensing the server
      _newAppState(aState.WifiOn);
    } else {
      // otherwise, i.e. when offline or on a mobile network,
      _newAppState(aState.noWifi);
    }
  }

  // initializes timer, which will be sending ping every 10 seconds
  void _starttimer() {
    _timer = Timer.periodic(Duration(seconds: 10), (t) {
      // ping when wifi is on and the app is in sensing state
      // also ping when the server was recently online, to chek if it hasn't gone offline
      if (state.app == aState.WifiOn) {
        sc.ping();
      }
    });
  }

  // checks whether wifi is on
  void _checkwifi() async {
    ConnectivityResult connectivityResult =
        await _connectivity.checkConnectivity();
    // if on a mobile network, waking won't work
    // in future may here add remote waking vias some API
    if (connectivityResult == ConnectivityResult.mobile) {
      // tell the app there's no WiFi available
      _newAppState(aState.noWifi);
    } else if (connectivityResult == ConnectivityResult.wifi) {
      // if WiFi is on start pinging the server
      _newAppState(aState.WifiOn);
    }
  }
}
