package com.difrancescogianmarco.arcore_flutter_plugin

import android.content.Context
import android.util.Log
import com.difrancescogianmarco.arcore_flutter_plugin.flutter_models.FlutterArCoreNode
import com.google.ar.sceneform.Node
import com.google.ar.sceneform.ux.TransformationSystem
import io.flutter.plugin.common.MethodChannel

typealias NodeHandler = (Node?, Throwable?) -> Unit

class NodeFactory {

    companion object {
        val TAG: String = NodeFactory::class.java.name

        fun makeNode(context: Context, flutterNode: FlutterArCoreNode, debug: Boolean, handler: NodeHandler) {
            if (debug) {
                Log.i(TAG, flutterNode.toString())
            }
            val node = flutterNode.buildNode()
            RenderableCustomFactory.makeRenderable(context, flutterNode) { renderable, t ->
                if (renderable != null) {
                    node.renderable = renderable
                    handler(node, null)
                }else{
                    handler(null,t)
                }
            }
        }

        fun makeTransformableNode(
            context: Context, 
            flutterNode: FlutterArCoreNode, 
            transformationSystem: TransformationSystem,
            methodChannel: MethodChannel,
            debug: Boolean, 
            handler: NodeHandler
        ) {
            if (debug) {
                Log.i(TAG, "Creating transformable node: ${flutterNode.toString()}")
            }
            val node = flutterNode.buildTransformableNode(transformationSystem, methodChannel)
            RenderableCustomFactory.makeRenderable(context, flutterNode) { renderable, t ->
                if (renderable != null) {
                    node.renderable = renderable
                    handler(node, null)
                } else {
                    handler(null, t)
                }
            }
        }
    }
}