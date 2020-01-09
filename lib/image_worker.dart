import "dart:async";
import "dart:developer";
import "dart:isolate";
import "dart:ffi" as ffi;
import "dart:typed_data";

import "package:camera/camera.dart";
import "package:image_processing_plugin/image_processing_plugin.dart";
import "package:image_processing_plugin/allocation.dart";

class ImageWorker { // Based on the example code provided by google here https://github.com/filiph/hn_app/blob/master/lib/src/notifiers/worker.dart
	SendPort _sendPort;
	Isolate _isolate;
	Completer<bool> _processingResult;
	final _isolateReady = Completer<void>();
	static ffi.Pointer<ffi.Uint8> _data;
	static Uint8List _bytes;

	Future<void> get isReady => _isolateReady.future;
	
	void dispose() {
		_isolate?.kill();
		_isolate = null;
		if (_data != null) {
			free(_data);
		}
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

	static void concatenatePlanes(List<Plane> planes) {
		int totalBytes = 0;
		for (int i = 0; i < planes.length; ++i) {
			totalBytes += planes[i].bytes.length;
		}
		if (_data == null) {
			_data = allocate<ffi.Uint8>(count: totalBytes);
			_bytes = _data.asTypedList(totalBytes);
		}
		int byteOffset = 0;
		for (int i = 0; i < planes.length; ++i) {
			final length = planes[i].bytes.length;
			_bytes.setRange(byteOffset, byteOffset += length, planes[i].bytes);
		}
	}

	static bool runImageProcessing(CameraImage image) {
		int time = DateTime.now().millisecondsSinceEpoch;
		print("ZZZZZ runImageProcessing entered. $time");
		Timeline.startSync("image_worker: concatenate plane data");
		concatenatePlanes(image.planes);
		Timeline.finishSync();
		print("ZZZZZ runImageProcessing: concatenate plane data: ${DateTime.now().millisecondsSinceEpoch - time}ms");

		Timeline.startSync("image_worker: process image");
		double result = ImageProcessingPlugin().processImage(_data, image.width, image.height, image.planes[0].bytesPerRow);
		Timeline.finishSync();
		print("ZZZZZ runImageProcessing: leaving. ${DateTime.now().millisecondsSinceEpoch}");
		return false; // No image processing occurs so no real point to this result at the moment.
	}
}