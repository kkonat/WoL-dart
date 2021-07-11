import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:http/http.dart';
import 'package:wake_on_lan/wake_on_lan.dart';

import 'app_cubit.dart';

part 'server_state.dart';

class ServerCubit extends Cubit<ServerState> {
  static const _ServerAddr = '192.168.0.91';
  static const _WakeAddr = '192.168.0.255';
  static const _MACAddr = '14:DA:E9:03:FD:AC';
  var _serverCredentials = '';
  ServerCubit() : super(ServerState());

  Future<Response> _req(String method, String command) async {
    // encode yours here, https://www.base64encode.org/
    // format: [user:passwd] w/o brackets

    var _authHeader = <String, String>{'Authorization': _serverCredentials};

    var uri =
        Uri(scheme: 'http', host: _ServerAddr, path: 'api/v2.0/' + command);

    return (method == "GET")
        ? await get(uri, headers: _authHeader) //GET
        : await post(uri, headers: _authHeader); //POST
  }

  void _newServerState(sState s) => emit(ServerState(srv: s)); //

// ping() pings the server to see whether it is on or off/line
  void ping() async {
    // Create ping object with desired args
    final ping = Ping(_ServerAddr, count: 1);

    // Begin ping process and listen for output
    ping.stream.listen((event) {
      if (event.summary != null) {
        if (event.summary!.received == 1) _newServerState(sState.online);
      }
    });
  }

  void setPass(String pwd) {
    _serverCredentials = 'Basic ' + base64Encode(utf8.encode('root:$pwd'));
  }

// wake() wakes the remote server and switches to sensing state
  void wake() async {
    // notify app that wake will be in progress,
    // this may be done in an instant, but it's async so new state is needed
    _newServerState(sState.booting);

    // Validate that the two strings are formatted correctly
    if (!IPv4Address.validate(_WakeAddr)) {
      print('Invalid IPv4 Address String');
      return;
    }
    if (!MACAddress.validate(_MACAddr)) {
      print('Invalid MAC Address String');
      return;
    }
    // Create the IPv4 and MAC objects
    var ipv4Address = IPv4Address.from(_WakeAddr);
    var macAddress = MACAddress.from(_MACAddr);

    // Send the WOL packets

    await WakeOnLAN.from(ipv4Address, macAddress, port: 9).wake();
  }

  void shutdown() async {
    var r = await _req('POST', 'system/shutdown');
    print(r.statusCode);
    print(r.body);
    _newServerState(sState.shuttingDown);
    Future.delayed(
        const Duration(seconds: 45), () => _newServerState(sState.offline));
  }

  // Can be used to check whether the server is BOOTING
  Future<String> serverState() async {
    var r = await _req('GET', 'system/state');
    print(r.statusCode);
    return (r.body); // "BOOTING" or "READY"
  }
}
