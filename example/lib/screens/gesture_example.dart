import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class GestureExample extends StatefulWidget {
  @override
  _GestureExampleState createState() => _GestureExampleState();
}

class _GestureExampleState extends State<GestureExample> {
  ArCoreController? arCoreController;
  bool _planeDetected = false;
  bool _objectPlaced = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Gesture Example'),
          actions: [
            IconButton(
              icon: Icon(Icons.info),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_objectPlaced 
                      ? 'Object placed! Use gestures to manipulate it.' 
                      : _planeDetected 
                        ? 'Plane detected! Tap on the plane to place object.'
                        : 'Move your device to detect surfaces.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            ArCoreView(
              onArCoreViewCreated: _onArCoreViewCreated,
              enableUpdateListener: true, // Enable update listener for plane detection
              enableTapRecognizer: true, // Enable tap recognition for gestures
              enablePlaneRenderer: true, // Show detected planes
              debug: true, // Enable debug logging
            ),
            // Status indicator
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _objectPlaced 
                    ? 'Object placed! Use gestures to manipulate it.' 
                    : _planeDetected 
                      ? 'Plane detected! Tap on the plane to place object.'
                      : 'Move your device to detect surfaces...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    
    // Set up gesture handler
    arCoreController?.onNodeTransformed = _onNodeTransformed;
    
    // Set up plane tap handler to place objects on detected planes
    arCoreController?.onPlaneTap = _onPlaneTap;
    
    // Set up plane detection handler to update UI
    arCoreController?.onPlaneDetected = _onPlaneDetected;
    
    // Don't add object automatically - wait for plane detection and tap
    print('ARCore view created. Move your device to detect surfaces, then tap to place object.');
  }

  void _onPlaneDetected(ArCorePlane plane) {
    if (!_planeDetected) {
      setState(() {
        _planeDetected = true;
      });
      print('Plane detected! Tap on the plane to place your object.');
    }
  }

  void _onNodeTransformed(String nodeName, vector.Vector3 position, vector.Vector4 rotation) {
    print('Node $nodeName transformed - Position: $position, Rotation: $rotation');
    // Handle the transformation event - e.g., update UI, sync with server, etc.
  }

  void _onPlaneTap(List<ArCoreHitTestResult> hits) {
    if (_objectPlaced || hits.isEmpty) return;
    
    // Get the first hit result (closest plane)
    final hit = hits.first;
    
    // Place the cube at the tapped location on the plane
    _addGestureObjectAtPosition(hit.pose.translation);
    
    setState(() {
      _planeDetected = true;
      _objectPlaced = true;
    });
    
    print('Object placed on plane at position: ${hit.pose.translation}');
  }

  Future _addGestureObjectAtPosition(vector.Vector3 position) async {
    final material = ArCoreMaterial(
      color: Colors.blue,
      metallic: 0.8,
      roughness: 0.2,
    );
    
    final cube = ArCoreCube(
      materials: [material],
      size: vector.Vector3(0.3, 0.3, 0.3),
    );
    
    final node = ArCoreNode(
      shape: cube,
      position: position, // Use the detected plane position
      // Enable gesture handling
      isTransformable: true,
      enablePanGestures: true,
      enableRotationGestures: true,
      name: 'gesture_cube_${DateTime.now().millisecondsSinceEpoch}',
    );
    
    arCoreController?.addArCoreNode(node);
  }

  @override
  void dispose() {
    arCoreController?.dispose();
    super.dispose();
  }
}
