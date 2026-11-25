import 'schedule_item.dart';

List<ScheduleItem> sampleClassesForDay(String day) {
  switch (day) {
    case 'L':
      return const [
        ScheduleItem(
          id: 'cls_l1',
          time: '08:30 - 10:30',
          title: 'IA',
          subtitle: 'Inteligencia Artificial (Aula 1.2)',
        ),
        ScheduleItem(
          id: 'cls_l2',
          time: '10:30 - 12:30',
          title: 'BD',
          subtitle: 'Bases de Datos (Laboratorio 2.1)',
        ),
      ];
    case 'M':
      return const [
        ScheduleItem(
          id: 'cls_m1',
          time: '09:30 - 11:30',
          title: 'NPI',
          subtitle: 'Nuevas Paradigmas de Interacción (Auxiliary Structure)',
        ),
        ScheduleItem(
          id: 'cls_m2',
          time: '11:30 - 13:30',
          title: 'SCD',
          subtitle: 'Sistemas Concurrentes y Distribuidos',
        ),
      ];
    case 'X':
      return const [
        ScheduleItem(
          id: 'cls_x1',
          time: '09:30 - 11:30',
          title: 'TW',
          subtitle: 'Tecnologías Web (Aula 0.1)',
        ),
        ScheduleItem(
          id: 'cls_x2',
          time: '12:00 - 14:00',
          title: 'DD',
          subtitle: 'Diseño e Integración de Sistemas (Aula 1.1)',
        ),
      ];
    case 'J':
      return const [
        ScheduleItem(
          id: 'cls_j1',
          time: '10:00 - 12:00',
          title: 'AC',
          subtitle: 'Arquitectura de Computadores (Aula 2.3)',
        ),
        ScheduleItem(
          id: 'cls_j2',
          time: '12:00 - 14:00',
          title: 'SO',
          subtitle: 'Sistemas Operativos (Laboratorio 1.4)',
        ),
      ];
    case 'V':
      return const [
        ScheduleItem(
          id: 'cls_v1',
          time: '09:00 - 11:00',
          title: 'IG',
          subtitle: 'Informática Gráfica (Laboratorio 0.2)',
        ),
      ];
    default:
      return const [];
  }
}

List<ScheduleItem> sampleEventsForDay(String day) {
  switch (day) {
    case 'L':
      return const [
        ScheduleItem(
          id: 'evt_l1',
          time: '17:00 - 18:30',
          title: 'Taller de Hackathon',
          subtitle: 'Entrada ETSIIT',
          location: ScheduleItem.facultyEntranceLocation,
          isEvent: true,
          category: ScheduleEventCategory.educational,
        ),
      ];
    case 'M':
      return const [
        ScheduleItem(
          id: 'evt_m1',
          time: '16:00 - 17:00',
          title: 'Eventos de música',
          subtitle: 'Entrada ETSIIT',
          location: ScheduleItem.facultyEntranceLocation,
          isEvent: true,
          category: ScheduleEventCategory.music,
        ),
      ];
    case 'X':
      return const [
        ScheduleItem(
          id: 'evt_x1',
          time: '18:00 - 19:30',
          title: 'Conferencia de IA y Ética',
          subtitle: 'Entrada ETSIIT',
          location: ScheduleItem.facultyEntranceLocation,
          isEvent: true,
          category: ScheduleEventCategory.educational,
        ),
      ];
    case 'J':
      return const [
        ScheduleItem(
          id: 'evt_j1',
          time: '16:30 - 18:00',
          title: 'Torneo de Ajedrez',
          subtitle: 'Entrada ETSIIT',
          location: ScheduleItem.facultyEntranceLocation,
          isEvent: true,
          category: ScheduleEventCategory.gaming,
        ),
      ];
    case 'V':
      return const [
        ScheduleItem(
          id: 'evt_v1',
          time: '15:00 - 17:00',
          title: 'Feria de Empresas y Empleo',
          subtitle: 'Entrada ETSIIT',
          location: ScheduleItem.facultyEntranceLocation,
          isEvent: true,
          category: ScheduleEventCategory.educational,
        ),
      ];
    default:
      return const [];
  }
}
