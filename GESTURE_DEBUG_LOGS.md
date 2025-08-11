# ARCore Flutter Plugin - Gesture Debugging Logs

## Logging Added - Complete Debug Coverage

To help debug why pan and rotation gestures aren't working, I've added comprehensive logging throughout the entire gesture pipeline:

## 1. Flutter Side Logging ✅

### ArCoreController.dart
- **Node Creation**: Logs when nodes are added with gesture properties
- **Callback Reception**: Logs when `onNodeTransformed` callbacks are received from Android
- **Parameter Details**: Shows gesture flags, node names, and transformation data

**Look for these logs:**
```
[ArCoreController] Adding node: gesture_cube_xxxxx
[ArCoreController] isTransformable: true
[ArCoreController] enablePanGestures: true
[ArCoreController] enableRotationGestures: true
[ArCoreController] Received onNodeTransformed callback
[ArCoreController] Node gesture_cube_xxxxx transformed - Position: [x,y,z], Rotation: [x,y,z,w]
```

### GestureExample.dart
- **Debug Enabled**: Set `debug: true` on ArCoreView to enable all logging
- **User Callback**: Your `_onNodeTransformed` method will show transformation events

## 2. Android Side Logging ✅

### ArCoreView.kt
- **Node Decision Logic**: Shows whether transformable or regular nodes are created
- **TransformationSystem Status**: Confirms if TransformationSystem is available
- **Gesture Properties**: Logs the gesture flags received from Flutter

**Look for these logs:**
```
isTransformable: true
enablePanGestures: true
enableRotationGestures: true
transformationSystem available: true
Creating TRANSFORMABLE node for gesture_cube_xxxxx
```

### NodeFactory.kt
- **Transformable Node Creation**: Detailed logging during GestureTransformableNode creation
- **Renderable Attachment**: Confirms when renderables are successfully attached
- **Error Handling**: Shows if there are any failures in node creation

**Look for these logs:**
```
Creating TRANSFORMABLE node: gesture_cube_xxxxx
enablePanGestures: true
enableRotationGestures: true
buildTransformableNode returned: [Node object]
Renderable created successfully, attaching to transformable node
```

### GestureTransformableNode.kt
- **Node Creation**: Logs when gesture nodes are instantiated
- **Touch Events**: Shows when touch events are received on gesture-enabled objects
- **Gesture Settings**: Confirms controller enable/disable status
- **Transformation Reporting**: Detailed position/rotation change tracking

**Look for these logs:**
```
GestureTransformableNode created for: gesture_cube_xxxxx
Touch event received on node: gesture_cube_xxxxx, action: [action_code]
Updating gesture settings for gesture_cube_xxxxx: pan=true, rotation=true
Gesture controllers updated: translation=true, rotation=true
reportTransformation called for node: gesture_cube_xxxxx
Current position: [x,y,z], rotation: [x,y,z,w]
Significant change detected, sending to Flutter
```

## 3. How to Use the Debug Logs

### Step 1: Enable Logging
```dart
// In gesture_example.dart (already done)
ArCoreView(
  debug: true, // This enables all debug logging
  onArCoreViewCreated: _onArCoreViewCreated,
)
```

### Step 2: Run and Monitor Logs

**Flutter logs (console):**
```bash
flutter run
# Watch for [ArCoreController] prefixed messages
```

**Android logs (logcat):**
```bash
# In another terminal
adb logcat -s "GestureTransformableNode" "NodeFactory" "flutter"
```

### Step 3: Test Gesture Sequence

1. **Launch app** → Look for node creation logs
2. **Tap cube to select** → Look for touch event logs
3. **Try pan gesture** → Look for transformation logs
4. **Try rotation gesture** → Look for controller activity logs

## 4. Troubleshooting Guide

### If you see "Creating REGULAR node" instead of "Creating TRANSFORMABLE node":
- Check if `isTransformable: true` is set on your ArCoreNode
- Verify TransformationSystem initialization didn't fail

### If no touch events are logged:
- Object might not be selectable/tappable
- Check if object is visible and within reach
- Verify AR tracking is working

### If touch events but no transformations:
- Controllers might be disabled (check gesture settings logs)
- TransformationSystem might not be properly configured
- Gesture recognition might be failing

### If transformations but no Flutter callbacks:
- MethodChannel communication issue
- Check `onNodeTransformed` callback is set
- Look for callback reception logs

## 5. Expected Log Flow (Successful Gesture)

```
1. [ArCoreController] Adding node: gesture_cube_xxxxx
2. [ArCoreController] isTransformable: true
3. Creating TRANSFORMABLE node for gesture_cube_xxxxx  
4. GestureTransformableNode created for: gesture_cube_xxxxx
5. Renderable created successfully, attaching to transformable node
6. [User taps and drags object]
7. Touch event received on node: gesture_cube_xxxxx
8. reportTransformation called for node: gesture_cube_xxxxx
9. Significant change detected, sending to Flutter
10. [ArCoreController] Received onNodeTransformed callback
11. Node gesture_cube_xxxxx transformed - Position: [x,y,z]
```

## 6. Quick Debug Test

Run the example app and immediately check for these key indicators:

✅ **Node created as transformable**: `Creating TRANSFORMABLE node`
✅ **Touch events received**: `Touch event received on node`  
✅ **Gesture controllers enabled**: `translation=true, rotation=true`
✅ **Transformations detected**: `Significant change detected`
✅ **Flutter callbacks working**: `onNodeTransformed callback`

This comprehensive logging will show exactly where in the gesture pipeline things might be failing!
