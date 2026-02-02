import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(ScalextricTimerApp(cameras: cameras));
}

class ScalextricTimerApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const ScalextricTimerApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scalextric Timer',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.black,
        brightness: Brightness.dark,
      ),
      home: MainMenuPage(cameras: cameras),
    );
  }
}

// Modelo de Coche
class Car {
  String id;
  String name;
  String color;

  Car({required this.id, required this.name, required this.color});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
  };

  factory Car.fromJson(Map<String, dynamic> json) => Car(
    id: json['id'],
    name: json['name'],
    color: json['color'],
  );
}

// Modelo de Carrera Guardada
class SavedRace {
  String id;
  String title;
  String carName;
  String carColor;
  DateTime date;
  bool isCountdownMode;
  int totalLaps;
  int countdownMinutes;
  Duration totalTime;
  List<Duration> lapTimes;
  Duration? bestLap;

  SavedRace({
    required this.id,
    required this.title,
    required this.carName,
    required this.carColor,
    required this.date,
    required this.isCountdownMode,
    required this.totalLaps,
    required this.countdownMinutes,
    required this.totalTime,
    required this.lapTimes,
    this.bestLap,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'carName': carName,
    'carColor': carColor,
    'date': date.toIso8601String(),
    'isCountdownMode': isCountdownMode,
    'totalLaps': totalLaps,
    'countdownMinutes': countdownMinutes,
    'totalTime': totalTime.inMilliseconds,
    'lapTimes': lapTimes.map((e) => e.inMilliseconds).toList(),
    'bestLap': bestLap?.inMilliseconds,
  };

  factory SavedRace.fromJson(Map<String, dynamic> json) => SavedRace(
    id: json['id'],
    title: json['title'],
    carName: json['carName'],
    carColor: json['carColor'],
    date: DateTime.parse(json['date']),
    isCountdownMode: json['isCountdownMode'],
    totalLaps: json['totalLaps'],
    countdownMinutes: json['countdownMinutes'],
    totalTime: Duration(milliseconds: json['totalTime']),
    lapTimes: (json['lapTimes'] as List).map((e) => Duration(milliseconds: e)).toList(),
    bestLap: json['bestLap'] != null ? Duration(milliseconds: json['bestLap']) : null,
  );
}

// PÃ¡gina del MenÃº Principal
class MainMenuPage extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MainMenuPage({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ðŸŽï¸ Scalextric Timer'),
        backgroundColor: Colors.red[900],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_motorsports, size: 100, color: Colors.red),
              SizedBox(height: 40),
              _buildMenuButton(
                context,
                'NUEVA CARRERA',
                Icons.play_arrow,
                Colors.red,
                () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => TimerHomePage(cameras: cameras),
                )),
              ),
              SizedBox(height: 16),
              _buildMenuButton(
                context,
                'MIS COCHES',
                Icons.directions_car,
                Colors.blue,
                () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => CarsManagementPage(),
                )),
              ),
              SizedBox(height: 16),
              _buildMenuButton(
                context,
                'HISTORIAL',
                Icons.history,
                Colors.green,
                () => Navigator.push(context, MaterialPageRoute(
                  builder: (context) => RaceHistoryPage(),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 30),
      label: Text(text, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        minimumSize: Size(280, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// PÃ¡gina de GestiÃ³n de Coches
class CarsManagementPage extends StatefulWidget {
  @override
  State<CarsManagementPage> createState() => _CarsManagementPageState();
}

class _CarsManagementPageState extends State<CarsManagementPage> {
  List<Car> _cars = [];

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    final prefs = await SharedPreferences.getInstance();
    final carsJson = prefs.getStringList('cars') ?? [];
    setState(() {
      _cars = carsJson.map((e) => Car.fromJson(json.decode(e))).toList();
    });
  }

  Future<void> _saveCars() async {
    final prefs = await SharedPreferences.getInstance();
    final carsJson = _cars.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList('cars', carsJson);
  }

  void _addCar() async {
    final result = await showDialog<Car>(
      context: context,
      builder: (context) => CarEditDialog(),
    );

    if (result != null) {
      setState(() => _cars.add(result));
      _saveCars();
    }
  }

  void _editCar(int index) async {
    final result = await showDialog<Car>(
      context: context,
      builder: (context) => CarEditDialog(car: _cars[index]),
    );

    if (result != null) {
      setState(() => _cars[index] = result);
      _saveCars();
    }
  }

  void _deleteCar(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar coche'),
        content: Text('Â¿Seguro que quieres eliminar "${_cars[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _cars.removeAt(index));
              _saveCars();
              Navigator.pop(context);
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Coches'),
        backgroundColor: Colors.blue[900],
      ),
      body: _cars.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_outlined, size: 100, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('No hay coches registrados', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _addCar,
                    icon: Icon(Icons.add),
                    label: Text('AÃ±adir primer coche'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _cars.length,
              itemBuilder: (context, index) {
                final car = _cars[index];
                final carColor = Color(int.parse(car.color.substring(1), radix: 16) + 0xFF000000);
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: carColor,
                      child: Icon(Icons.directions_car, color: Colors.white),
                    ),
                    title: Text(car.name, style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editCar(index),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCar(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCar,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
      ),
    );
  }
}

// DiÃ¡logo para aÃ±adir/editar coche
class CarEditDialog extends StatefulWidget {
  final Car? car;

  const CarEditDialog({Key? key, this.car}) : super(key: key);

  @override
  State<CarEditDialog> createState() => _CarEditDialogState();
}

class _CarEditDialogState extends State<CarEditDialog> {
  late TextEditingController _nameController;
  String _selectedColor = '#FF0000';

  final List<String> _colors = [
    '#FF0000', '#0000FF', '#FFFF00', '#00FF00', '#FF6600', 
    '#9900FF', '#000000', '#FFFFFF', '#FF1493', '#00CED1',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.car?.name ?? '');
    _selectedColor = widget.car?.color ?? '#FF0000';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.car == null ? 'AÃ±adir Coche' : 'Editar Coche'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nombre del coche',
              border: OutlineInputBorder(),
            ),
            maxLength: 50,
          ),
          SizedBox(height: 16),
          Text('Color:', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colors.map((colorHex) {
              final color = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = colorHex),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == colorHex ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: _selectedColor == colorHex
                      ? Icon(Icons.check, color: colorHex == '#000000' ? Colors.white : Colors.black)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              final car = Car(
                id: widget.car?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text.trim(),
                color: _selectedColor,
              );
              Navigator.pop(context, car);
            }
          },
          child: Text('Guardar'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        ),
      ],
    );
  }
}

// PÃ¡gina del CronÃ³metro (actualizada)
class TimerHomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const TimerHomePage({Key? key, required this.cameras}) : super(key: key);

  @override
  State<TimerHomePage> createState() => _TimerHomePageState();
}

class _TimerHomePageState extends State<TimerHomePage> {
  CameraController? _cameraController;
  bool _isDetecting = false;
  bool _raceStarted = false;
  bool _raceFinished = false;
  
  // ConfiguraciÃ³n
  int _totalLaps = 10;
  bool _isCountdownMode = false;
  int _countdownMinutes = 5;
  bool _startWithLights = true;
  Car? _selectedCar;
  List<Car> _cars = [];
  
  // Estado de la carrera
  int _currentLap = 0;
  List<Duration> _lapTimes = [];
  Stopwatch _stopwatch = Stopwatch();
  Duration _lastLapTime = Duration.zero;
  Timer? _displayTimer;
  
  // SemÃ¡foro
  bool _showingLights = false;
  int _lightsOn = 0;
  
  // DetecciÃ³n
  int _detectionThreshold = 50;
  bool _lastFrameWasBright = false;
  int _brightnessReference = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadCars();
  }

  Future<void> _loadCars() async {
    final prefs = await SharedPreferences.getInstance();
    final carsJson = prefs.getStringList('cars') ?? [];
    setState(() {
      _cars = carsJson.map((e) => Car.fromJson(json.decode(e))).toList();
      if (_cars.isNotEmpty) {
        _selectedCar = _cars.first;
      }
    });
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;
    
    _cameraController = CameraController(
      widget.cameras.first,
      ResolutionPreset.low,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _displayTimer?.cancel();
    super.dispose();
  }

  void _startRace() {
    if (_selectedCar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, selecciona un coche primero')),
      );
      return;
    }

    if (_startWithLights) {
      _startLightsSequence();
    } else {
      _startRaceNow();
    }
  }

  void _startLightsSequence() async {
    setState(() {
      _showingLights = true;
      _lightsOn = 0;
    });

    for (int i = 1; i <= 5; i++) {
      await Future.delayed(Duration(seconds: 1));
      setState(() => _lightsOn = i);
    }

    await Future.delayed(Duration(milliseconds: 2000 + (DateTime.now().millisecond % 3000)));

    setState(() {
      _showingLights = false;
      _lightsOn = 0;
    });

    _startRaceNow();
  }

  void _startRaceNow() {
    setState(() {
      _raceStarted = true;
      _raceFinished = false;
      _currentLap = 0;
      _lapTimes.clear();
      _lastLapTime = Duration.zero;
    });

    _stopwatch.reset();
    _stopwatch.start();
    
    _displayTimer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      if (mounted) setState(() {});
    });

    _startDetection();
  }

  void _startDetection() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    _isDetecting = true;
    _brightnessReference = 0;

    _cameraController!.startImageStream((CameraImage image) {
      if (!_isDetecting || _raceFinished) return;
      _processImage(image);
    });
  }

  void _processImage(CameraImage image) async {
    if (_raceFinished) return;

    int brightness = _calculateBrightness(image);
    
    if (_brightnessReference == 0) {
      _brightnessReference = brightness;
      return;
    }

    bool isBright = brightness > (_brightnessReference + _detectionThreshold);

    if (isBright && !_lastFrameWasBright) {
      _onLapDetected();
    }

    _lastFrameWasBright = isBright;
  }

  int _calculateBrightness(CameraImage image) {
    final plane = image.planes[0];
    int sum = 0;
    int sampleCount = 100;
    int step = plane.bytes.length ~/ sampleCount;

    for (int i = 0; i < plane.bytes.length; i += step) {
      sum += plane.bytes[i];
    }

    return sum ~/ sampleCount;
  }

  void _onLapDetected() {
    if (_raceFinished) return;

    Duration currentTime = _stopwatch.elapsed;
    Duration lapTime = currentTime - _lastLapTime;

    if (_currentLap > 0 && lapTime.inMilliseconds < 1000) {
      return;
    }

    setState(() {
      _currentLap++;
      if (_currentLap > 1) {
        _lapTimes.add(lapTime);
      }
      _lastLapTime = currentTime;

      if (!_isCountdownMode && _currentLap > _totalLaps) {
        _finishRace();
      } else if (_isCountdownMode && currentTime.inMinutes >= _countdownMinutes) {
        _finishRace();
      }
    });
  }

  void _finishRace() {
    setState(() => _raceFinished = true);
    _stopwatch.stop();
    _isDetecting = false;
    _cameraController?.stopImageStream();
    _displayTimer?.cancel();
    
    // Mostrar diÃ¡logo para guardar
    _showSaveDialog();
  }

  void _showSaveDialog() async {
    final titleController = TextEditingController();
    
    final shouldSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Guardar Carrera'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Â¿Quieres guardar esta carrera?'),
            SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'TÃ­tulo de la carrera',
                hintText: 'Ej: Carrera del sÃ¡bado',
                border: OutlineInputBorder(),
              ),
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No guardar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Guardar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );

    if (shouldSave == true && titleController.text.trim().isNotEmpty) {
      await _saveRace(titleController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Carrera guardada correctamente')),
        );
      }
    }
  }

  Future<void> _saveRace(String title) async {
    if (_selectedCar == null) return;

    final race = SavedRace(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      carName: _selectedCar!.name,
      carColor: _selectedCar!.color,
      date: DateTime.now(),
      isCountdownMode: _isCountdownMode,
      totalLaps: _totalLaps,
      countdownMinutes: _countdownMinutes,
      totalTime: _stopwatch.elapsed,
      lapTimes: _lapTimes,
      bestLap: _getBestLap(),
    );

    final prefs = await SharedPreferences.getInstance();
    final racesJson = prefs.getStringList('races') ?? [];
    racesJson.add(json.encode(race.toJson()));
    await prefs.setStringList('races', racesJson);
  }

  void _resetRace() {
    setState(() {
      _raceStarted = false;
      _raceFinished = false;
      _currentLap = 0;
      _lapTimes.clear();
      _lastLapTime = Duration.zero;
      _showingLights = false;
      _lightsOn = 0;
    });
    _stopwatch.reset();
    _displayTimer?.cancel();
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    String milliseconds = (duration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  Duration? _getBestLap() {
    if (_lapTimes.isEmpty) return null;
    return _lapTimes.reduce((a, b) => a < b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('ðŸŽï¸ Nueva Carrera'),
        backgroundColor: Colors.red[900],
      ),
      body: _raceStarted ? _buildRaceView() : _buildConfigView(),
    );
  }

  Widget _buildConfigView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SelecciÃ³n de coche
          Card(
            color: Colors.grey[900],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('SELECCIONA TU COCHE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                  SizedBox(height: 16),
                  if (_cars.isEmpty)
                    Column(
                      children: [
                        Text('No hay coches registrados', style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (context) => CarsManagementPage(),
                            ));
                            _loadCars();
                          },
                          icon: Icon(Icons.add),
                          label: Text('AÃ±adir coche'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        ),
                      ],
                    )
                  else
                    DropdownButton<Car>(
                      value: _selectedCar,
                      isExpanded: true,
                      items: _cars.map((car) {
                        final carColor = Color(int.parse(car.color.substring(1), radix: 16) + 0xFF000000);
                        return DropdownMenuItem<Car>(
                          value: car,
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: carColor,
                                radius: 12,
                              ),
                              SizedBox(width: 12),
                              Text(car.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (car) => setState(() => _selectedCar = car),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            color: Colors.grey[900],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('MODO DE CARRERA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                  SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Contrarreloj'),
                    subtitle: Text(_isCountdownMode ? 'DuraciÃ³n fija' : 'NÃºmero de vueltas'),
                    value: _isCountdownMode,
                    activeColor: Colors.red,
                    onChanged: (value) => setState(() => _isCountdownMode = value),
                  ),
                  if (!_isCountdownMode) ...[
                    SizedBox(height: 8),
                    Text('NÃºmero de vueltas: $_totalLaps', style: TextStyle(fontSize: 16)),
                    Slider(
                      value: _totalLaps.toDouble(),
                      min: 1,
                      max: 50,
                      divisions: 49,
                      activeColor: Colors.red,
                      onChanged: (value) => setState(() => _totalLaps = value.toInt()),
                    ),
                  ] else ...[
                    SizedBox(height: 8),
                    Text('DuraciÃ³n: $_countdownMinutes minutos', style: TextStyle(fontSize: 16)),
                    Slider(
                      value: _countdownMinutes.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      activeColor: Colors.red,
                      onChanged: (value) => setState(() => _countdownMinutes = value.toInt()),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            color: Colors.grey[900],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('CONFIGURACIÃ“N DE SALIDA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                  SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('SemÃ¡foro F1'),
                    subtitle: Text(_startWithLights ? 'Con secuencia de luces' : 'Inicio con primer paso'),
                    value: _startWithLights,
                    activeColor: Colors.red,
                    onChanged: (value) => setState(() => _startWithLights = value),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            color: Colors.grey[900],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('SENSIBILIDAD DETECCIÃ“N', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                  SizedBox(height: 8),
                  Text('Ajusta segÃºn la iluminaciÃ³n', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Slider(
                    value: _detectionThreshold.toDouble(),
                    min: 20,
                    max: 100,
                    divisions: 80,
                    activeColor: Colors.red,
                    label: _detectionThreshold.toString(),
                    onChanged: (value) => setState(() => _detectionThreshold = value.toInt()),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: _startRace,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'ðŸ INICIAR CARRERA',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceView() {
    Duration bestLap = _getBestLap() ?? Duration.zero;
    
    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.3,
            child: CameraPreview(_cameraController!),
          ),
        ),
        
        Column(
          children: [
            if (_showingLights) _buildStartingLights(),
            
            SizedBox(height: 20),
            
            // InformaciÃ³n del coche
            if (_selectedCar != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(int.parse(_selectedCar!.color.substring(1), radix: 16) + 0xFF000000),
                      radius: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      _selectedCar!.name,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 10),
            
            Container(
              padding: EdgeInsets.all(20),
              child: Text(
                _formatDuration(_stopwatch.elapsed),
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
            ),
            
            Text(
              _isCountdownMode 
                ? 'Vuelta $_currentLap' 
                : 'Vuelta $_currentLap / $_totalLaps',
              style: TextStyle(fontSize: 24, color: Colors.white, shadows: [Shadow(blurRadius: 10, color: Colors.black)]),
            ),
            
            SizedBox(height: 20),
            
            Expanded(
              child: Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _lapTimes.isEmpty
                    ? Center(child: Text('Esperando primera vuelta...', style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                        itemCount: _lapTimes.length,
                        itemBuilder: (context, index) {
                          Duration lapTime = _lapTimes[index];
                          bool isBest = lapTime == bestLap;
                          return ListTile(
                            leading: Icon(
                              isBest ? Icons.emoji_events : Icons.flag,
                              color: isBest ? Colors.amber : Colors.white70,
                            ),
                            title: Text(
                              'Vuelta ${index + 2}',
                              style: TextStyle(
                                color: isBest ? Colors.amber : Colors.white,
                                fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: Text(
                              _formatDuration(lapTime),
                              style: TextStyle(
                                fontSize: 18,
                                color: isBest ? Colors.amber : Colors.white,
                                fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_raceFinished)
                    ElevatedButton.icon(
                      onPressed: _resetRace,
                      icon: Icon(Icons.refresh),
                      label: Text('NUEVA CARRERA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        _finishRace();
                      },
                      icon: Icon(Icons.stop),
                      label: Text('DETENER'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: _resetRace,
                    icon: Icon(Icons.close),
                    label: Text('CANCELAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStartingLights() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          bool isOn = index < _lightsOn;
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOn ? Colors.red : Colors.grey[800],
              boxShadow: isOn
                  ? [BoxShadow(color: Colors.red, blurRadius: 20, spreadRadius: 5)]
                  : [],
            ),
          );
        }),
      ),
    );
  }
}

// PÃ¡gina de Historial de Carreras
class RaceHistoryPage extends StatefulWidget {
  @override
  State<RaceHistoryPage> createState() => _RaceHistoryPageState();
}

class _RaceHistoryPageState extends State<RaceHistoryPage> {
  List<SavedRace> _races = [];

  @override
  void initState() {
    super.initState();
    _loadRaces();
  }

  Future<void> _loadRaces() async {
    final prefs = await SharedPreferences.getInstance();
    final racesJson = prefs.getStringList('races') ?? [];
    setState(() {
      _races = racesJson.map((e) => SavedRace.fromJson(json.decode(e))).toList();
      _races.sort((a, b) => b.date.compareTo(a.date)); // MÃ¡s recientes primero
    });
  }

  Future<void> _deleteRace(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final racesJson = prefs.getStringList('races') ?? [];
    racesJson.removeAt(index);
    await prefs.setStringList('races', racesJson);
    _loadRaces();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    String milliseconds = (duration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _viewRaceDetails(SavedRace race) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RaceDetailPage(race: race)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Carreras'),
        backgroundColor: Colors.green[900],
      ),
      body: _races.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 100, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('No hay carreras guardadas', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _races.length,
              itemBuilder: (context, index) {
                final race = _races[index];
                final carColor = Color(int.parse(race.carColor.substring(1), radix: 16) + 0xFF000000);
                
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _viewRaceDetails(race),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: carColor,
                                child: Icon(Icons.directions_car, color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      race.title,
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      race.carName,
                                      style: TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Eliminar carrera'),
                                      content: Text('Â¿Seguro que quieres eliminar esta carrera?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _deleteRace(index);
                                            Navigator.pop(context);
                                          },
                                          child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDate(race.date), style: TextStyle(color: Colors.grey)),
                              Row(
                                children: [
                                  Icon(Icons.timer, size: 16, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text(_formatDuration(race.totalTime)),
                                ],
                              ),
                            ],
                          ),
                          if (race.bestLap != null) ...[
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                                SizedBox(width: 4),
                                Text(
                                  'Mejor vuelta: ${_formatDuration(race.bestLap!)}',
                                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// PÃ¡gina de Detalle de Carrera
class RaceDetailPage extends StatelessWidget {
  final SavedRace race;

  const RaceDetailPage({Key? key, required this.race}) : super(key: key);

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    String milliseconds = (duration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} a las ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final carColor = Color(int.parse(race.carColor.substring(1), radix: 16) + 0xFF000000);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de Carrera'),
        backgroundColor: Colors.green[900],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      race.title,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: carColor,
                          radius: 20,
                          child: Icon(Icons.directions_car, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text(
                          race.carName,
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      _formatDate(race.date),
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTADÃSTICAS',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    SizedBox(height: 12),
                    _buildStatRow('Modo', race.isCountdownMode ? 'Contrarreloj (${race.countdownMinutes} min)' : '${race.totalLaps} vueltas'),
                    _buildStatRow('Tiempo total', _formatDuration(race.totalTime)),
                    _buildStatRow('Vueltas completadas', race.lapTimes.length.toString()),
                    if (race.bestLap != null)
                      _buildStatRow('Mejor vuelta', _formatDuration(race.bestLap!), color: Colors.amber),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIEMPOS POR VUELTA',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    SizedBox(height: 12),
                    if (race.lapTimes.isEmpty)
                      Text('No hay tiempos registrados', style: TextStyle(color: Colors.grey))
                    else
                      ...race.lapTimes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final lapTime = entry.value;
                        final isBest = lapTime == race.bestLap;
                        return ListTile(
                          leading: Icon(
                            isBest ? Icons.emoji_events : Icons.flag,
                            color: isBest ? Colors.amber : Colors.white70,
                          ),
                          title: Text(
                            'Vuelta ${index + 2}',
                            style: TextStyle(
                              fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                              color: isBest ? Colors.amber : null,
                            ),
                          ),
                          trailing: Text(
                            _formatDuration(lapTime),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                              color: isBest ? Colors.amber : null,
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
