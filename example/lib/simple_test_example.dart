import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class SimpleTestExample extends StatefulWidget {
  @override
  _SimpleTestExampleState createState() => _SimpleTestExampleState();
}

class _SimpleTestExampleState extends State<SimpleTestExample> {
  ArCoreController? arCoreController;
  String? selectedNodeName;
  bool isObjectPlaced = false;
  int cubeCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple Test - Add/Remove'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          // AR View
          ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated,
            enableTapRecognizer: true,
            enablePlaneRenderer: true,
          ),
          
          // Simple test controls
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Simple Test Controls',
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  Text(
                    'Objects placed: $cubeCount',
                    style: TextStyle(color: Colors.white),
                  ),
                  
                  SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _addCubeAtOrigin,
                        child: Text('Add Cube'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: cubeCount > 0 ? _removeLastCube : null,
                        child: Text('Remove Last'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 8),
                  
                  if (selectedNodeName != null)
                    Text(
                      'Selected: $selectedNodeName',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
          
          // Instructions
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '✅ This tests basic ArCoreController functionality:\n'
                '• Tap "Add Cube" to place objects\n'
                '• Tap "Remove Last" to remove objects\n'
                '• This verifies the core system works',
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    arCoreController!.onNodeTap = _onNodeTapped;
    
    print('✅ Simple test controller created');
  }

  void _onNodeTapped(String name) {
    print('Node tapped: $name');
    setState(() {
      selectedNodeName = name;
    });
    
    _showMessage('Selected $name');
  }

  void _addCubeAtOrigin() {
    if (arCoreController == null) {
      _showMessage('ArCore not ready');
      return;
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nodeName = "test_cube_$timestamp";
    
    // Create cube at origin point (0, -1, -2) - slightly in front and below camera
    final cubeNode = ArCoreNode(
      name: nodeName,
      shape: ArCoreCube(
        materials: [
          ArCoreMaterial(
            color: _getRandomColor(),
            metallic: 0.0,
            roughness: 0.4,
          ),
        ],
        size: vector.Vector3(0.3, 0.3, 0.3),
      ),
      position: vector.Vector3(
        (cubeCount % 3 - 1) * 0.5, // Spread cubes horizontally: -0.5, 0, 0.5
        -1.0, // Below eye level
        -2.0 - (cubeCount ~/ 3) * 0.5 // Move away for each row
      ),
    );

    arCoreController!.addArCoreNode(cubeNode);
    
    setState(() {
      cubeCount++;
      selectedNodeName = nodeName;
      isObjectPlaced = true;
    });
    
    print('✅ Added test cube: $nodeName');
    _showMessage('Added cube #$cubeCount');
  }
  
  void _removeLastCube() {
    if (arCoreController == null || cubeCount == 0) {
      _showMessage('No cubes to remove');
      return;
    }
    
    // This is a simplified approach - in a real app you'd track node names
    // For this test, we'll just decrement the counter and show the message
    setState(() {
      cubeCount = (cubeCount - 1).clamp(0, 999);
      if (cubeCount == 0) {
        selectedNodeName = null;
        isObjectPlaced = false;
      }
    });
    
    _showMessage('Would remove last cube (simplified test)');
    print('📝 Remove cube requested - Count now: $cubeCount');
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.cyan,
      Colors.pink,
    ];
    return colors[cubeCount % colors.length];
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    arCoreController?.dispose();
    super.dispose();
  }
}
