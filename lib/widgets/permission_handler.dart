import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PermissionHandler extends StatefulWidget {
  final VoidCallback onPermissionGranted;

  const PermissionHandler({
    Key? key,
    required this.onPermissionGranted,
  }) : super(key: key);

  @override
  State<PermissionHandler> createState() => _PermissionHandlerState();
}

class _PermissionHandlerState extends State<PermissionHandler> {
  bool _isRequestingPermission = false;
  String? _errorMessage;
  bool _permanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final hasPermissions = await PermissionService.checkMediaPermissions();

      if (hasPermissions) {
        widget.onPermissionGranted();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ أثناء التحقق من الأذونات: $e';
      });
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isRequestingPermission = true;
      _errorMessage = null;
    });

    try {
      bool permissionsGranted = await PermissionService.requestMediaPermissions();

      if (permissionsGranted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('permissions_granted', true);
        widget.onPermissionGranted();
      } else {
        final cameraPermanentlyDenied = await Permission.camera.isPermanentlyDenied;
        final micPermanentlyDenied = await Permission.microphone.isPermanentlyDenied;

        setState(() {
          _permanentlyDenied = cameraPermanentlyDenied || micPermanentlyDenied;
          _errorMessage = _permanentlyDenied
              ? AppLocalizations.of(context)!.permissionsPermanentlyDenied
              : AppLocalizations.of(context)!.permissionsRequired;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${AppLocalizations.of(context)!.permissionsError}: $e';
      });
    } finally {
      setState(() {
        _isRequestingPermission = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 80,
                  color: Colors.white,
                )
                    .animate()
                    .fade(duration: 800.ms)
                    .scale(delay: 300.ms),

                const SizedBox(height: 24),

                Text(
                  localizations.needPermissionsAccess,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fade(delay: 400.ms, duration: 800.ms),

                const SizedBox(height: 16),

                Text(
                  localizations.permissionsDescription,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fade(delay: 600.ms, duration: 800.ms),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isRequestingPermission
                      ? null
                      : _permanentlyDenied
                      ? () => openAppSettings()
                      : _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isRequestingPermission
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    _permanentlyDenied
                        ? localizations.openAppSettings
                        : localizations.allowAccess,
                    style: const TextStyle(fontSize: 16),
                  ),
                )
                    .animate()
                    .fade(delay: 800.ms, duration: 800.ms),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                Text(
                  localizations.permissionsInfoNote,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}