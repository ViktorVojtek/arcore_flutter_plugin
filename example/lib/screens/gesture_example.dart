import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class GestureExample extends StatefulWidget {
  @override
  _GestureExampleState createState() => _GestureExampleState();
}

class _GestureExampleState extends State<GestureExample> {
  ArCoreController? arCoreController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Gesture Example'),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _addGestureObject,
            ),
          ],
        ),
        body: ArCoreView(
          onArCoreViewCreated: _onArCoreViewCreated,
          enableUpdateListener: false,
          debug: true, // Enable debug logging
        ),
      ),
    );
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    
    // Set up gesture handler
    arCoreController?.onNodeTransformed = _onNodeTransformed;

    _addGestureObject();
  }

  void _onNodeTransformed(String nodeName, vector.Vector3 position, vector.Vector4 rotation) {
    print('Node $nodeName transformed - Position: $position, Rotation: $rotation');
    // Handle the transformation event - e.g., update UI, sync with server, etc.
  }

  Future _addGestureObject() async {
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
      position: vector.Vector3(0, 0, -1.5),
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
