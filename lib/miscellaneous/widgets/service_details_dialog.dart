import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:npi/miscellaneous/service_option.dart';

class ServiceDetailsDialog extends StatelessWidget {
  final ServiceOption service;

  const ServiceDetailsDialog({super.key, required this.service});

  Future<void> _openUrl(BuildContext context) async {
    final Uri uri = Uri.parse(service.url);

    try {
      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la página web')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al abrir la página web')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

      // TÍTULO
      title: Row(
        children: [
          Icon(service.icono, color: service.color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              service.titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),

      // CONTENIDO
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DESCRIPCIÓN
          Text(
            service.descripcion,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),

          const SizedBox(height: 24),

          // TÍTULO DE LA URL
          const Text(
            'Más información:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263D5A),
            ),
          ),

          const SizedBox(height: 10),

          // ENLACE
          InkWell(
            onTap: () => _openUrl(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: Color(0xFF1976D2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service.url,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1976D2),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // BOTÓN CERRAR
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Cerrar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF263D5A),
            ),
          ),
        ),
      ],
    );
  }
}
