import 'package:arcore_flutter_plugin_example/screens/augmented_faces.dart';
import 'package:arcore_flutter_plugin_example/screens/augmented_images.dart';
import 'package:arcore_flutter_plugin_example/screens/image_object.dart';
import 'package:arcore_flutter_plugin_example/screens/matri_3d.dart';
import 'package:arcore_flutter_plugin_example/screens/multiple_augmented_images.dart';
import 'package:flutter/material.dart';
import 'screens/hello_world.dart';
import 'screens/custom_object.dart';
import 'screens/runtime_materials.dart';
import 'screens/texture_and_rotation.dart';
import 'screens/assets_object.dart';
import 'screens/auto_detect_plane.dart';
import 'screens/remote_object.dart';
import 'screens/gesture_example.dart';
import 'working_gesture_example.dart';
import 'simple_test_example.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ArCore Demo'),
      ),
      body: ListView(
        children: <Widget>[
          // Priority item - Simple Test
          Container(
            margin: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: ListTile(
              leading: Icon(Icons.science, color: Colors.blue, size: 32),
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SimpleTestExample()));
              },
              title: Text("🧪 Simple Test - Add/Remove",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
              subtitle: Text("✅ Basic functionality test (no gestures needed)"),
            ),
          ),
          
          // Priority item - Working Gesture Control
          Container(
            margin: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: ListTile(
              leading: Icon(Icons.touch_app, color: Colors.green, size: 32),
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => WorkingGestureExample()));
              },
              title: Text("🎯 Working Gesture Control",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
              subtitle: Text("✅ Guaranteed working manual controls"),
            ),
          ),
          
          ListTile(
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => HelloWorld()));
            },
            title: Text("Hello World"),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => GestureExample()));
            },
            title: Text("Gesture Example - Pan & Rotate"),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ImageObjectScreen()));
            },
            title: Text("Image"),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => AugmentedPage()));
            },
            title: Text("AugmentedPage"),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => MultipleAugmentedImagesPage()));
            },
            title: Text("Multiple augmented images"),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => CustomObject()));
            },
            title: Text("Custom Anchored Object with onTap"),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => RuntimeMaterials()));
            },
            title: Text("Change Materials Property in runtime"),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ObjectWithTextureAndRotation()));
            },
            title: Text("Custom object with texture and rotation listener "),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => AutoDetectPlane()));
            },
            title: Text("Plane detect handler"),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => Matrix3DRenderingPage()));
            },
            title: Text("3D Matrix"),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => AssetsObject()));
            },
            title: Text("Custom sfb object"),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => RemoteObject()));
            },
            title: Text("Remote object"),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => AugmentedFacesScreen()));
            },
            title: Text("Augmented Faces"),
          ),
        ],
      ),
    );
  }
}
