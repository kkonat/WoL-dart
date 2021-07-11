import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wake_on_lan/wake_on_lan.dart';
import 'package:dart_ping/dart_ping.dart';

part 'net_state.dart';

// NetCubit is the network state cubit
class NetCubit extends Cubit<NetState> {
  static const _pingAddr = '192.168.0.91';
  static const _wakeAddr = '192.168.0.255';
  static const _macAddr = '14:DA:E9:03:FD:AC';

  late final Timer _timer;
  late final Connectivity _connectivity;
  late final StreamSubscription<ConnectivityResult> _connectivitySubscription;

  NetCubit() : super(NetState()) {
    _connectivity = Connectivity();
  }

  void _emit(aState s) => emit(NetState(net: s)); // for brievity

  // startup code, called from widget state InitState()
  void initialize() {
    _starttimer();
    _checkwifi();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
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
      _emit(aState.sensing);
    } else
      // otherwise, i.e. when offline or on a mobile network,
      _emit(aState.noWifi);
  }

  // initializes timer, which will be sending ping every 10 seconds
  void _starttimer() {
    _timer = Timer.periodic(Duration(seconds: 10), (t) {
      // ping when wifi is on and the app is in sensing state
      // also ping when the server was recently online, to chek if it hasn't gone offline
      if (state.net == aState.sensing || state.net == aState.online) _ping();
    });
  }

  // checks whether wifi is on
  void _checkwifi() async {
    _emit(aState.checkingWifi);
    ConnectivityResult connectivityResult =
        await _connectivity.checkConnectivity();
    // if on a mobile network, waking won't work
    // in future may here add remote waking vias some API
    if (connectivityResult == ConnectivityResult.mobile) {
      // tell the app there's no WiFi available
      _emit(aState.noWifi);
    } else if (connectivityResult == ConnectivityResult.wifi) {
      // if WiFi is on start pinging the server
      _emit(aState.sensing);
    }
  }

// ping() pings the server to see whether it is on or off/line
  void _ping() async {
    // Create ping object with desired args
    final ping = Ping(_pingAddr, count: 1);

    emit(NetState(net: aState.pinging));

    // Begin ping process and listen for output
    ping.stream.listen((event) {
      if (event.summary != null) {
        if (event.summary!.received == 0)
          // no ping recived, go to sleep and then ping back again, go to the sensing state
          emit(NetState(net: aState.sensing));
        else
          // the host responded, it is online
          emit(NetState(net: aState.online));
      }
    });
  }

// wake() wakes the remote server and switches to sensing state
  void wake() async {
    // notify app that wake will be in progress,
    // this may be done in an instant, but it's async so new state is needed
    _emit(aState.waking);

    // Validate that the two strings are formatted correctly
    if (!IPv4Address.validate(_wakeAddr)) {
      print('Invalid IPv4 Address String');
      return;
    }
    if (!MACAddress.validate(_macAddr)) {
      print('Invalid MAC Address String');
      return;
    }
    // Create the IPv4 and MAC objects
    var ipv4Address = IPv4Address.from(_wakeAddr);
    var macAddress = MACAddress.from(_macAddr);

    // Send the WOL packets

    await WakeOnLAN.from(ipv4Address, macAddress, port: 9).wake();

    // start checking when the host comes online
    _emit(aState.sensing);
  }
}
