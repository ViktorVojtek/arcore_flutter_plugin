package com.difrancescogianmarco.arcore_flutter_plugin

import android.app.Activity
import android.app.Application
import android.content.Context
import android.graphics.BitmapFactory
import android.os.Bundle
import android.os.Handler
import android.util.Log
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.View
import android.widget.Toast
import com.difrancescogianmarco.arcore_flutter_plugin.flutter_models.FlutterArCoreHitTestResult
import com.difrancescogianmarco.arcore_flutter_plugin.flutter_models.FlutterArCoreNode
import com.difrancescogianmarco.arcore_flutter_plugin.flutter_models.FlutterArCorePose
import com.difrancescogianmarco.arcore_flutter_plugin.models.RotatingNode
import com.difrancescogianmarco.arcore_flutter_plugin.models.GestureTransformableNode
import com.difrancescogianmarco.arcore_flutter_plugin.utils.ArCoreUtils
import com.google.ar.core.*
import com.google.ar.core.exceptions.CameraNotAvailableException
import com.google.ar.core.exceptions.UnavailableException
import com.google.ar.core.exceptions.UnavailableUserDeclinedInstallationException
import com.google.ar.sceneform.*
import com.google.ar.sceneform.rendering.ModelRenderable
import com.google.ar.sceneform.rendering.Texture
import com.google.ar.sceneform.ux.AugmentedFaceNode
import com.google.ar.sceneform.ux.TransformationSystem
import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

import android.graphics.Bitmap
import android.os.Environment
import android.view.PixelCopy
import android.os.HandlerThread
import android.content.ContextWrapper
import java.io.FileOutputStream
import java.io.File
import java.io.IOException
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

class ArCoreView(val activity: Activity, context: Context, messenger: BinaryMessenger, id: Int, private val isAugmentedFaces: Boolean, private val debug: Boolean) : PlatformView, MethodChannel.MethodCallHandler {
    private val methodChannel: MethodChannel = MethodChannel(messenger, "arcore_flutter_plugin_$id")
    //       private val activity: Activity = (context.applicationContext as FlutterApplication).currentActivity
    lateinit var activityLifecycleCallbacks: Application.ActivityLifecycleCallbacks
    private var installRequested: Boolean = false
    private var mUserRequestedInstall = true
    private val TAG: String = ArCoreView::class.java.name
    private var arSceneView: ArSceneView? = null
    private var transformationSystem: TransformationSystem? = null
    private val gestureDetector: GestureDetector
    private val RC_PERMISSIONS = 0x123
    private var sceneUpdateListener: Scene.OnUpdateListener
    private var faceSceneUpdateListener: Scene.OnUpdateListener

    //AUGMENTEDFACE
    private var faceRegionsRenderable: ModelRenderable? = null
    private var faceMeshTexture: Texture? = null
    private val faceNodeMap = HashMap<AugmentedFace, AugmentedFaceNode>()

    init {
        methodChannel.setMethodCallHandler(this)
        arSceneView = ArSceneView(context)
        
        // Set up a tap gesture detector.
        gestureDetector = GestureDetector(
                context,
                object : GestureDetector.SimpleOnGestureListener() {
                    override fun onSingleTapUp(e: MotionEvent): Boolean {
                        onSingleTap(e)
                        return true
                    }

                    override fun onDown(e: MotionEvent): Boolean {
                        return true
                    }
                })
        
        // Initialize TransformationSystem for gesture handling
        transformationSystem = TransformationSystem(context.resources.displayMetrics, null)

        sceneUpdateListener = Scene.OnUpdateListener { frameTime ->

            val frame = arSceneView?.arFrame ?: return@OnUpdateListener

            if (frame.camera.trackingState != TrackingState.TRACKING) {
                return@OnUpdateListener
            }

            for (plane in frame.getUpdatedTrackables(Plane::class.java)) {
                if (plane.trackingState == TrackingState.TRACKING) {

                    val pose = plane.centerPose
                    val map: HashMap<String, Any> = HashMap<String, Any>()
                    map["type"] = plane.type.ordinal
                    map["centerPose"] = FlutterArCorePose(pose.translation, pose.rotationQuaternion).toHashMap()
                    map["extentX"] = plane.extentX
                    map["extentZ"] = plane.extentZ

                    methodChannel.invokeMethod("onPlaneDetected", map)
                }
            }
        }

        faceSceneUpdateListener = Scene.OnUpdateListener { frameTime ->
            run {
                //                if (faceRegionsRenderable == null || faceMeshTexture == null) {
                if (faceMeshTexture == null) {
                    return@OnUpdateListener
                }

                val faceList = arSceneView?.session?.getAllTrackables(AugmentedFace::class.java)

                faceList?.let {
                    // Make new AugmentedFaceNodes for any new faces.
                    for (face in faceList) {
                        if (!faceNodeMap.containsKey(face)) {
                            val faceNode = AugmentedFaceNode(face)
                            faceNode.setParent(arSceneView?.scene)
                            faceNode.faceRegionsRenderable = faceRegionsRenderable
                            faceNode.faceMeshTexture = faceMeshTexture
                            faceNodeMap[face] = faceNode
                        }
                    }

                    // Remove any AugmentedFaceNodes associated with an AugmentedFace that stopped tracking.
                    val iter = faceNodeMap.iterator()
                    while (iter.hasNext()) {
                        val entry = iter.next()
                        val face = entry.key
                        if (face.trackingState == TrackingState.STOPPED) {
                            val faceNode = entry.value
                            faceNode.setParent(null)
                            iter.remove()
                        }
                    }
                }
            }
        }

        // Lastly request CAMERA permission which is required by ARCore.
        ArCoreUtils.requestCameraPermission(activity, RC_PERMISSIONS)
        setupLifeCycle(context)
    }

    fun debugLog(message: String) {
        if (debug) {
            Log.i(TAG, "ARCore: $message")
        }
    }


    fun loadMesh(textureBytes: ByteArray?) {
        // Load the face regions renderable.
        // This is a skinned model that renders 3D objects mapped to the regions of the augmented face.
        /*ModelRenderable.builder()
                .setSource(activity, Uri.parse("fox_face.sfb"))
                .build()
                .thenAccept { modelRenderable ->
                    faceRegionsRenderable = modelRenderable;
                    modelRenderable.isShadowCaster = false;
                    modelRenderable.isShadowReceiver = false;
                }*/

        // Load the face mesh texture.
        //                .setSource(activity, Uri.parse("fox_face_mesh_texture.png"))
        Texture.builder()
                .setSource(BitmapFactory.decodeByteArray(textureBytes, 0, textureBytes!!.size))
                .build()
                .thenAccept { texture -> faceMeshTexture = texture }
    }


    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> {
                arScenViewInit(call, result, activity)
            }
            "addArCoreNode" -> {
                debugLog(" addArCoreNode")
                val map = call.arguments as HashMap<String, Any>
                val flutterNode = FlutterArCoreNode(map);
                onAddNode(flutterNode, result)
            }
            "addArCoreNodeWithAnchor" -> {
                debugLog(" addArCoreNode")
                val map = call.arguments as HashMap<String, Any>
                val flutterNode = FlutterArCoreNode(map)
                addNodeWithAnchor(flutterNode, result)
            }
            "removeARCoreNode" -> {
                debugLog(" removeARCoreNode")
                val map = call.arguments as HashMap<String, Any>
                removeNode(map["nodeName"] as String, result)
            }
            "positionChanged" -> {
                debugLog(" positionChanged")

            }
            "rotationChanged" -> {
                debugLog(" rotationChanged")
                updateRotation(call, result)

            }
            "updateMaterials" -> {
                debugLog(" updateMaterials")
                updateMaterials(call, result)

            }
            "takeScreenshot" -> {
                debugLog(" takeScreenshot")
                takeScreenshot(call, result)

            }
            "loadMesh" -> {
                val map = call.arguments as HashMap<String, Any>
                val textureBytes = map["textureBytes"] as ByteArray
                loadMesh(textureBytes)
            }
            "dispose" -> {
                debugLog("Disposing ARCore now")
                dispose()
            }
            "resume" -> {
                debugLog("Resuming ARCore now")
                onResume()
            }
            "getTrackingState" -> {
                debugLog("1/3: Requested tracking state, returning that back to Flutter now")

                val trState = arSceneView?.arFrame?.camera?.trackingState
                debugLog("2/3: Tracking state is " + trState.toString())
                methodChannel.invokeMethod("getTrackingState", trState.toString())
            }
            "togglePlaneRenderer" -> {
                debugLog(" Toggle planeRenderer visibility" )
                arSceneView!!.planeRenderer.isVisible = !arSceneView!!.planeRenderer.isVisible
            }
            "touch" -> {
                debugLog("Touch method called - ignoring for now")
                // This method is called by some gesture code but we handle gestures directly
                // in the touch listener, so we can safely ignore this
                result.success(null)
            }
            "onNodeTransformed" -> {
                debugLog("onNodeTransformed callback received")
                // This should be called from the GestureTransformableNode when it transforms
                result.success(null)
            }
            else -> {
                debugLog("Unknown method called: ${call.method}")
                result.notImplemented()
            }
        }
    }

/*    fun maybeEnableArButton() {
        Log.i(TAG,"maybeEnableArButton" )
        try{
            val availability = ArCoreApk.getInstance().checkAvailability(activity.applicationContext)
            if (availability.isTransient) {
                // Re-query at 5Hz while compatibility is checked in the background.
                Handler().postDelayed({ maybeEnableArButton() }, 200)
            }
            if (availability.isSupported) {
                debugLog("AR SUPPORTED")
            } else { // Unsupported or unknown.
                debugLog("AR NOT SUPPORTED")
            }
        }catch (ex:Exception){
            Log.i(TAG,"maybeEnableArButton ${ex.localizedMessage}" )
        }

    }*/

    private fun setupLifeCycle(context: Context) {
        activityLifecycleCallbacks = object : Application.ActivityLifecycleCallbacks {
            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
                debugLog("onActivityCreated")
//                maybeEnableArButton()
            }

            override fun onActivityStarted(activity: Activity) {
                debugLog("onActivityStarted")
            }

            override fun onActivityResumed(activity: Activity) {
                debugLog("onActivityResumed")
                onResume()
            }

            override fun onActivityPaused(activity: Activity) {
                debugLog("onActivityPaused")
                onPause()
            }

            override fun onActivityStopped(activity: Activity) {
                debugLog("onActivityStopped (Just so you know)")
//                onPause()
            }

            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}

            override fun onActivityDestroyed(activity: Activity) {
                debugLog("onActivityDestroyed (Just so you know)")
//                onDestroy()
//                dispose()
            }
        }

        activity.application.registerActivityLifecycleCallbacks(this.activityLifecycleCallbacks)
    }

    private fun onSingleTap(tap: MotionEvent?) {
        debugLog(" onSingleTap")
        val frame = arSceneView?.arFrame
        if (frame != null) {
            if (tap != null && frame.camera.trackingState == TrackingState.TRACKING) {
                val hitList = frame.hitTest(tap)
                val list = ArrayList<HashMap<String, Any>>()
                for (hit in hitList) {
                    val trackable = hit.trackable
                    if (trackable is Plane && trackable.isPoseInPolygon(hit.hitPose)) {
                        hit.hitPose
                        val distance: Float = hit.distance
                        val translation = hit.hitPose.translation
                        val rotation = hit.hitPose.rotationQuaternion
                        val flutterArCoreHitTestResult = FlutterArCoreHitTestResult(distance, translation, rotation)
                        val arguments = flutterArCoreHitTestResult.toHashMap()
                        list.add(arguments)
                    }
                }
                methodChannel.invokeMethod("onPlaneTap", list)
            }
        }
    }

    private fun takeScreenshot(call: MethodCall, result: MethodChannel.Result) {
        try {
            // create bitmap screen capture

            // Create a bitmap the size of the scene view.
            val bitmap: Bitmap = Bitmap.createBitmap(arSceneView!!.getWidth(), arSceneView!!.getHeight(),
                    Bitmap.Config.ARGB_8888)

            // Create a handler thread to offload the processing of the image.
            val handlerThread = HandlerThread("PixelCopier")
            handlerThread.start()
            // Make the request to copy.
            // Make the request to copy.
            PixelCopy.request(arSceneView!!, bitmap, { copyResult ->
                if (copyResult === PixelCopy.SUCCESS) {
                    try {
                        saveBitmapToDisk(bitmap)
                    } catch (e: IOException) {
                        e.printStackTrace();
                    }
                }
                handlerThread.quitSafely()
            }, Handler(handlerThread.getLooper()))

        } catch (e: Throwable) {
            // Several error may come out with file handling or DOM
            e.printStackTrace()
        }
        result.success(null)
    }

    @Throws(IOException::class)
    fun saveBitmapToDisk(bitmap: Bitmap):String {

//        val now = LocalDateTime.now()
//        now.format(DateTimeFormatter.ofPattern("M/d/y H:m:ss"))
        val now = "rawScreenshot"
        // android/data/com.hswo.mvc_2021.hswo_mvc_2021_flutter_ar/files/
        // activity.applicationContext.getFilesDir().toString() //doesnt work!!
        // Environment.getExternalStorageDirectory()
        val mPath: String =  Environment.getExternalStorageDirectory().toString() + "/DCIM/" + now + ".jpg"
        val mediaFile = File(mPath)
        debugLog(mediaFile.toString())
        //Log.i("path","fileoutputstream opened")
        //Log.i("path",mPath)
        val fileOutputStream = FileOutputStream(mediaFile)
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, fileOutputStream)
        fileOutputStream.flush()
        fileOutputStream.close()
//        Log.i("path","fileoutputstream closed")
        return mPath as String
    }

    private fun arScenViewInit(call: MethodCall, result: MethodChannel.Result, context: Context) {
        debugLog("arScenViewInit")
        
        // The TransformationSystem is already initialized and will handle its own visualization
        if (transformationSystem != null) {
            debugLog("✅ TransformationSystem is ready for gesture handling")
        }
        
        val enableTapRecognizer: Boolean? = call.argument("enableTapRecognizer")
        if (enableTapRecognizer != null && enableTapRecognizer) {
            arSceneView
                    ?.scene
                    ?.setOnTouchListener { hitTestResult: HitTestResult, event: MotionEvent ->
                        
                        debugLog("Scene touch event - Action: ${event.action}, PointerCount: ${event.pointerCount}")
                        
                        // For transformable nodes, select them first then let them handle their own gestures
                        if (hitTestResult.node is GestureTransformableNode) {
                            val transformableNode = hitTestResult.node as GestureTransformableNode
                            debugLog("Touch event on transformable node: ${transformableNode.name}")
                            
                            // Explicitly select the node for transformation
                            transformationSystem?.selectNode(transformableNode)
                            debugLog("Selected transformable node: ${transformableNode.name} for transformation")
                            
                            // Let the transformable node handle the touch event
                            return@setOnTouchListener false
                        }

                        // Handle regular nodes
                        if (hitTestResult.node != null) {
                            debugLog(" onNodeTap " + hitTestResult.node?.name)
                            debugLog(hitTestResult.node?.localPosition.toString())
                            debugLog(hitTestResult.node?.worldPosition.toString())
                            methodChannel.invokeMethod("onNodeTap", hitTestResult.node?.name)
                            return@setOnTouchListener true
                        }
                        
                        // Default fallback
                        gestureDetector.onTouchEvent(event)
                    }
        }
        val enableUpdateListener: Boolean? = call.argument("enableUpdateListener")
        if (enableUpdateListener != null && enableUpdateListener) {
            // Set an update listener on the Scene that will hide the loading message once a Plane is
            // detected.
            arSceneView?.scene?.addOnUpdateListener(sceneUpdateListener)
        }

        val enablePlaneRenderer: Boolean? = call.argument("enablePlaneRenderer")
        if (enablePlaneRenderer != null && !enablePlaneRenderer) {
            debugLog(" The plane renderer (enablePlaneRenderer) is set to " + enablePlaneRenderer.toString())
            arSceneView!!.planeRenderer.isVisible = false
        }
        
        result.success(null)
    }

    fun addNodeWithAnchor(flutterArCoreNode: FlutterArCoreNode, result: MethodChannel.Result) {

        if (arSceneView == null) {
            return
        }

        val myAnchor = arSceneView?.session?.createAnchor(Pose(flutterArCoreNode.getPosition(), flutterArCoreNode.getRotation()))
        if (myAnchor != null) {
            
            debugLog("=== ANCHOR NODE CREATION START ===")
            debugLog("Anchor node name: ${flutterArCoreNode.name}")
            debugLog("isTransformable: ${flutterArCoreNode.isTransformable}")
            debugLog("transformationSystem available: ${transformationSystem != null}")
            
            val shouldCreateTransformableAnchor = flutterArCoreNode.isTransformable && transformationSystem != null
            debugLog("Should create transformable anchor: $shouldCreateTransformableAnchor")
            
            if (shouldCreateTransformableAnchor) {
                debugLog("✅ Creating TRANSFORMABLE anchor node for ${flutterArCoreNode.name}")
                // Create transformable anchor node
                NodeFactory.makeTransformableNode(activity.applicationContext, flutterArCoreNode, transformationSystem!!, methodChannel, debug) { node, throwable ->
                    debugLog("✅ Transformable anchor creation callback - Node: ${node?.name}, Error: ${throwable?.message}")
                    
                    if (node != null) {
                        // Set the anchor for the transformable node
                        val anchorNode = AnchorNode(myAnchor)
                        anchorNode.name = "${flutterArCoreNode.name}_anchor"
                        anchorNode.addChild(node)
                        
                        debugLog("✅ Attaching transformable anchor to scene")
                        attachNodeToParent(anchorNode, flutterArCoreNode.parentNodeName)
                        
                        // Add children
                        for (childNode in flutterArCoreNode.children) {
                            childNode.parentNodeName = flutterArCoreNode.name
                            onAddNode(childNode, null)
                        }
                        
                        debugLog("✅ Transformable anchor node creation completed")
                        result.success(null)
                    } else {
                        debugLog("❌ Transformable anchor creation FAILED: ${throwable?.message}")
                        result.error("Transformable Anchor Error", throwable?.localizedMessage, null)
                    }
                }
            } else {
                debugLog("❌ Creating REGULAR anchor for ${flutterArCoreNode.name}")
                // Create regular anchor node (original logic)
                RenderableCustomFactory.makeRenderable(activity.applicationContext, flutterArCoreNode) { renderable, t ->
                    if (t != null) {
                        result.error("Make Renderable Error", t.localizedMessage, null)
                        return@makeRenderable
                    }
                    
                    val anchorNode = AnchorNode(myAnchor)
                    anchorNode.name = flutterArCoreNode.name
                    anchorNode.renderable = renderable

                    debugLog("addNodeWithAnchor inserted ${anchorNode.name}")
                    attachNodeToParent(anchorNode, flutterArCoreNode.parentNodeName)

                    for (node in flutterArCoreNode.children) {
                        node.parentNodeName = flutterArCoreNode.name
                        onAddNode(node, null)
                    }
                    result.success(null)
                }
            }
        } else {
            debugLog("❌ Failed to create anchor")
            result.error("Anchor Error", "Failed to create anchor", null)
        }
    }

    fun onAddNode(flutterArCoreNode: FlutterArCoreNode, result: MethodChannel.Result?) {

        debugLog("=== NODE CREATION START ===")
        debugLog("Node name: ${flutterArCoreNode.name}")
        debugLog("Node dart type: ${flutterArCoreNode.dartType}")
        debugLog("isTransformable: ${flutterArCoreNode.isTransformable}")
        debugLog("enablePanGestures: ${flutterArCoreNode.enablePanGestures}")
        debugLog("enableRotationGestures: ${flutterArCoreNode.enableRotationGestures}")
        debugLog("transformationSystem available: ${transformationSystem != null}")
        debugLog("transformationSystem object: $transformationSystem")
        
        val shouldCreateTransformable = flutterArCoreNode.isTransformable && transformationSystem != null
        debugLog("Should create transformable node: $shouldCreateTransformable")
        
        if (shouldCreateTransformable) {
            debugLog("✅ Creating TRANSFORMABLE node for ${flutterArCoreNode.name}")
            // Create transformable node for gesture handling
            NodeFactory.makeTransformableNode(activity.applicationContext, flutterArCoreNode, transformationSystem!!, methodChannel, debug) { node, throwable ->
                debugLog("✅ Transformable node creation callback - Node: ${node?.name}, Error: ${throwable?.message}")
                
                if (node != null) {
                    debugLog("✅ Attaching transformable node to parent")
                    attachNodeToParent(node, flutterArCoreNode.parentNodeName)
                    for (n in flutterArCoreNode.children) {
                        n.parentNodeName = flutterArCoreNode.name
                        onAddNode(n, null)
                    }
                } else {
                    debugLog("❌ Transformable node creation FAILED: ${throwable?.message}")
                }
            }
        } else {
            debugLog("❌ Creating REGULAR node for ${flutterArCoreNode.name} (isTransformable=${flutterArCoreNode.isTransformable}, transformationSystem=${transformationSystem != null})")
            // Create regular node
            NodeFactory.makeNode(activity.applicationContext, flutterArCoreNode, debug) { node, throwable ->
                debugLog("Regular node creation callback - Node: ${node?.name}, Error: ${throwable?.message}")

                if (node != null) {
                    attachNodeToParent(node, flutterArCoreNode.parentNodeName)
                    for (n in flutterArCoreNode.children) {
                        n.parentNodeName = flutterArCoreNode.name
                        onAddNode(n, null)
                    }
                } else {
                    debugLog("❌ Regular node creation FAILED: ${throwable?.message}")
                }
            }
        }
        
        result?.success(null)
        debugLog("=== NODE CREATION END ===")
    }

    fun attachNodeToParent(node: Node?, parentNodeName: String?) {
        if (parentNodeName != null) {
            debugLog(parentNodeName);
            val parentNode: Node? = arSceneView?.scene?.findByName(parentNodeName)
            parentNode?.addChild(node)
        } else {
            debugLog("addNodeToSceneWithGeometry: NOT PARENT_NODE_NAME")
            arSceneView?.scene?.addChild(node)
        }
    }

    fun removeNode(name: String, result: MethodChannel.Result) {
        val node = arSceneView?.scene?.findByName(name)
        if (node != null) {
            arSceneView?.scene?.removeChild(node);
            debugLog("removed ${node.name}")
        }

        result.success(null)
    }

    fun updateRotation(call: MethodCall, result: MethodChannel.Result) {
        val name = call.argument<String>("name")
        val node = arSceneView?.scene?.findByName(name) as RotatingNode
        debugLog("rotating node:  $node")
        val degreesPerSecond = call.argument<Double?>("degreesPerSecond")
        debugLog("rotating value:  $degreesPerSecond")
        if (degreesPerSecond != null) {
            debugLog("rotating value:  ${node.degreesPerSecond}")
            node.degreesPerSecond = degreesPerSecond.toFloat()
        }
        result.success(null)
    }

    fun updateMaterials(call: MethodCall, result: MethodChannel.Result) {
        val name = call.argument<String>("name")
        val materials = call.argument<ArrayList<HashMap<String, *>>>("materials")!!
        val node = arSceneView?.scene?.findByName(name)
        val oldMaterial = node?.renderable?.material?.makeCopy()
        if (oldMaterial != null) {
            val material = MaterialCustomFactory.updateMaterial(oldMaterial, materials[0])
            node.renderable?.material = material
        }
        result.success(null)
    }

    override fun getView(): View {
        return arSceneView as View
    }

    override fun dispose() {
        if (arSceneView != null) {
            onPause()
            onDestroy()
        }
    }

    fun onResume() {
        debugLog("onResume()")

        if (arSceneView == null) {
            return
        }

        // request camera permission if not already requested
        if (!ArCoreUtils.hasCameraPermission(activity)) {
            ArCoreUtils.requestCameraPermission(activity, RC_PERMISSIONS)
        }

        if (arSceneView?.session == null) {
            debugLog("session is null")
            try {
                val session = ArCoreUtils.createArSession(activity, mUserRequestedInstall, isAugmentedFaces)
                if (session == null) {
                    // Ensures next invocation of requestInstall() will either return
                    // INSTALLED or throw an exception.
                    mUserRequestedInstall = false
                    return
                } else {
                    val config = Config(session)
                    if (isAugmentedFaces) {
                        config.augmentedFaceMode = Config.AugmentedFaceMode.MESH3D
                    }
                    config.updateMode = Config.UpdateMode.LATEST_CAMERA_IMAGE
                    config.focusMode = Config.FocusMode.AUTO;
                    session.configure(config)
                    arSceneView?.setupSession(session)
                }
            } catch (ex: UnavailableUserDeclinedInstallationException) {
                // Display an appropriate message to the user zand return gracefully.
                Toast.makeText(activity, "TODO: handle exception " + ex.localizedMessage, Toast.LENGTH_LONG)
                        .show();
                return
            } catch (e: UnavailableException) {
                ArCoreUtils.handleSessionException(activity, e)
                return
            }
        }

        try {
            arSceneView?.resume()
        } catch (ex: CameraNotAvailableException) {
            ArCoreUtils.displayError(activity, "Unable to get camera", ex)
            activity.finish()
            return
        }

        if (arSceneView?.session != null) {
            //arSceneView!!.planeRenderer.isVisible = false
            debugLog("Searching for surfaces")
        }
    }

    fun onPause() {
        if (arSceneView != null) {
            arSceneView?.pause()
        }
    }

    fun onDestroy() {
      if (arSceneView != null) {
            debugLog("Goodbye ARCore! Destroying the Activity now 7.")

            try {
                arSceneView?.scene?.removeOnUpdateListener(sceneUpdateListener)
                arSceneView?.scene?.removeOnUpdateListener(faceSceneUpdateListener)
                debugLog("Goodbye arSceneView.")

                arSceneView?.destroy()
                arSceneView = null

            }catch (e : Exception){
                e.printStackTrace();
           }
        }
    }

    /* private fun tryPlaceNode(tap: MotionEvent?, frame: Frame) {
        if (tap != null && frame.camera.trackingState == TrackingState.TRACKING) {
            for (hit in frame.hitTest(tap)) {
                val trackable = hit.trackable
                if (trackable is Plane && trackable.isPoseInPolygon(hit.hitPose)) {
                    // Create the Anchor.
                    val anchor = hit.createAnchor()
                    val anchorNode = AnchorNode(anchor)
                    anchorNode.setParent(arSceneView?.scene)

                    ModelRenderable.builder()
                            .setSource(activity.applicationContext, Uri.parse("TocoToucan.sfb"))
                            .build()
                            .thenAccept { renderable ->
                                val node = Node()
                                node.renderable = renderable
                                anchorNode.addChild(node)
                            }.exceptionally { throwable ->
                                Log.e(TAG, "Unable to load Renderable.", throwable);
                                return@exceptionally null
                            }
                }
            }
        }

    }*/

    /*    fun updatePosition(call: MethodCall, result: MethodChannel.Result) {
        val name = call.argument<String>("name")
        val node = arSceneView?.scene?.findByName(name)
        node?.localPosition = parseVector3(call.arguments as HashMap<String, Any>)
        result.success(null)
    }*/
}
