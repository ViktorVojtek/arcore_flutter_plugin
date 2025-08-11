package com.difrancescogianmarco.arcore_flutter_plugin.models

import android.util.Log
import com.google.ar.sceneform.Node
import com.google.ar.sceneform.FrameTime
import com.google.ar.sceneform.ux.TransformableNode
import com.google.ar.sceneform.ux.TransformationSystem
import io.flutter.plugin.common.MethodChannel

/**
 * A simplified TransformableNode with Flutter gesture callbacks
 */
class GestureTransformableNode(
    private val transformationSystem: TransformationSystem,
    private val methodChannel: MethodChannel,
    private val nodeName: String
) : TransformableNode(transformationSystem) {

    private val TAG = "GestureTransformableNode"

    var enablePanGestures: Boolean = true
        set(value) {
            field = value
            Log.d(TAG, "enablePanGestures set to: $value for node: $nodeName")
            updateGestureSettings()
        }

    var enableRotationGestures: Boolean = true
        set(value) {
            field = value
            Log.d(TAG, "enableRotationGestures set to: $value for node: $nodeName")
            updateGestureSettings()
        }

    init {
        Log.i(TAG, "GestureTransformableNode created for: $nodeName")
        Log.i(TAG, "Pan enabled: $enablePanGestures, Rotation enabled: $enableRotationGestures")
        updateGestureSettings()
        
        // Enable node selection when tapped
        setOnTapListener { _, _ ->
            Log.i(TAG, "Node $nodeName tapped - selecting for transformation")
            transformationSystem.selectNode(this)
            Log.i(TAG, "Node $nodeName selected for transformation")
            true
        }
    }

    private fun updateGestureSettings() {
        Log.d(TAG, "Updating gesture settings for $nodeName: pan=$enablePanGestures, rotation=$enableRotationGestures")
        
        // Configure gesture controllers
        try {
            scaleController.isEnabled = false // Disable scaling
            translationController.isEnabled = enablePanGestures
            rotationController.isEnabled = enableRotationGestures
            Log.d(TAG, "Gesture controllers updated successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error updating gesture controllers: ${e.message}")
        }
    }

    // Simple reporting method - can be called when needed
    fun reportCurrentTransformation() {
        try {
            val data = mapOf(
                "nodeName" to nodeName,
                "position" to listOf(localPosition.x, localPosition.y, localPosition.z),
                "rotation" to listOf(localRotation.x, localRotation.y, localRotation.z, localRotation.w)
            )
            
            methodChannel.invokeMethod("onNodeTransformed", data)
            Log.d(TAG, "Sent transformation to Flutter for $nodeName")
        } catch (e: Exception) {
            Log.e(TAG, "Error reporting transformation: ${e.message}")
        }
    }
}
