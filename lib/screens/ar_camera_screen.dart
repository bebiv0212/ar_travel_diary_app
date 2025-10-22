import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_updated/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_updated/datatypes/config_datatypes.dart';
import 'package:ar_flutter_plugin_updated/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_updated/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_updated/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:ar_flutter_plugin_updated/models/ar_hit_test_result.dart';
import 'package:ar_flutter_plugin_updated/models/ar_material.dart'; // Import ARMaterial

class ArCameraScreen extends StatefulWidget {
  const ArCameraScreen({super.key});

  @override
  State<ArCameraScreen> createState() => _ArCameraScreenState();
}

class _ArCameraScreenState extends State<ArCameraScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Camera'),
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: onRemoveEverything,
                  child: const Text("Remove Everything"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager?.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          showWorldOrigin: true,
          handlePans: true,
          handleRotations: true,
        );
    this.arObjectManager?.onInitialize();

    this.arSessionManager?.onPlaneOrPointTap = onPlaneOrPointTapped;
    this.arObjectManager?.onNodeTap = onNodeTapped;
  }

  Future<void> onRemoveEverything() async {
    for (var anchor in anchors) {
      arAnchorManager?.removeAnchor(anchor);
    }
    anchors = [];
  }

  Future<void> onNodeTapped(List<String> nodeNames) async {
    var numAnchors = anchors.length;
    arSessionManager?.onError("Tapped $numAnchors node(s)");
  }

  Future<void> onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
    var singleHitTestResult = hitTestResults.firstWhere(
        (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane);
    var newAnchor =
        ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
    bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);
    if (didAddAnchor!) {
      anchors.add(newAnchor);

      // Create a material with the image texture
      var material = ARMaterial(
        texture: "assets/images/placeholder.png", // Placeholder image
        metallic: 0.0,
        roughness: 0.0,
      );

      // Add a node to the anchor with the plane GLB model and textured material
      var newNode = ARNode(
          type: NodeType.localGltf,
          uri: "assets/models/plane.glb", // Placeholder for a plane model
          scale: Vector3(0.2, 0.2, 0.2),
          position: Vector3(0.0, 0.0, 0.0),
          rotation: Vector4(1.0, 0.0, 0.0, 0.0),
          materials: [material]); // Assign the material
      bool? didAddNodeToAnchor =
          await arObjectManager?.addNode(newNode, anchor: newAnchor);
      if (didAddNodeToAnchor!) {
        nodes.add(newNode);
      } else {
        arSessionManager?.onError("Adding node to anchor failed");
      }
    } else {
      arSessionManager?.onError("Adding anchor failed");
    }
  }
}