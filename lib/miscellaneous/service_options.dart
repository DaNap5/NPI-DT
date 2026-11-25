import 'package:flutter/material.dart';
import 'package:npi/miscellaneous/service_option.dart';

const List<ServiceOption> serviceOptions = [
  ServiceOption(
    titulo: 'Comedor',
    icono: Icons.restaurant_menu,
    color: Color(0xFFFFA726),
    descripcion: 'Consulta toda la información sobre los comedores universitarios, horarios, menús y servicios disponibles.',
    url: 'https://www.ugr.es/info/perfiles/personal/vive-ugr/comedores-universitarios',
  ),
  ServiceOption(
    titulo: 'Transporte público',
    icono: Icons.directions_bus_filled,
    color: Color(0xFF42A5F5),
    descripcion: 'Aquí encontrarás información sobre las opciones de transporte público disponibles para desplazarte hasta la universidad.',
    url: 'https://internacional.ugr.es/estudiantes/servicios-recursos/mapa-transporte',
  ),
  ServiceOption(
    titulo: 'Oficina de Relaciones Internacionales',
    icono: Icons.public,
    color: Color(0xFF66BB6A),
    descripcion: 'Información sobre programas de movilidad internacional, Erasmus, convenios y oportunidades de intercambio.',
    url: 'https://www.ugr.es/universidad/servicios/ori',
  ),
  ServiceOption(
    titulo: 'Instalaciones deportivas',
    icono: Icons.sports_soccer,
    color: Color(0xFFAB47BC),
    descripcion: 'Descubre las instalaciones deportivas, actividades y servicios deportivos que ofrece la universidad.',
    url: 'https://deportes.ugr.es/instalaciones',
  ),
  ServiceOption(
    titulo: 'Servicio de Asistencia Estudiantil',
    icono: Icons.support_agent,
    color: Color(0xFF26A69A),
    descripcion: 'Accede a información sobre becas, ayudas, orientación y otros servicios de apoyo al estudiante.',
    url: 'https://www.ugr.es/universidad/servicios/sae',
  ),
  ServiceOption(
    titulo: 'Centro de Empleo y Prácticas',
    icono: Icons.work_history,
    color: Color(0xFFEF5350),
    descripcion: 'Consulta información sobre ofertas de empleo, prácticas externas, orientación laboral y desarrollo profesional.',
    url: 'https://empleo.ugr.es/',
  ),
];
