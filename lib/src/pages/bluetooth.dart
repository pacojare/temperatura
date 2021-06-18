import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothApp extends StatefulWidget {
  @override
  _BluetoothAppState createState() => _BluetoothAppState();
}

//Se implementa la clase directamente involucrada a la construcción del widget creado previamente
class _BluetoothAppState extends State<BluetoothApp> {
  //Se inicializa el estado de la conexion bluetooth como desconocido
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  //Se inicializa una clave global, que ayudará a mostrar la barra de estado de conexión
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  //Se crea un objeto de tipo FlutterBluetoothSerial, para obtener instancias del estado del bluetooth del dispositivo
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  //Variable de rastreo de conexión bluetooth con el dispositivo
  BluetoothConnection connection;
  //Variable de estado del dispositivo
  int _deviceState;
  //Temperatura
  int _temperatura = 30;
  //Flag del estado de desconexión del enlace
  bool isDisconnecting = false;

  //Mapa de colores a usar en funciones de la interfaz
  Map<String, Color> colors = {
    'onBorderColor': Colors.green,
    'offBorderColor': Colors.red,
    'neutralBorderColor': Colors.transparent,
    'onTextColor': Colors.green[700],
    'offTextColor': Colors.red[700],
    'neutralTextColor': Colors.blue,
  };

  //Función que devuelve rastre ya sea que el dispositivo siga conectado
  bool get isConnected => connection != null && connection.isConnected;

  //Definición de variables que serán requeridas después
  List<BluetoothDevice> _devicesList = []; //Lista de dispositivos
  BluetoothDevice _device; //Dispositivo
  bool _connected = false;
  bool _isButtonUnavalible = false;

  //sobreescritura del método initState, para manipular instancias bluettoth del dispositivo
  @override
  void initState() {
    super.initState();

    //se obtinene el estado actual del bluetooth del dispositivo
    _bluetooth.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _deviceState = 0; //Dispositivo en estado neutral
    //Si el bluetooth del dispositivo está activado se pide permiso para activarlo automáticamente cuándo la aplicación se inicie
    enableBluetooth();

    //Revisión de más estados de bluetooth del dispositivo para control de botones
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
        if (_bluetoothState == BluetoothState.STATE_OFF) {
          _isButtonUnavalible = true;
        }
        getPairedDevices();
      });
    });
  }

  @override
  void dispose() {
    //Control de pérdida de memoria y conexión del enlace
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }
    super.dispose();
  }

  //Petición de Bluetooth al usuario en modo de espera (mientras el usuario permite o denega)
  Future<void> enableBluetooth() async {
    //Recuperación del estado de Bluetooth
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    //Si el bluetooth está apagado, encender al arrancar y recuperar los dispositivos que están emparejados
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  //Recuperación y enlistao de dispositivos emparejados

  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];
    //Obtención de dispositivos emparejados
    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    }
    //Control de llamada a [setState] a menos que [mounted] sea verdadero
    if (!mounted) {
      return;
    }

    //Almacena la lista de [devices] en la [_devicesList] para acceso a la lista desde fuera de esta clase
    setState(() {
      _devicesList = devices;
    });
  }

  //Construcción de interfaz

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text("Control de Temperatura"),
          centerTitle: true,
        ),
        body: Container(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Visibility(
                visible: _isButtonUnavalible &&
                    _bluetoothState == BluetoothState.STATE_ON,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white54,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Encender Bluetooth',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Switch(
                      value: _bluetoothState.isEnabled,
                      onChanged: (bool value) {
                        future() async {
                          if (value) {
                            await FlutterBluetoothSerial.instance
                                .requestEnable();
                          } else {
                            await FlutterBluetoothSerial.instance
                                .requestDisable();
                          }

                          await getPairedDevices();
                          _isButtonUnavalible = false;

                          if (_connected) {
                            _disconnect();
                          }
                        }

                        future().then((_) {
                          setState(() {});
                        });
                      },
                    )
                  ],
                ),
              ),
              Stack(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Container(
                          color: Colors.grey[200],
                          padding: const EdgeInsets.all(5.0),
                          child: Column(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(right: 35),
                                //icono de automovil
                                child: IconButton(
                                  icon: Icon(
                                    Icons.device_thermostat,
                                    size: 70,
                                    color: Colors.black54,
                                  ),
                                  onPressed: null,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 30),
                                //Titulo
                                child: Text(
                                  "Dispositivo",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                //Row de funciones
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    Text(
                                      'Seleccionar',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    //Listado de dispositivos disponibles
                                    DropdownButton(
                                      items: _getDeviceItems(),
                                      onChanged: (value) =>
                                          setState(() => _device = value),
                                      value: _devicesList.isNotEmpty
                                          ? _device
                                          : null,
                                      iconSize: 30,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                //Row de botones 1
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    //botón conectar
                                    RaisedButton.icon(
                                      icon: Icon(
                                        Icons.bluetooth_searching,
                                        color: Colors.white,
                                      ),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30)),
                                      color: Colors.green[600],
                                      elevation: 0,
                                      onPressed: _isButtonUnavalible
                                          ? null
                                          : _connected
                                              ? _disconnect
                                              : _connect,
                                      label: Text(
                                        _connected ? 'Desconectar' : 'Conectar',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                    //Botón de actualizar
                                    FlatButton.icon(
                                      color: Colors.lightBlue,
                                      icon: Icon(
                                        Icons.refresh,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        "Actualizar",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 16),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      splashColor: Colors.blue,
                                      onPressed: () async {
                                        await getPairedDevices().then((_) {
                                          show(
                                              "Lista de dispositivos actualizados");
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  'Temperatura : ' +
                                      _temperatura.toString() +
                                      "°",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Card(
                                  color: Colors.grey[300],
                                  elevation: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: <Widget>[
                                        //Row de botones 2
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            //Boton de subir
                                            Ink(
                                              height: 80,
                                              width: 80,
                                              decoration: ShapeDecoration(
                                                  color: Colors.green[300],
                                                  shape: CircleBorder()),
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.arrow_upward,
                                                  color: Colors.white,
                                                  size: 60,
                                                ),
                                                onPressed: _connected
                                                    ? _sendOnMessageToBluetooth
                                                    : null,
                                                color: Colors.green[300],
                                              ),
                                            ),
                                            //Temperatura

                                            //Botón bajar
                                            Ink(
                                              height: 80,
                                              width: 80,
                                              decoration: ShapeDecoration(
                                                  color: Colors.green[300],
                                                  shape: CircleBorder()),
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.arrow_downward,
                                                  color: Colors.white,
                                                  size: 60,
                                                ),
                                                onPressed: _connected
                                                    ? _sendOffMessageToBluetooth
                                                    : null,
                                                color: Colors.red[300],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 15),
                                          //Row de Títulos
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: <Widget>[
                                              Text(
                                                "Subir                                                                   Bajar",
                                                style: TextStyle(
                                                    color: Colors.black54,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
              //Expanded
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Center(
                    //Apartado final
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: 20),
                        //Botón de ajuste de bluetooth
                        RaisedButton(
                          elevation: 1,
                          child: Text("Ajuste de Bluetooth"),
                          onPressed: () {
                            FlutterBluetoothSerial.instance.openSettings();
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  //Creación de lista de dispositios a mostrar en interfaz
  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      //Lista vacia
      items.add(DropdownMenuItem(
        child: Text("Ninguno"),
      ));
    } else {
      _devicesList.forEach((device) {
        //Adición de dispositivos
        items.add(DropdownMenuItem(
          child: Text(device.name),
          value: device,
        ));
      });
    }
    return items;
  }

  //Método para conectar a un dispositivo bluetooth
  void _connect() async {
    setState(() {
      _isButtonUnavalible = true;
    });
    if (_device == null) {
      show("No hay dispositivos conectados");
    } else {
      if (!isConnected) {
        await BluetoothConnection.toAddress(_device.address)
            .then((_connection) {
          print('Conectado a dispositivo');
          connection = _connection;
          setState(() {
            _connected = true;
          });
          connection.input.listen(null).onDone(() {
            if (isDisconnecting) {
              print('Desconectado localmente');
            } else {
              print('Desconectado remotamente');
            }
            if (this.mounted) {
              setState(() {});
            }
          });
        }).catchError((error) {
          print('No se puede conectar, ocurrió un error');
          print(error);
        });
        show('Dispositivo conectado');

        setState(() => _isButtonUnavalible = false);
      }
    }
  }

  //Método para desconectar bluetooth

  void _disconnect() async {
    setState(() {
      _isButtonUnavalible = true;
      _deviceState = 0;
      connection.output.add(utf8.encode("0"));
    });

    await connection.close();
    show('Dispositivo desconectado');
    if (!connection.isConnected) {
      setState(() {
        _connected = false;
        _isButtonUnavalible = false;
      });
    }
  }

  //Subir limite
  //Método para mandar código de encendido (S = [83])
  void _sendOnMessageToBluetooth() async {
    connection.output.add(utf8.encode("S"));
    _temperatura++;
    await connection.output.allSent;
    show("Subir Limite");
    setState(() {
      _deviceState = 1; //Estado de dispositivo encendido
    });
  }

  //Bajar Limite
  //Método para mandar código de encendido (B = [66])
  void _sendOffMessageToBluetooth() async {
    connection.output.add(utf8.encode("B"));
    _temperatura--;
    await connection.output.allSent;
    show("Bajar Limite");
    setState(() {
      _deviceState = 1; //Estado de dispositivo apagado
    });
  }

  //Método para mostar SnackBar inferior con mensaje como texto
  Future show(
    String message, {
    Duration duration: const Duration(seconds: 3),
  }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(
        message,
      ),
      duration: duration,
    ));
  }
}
