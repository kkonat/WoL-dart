import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/net_cubit.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NetCubit(),
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
    BlocProvider.of<NetCubit>(context).initialize();
  }

  @override
  void dispose() {
    BlocProvider.of<NetCubit>(context).cleanup();
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
            Text(
              'Current cubit state:',
            ),
            BlocBuilder<NetCubit, NetState>(
              builder: (context, state) {
                return Text(
                  state.net.toString(),
                  style: Theme.of(context).textTheme.headline4,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: ElevatedButton(
                style: style,
                onPressed: () {
                  BlocProvider.of<NetCubit>(context).wake();
                },
                child: const Text('Wake...'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          BlocProvider.of<NetCubit>(context).wake();
        },
        tooltip: 'Connect',
        child: BlocBuilder<NetCubit, NetState>(
          builder: (context, state) {
            var icon;
            switch (state.net) {
              case aState.checkingWifi:
                icon = Icons.device_unknown_outlined;
                break;
              case aState.noWifi:
                icon = Icons.do_disturb;
                break;
              case aState.online:
                icon = Icons.flash_on_rounded;
                break;
              case aState.sensing:
                icon = Icons.flash_off_rounded;
                break;
              case aState.pinging:
                icon = Icons.hourglass_empty_outlined;
                break;
              case aState.waking:
                icon = Icons.notifications_none_outlined;
                break;
            }
            return Icon(icon);
          },
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
