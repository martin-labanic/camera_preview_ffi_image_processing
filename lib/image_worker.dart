import "dart:async";
import 'dart:developer';
import "dart:isolate";
import "dart:typed_data";

import "package:camera/camera.dart";
import "package:flutter/foundation.dart";
import "package:image_processing_plugin/image_processing_plugin.dart";

class ImageWorker { // Based on the example code provided by google here https://github.com/filiph/hn_app/blob/master/lib/src/notifiers/worker.dart
	SendPort _sendPort;
	Isolate _isolate;
	Completer<bool> _processingResult;
	final _isolateReady = Completer<void>();

	Future<void> get isReady => _isolateReady.future;

	Worker() {
		init();
	}

	void dispose() {
		_isolate?.kill();
		_isolate = null;
	}

	Future<bool> processCameraData(CameraImage image) async {
		_sendPort.send(image);
		_processingResult = Completer<bool>();
		return _processingResult.future;
	}

	Future<void> init() async {
		final receivePort = ReceivePort();
		final errorPort = ReceivePort();
		errorPort.listen(print);

		receivePort.listen(_handleMessage);
		_isolate = await Isolate.spawn(
			_isolateEntry,
			receivePort.sendPort,
			onError: errorPort.sendPort,
		);
	}

	void _handleMessage(dynamic message) {
		if (message is SendPort) {
			_sendPort = message;
			_isolateReady.complete();
			return;
		}
		if (message is bool) {
			_processingResult?.complete(message);
			_processingResult = null;
			return;
		}

		throw UnimplementedError("Undefined behavior for message: $message");
	}

	static void _isolateEntry(dynamic message) {
		SendPort sendPort;
		final receivePort = ReceivePort();

		receivePort.listen((dynamic message) async {
			assert(message is CameraImage);
			try {
				Timeline.startSync("image_worker: image processing on the isolate");
				final result = await runImageProcessing(message as CameraImage);
				Timeline.finishSync();
				sendPort.send(result);
			} finally {
//				client.close();
			}
		});

		if (message is SendPort) {
			sendPort = message;
			sendPort.send(receivePort.sendPort);
			return;
		}
	}

	static Uint8List concatenatePlanes(List<Plane> planes) {
		final WriteBuffer allBytes = WriteBuffer();
		planes.forEach((Plane plane) => allBytes.putUint8List(plane.bytes));
		return allBytes.done().buffer.asUint8List();
	}

	static bool runImageProcessing(CameraImage image) {
		int time = DateTime.now().millisecondsSinceEpoch;
		print("ZZZZZ runImageProcessing entered. $time");
		Timeline.startSync("image_worker: concatenate image plane data");
		Uint8List data = concatenatePlanes(image.planes);
		Timeline.finishSync();
		print("ZZZZZ runImageProcessing: concatenate plane data: ${DateTime.now().millisecondsSinceEpoch - time}ms");

		Timeline.startSync("image_worker: process image");
		double result = ImageProcessingPlugin().processImage(data, image.width, image.height, image.planes[0].bytesPerRow);
		Timeline.finishSync();
		print("ZZZZZ runImageProcessing: leaving. ${DateTime.now().millisecondsSinceEpoch}");
		return false; // No image processing occurs so no real point to this result at the moment.
	}
}