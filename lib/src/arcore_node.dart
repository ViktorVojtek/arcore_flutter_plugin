import 'package:arcore_flutter_plugin/src/arcore_image.dart';
import 'package:arcore_flutter_plugin/src/shape/arcore_shape.dart';
import 'package:arcore_flutter_plugin/src/utils/random_string.dart'
    as random_string;
import 'package:arcore_flutter_plugin/src/utils/vector_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

class ArCoreNode {
  ArCoreNode({
    this.shape,
    this.image,
    String? name,
    Vector3? position,
    Vector3? scale,
    Vector4? rotation,
    this.children = const [],
    this.isTransformable = false,
    this.enablePanGestures = true,
    this.enableRotationGestures = true,
  })  : name = name ?? random_string.randomString(),
        position = position != null ? ValueNotifier(position) : null,
        scale = scale != null ? ValueNotifier(scale) : null,
        rotation = rotation != null ? ValueNotifier(rotation) : null,
        assert(!(shape != null && image != null));

  final List<ArCoreNode>? children;

  final ArCoreShape? shape;

  final ValueNotifier<Vector3>? position;

  final ValueNotifier<Vector3>? scale;

  final ValueNotifier<Vector4>? rotation;

  final String? name;

  final ArCoreImage? image;

  /// Whether this node should use TransformableNode for gesture support
  final bool isTransformable;

  /// Whether pan gestures are enabled for this node (requires isTransformable = true)
  final bool enablePanGestures;

  /// Whether rotation gestures are enabled for this node (requires isTransformable = true)
  final bool enableRotationGestures;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'dartType': runtimeType.toString(),
        'shape': shape?.toMap(),
        'position': convertVector3ToMap(position?.value),
        'scale': convertVector3ToMap(scale?.value),
        'rotation': convertVector4ToMap(rotation?.value),
        'name': name,
        'image': image?.toMap(),
        'children':
            this.children?.map((arCoreNode) => arCoreNode.toMap()).toList(),
        'isTransformable': isTransformable,
        'enablePanGestures': enablePanGestures,
        'enableRotationGestures': enableRotationGestures,
      }..removeWhere((String k, dynamic v) => v == null);
}
