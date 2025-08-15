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
  bool _useGLBModel = false; // Flag to determine which object to place

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
                        ? 'Plane detected! Tap on the plane to place ${_useGLBModel ? "grill model" : "cube"}.'
                        : 'Move your device to detect surfaces. Toggle the button to switch between cube and grill model.'),
                    duration: Duration(seconds: 3),
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
            // Model selection button
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _useGLBModel ? Colors.green.shade600 : Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _useGLBModel = !_useGLBModel;
                      // Allow placing new object
                      _objectPlaced = false;
                    });
                    print('Toggle button pressed - now using: ${_useGLBModel ? "GLB Model" : "Blue Cube"}');
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _useGLBModel ? Icons.kitchen : Icons.view_in_ar,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        _useGLBModel ? 'GLB Grill' : 'Blue Cube',
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                      ? 'Plane detected! Tap on the plane to place ${_useGLBModel ? "grill model" : "cube"}.'
                      : 'Move your device to detect surfaces. Use the toggle button to switch between models.',
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
    if (_useGLBModel) {
      // Place GLB grill model with gesture support
      final node = ArCoreReferenceNode(
        name: 'grill_model_${DateTime.now().millisecondsSinceEpoch}',
        objectUrl: "https://storage.googleapis.com/room-bucket/grill_vulcanus_pro730_masterchef-729db30b-5d45-4fed-b85e-4b7f037f5a9d.glb",
        position: position,
        scale: vector.Vector3(1.0, 1.0, 1.0), // Scale down the model if needed
        // Enable gesture handling for GLB model
        isTransformable: true,
        enablePanGestures: true,
        enableRotationGestures: true,
      );
      
      arCoreController?.addArCoreNodeWithAnchor(node);
    } else {
      // Place blue cube (original logic)
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
  }

  @override
  void dispose() {
    arCoreController?.dispose();
    super.dispose();
  }
}
