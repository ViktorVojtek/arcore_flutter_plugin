import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';

class ManualGestureExample extends StatefulWidget {
  @override
  _ManualGestureExampleState createState() => _ManualGestureExampleState();
}

class _ManualGestureExampleState extends State<ManualGestureExample> {
  ArCoreController? arCoreController;
  String? selectedNodeName;
  double currentScale = 1.0;
  double currentRotationY = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manual Gesture Control'),
      ),
      body: Stack(
        children: [
          ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated,
            enableTapRecognizer: true,
          ),
          // Manual Controls Overlay
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
                    'Manual Controls',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  
                  // Rotation Controls
                  Text('Rotation', style: TextStyle(color: Colors.white)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _rotateObject(-15),
                        child: Text('← 15°'),
                      ),
                      ElevatedButton(
                        onPressed: () => _rotateObject(-45),
                        child: Text('← 45°'),
                      ),
                      ElevatedButton(
                        onPressed: () => _rotateObject(45),
                        child: Text('45° →'),
                      ),
                      ElevatedButton(
                        onPressed: () => _rotateObject(15),
                        child: Text('15° →'),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Scale Controls
                  Text('Scale', style: TextStyle(color: Colors.white)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _scaleObject(0.8),
                        child: Text('Smaller'),
                      ),
                      ElevatedButton(
                        onPressed: () => _scaleObject(1.0),
                        child: Text('Reset'),
                      ),
                      ElevatedButton(
                        onPressed: () => _scaleObject(1.25),
                        child: Text('Bigger'),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Continuous Controls
                  Text('Continuous Rotation', style: TextStyle(color: Colors.white)),
                  Slider(
                    value: currentRotationY,
                    min: 0,
                    max: 360,
                    divisions: 36,
                    label: '${currentRotationY.round()}°',
                    onChanged: (value) {
                      setState(() {
                        currentRotationY = value;
                      });
                      _setObjectRotation(value);
                    },
                  ),
                  
                  Text('Continuous Scale', style: TextStyle(color: Colors.white)),
                  Slider(
                    value: currentScale,
                    min: 0.1,
                    max: 3.0,
                    divisions: 29,
                    label: '${currentScale.toStringAsFixed(1)}x',
                    onChanged: (value) {
                      setState(() {
                        currentScale = value;
                      });
                      _setObjectScale(value);
                    },
                  ),
                  
                  SizedBox(height: 8),
                  Text(
                    selectedNodeName != null ? 'Selected: $selectedNodeName' : 'Tap to place object',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
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
    arCoreController!.onPlaneTap = _handleOnPlaneOrPointTap;
    
    // Set up gesture callback to receive transformation updates
    arCoreController!.onNodeTransformed = (nodeName, position, rotation) {
      print('Node $nodeName transformed - Position: $position, Rotation: $rotation');
      // Update UI to reflect the transformation
      setState(() {
        // Update current values based on transformation
        selectedNodeName = nodeName;
      });
    };
  }

  void _handleOnPlaneOrPointTap(List<ArCoreHitTestResult> hits) {
    final hit = hits.first;
    _addSimpleGestureNode(hit);
  }

  void _onNodeTapped(String name) {
    print('Node tapped: $name');
    setState(() {
      selectedNodeName = name;
    });
    
    // Show a snackbar to indicate the node is selected for manual control
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected $name for manual control'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _addSimpleGestureNode(ArCoreHitTestResult hitTestResult) {
    final earthNode = ArCoreNode(
      name: "earth_${DateTime.now().millisecondsSinceEpoch}",
      shape: ArCoreSphere(
        materials: [
          ArCoreMaterial(
            color: Colors.blue,
            metallic: 0.0,
            roughness: 0.5,
          ),
        ],
        radius: 0.1,
      ),
      position: hitTestResult.pose.translation,
      rotation: hitTestResult.pose.rotation,
    );

    arCoreController!.addArCoreNode(earthNode);
    setState(() {
      selectedNodeName = earthNode.name;
    });
    
    print('Added node: ${earthNode.name}');
  }

  void _rotateObject(double degrees) {
    if (selectedNodeName == null || arCoreController == null) {
      _showMessage('No object selected');
      return;
    }

    setState(() {
      currentRotationY = (currentRotationY + degrees) % 360;
    });
    
    _showMessage('Rotation: ${currentRotationY.round()}° (Manual control - node update not implemented)');
    print('Would rotate $selectedNodeName by $degrees degrees to total ${currentRotationY}°');
  }

  void _setObjectRotation(double degrees) {
    if (selectedNodeName == null || arCoreController == null) return;
    
    setState(() {
      currentRotationY = degrees;
    });
    
    print('Would set rotation of $selectedNodeName to $degrees degrees');
    _showMessage('Rotation: ${degrees.round()}°');
  }

  void _scaleObject(double scaleFactor) {
    if (selectedNodeName == null || arCoreController == null) {
      _showMessage('No object selected');
      return;
    }

    setState(() {
      currentScale = scaleFactor;
    });
    
    _setObjectScale(scaleFactor);
  }

  void _setObjectScale(double scale) {
    if (selectedNodeName == null || arCoreController == null) return;
    
    // Note: Direct scaling might not be available in the plugin
    // This is a placeholder for custom scaling implementation
    print('Requested scale for $selectedNodeName: ${scale}x');
    _showMessage('Scale: ${scale.toStringAsFixed(1)}x');
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  void dispose() {
    arCoreController?.dispose();
    super.dispose();
  }
}
