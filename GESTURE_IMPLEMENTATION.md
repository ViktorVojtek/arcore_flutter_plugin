# ARCore Flutter Plugin - Gesture Implementation

## Overview
Successfully implemented pan and rotation gestures for ARCore objects using Android-side TransformableNode for optimal performance.

## Features Implemented

### 1. Flutter-Side Gesture Properties
- **isTransformable**: Boolean flag to enable/disable gesture handling on a node
- **enablePanGestures**: Boolean flag to enable pan (drag) gestures
- **enableRotationGestures**: Boolean flag to enable rotation gestures

### 2. Flutter-Side Gesture Callbacks
- **ArCoreGestureHandler**: Typedef for gesture event callbacks
- **onNodeTransformed**: Callback that fires when a node is transformed via gestures
  - Parameters: `String nodeName`, `Vector3 position`, `Vector4 rotation`

### 3. Android-Side Implementation
- **GestureTransformableNode**: Custom TransformableNode that reports transformations back to Flutter
- **TransformationSystem**: Integrated Sceneform's native gesture handling system
- **NodeFactory**: Updated to create transformable nodes when needed

## Usage

### Basic Setup
```dart
final node = ArCoreNode(
  shape: ArCoreCube(materials: [material], size: Vector3(0.3, 0.3, 0.3)),
  position: Vector3(0, 0, -1.5),
  // Enable gesture handling
  isTransformable: true,
  enablePanGestures: true,
  enableRotationGestures: true,
  name: 'gesture_cube',
);

// Set up gesture callback
arCoreController?.onNodeTransformed = (String nodeName, Vector3 position, Vector4 rotation) {
  print('Node $nodeName transformed - Position: $position, Rotation: $rotation');
};

// Add the node
arCoreController?.addArCoreNode(node);
```

### Example Screen
Created `gesture_example.dart` demonstrating:
- Blue cube with gesture handling enabled
- Callback implementation for transformation events
- Add button to create additional gesturable objects

## Technical Architecture

### Flow
1. Flutter sets gesture properties on ArCoreNode
2. Properties passed through MethodChannel to Android
3. NodeFactory conditionally creates GestureTransformableNode vs regular Node
4. TransformationSystem handles native gesture recognition
5. GestureTransformableNode reports transformations back to Flutter via MethodChannel
6. Flutter triggers onNodeTransformed callback

### Performance Considerations
- **Native gesture handling**: Uses Android's native TransformationSystem for smooth performance
- **Minimal channel communication**: Only reports final transformation results, not intermediate gesture events
- **Conditional creation**: Only creates TransformableNodes when isTransformable=true

## Files Modified

### Flutter Side (Dart)
- `lib/src/arcore_node.dart`: Added gesture properties
- `lib/src/arcore_controller.dart`: Added gesture callback handling
- `example/lib/screens/gesture_example.dart`: Created demonstration screen
- `example/lib/home.dart`: Added gesture example to menu

### Android Side (Kotlin)
- `android/.../models/GestureTransformableNode.kt`: New TransformableNode subclass
- `android/.../flutter_models/FlutterArCoreNode.kt`: Added gesture properties support
- `android/.../NodeFactory.kt`: Added makeTransformableNode method
- `android/.../ArCoreView.kt`: Integrated TransformationSystem and conditional node creation

## Gesture Types Supported

### Pan Gestures
- **Single-finger drag**: Move objects along detected plane surfaces
- **2D movement on 3D surface**: Objects follow detected planes naturally
- **No collision detection**: Objects can overlap and move freely

### Rotation Gestures
- **Two-finger rotation**: Rotate objects around their local axes
- **Smooth native performance**: Leverages Sceneform's optimized gesture recognition
- **Real-time feedback**: Immediate visual response during gestures

## Testing

### Verification
- Flutter code compiles successfully
- Android integration builds without errors
- Example app demonstrates functionality
- Gesture callbacks properly triggered

### Manual Testing Steps
1. Run example app
2. Navigate to "Gesture Example - Pan & Rotate"
3. Tap to place blue cube in AR space
4. Use single finger to pan/drag cube
5. Use two fingers to rotate cube
6. Observe console logs showing transformation events

## Future Enhancements

### Possible Extensions
- Scale gestures (pinch to zoom)
- Constraint systems (limit movement/rotation ranges)
- Collision detection and physics
- Multi-object gesture handling
- Custom gesture recognizers

### Performance Optimizations
- Gesture batching for multiple objects
- Gesture priority systems
- Memory management for large scenes

## Compatibility
- **Flutter**: 3.32.4+
- **Sceneform**: 1.17.1
- **ARCore**: Compatible with existing plugin architecture
- **Android**: Minimum SDK as per existing plugin requirements
