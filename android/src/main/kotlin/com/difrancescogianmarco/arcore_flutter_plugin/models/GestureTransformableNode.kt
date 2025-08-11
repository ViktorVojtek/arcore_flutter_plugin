package com.difrancescogianmarco.arcore_flutter_plugin.models

import android.util.Log
import com.google.ar.sceneform.Node
import com.google.ar.sceneform.ux.TransformableNode
import com.google.ar.sceneform.ux.TransformationSystem
import io.flutter.plugin.common.MethodChannel

/**
 * A TransformableNode with Flutter gesture callbacks
 */
class GestureTransformableNode(
    transformationSystem: TransformationSystem,
    private val methodChannel: MethodChannel,
    private val nodeName: String
) : TransformableNode(transformationSystem) {

    private val TAG = "GestureTransformableNode"

    var enablePanGestures: Boolean = true
        set(value) {
            field = value
            Log.d(TAG, "enablePanGestures set to: $value for node: $nodeName")
            // Update transformation system settings
            updateGestureSettings()
        }

    var enableRotationGestures: Boolean = true
        set(value) {
            field = value
            Log.d(TAG, "enableRotationGestures set to: $value for node: $nodeName")
            // Update transformation system settings  
            updateGestureSettings()
        }

    private var lastReportedPosition: FloatArray? = null
    private var lastReportedRotation: FloatArray? = null

    init {
        Log.d(TAG, "GestureTransformableNode created for: $nodeName")
        // Set up transformation listeners
        setOnTouchListener { _, event ->
            Log.d(TAG, "Touch event received on node: $nodeName, action: ${event.action}")
            // Report transformation changes to Flutter
            reportTransformation()
            false // Allow gesture processing to continue
        }
    }

    private fun updateGestureSettings() {
        Log.d(TAG, "Updating gesture settings for $nodeName: pan=$enablePanGestures, rotation=$enableRotationGestures")
        // Configure which gestures are enabled
        scaleController.isEnabled = false // Disable scaling for now
        translationController.isEnabled = enablePanGestures
        rotationController.isEnabled = enableRotationGestures
        Log.d(TAG, "Gesture controllers updated: translation=${translationController.isEnabled}, rotation=${rotationController.isEnabled}")
    }

    private fun reportTransformation() {
        Log.d(TAG, "reportTransformation called for node: $nodeName")
        val currentPosition = floatArrayOf(
            localPosition.x,
            localPosition.y, 
            localPosition.z
        )
        
        val currentRotation = floatArrayOf(
            localRotation.x,
            localRotation.y,
            localRotation.z,
            localRotation.w
        )

        Log.d(TAG, "Current position: [${currentPosition.joinToString()}], rotation: [${currentRotation.joinToString()}]")

        // Only report if position or rotation changed significantly
        if (hasSignificantChange(lastReportedPosition, currentPosition) || 
            hasSignificantChange(lastReportedRotation, currentRotation)) {
            
            Log.d(TAG, "Significant change detected, sending to Flutter")
            val data = mapOf(
                "nodeName" to nodeName,
                "position" to currentPosition.toList(),
                "rotation" to currentRotation.toList()
            )
            
            methodChannel.invokeMethod("onNodeTransformed", data)
            
            lastReportedPosition = currentPosition
            lastReportedRotation = currentRotation
        } else {
            Log.d(TAG, "No significant change, not reporting")
        }
    }

    private fun hasSignificantChange(oldValue: FloatArray?, newValue: FloatArray): Boolean {
        if (oldValue == null) return true
        
        val threshold = 0.001f // Minimum change threshold
        for (i in oldValue.indices) {
            if (kotlin.math.abs(oldValue[i] - newValue[i]) > threshold) {
                return true
            }
        }
        return false
    }
}
