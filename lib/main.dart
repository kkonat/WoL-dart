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
              BlocBuilder<ServerCubit, ServerState>(
                builder: (context, state) {
                  return Text(
                    state.srv.toString(),
                    style: Theme.of(context).textTheme.headline4,
                  );
                },
              ),
              BlocBuilder<AppCubit, AppState>(
                builder: (context, state) {
                  return Text(
                    state.app.toString(),
                    style: Theme.of(context).textTheme.headline4,
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: BlocBuilder<ServerCubit, ServerState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      style: style,
                      onPressed: (state.ofSrv == sState.offline)
                          ? () {
                              BlocProvider.of<ServerCubit>(context).wake();
                            }
                          : null,
                      child: const Text('Wake...'),
                    );
                  },
                ),
              ),
              _buildPasswordRow(),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: ElevatedButton(
                  style: style,
                  onPressed: () {
                    BlocProvider.of<ServerCubit>(context).shutdown();
                  },
                  child: const Text('Shutdown'),
                ),
              ),
            ],
          ),
        ),
      ),
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
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter Freenas API password here'),
                  onChanged: (text) {
                    BlocProvider.of<ServerCubit>(context).setPass(text);
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
                  child: Text('Store')),
            ],
          );
  }
}
