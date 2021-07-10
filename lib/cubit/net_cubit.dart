import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wake_on_lan/wake_on_lan.dart';
import 'package:dart_ping/dart_ping.dart';

part 'net_state.dart';

class NetCubit extends Cubit<NetState> {
  var ip = '192.168.0.91';
  var mac = '14:DA:E9:03:FD:AC';

  late Connectivity _connectivity;

  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  late Timer _timer;

  NetCubit() : super(NetState()) {
    _connectivity = Connectivity();
  }

  void initialize() {
    starttimer();

    checkwifi();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void cleanup() {
    _connectivitySubscription.cancel();
    _timer.cancel();
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.wifi) {
      emit(NetState(nState: aState.sensing));
    } else
      emit(NetState(nState: aState.noWifi));
  }

  void starttimer() {
    _timer = Timer.periodic(Duration(seconds: 10), (t) {
      if (state.nState == aState.sensing) ping();
    });
  }

  void checkwifi() async {
    emit(NetState(nState: aState.checkingWifi));
    ConnectivityResult connectivityResult =
        await _connectivity.checkConnectivity();

    if (connectivityResult == ConnectivityResult.mobile) {
      emit(NetState(nState: aState.noWifi));
    } else if (connectivityResult == ConnectivityResult.wifi) {
      ping();
    }
  }

  void ping() async {
    // Create ping object with desired args
    final ping = Ping(ip, count: 1);

    emit(NetState(nState: aState.pinging));
    // [Optional]
    // Preview command that will be run (helpful for debugging)
    print('Running command: ${ping.command}');

    // Begin ping process and listen for output
    ping.stream.listen((event) {
      if (event.summary != null) {
        if (event.summary!.received == 0)
          emit(NetState(nState: aState.periodicallyChecking));
        else
          emit(NetState(nState: aState.online));
      }
    });
  }

  void wake() async {
    emit(NetState(nState: aState.waking));

    // Validate that the two strings are formatted correctly
    if (!IPv4Address.validate(ip)) {
      print('Invalid IPv4 Address String');
      return;
    }
    if (!MACAddress.validate(mac)) {
      print('Invalid MAC Address String');
      return;
    }
    // Create the IPv4 and MAC objects
    var ipv4Address = IPv4Address.from(ip);
    var macAddress = MACAddress.from(mac);
    // Send the WOL packetz
    // Port parameter is optional, set to 55 here as an example, but defaults to port 9
    await WakeOnLAN.from(ipv4Address, macAddress, port: 9).wake();
    emit(NetState(nState: aState.sensing));
  }
}
