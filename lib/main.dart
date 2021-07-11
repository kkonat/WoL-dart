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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<AppCubit>(context).initialize();
  }

  @override
  void dispose() {
    BlocProvider.of<AppCubit>(context).cleanup();

    super.dispose();
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
              child: ElevatedButton(
                style: style,
                onPressed: () {
                  BlocProvider.of<ServerCubit>(context).wake();
                },
                child: const Text('Wake...'),
              ),
            ),
            TextField(
              decoration: InputDecoration(
                  border: OutlineInputBorder(), hintText: 'Password'),
              onChanged: (text) {
                BlocProvider.of<ServerCubit>(context).setPass(text);
              },
            ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          BlocProvider.of<ServerCubit>(context).wake();
        },
        tooltip: 'Connect',
        child: BlocBuilder<AppCubit, AppState>(
          builder: (context, state) => Text('Wake'),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
