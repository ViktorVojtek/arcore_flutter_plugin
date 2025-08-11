package com.difrancescogianmarco.arcore_flutter_plugin.models

import android.util.Log
import com.google.ar.sceneform.Node
import com.google.ar.sceneform.FrameTime
import com.google.ar.sceneform.ux.TransformableNode
import com.google.ar.sceneform.ux.TransformationSystem
import io.flutter.plugin.common.MethodChannel

/**
 * A TransformableNode with Flutter gesture callbacks
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
        
        // Configure gesture settings immediately
        updateGestureSettings()
        
        // Set up proper touch handling for TransformableNode
        setOnTapListener { hitTestResult, motionEvent ->
            Log.d(TAG, "Node $nodeName tapped - selecting for transformation")
            // This is CRUCIAL: select the node when tapped to enable gestures
            if (transformationSystem != null) {
                transformationSystem.selectNode(this)
                Log.d(TAG, "Node $nodeName selected for transformation")
                true
            } else {
                Log.w(TAG, "TransformationSystem is null, cannot select node")
                false
            }
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

        // Always report transformations to Flutter for now (remove threshold check)
        Log.d(TAG, "Sending transformation to Flutter")
        val data = mapOf(
            "nodeName" to nodeName,
            "position" to currentPosition.toList(),
            "rotation" to currentRotation.toList()
        )
        
        methodChannel.invokeMethod("onNodeTransformed", data)
        
        lastReportedPosition = currentPosition
        lastReportedRotation = currentRotation
    }
    
    // Override this method to report transformations when they actually happen
    override fun onTransformChanged(node: Node?, endTransform: Boolean) {
        super.onTransformChanged(node, endTransform)
        Log.d(TAG, "onTransformChanged called for $nodeName, endTransform: $endTransform")
        if (endTransform) {
            reportTransformation()
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
