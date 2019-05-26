import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '家電遙控',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: '家電遙控'),
    );
  }
}

enum Level { close, strong, normal, weak }

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  FlutterBluetoothSerial flutterBlue = FlutterBluetoothSerial.instance;

  var scanSubscription;
  List<BluetoothDevice> blueDeviceList;
  BluetoothDevice deviceConnection;
  bool isConnected = false;
  Level level = Level.close;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                FloatingActionButton(
                    backgroundColor: isConnected
                        ? level == Level.strong ? Colors.blue : Colors.grey[300]
                        : Colors.grey,
                    child: Text(
                      "強",
                      style: TextStyle(
                          color: isConnected && level == Level.strong
                              ? Colors.white
                              : Colors.grey[800]),
                    ),
                    onPressed: isConnected
                        ? () async {
                            await flutterBlue.write('b');
                            setState(() {
                              level = Level.strong;
                            });
                          }
                        : null),
                FloatingActionButton(
                    backgroundColor: isConnected
                        ? level == Level.normal ? Colors.blue : Colors.grey[300]
                        : Colors.grey,
                    child: Text(
                      "中",
                      style: TextStyle(
                          color: isConnected && level == Level.normal
                              ? Colors.white
                              : Colors.grey[800]),
                    ),
                    onPressed: isConnected
                        ? () async {
                            await flutterBlue.write('c');
                            setState(() {
                              level = Level.normal;
                            });
                          }
                        : null),
                FloatingActionButton(
                    backgroundColor: isConnected
                        ? level == Level.weak ? Colors.blue : Colors.grey[300]
                        : Colors.grey,
                    child: Text(
                      "弱",
                      style: TextStyle(
                          color: isConnected && level == Level.weak
                              ? Colors.white
                              : Colors.grey[800]),
                    ),
                    onPressed: isConnected
                        ? () async {
                            await flutterBlue.write('d');
                            setState(() {
                              level = Level.weak;
                            });
                          }
                        : null),
              ],
            ),
            SizedBox(height: 16),
            RaisedButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(30.0),
                  ),
                ),
                padding: EdgeInsets.all(16),
                color: isConnected
                    ? level == Level.close ? Colors.blue : Colors.grey[300]
                    : Colors.grey,
                child: Text(
                  "關",
                  style: TextStyle(
                      color: isConnected && level == Level.close
                          ? Colors.white
                          : Colors.grey[800]),
                ),
                onPressed: isConnected
                    ? () async {
                        await flutterBlue.write('a');
                        setState(() {
                          level = Level.close;
                        });
                      }
                    : null),
            SizedBox(height: 16),
            Builder(builder: (BuildContext context) {
              return RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(30.0),
                    ),
                  ),
                  child: Text(
                    "中斷連線",
                  ),
                  padding: EdgeInsets.all(16),
                  onPressed: isConnected
                      ? () async {
                          await flutterBlue.disconnect();
                          setState(() {
                            isConnected = false;
                          });
                          showMessage(context, "中斷成功");
                        }
                      : null);
            }),
          ],
        ),
      ),
      floatingActionButton: Builder(builder: (BuildContext context) {
        return FloatingActionButton(
          onPressed: () {
            List<Widget> list = [];
            for (int i = 0; i < blueDeviceList.length; i++) {
              list.add(_dialogItem(i, blueDeviceList[i]));
            }
            showDialog<int>(
                    context: context,
                    builder: (BuildContext _) =>
                        SimpleDialog(title: Text("請選擇設備"), children: list))
                .then<void>((int position) async {
              if (position != null) {
                deviceConnection = blueDeviceList[position];
                flutterBlue.connect(deviceConnection).catchError((error) {
                  //showMessage(context, "連接失敗");
                });
                setState(() {
                  isConnected = true;
                });
                showMessage(context, "連接成功");
              }
            });
          },
          tooltip: 'bluetooth select',
          child: Icon(Icons.bluetooth_audio),
        );
      }),
    );
  }

  Color get textColor => isConnected ? Colors.white : Colors.grey[800];

  void initBluetooth() async {
    blueDeviceList = [];
    List<BluetoothDevice> devices = [];

    try {
      blueDeviceList = await flutterBlue.getBondedDevices();
      for (var i in devices) {
        blueDeviceList.add(i);
      }
    } on PlatformException {
      // TODO - Error
    }
  }

  SimpleDialogOption _dialogItem(int index, BluetoothDevice device) {
    return SimpleDialogOption(
        child: ListTile(
          title: Text(device.name),
          subtitle: Text("${device.address}"),
        ),
        onPressed: () {
          Navigator.pop(context, index);
        });
  }

  showMessage(BuildContext context, String text) {
    final snackBar = SnackBar(content: Text(text));
    Scaffold.of(context).showSnackBar(snackBar);
  }
}
