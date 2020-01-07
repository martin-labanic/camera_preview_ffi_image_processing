import "package:camera/camera.dart";
import "package:flutter_app/image_worker.dart";

abstract class CameraHook {
  void setup();
  bool isReady();
  void dispose();
}

class ProcessingHook extends CameraHook {
  ImageWorker _worker;
  bool _workerReady = false;

  void setup() async {
    // Setup the isolate that is going to process the image data.
    _worker = ImageWorker();
    await _worker.init();
    _workerReady = true;
  }

  bool isReady() {
    return _workerReady;
  }

  Future<bool> processCameraData(CameraImage image) async {
    return _worker.processCameraData(image);
  }

  void dispose() {
    _worker?.dispose();
    _worker = null;
  }
}