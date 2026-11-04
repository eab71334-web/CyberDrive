import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Default UUIDs for HM-10 / JDY-08 style BLE UART modules.
// Change them if your car uses a different BLE module.
final Guid kServiceUuid = Guid('FFE0');
final Guid kCharUuid = Guid('FFE1');

void main() => runApp(const CyberDriveApp());

class CyberDriveApp extends StatelessWidget {
  const CyberDriveApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CyberDrive',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF00D2FF)),
          scaffoldBackgroundColor: const Color(0xFF0B1220),
        ),
        home: const Directionality(
            textDirection: TextDirection.rtl, child: ScanPage()),
      );
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  List<ScanResult> results = [];
  bool scanning = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FlutterBluePlus.scanResults.listen((r) {
      if (mounted) setState(() => results = r);
    });
    FlutterBluePlus.isScanning.listen((s) {
      if (mounted) setState(() => scanning = s);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _scan() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    } catch (e) {
      _msg('تعذر البحث: $e');
    }
  }

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _connect(BluetoothDevice d) async {
    try {
      await FlutterBluePlus.stopScan();
      await d.connect(timeout: const Duration(seconds: 10));
      final services = await d.discoverServices();
      BluetoothCharacteristic? target;
      for (final s in services) {
        if (s.uuid == kServiceUuid) {
          for (final c in s.characteristics) {
            if (c.uuid == kCharUuid) target = c;
          }
        }
      }
      // Fallback: first writable characteristic.
      target ??= services
          .expand((s) => s.characteristics)
          .where((c) =>
              c.properties.write || c.properties.writeWithoutResponse)
          .cast<BluetoothCharacteristic?>()
          .firstWhere((_) => true, orElse: () => null);
      if (target == null) {
        _msg('لم أجد خاصية كتابة في هذا الجهاز');
        await d.disconnect();
        return;
      }
      if (!mounted) return;
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: ControlPage(device: d, characteristic: target!))));
      await d.disconnect();
    } catch (e) {
      _msg('فشل الاتصال: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = results
        .where((r) => r.device.platformName.isNotEmpty)
        .toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    return Scaffold(
      appBar: AppBar(title: const Text('CyberDrive • اختر السيارة')),
      body: list.isEmpty
          ? Center(
              child: Text(scanning
                  ? 'جاري البحث...'
                  : 'اضغط زر البحث وشغّل بلوتوث السيارة'))
          : ListView(
              children: [
                for (final r in list)
                  ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(r.device.platformName),
                    subtitle: Text(r.device.remoteId.str),
                    trailing: Text('${r.rssi} dBm'),
                    onTap: () => _connect(r.device),
                  )
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: scanning ? null : _scan,
        icon: const Icon(Icons.search),
        label: Text(scanning ? 'جاري البحث' : 'بحث'),
      ),
    );
  }
}

class ControlPage extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;
  const ControlPage(
      {super.key, required this.device, required this.characteristic});
  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  double speed = 7;
  bool lights = false;

  Future<void> _send(String cmd) async {
    try {
      await widget.characteristic.write(utf8.encode(cmd),
          withoutResponse: widget.characteristic.properties.writeWithoutResponse);
    } catch (_) {}
  }

  Widget _hold(IconData icon, String cmd) => GestureDetector(
        onTapDown: (_) => _send(cmd),
        onTapUp: (_) => _send('S'),
        onTapCancel: () => _send('S'),
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFF16233B),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF00D2FF), width: 2),
          ),
          child: Icon(icon, size: 48, color: const Color(0xFF00D2FF)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.platformName)),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(children: [
              const Text('السرعة'),
              Slider(
                min: 1,
                max: 9,
                divisions: 8,
                value: speed,
                label: speed.round().toString(),
                onChanged: (v) {
                  setState(() => speed = v);
                  _send(v.round().toString());
                },
              ),
            ]),
            Column(children: [
              _hold(Icons.keyboard_arrow_up, 'F'),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _hold(Icons.keyboard_arrow_left, 'L'),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _send('S'),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                        color: Colors.red.shade800,
                        borderRadius: BorderRadius.circular(45)),
                    child: const Icon(Icons.stop, size: 48),
                  ),
                ),
                const SizedBox(width: 12),
                _hold(Icons.keyboard_arrow_right, 'R'),
              ]),
              const SizedBox(height: 12),
              _hold(Icons.keyboard_arrow_down, 'B'),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              FilledButton.icon(
                onPressed: () {
                  setState(() => lights = !lights);
                  _send(lights ? 'W' : 'w');
                },
                icon: Icon(lights ? Icons.lightbulb : Icons.lightbulb_outline),
                label: const Text('الأضواء'),
              ),
              FilledButton.icon(
                onPressed: () => _send('V'),
                icon: const Icon(Icons.volume_up),
                label: const Text('منبه'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
