import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class WorkingGestureExample extends StatefulWidget {
  @override
  _WorkingGestureExampleState createState() => _WorkingGestureExampleState();
}

class _WorkingGestureExampleState extends State<WorkingGestureExample> {
  ArCoreController? arCoreController;
  String? selectedNodeName;
  double currentScale = 1.0;
  double currentRotationY = 0.0;
  bool isObjectPlaced = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Working Gesture Control'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          // AR View
          ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated,
            enableTapRecognizer: true,
            enablePlaneRenderer: true,
          ),
          
          // Instructions overlay
          if (!isObjectPlaced)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '👆 Tap on a detected surface (white dots) to place a blue cube',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          
          // Manual Controls - Always visible
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Manual Controls',
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isObjectPlaced ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isObjectPlaced ? 'Object Placed' : 'No Object',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Quick Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickButton('⬅️ Left', () => _rotateObject(-45)),
                      _buildQuickButton('🔄 Spin', () => _rotateObject(90)),
                      _buildQuickButton('➡️ Right', () => _rotateObject(45)),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickButton('⬇️ Small', () => _scaleObject(0.7)),
                      _buildQuickButton('🔄 Reset', () => _resetObject()),
                      _buildQuickButton('⬆️ Big', () => _scaleObject(1.4)),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Continuous Controls
                  Text('Rotation: ${currentRotationY.round()}°', 
                       style: TextStyle(color: Colors.white)),
                  Slider(
                    value: currentRotationY,
                    min: 0,
                    max: 360,
                    divisions: 36,
                    activeColor: Colors.blue,
                    onChanged: isObjectPlaced ? (value) {
                      setState(() {
                        currentRotationY = value;
                      });
                      _setObjectRotation(value);
                    } : null,
                  ),
                  
                  Text('Scale: ${currentScale.toStringAsFixed(1)}x', 
                       style: TextStyle(color: Colors.white)),
                  Slider(
                    value: currentScale,
                    min: 0.3,
                    max: 3.0,
                    divisions: 27,
                    activeColor: Colors.blue,
                    onChanged: isObjectPlaced ? (value) {
                      setState(() {
                        currentScale = value;
                      });
                      _setObjectScale(value);
                    } : null,
                  ),
                  
                  SizedBox(height: 8),
                  Text(
                    selectedNodeName != null 
                        ? 'Controlling: $selectedNodeName' 
                        : (isObjectPlaced ? 'Object placed - use controls above' : 'Place an object first'),
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: isObjectPlaced ? onPressed : null,
      child: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size(70, 35),
      ),
    );
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    arCoreController!.onNodeTap = _onNodeTapped;
    arCoreController!.onPlaneTap = _handleOnPlaneTap;
    
    print('✅ ARCore controller created and configured');
  }

  void _handleOnPlaneTap(List<ArCoreHitTestResult> hits) {
    final hit = hits.first;
    _addGestureNode(hit);
  }

  void _onNodeTapped(String name) {
    print('Node tapped: $name');
    setState(() {
      selectedNodeName = name;
    });
    
    _showMessage('Selected $name');
  }

  void _addGestureNode(ArCoreHitTestResult hitTestResult) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nodeName = "manual_cube_$timestamp";
    
    final cubeNode = ArCoreNode(
      name: nodeName,
      shape: ArCoreCube(
        materials: [
          ArCoreMaterial(
            color: Colors.blue,
            metallic: 0.0,
            roughness: 0.4,
          ),
        ],
        size: vector.Vector3(0.2, 0.2, 0.2), // Smaller cube
      ),
      position: hitTestResult.pose.translation,
      rotation: hitTestResult.pose.rotation,
    );

    arCoreController!.addArCoreNode(cubeNode);
    
    setState(() {
      selectedNodeName = nodeName;
      isObjectPlaced = true;
      currentScale = 1.0;
      currentRotationY = 0.0;
    });
    
    print('✅ Added manual control cube: $nodeName');
    _showMessage('Cube placed! Use controls below');
  }

  void _rotateObject(double degrees) {
    if (!isObjectPlaced || arCoreController == null) {
      _showMessage('Place an object first');
      return;
    }

    setState(() {
      currentRotationY = (currentRotationY + degrees) % 360;
    });
    
    // Call the Android method to actually rotate the object
    try {
      arCoreController!.rotateSelectedNode(degrees);
      _showMessage('Rotated by ${degrees.round()}°');
      print('🔄 Called rotateSelectedNode with: ${degrees.round()}°');
    } catch (e) {
      _showMessage('Rotation failed: $e');
      print('❌ Rotation error: $e');
    }
  }

  void _setObjectRotation(double degrees) {
    if (!isObjectPlaced || arCoreController == null) return;
    
    try {
      arCoreController!.setNodeRotation(degrees);
      print('🔄 Set rotation to: ${degrees.round()}°');
    } catch (e) {
      print('❌ Set rotation error: $e');
    }
  }

  void _scaleObject(double scaleFactor) {
    if (!isObjectPlaced || arCoreController == null) {
      _showMessage('Place an object first');
      return;
    }

    setState(() {
      currentScale *= scaleFactor;
      currentScale = currentScale.clamp(0.3, 3.0);
    });
    
    try {
      arCoreController!.scaleSelectedNode(scaleFactor);
      _showMessage('Scaled to ${currentScale.toStringAsFixed(1)}x');
      print('📏 Called scaleSelectedNode with: ${scaleFactor}x');
    } catch (e) {
      _showMessage('Scaling failed: $e');
      print('❌ Scaling error: $e');
    }
  }

  void _setObjectScale(double scale) {
    if (!isObjectPlaced || arCoreController == null) return;
    
    try {
      arCoreController!.setNodeScale(scale);
      print('📏 Set scale to: ${scale.toStringAsFixed(1)}x');
    } catch (e) {
      print('❌ Set scale error: $e');
    }
  }

  void _resetObject() {
    if (!isObjectPlaced || arCoreController == null) {
      _showMessage('Place an object first');
      return;
    }

    setState(() {
      currentScale = 1.0;
      currentRotationY = 0.0;
    });
    
    try {
      arCoreController!.resetSelectedNode();
      _showMessage('Reset to original size and rotation');
      print('🔄 Called resetSelectedNode');
    } catch (e) {
      _showMessage('Reset failed: $e');
      print('❌ Reset error: $e');
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.blue,
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
