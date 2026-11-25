import 'package:flutter/material.dart';

class ServiceOption {
  final String titulo;
  final IconData icono;
  final Color color;
  final String descripcion;
  final String url;

  const ServiceOption({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.descripcion,
    required this.url,
  });
}
