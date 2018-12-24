import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'Bluetooth C8763'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  FlutterBlue flutterBlue = FlutterBlue.instance;

  var scanSubscription;
  List<BluetoothDevice> blueDeviceList;
  bool isConnected = false;
  var deviceConnection;

  @override
  void initState() {
    super.initState();
    initBluetooth();
  }

  @override
  void dispose() {
    super.dispose();
    scanSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
                child: Text("開"),
                onPressed: isConnected
                    ? () async {
                        await deviceConnection
                            .writeCharacteristic('a', [0x12, 0x34]);
                      }
                    : null),
            RaisedButton(
                child: Text("關"),
                onPressed: isConnected
                    ? () async {
                        await deviceConnection
                            .writeCharacteristic('b', [0x12, 0x34]);
                      }
                    : null),
            RaisedButton(
                child: Text("中斷連線"),
                onPressed: isConnected
                    ? () {
                        deviceConnection.cancel();
                      }
                    : null),
            RaisedButton(
                child: Text("重新掃描"),
                onPressed: () {
                  scanSubscription.cancel();
                  initBluetooth();
                  setState(() {
                    isConnected = false;
                  });
                })
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          List<Widget> list = [];
          for (int i = 0; i < blueDeviceList.length; i++) {
            list.add(_dialogItem(i, blueDeviceList[i]));
          }
          showDialog<int>(
              context: context,
              builder: (BuildContext context) =>
                  SimpleDialog(title: Text("請選擇設備"), children: list))
              .then<void>((int position) {
            if (position != null) {
              deviceConnection = flutterBlue
                  .connect(blueDeviceList[position])
                  .listen((s) {
                if (s == BluetoothDeviceState.connected) {
                  setState(() {
                    isConnected = true;
                  });
                  showMessage("連接成功");
                } else if (s == BluetoothDeviceState.disconnected)
                  setState(() {
                    isConnected = false;
                  });
              });
            }
          });
        },
        tooltip: 'bluetooth select',
        child: Icon(Icons.bluetooth_audio),
      ),
    );
  }

  void initBluetooth() {
    blueDeviceList = [];
    scanSubscription = flutterBlue.scan().listen((scanResult) async {
      var index = -1;
      for (var i = 0; i < blueDeviceList.length; i++) {
        if (blueDeviceList[i].id.id == scanResult.device.id.id) {
          blueDeviceList[i] = scanResult.device;
          index = i;
        }
      }
      if (index == -1) {
        var state = await scanResult.device.state;
        if (state == BluetoothDeviceState.disconnected) {
          blueDeviceList.add(scanResult.device);
        }
      }
    });
  }

  SimpleDialogOption _dialogItem(int index, BluetoothDevice device) {
    return SimpleDialogOption(
        child: ListTile(
          title: Text(device.name),
          subtitle: Text("${device.id}"),
        ),
        onPressed: () {
          Navigator.pop(context, index);
        });
  }

  showMessage(String text) {
    final snackBar = SnackBar(content: Text(text));
    Scaffold.of(context).showSnackBar(snackBar);
  }
}
