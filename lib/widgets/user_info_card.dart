import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UserInfoCard extends StatelessWidget {
  final String name;
  final String country;
  final String gender;
  final VoidCallback onClose;

  const UserInfoCard({
    Key? key,
    required this.name,
    required this.country,
    required this.gender,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtenemos las traducciones del contexto
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.userInfo, // "معلومات المستخدم" traducido
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              InkWell(
                onTap: onClose,
                child: const Icon(
                  Icons.close,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white30),
          _buildInfoRow(context, Icons.person, l10n.name, name),
          const SizedBox(height: 8),
          _buildInfoRow(context, Icons.flag, l10n.country, country),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            gender == l10n.male ? Icons.male : Icons.female,
            l10n.gender,
            gender,
            gender == l10n.male ? Colors.blue : Colors.pink,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, [Color? iconColor]) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor ?? Colors.white,
          size: 16,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}