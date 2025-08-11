package com.difrancescogianmarco.arcore_flutter_plugin.models

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

    var enablePanGestures: Boolean = true
        set(value) {
            field = value
            // Update transformation system settings
            updateGestureSettings()
        }

    var enableRotationGestures: Boolean = true
        set(value) {
            field = value
            // Update transformation system settings  
            updateGestureSettings()
        }

    private var lastReportedPosition: FloatArray? = null
    private var lastReportedRotation: FloatArray? = null

    init {
        // Set up transformation listeners
        setOnTouchListener { _, _ ->
            // Report transformation changes to Flutter
            reportTransformation()
            false // Allow gesture processing to continue
        }
    }

    private fun updateGestureSettings() {
        // Configure which gestures are enabled
        scaleController.isEnabled = false // Disable scaling for now
        translationController.isEnabled = enablePanGestures
        rotationController.isEnabled = enableRotationGestures
    }

    private fun reportTransformation() {
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

        // Only report if position or rotation changed significantly
        if (hasSignificantChange(lastReportedPosition, currentPosition) || 
            hasSignificantChange(lastReportedRotation, currentRotation)) {
            
            val data = mapOf(
                "nodeName" to nodeName,
                "position" to currentPosition.toList(),
                "rotation" to currentRotation.toList()
            )
            
            methodChannel.invokeMethod("onNodeTransformed", data)
            
            lastReportedPosition = currentPosition
            lastReportedRotation = currentRotation
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
