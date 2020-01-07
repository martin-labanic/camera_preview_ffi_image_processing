import 'dart:developer';

import "package:camera/camera.dart";
import "package:flutter/material.dart";
import "package:flutter_app/camera_hooks.dart";
import "package:wakelock/wakelock.dart";

class TCameraPreview extends StatefulWidget {
	@override
	_TCameraPreviewState createState() {
		return _TCameraPreviewState();
	}
}

class _TCameraPreviewState extends State<TCameraPreview>{
	CameraController _cameraController;
	List<CameraDescription> _availableCameras;
	bool _isRunning = false;
	bool _detected = false;
	ProcessingHook _cameraHook;

	@override
	void initState() {
		super.initState();
		this.setupCameraPreview();
		Wakelock.enable();
	}

	void setupCameraPreview() async {
		_availableCameras = await availableCameras();
		_cameraController = CameraController(_availableCameras[1], ResolutionPreset.medium); // ZZZZZ Setting this to ResolutionPreset.low does not appear to change the frequency of gc events in the log.
		await _cameraController.initialize().then((_) {
			if (!mounted) {
				return;
			}
			setState(() {});
		});

		_cameraHook = ProcessingHook();
		await _cameraHook.setup();
		await _cameraController.startImageStream((CameraImage image) async {
			if (_isRunning || _cameraHook == null || !_cameraHook.isReady()) {
				return;
			}
			_isRunning = true;
			try {
				int time = DateTime.now().millisecondsSinceEpoch;
				print("ZZZZZ startImageStream: sending image data to processing isolate. $time");
				Timeline.startSync("camera_preview_test: passing the data off for processing on another isolate");
				bool detected = await _cameraHook.processCameraData(image);
				Timeline.finishSync();
				print("ZZZZZ startImageStream: returned from isolate. ${DateTime.now().millisecondsSinceEpoch}");
				if (detected != _detected) {
					updateDetected(detected);
				}
				print("-------------------------- startImageStream: processed camera data in ${DateTime.now().millisecondsSinceEpoch - time}ms --------------------------");
			} catch (e) {
				print("ZZZZZ startImageStream: Exception: ${e.toString()}");
			} finally {
				_isRunning = false;
			}
		}
		);
	}

	void updateDetected(bool detected) {
		setState(() {
			_detected = detected;
		});
	}

	@override
	void dispose() {
		_cameraController?.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		if (_cameraController == null || !_cameraController.value.isInitialized) {
			return Container();
		}
		return Stack(
			children: <Widget>[
				AspectRatio(
					aspectRatio: _cameraController.value.aspectRatio,
					child: CameraPreview(_cameraController)
				),
				Align(
					alignment: Alignment.topRight,
					child: Container(
						color: _detected ? Colors.green : Colors.pink,
						height: 50.0,
						width: 50.0,
					),
				)
			]
		);
	}
}
