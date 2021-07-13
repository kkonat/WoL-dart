import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/app_cubit.dart';
import 'cubit/server_cubit.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var sc = ServerCubit();
    var ac = AppCubit(sc);

    return MultiBlocProvider(
      providers: [
        BlocProvider<ServerCubit>(
          create: (BuildContext context) => sc,
        ),
        BlocProvider<AppCubit>(
          create: (BuildContext context) => ac,
        ),
      ],
      child: MaterialApp(
        title: 'Wake on LAN',
        theme: ThemeData(
          primarySwatch: Colors.lime,
        ),
        home: MyHomePage(title: 'Wake on LAN'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    BlocProvider.of<AppCubit>(context).initialize();

    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    BlocProvider.of<AppCubit>(context).cleanup();
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  // late AppLifecycleState _appLifecycleState;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      // _appLifecycleState = state;
    });
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        BlocProvider.of<AppCubit>(context).sleep();
        break;
      case AppLifecycleState.resumed:
        BlocProvider.of<AppCubit>(context).resume();

        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style =
        ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              buildInfoColumn(),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: BlocBuilder<ServerCubit, ServerState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        ElevatedButton(
                          style: style,
                          onPressed: (state.ofSrv == sState.offline)
                              ? () {
                                  BlocProvider.of<ServerCubit>(context).wake();
                                }
                              : null,
                          child: const Text('Wake...'),
                        ),
                        _buildPasswordRow(),
                        _buildShutdownRow(style, state, context),
                      ],
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Row _buildShutdownRow(
      ButtonStyle style, ServerState state, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          style: style,
          onPressed: (state.ofSrv == sState.online)
              ? () {
                  BlocProvider.of<ServerCubit>(context).shutdown();
                }
              : null,
          child: const Text('Shutdown'),
        ),
        _savedPass
            ? TextButton(
                onPressed: () {
                  BlocProvider.of<ServerCubit>(context).savePass();
                  setState(() {
                    _savedPass = false;
                  });
                },
                child: Text('Enter\npassword',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11)))
            : Container()
      ],
    );
  }

  Column buildInfoColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BlocBuilder<ServerCubit, ServerState>(
          builder: (context, state) {
            return Text(
              'The server is now ' + state.ofSrv.toString().split(".").last,
              style: Theme.of(context).textTheme.bodyText1,
            );
          },
        ),
        BlocBuilder<AppCubit, AppState>(
          builder: (context, state) {
            return Text(
              'The application is now ' + state.app.toString().split(".").last,
              style: Theme.of(context).textTheme.bodyText1,
            );
          },
        ),
      ],
    );
  }

  var _savedPass = false;
  Widget _buildPasswordRow() {
    return _savedPass
        ? Container()
        : Row(
            children: [
              Expanded(
                child: TextField(
                  obscureText: true,
                  obscuringCharacter: '\u{2620}',
                  controller: _controller,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter Freenas API password here'),
                  onChanged: (text) {
                    BlocProvider.of<ServerCubit>(context).setPass(text);
                    //_controller.text = text;
                  },
                ),
              ),
              ElevatedButton(
                  onPressed: () {
                    BlocProvider.of<ServerCubit>(context).savePass();
                    setState(() {
                      _savedPass = true;
                    });
                  },
                  child: Text('Hide')),
            ],
          );
  }
}
