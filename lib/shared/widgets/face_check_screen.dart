import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/Utils/haptics.dart';
import '../../core/localization/l10n.dart';
import '../../features/onboarding/data/onboarding_api_service.dart';
import 'app_buttons.dart';

/// Step-up face check for sensitive actions (large transfers).
///
/// Takes a selfie and asks `POST /onboarding/verify-face` whether it matches
/// the user's saved profile picture. Resolves `true` only on a match; a
/// mismatch, a cancelled screen or a service error all resolve `false`
/// (the caller blocks the action — the user can retry here first).
Future<bool> confirmWithFace(BuildContext context,
    {required String identityUserId}) async {
  final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _FaceCheckScreen(identityUserId: identityUserId),
  ));
  return ok ?? false;
}

class _FaceCheckScreen extends StatefulWidget {
  final String identityUserId;

  const _FaceCheckScreen({required this.identityUserId});

  @override
  State<_FaceCheckScreen> createState() => _FaceCheckScreenState();
}

class _FaceCheckScreenState extends State<_FaceCheckScreen> {
  CameraController? _camera;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    setState(() => _error = null);
    try {
      if (!kIsWeb && !(await Permission.camera.request()).isGranted) {
        if (mounted) setState(() => _error = context.l10n.faceCheckNoCamera);
        return;
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _error = context.l10n.faceCheckNoCamera);
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller =
          CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _camera = controller);
    } catch (e) {
      debugPrint('face check camera: $e');
      if (mounted) setState(() => _error = context.l10n.faceCheckNoCamera);
    }
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized || _verifying) return;
    Haptics.press();
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final shot = await camera.takePicture();
      final image = base64Encode(await shot.readAsBytes());
      final res = await OnboardingApiService().verifyFace(
        identityUserId: widget.identityUserId,
        faceImageBase64: image,
      );
      if (!mounted) return;
      if (res.isSuccess && (res.data?.isMatch ?? false)) {
        Haptics.success();
        Navigator.of(context).pop(true);
        return;
      }
      Haptics.error();
      setState(() {
        _verifying = false;
        _error = res.isSuccess
            ? context.l10n.faceCheckNoMatch
            : context.l10n.faceCheckServiceError;
      });
    } catch (e) {
      debugPrint('face check: $e');
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = context.l10n.faceCheckServiceError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    final ready = camera != null && camera.value.isInitialized;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1A12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              Text(
                context.l10n.faceCheckTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Effra',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.faceCheckBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Effra',
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _error != null
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF22C55E),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: ready
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: camera.value.previewSize?.height ?? 260,
                            height: camera.value.previewSize?.width ?? 260,
                            child: CameraPreview(camera),
                          ),
                        )
                      : const ColoredBox(
                          color: Color(0xFF13261B),
                          child: Center(
                            child: Icon(Icons.face_retouching_natural,
                                size: 72, color: Colors.white38),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 44,
                child: _error == null
                    ? null
                    : Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Effra',
                          fontSize: 13.5,
                          color: Color(0xFFFCA5A5),
                        ),
                      ),
              ),
              const Spacer(),
              AppPrimaryButton(
                label: ready
                    ? (_error != null
                        ? context.l10n.faceCheckRetry
                        : context.l10n.faceCheckTake)
                    : context.l10n.faceCheckStartCamera,
                loading: _verifying,
                leadingIcon: ready ? Icons.camera_alt_rounded : null,
                onPressed: ready ? _capture : _startCamera,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
