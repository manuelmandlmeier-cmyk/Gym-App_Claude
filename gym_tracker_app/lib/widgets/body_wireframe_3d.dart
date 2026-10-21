import 'dart:math';
import 'package:flutter/material.dart';
import '../models/body_model.dart';

class BodyWireframe3D extends StatefulWidget {
  final BodyMeasurements measurements;
  final Map<MuscleGroup, double> muscleHeatmap;

  const BodyWireframe3D({
    super.key,
    required this.measurements,
    required this.muscleHeatmap,
  });

  @override
  State<BodyWireframe3D> createState() => _BodyWireframe3DState();
}

class _BodyWireframe3DState extends State<BodyWireframe3D> {
  double _angleY = 0.3;
  double _angleX = 0.1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _angleY += details.delta.dx * 0.01;
          _angleX += details.delta.dy * 0.01;
        });
      },
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _WireframePainter(
            angleY: _angleY,
            angleX: _angleX,
            m: widget.measurements,
            heatmap: widget.muscleHeatmap,
          ),
        ),
      ),
    );
  }
}

class _Point3D {
  double x, y, z;
  _Point3D(this.x, this.y, this.z);
}

class _WireframePainter extends CustomPainter {
  final double angleY;
  final double angleX;
  final BodyMeasurements m;
  final Map<MuscleGroup, double> heatmap;

  _WireframePainter({
    required this.angleY,
    required this.angleX,
    required this.m,
    required this.heatmap,
  });

  Color _getHeatColor(MuscleGroup group) {
    final intensity = heatmap[group] ?? 0.0;
    if (intensity < 0.1) return const Color(0xFF4A5568);
    if (intensity < 0.4) return const Color(0xFF38A169);
    if (intensity < 0.7) return const Color(0xFFDD6B20);
    return const Color(0xFFE53E3E);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseScale = size.height / 240.0;

    final double shoulderScale = (m.shouldersCm / 115.0).clamp(0.8, 1.4);
    final double chestScale = (m.chestCm / 100.0).clamp(0.8, 1.4);
    final double waistScale = (m.waistCm / 80.0).clamp(0.8, 1.4);
    final double hipScale = (m.hipsCm / 95.0).clamp(0.8, 1.4);
    final double armScale = (m.bicepsCm / 35.0).clamp(0.8, 1.5);
    final double legScale = (m.thighsCm / 58.0).clamp(0.8, 1.5);

    final Map<String, _Point3D> rawNodes = {
      'head_top': _Point3D(0, -90, 0),
      'head_bottom': _Point3D(0, -75, 0),
      'shoulder_l': _Point3D(-28 * shoulderScale, -65, 0),
      'shoulder_r': _Point3D(28 * shoulderScale, -65, 0),
      'chest_l': _Point3D(-22 * chestScale, -50, 10 * chestScale),
      'chest_r': _Point3D(22 * chestScale, -50, 10 * chestScale),
      'chest_back_l': _Point3D(-22 * chestScale, -50, -10 * chestScale),
      'chest_back_r': _Point3D(22 * chestScale, -50, -10 * chestScale),
      'waist_l': _Point3D(-16 * waistScale, -20, 6 * waistScale),
      'waist_r': _Point3D(16 * waistScale, -20, 6 * waistScale),
      'waist_back_l': _Point3D(-16 * waistScale, -20, -6 * waistScale),
      'waist_back_r': _Point3D(16 * waistScale, -20, -6 * waistScale),
      'hip_l': _Point3D(-18 * hipScale, 5, 0),
      'hip_r': _Point3D(18 * hipScale, 5, 0),
      'elbow_l': _Point3D(-34 * shoulderScale, -35, 0),
      'elbow_r': _Point3D(34 * shoulderScale, -35, 0),
      'wrist_l': _Point3D(-38 * shoulderScale * armScale, -5, 0),
      'wrist_r': _Point3D(38 * shoulderScale * armScale, -5, 0),
      'knee_l': _Point3D(-12 * legScale, 50, 0),
      'knee_r': _Point3D(12 * legScale, 50, 0),
      'ankle_l': _Point3D(-10 * legScale, 95, 0),
      'ankle_r': _Point3D(10 * legScale, 95, 0),
    };

    final Map<String, Offset> projected = {};
    rawNodes.forEach((key, pt) {
      final double x1 = pt.x * cos(angleY) + pt.z * sin(angleY);
      final double z1 = -pt.x * sin(angleY) + pt.z * cos(angleY);

      final double y2 = pt.y * cos(angleX) - z1 * sin(angleX);
      final double z2 = pt.y * sin(angleX) + z1 * cos(angleX);

      const double distance = 300.0;
      final double fov = distance / (distance + z2);

      projected[key] = Offset(
        center.dx + x1 * fov * baseScale,
        center.dy + y2 * fov * baseScale,
      );
    });

    void drawSegment(String p1, String p2, MuscleGroup group, {double strokeWidth = 2.5}) {
      final a = projected[p1];
      final b = projected[p2];
      if (a == null || b == null) return;
      final paint = Paint()
        ..color = _getHeatColor(group)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(a, b, paint);
    }

    final gridPaint = Paint()
      ..color = const Color(0x0DFFFFFF)
      ..strokeWidth = 1.0;
    for (double i = -150; i <= 150; i += 30) {
      canvas.drawLine(Offset(center.dx + i, center.dy - 120), Offset(center.dx + i, center.dy + 120), gridPaint);
    }

    final headPaint = Paint()
      ..color = const Color(0xFFCBD5E0)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(projected['head_top']!, projected['head_bottom']!, headPaint);

    drawSegment('shoulder_l', 'shoulder_r', MuscleGroup.shoulders, strokeWidth: 4.0);
    drawSegment('shoulder_l', 'chest_l', MuscleGroup.chest, strokeWidth: 3.0);
    drawSegment('shoulder_r', 'chest_r', MuscleGroup.chest, strokeWidth: 3.0);
    drawSegment('chest_l', 'chest_r', MuscleGroup.chest, strokeWidth: 3.5);
    drawSegment('chest_l', 'waist_l', MuscleGroup.core, strokeWidth: 3.0);
    drawSegment('chest_r', 'waist_r', MuscleGroup.core, strokeWidth: 3.0);
    drawSegment('waist_l', 'waist_r', MuscleGroup.core, strokeWidth: 3.0);

    drawSegment('shoulder_l', 'chest_back_l', MuscleGroup.back, strokeWidth: 2.5);
    drawSegment('shoulder_r', 'chest_back_r', MuscleGroup.back, strokeWidth: 2.5);
    drawSegment('chest_back_l', 'waist_back_l', MuscleGroup.back, strokeWidth: 3.0);
    drawSegment('chest_back_r', 'waist_back_r', MuscleGroup.back, strokeWidth: 3.0);

    drawSegment('shoulder_l', 'elbow_l', MuscleGroup.biceps, strokeWidth: 3.5);
    drawSegment('shoulder_r', 'elbow_r', MuscleGroup.biceps, strokeWidth: 3.5);
    drawSegment('elbow_l', 'wrist_l', MuscleGroup.triceps, strokeWidth: 3.0);
    drawSegment('elbow_r', 'wrist_r', MuscleGroup.triceps, strokeWidth: 3.0);

    drawSegment('waist_l', 'hip_l', MuscleGroup.core, strokeWidth: 3.0);
    drawSegment('waist_r', 'hip_r', MuscleGroup.core, strokeWidth: 3.0);
    drawSegment('hip_l', 'knee_l', MuscleGroup.legs, strokeWidth: 4.0);
    drawSegment('hip_r', 'knee_r', MuscleGroup.legs, strokeWidth: 4.0);
    drawSegment('knee_l', 'ankle_l', MuscleGroup.legs, strokeWidth: 3.2);
    drawSegment('knee_r', 'ankle_r', MuscleGroup.legs, strokeWidth: 3.2);

    final nodePaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;
    for (final offset in projected.values) {
      canvas.drawCircle(offset, 3.0, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WireframePainter oldDelegate) => true;
}
