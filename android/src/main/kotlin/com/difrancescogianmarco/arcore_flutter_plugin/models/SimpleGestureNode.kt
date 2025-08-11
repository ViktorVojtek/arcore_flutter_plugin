package com.difrancescogianmarco.arcore_flutter_plugin.models

import android.util.Log
import com.google.ar.sceneform.ux.TransformableNode
import com.google.ar.sceneform.ux.TransformationSystem
import io.flutter.plugin.common.MethodChannel

class SimpleGestureNode(
    private val transformationSystem: TransformationSystem,
    private val nodeName: String,
    private val methodChannel: MethodChannel,
    enablePanGestures: Boolean = true,
    enableRotationGestures: Boolean = true
) : TransformableNode(transformationSystem) {

    companion object {
        private const val TAG = "SimpleGestureNode"
    }

    init {
        Log.i(TAG, "SimpleGestureNode created for: $nodeName")
        
        // Enable all gesture controllers for better gesture detection
        scaleController.isEnabled = true
        translationController.isEnabled = enablePanGestures
        rotationController.isEnabled = enableRotationGestures
        
        Log.d(TAG, "Gesture controllers: scale=true, translation=$enablePanGestures, rotation=$enableRotationGestures")
        
        // Set up tap listener for selection
        setOnTapListener { _, _ ->
            Log.d(TAG, "Node $nodeName tapped - selecting for transformation")
            transformationSystem.selectNode(this)
        }
    }
}
