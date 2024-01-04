import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';
import 'package:kdgaugeview/kdgaugeview.dart';
import 'package:lottie/lottie.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final internetSpeedTest = FlutterInternetSpeedTest()..enableLog();

  bool isTestDownload = true;

  bool _testInProgress = false;
  double _downloadRate = 0;
  double _uploadRate = 0;
  String _downloadProgress = '0';
  String _uploadProgress = '0';
  int _downloadCompletionTime = 0;
  int _uploadCompletionTime = 0;
  bool _isServerSelectionInProgress = false;

  GlobalKey<KdGaugeViewState> key = GlobalKey<KdGaugeViewState>();

  String? _ip;
  String? _asn;
  String? _isp;

  String _unitText = 'Mbps';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      reset();
    });
  }

  Future onStartTesting() async {
    reset();
    await internetSpeedTest.startTesting(onStarted: () {
      setState(() => _testInProgress = true);
    }, onCompleted: (TestResult download, TestResult upload) {
      if (kDebugMode) {
        print(
            'the transfer rate ${download.transferRate}, ${upload.transferRate}');
      }
      setState(() {
        _downloadRate = download.transferRate;
        _unitText = download.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
        _downloadProgress = '100';
        _downloadCompletionTime = download.durationInMillis;
      });
      setState(() {
        _uploadRate = upload.transferRate;
        _unitText = upload.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
        _uploadProgress = '100';
        _uploadCompletionTime = upload.durationInMillis;
        _testInProgress = false;
      });
    }, onProgress: (double percent, TestResult data) {
      if (kDebugMode) {
        print('the transfer rate $data.transferRate, the percent $percent');
      }
      setState(() {
        _unitText = data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
        if (data.type == TestType.download) {
          _downloadRate = data.transferRate;
          _downloadProgress = percent.toStringAsFixed(2);
        } else {
          _uploadRate = data.transferRate;
          _uploadProgress = percent.toStringAsFixed(2);
        }
      });
    }, onError: (String errorMessage, String speedTestError) {
      if (kDebugMode) {
        print(
            'the errorMessage $errorMessage, the speedTestError $speedTestError');
      }
      reset();
    }, onDefaultServerSelectionInProgress: () {
      setState(() {
        _isServerSelectionInProgress = true;
      });
    }, onDefaultServerSelectionDone: (Client? client) {
      setState(() {
        _isServerSelectionInProgress = false;
        _ip = client?.ip;
        _asn = client?.asn;
        _isp = client?.isp;
      });
    }, onDownloadComplete: (TestResult data) {
      setState(() {
        _downloadRate = data.transferRate;
        _unitText = data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
        _downloadCompletionTime = data.durationInMillis;
        isTestDownload = false;
      });
    }, onUploadComplete: (TestResult data) {
      setState(() {
        _uploadRate = data.transferRate;
        _unitText = data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
        _uploadCompletionTime = data.durationInMillis;
        isTestDownload = true;
      });
    }, onCancel: () {
      reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('Crave Internet Speed Test')),
        ),
        body: ListView(
          children: <Widget>[
            Container(
              constraints: const BoxConstraints(
                maxWidth: 200,
                maxHeight: 200,
              ),
              child: _buildRadialGauge(),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSpeed(
                  'Download Speed',
                  progress: _downloadProgress,
                  rate: _downloadRate,
                  rateUnit: _unitText,
                  time: _downloadCompletionTime,
                ),
                const SizedBox(height: 16.0),
                _buildSpeed(
                  'Upload Speed',
                  progress: _uploadProgress,
                  rate: _uploadRate,
                  rateUnit: _unitText,
                  time: _uploadCompletionTime,
                ),
              ],
            ),
            const SizedBox(height: 32.0),
            Center(
              child: Text(_isServerSelectionInProgress
                  ? 'Selecting Server...'
                  : 'IP: ${_ip ?? '--'} | ASP: ${_asn ?? '--'} | ISP: ${_isp ?? '--'}'),
            ),
            const SizedBox(height: 16.0),
            if (!_testInProgress) ...{
              Center(child: _button())
            } else ...{
              Center(
                child: Lottie.asset('animations/loading time.json',
                    height: 100,
                    repeat: true,
                    reverse: false,
                    fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton.icon(
                  onPressed: () => internetSpeedTest.cancelTest(),
                  icon: const Icon(Icons.cancel_rounded),
                  label: const Text('Cancel'),
                ),
              )
            },
          ],
        ),
      ),
    );
  }

  ElevatedButton _button() {
    return ElevatedButton(
      child: const Text('Start Testing'),
      onPressed: () async {
        onStartTesting();
      },
    );
  }

  Column _buildSpeed(
    String title, {
    required String progress,
    required double rate,
    required String rateUnit,
    required int time,
  }) {
    return Column(
      // mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text('Progress: $progress%'),
        Text('Download Rate: $rate $rateUnit'),
        if (time > 0)
          Text('Time taken: ${(time / 1000).toStringAsFixed(2)} sec(s)'),
      ],
    );
  }

  SfRadialGauge _buildRadialGauge() {
    return SfRadialGauge(
      title:
          GaugeTitle(text: isTestDownload ? 'Download Speed' : 'Upload Speed'),
      enableLoadingAnimation: true,
      axes: <RadialAxis>[
        RadialAxis(minimum: 0, maximum: 100, ranges: <GaugeRange>[
          GaugeRange(
              startValue: 0,
              endValue: 33,
              color: Colors.red,
              startWidth: 10,
              endWidth: 10),
          GaugeRange(
              startValue: 33,
              endValue: 66,
              color: Colors.orange,
              startWidth: 10,
              endWidth: 10),
          GaugeRange(
              startValue: 66,
              endValue: 100,
              color: Colors.green,
              startWidth: 10,
              endWidth: 10)
        ], pointers: <GaugePointer>[
          NeedlePointer(
            value: isTestDownload ? _downloadRate : _uploadRate,
            enableAnimation: true,
          ),
        ], annotations: <GaugeAnnotation>[
          GaugeAnnotation(
              widget: Text(
                  isTestDownload
                      ? ' $_downloadRate' ' Mbps'
                      : '$_uploadRate' ' Mbps',
                  style: const TextStyle(
                      fontSize: 25, fontWeight: FontWeight.bold)),
              angle: 90,
              positionFactor: 0.5)
        ]),
      ],
    );
  }

  void reset() {
    setState(() {
      {
        _testInProgress = false;
        _downloadRate = 0;
        _uploadRate = 0;
        _downloadProgress = '0';
        _uploadProgress = '0';
        _unitText = 'Mbps';
        _downloadCompletionTime = 0;
        _uploadCompletionTime = 0;

        _ip = null;
        _asn = null;
        _isp = null;
      }
    });
  }
}
