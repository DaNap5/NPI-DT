import 'dart:async';

import 'package:flutter/material.dart';
import 'package:npi/data/repositories/location_repository.dart';
import 'package:npi/data/services/leap_websocket_service.dart';
import 'package:npi/domain/models/leap_event.dart';

import 'package:npi/ui/auth/selection/widgets/auth_selection_screen.dart';
import 'package:npi/ui/events/widgets/event_screen.dart';
import 'package:npi/ui/miscellaneous/widgets/miscellaneous_page.dart';
import 'package:npi/ui/orientation/directions_page.dart';
import 'package:npi/ui/orientation/view_models/directions_flow_view_model.dart';
import 'package:npi/ui/orientation/widgets/inside_view.dart';

import '../view_models/schedule_controller.dart';
import 'action_button.dart';
import 'day_block.dart';
import 'floating_day_picker.dart';

class ScheduleScreen extends StatefulWidget {
  final ScheduleController controller;
  final LocationRepository? locationRepository;
  final WidgetBuilder? eventsPageBuilder;
  final LeapWebSocketService? leapService;

  const ScheduleScreen({
    super.key,
    required this.controller,
    this.locationRepository,
    this.eventsPageBuilder,
    this.leapService,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _viewMode = 0;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _dayKeys = {
    'L': GlobalKey(),
    'M': GlobalKey(),
    'X': GlobalKey(),
    'J': GlobalKey(),
    'V': GlobalKey(),
  };

  bool _isManualScrolling = false;
  StreamSubscription<LeapEvent>? _leapSubscription;
  static const List<String> _weekDays = ['L', 'M', 'X', 'J', 'V'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _leapSubscription = widget.leapService?.events.listen(_handleLeapEvent);
  }

  @override
  void dispose() {
    _leapSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleLeapEvent(LeapEvent event) {
    if (!mounted || event is! LeapGestureDetected) return;

    switch (event.gesture) {
      case LeapGestureType.swipeRight:
        final currentIndex = _weekDays.indexOf(widget.controller.selectedDay);
        final nextIndex = (currentIndex + 1) % _weekDays.length;
        _scrollToDay(_weekDays[nextIndex]);
        break;

      case LeapGestureType.swipeLeft:
        final currentIndex = _weekDays.indexOf(widget.controller.selectedDay);
        final prevIndex =
            (currentIndex - 1 + _weekDays.length) % _weekDays.length;
        _scrollToDay(_weekDays[prevIndex]);
        break;

      case LeapGestureType.openHand:
      case LeapGestureType.swipeDown:
        if (_viewMode == 0) {
          setState(() => _viewMode = 2);
        }
        break;

      case LeapGestureType.closedFist:
      case LeapGestureType.swipeUp:
        if (_viewMode == 2) {
          setState(() => _viewMode = 0);
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        break;

      case LeapGestureType.pinch:
        _handleVerMasPressed();
        break;
    }
  }

  void _onScroll() {
    if (_viewMode != 2 || _isManualScrolling) return;

    for (final day in ['L', 'M', 'X', 'J', 'V']) {
      final key = _dayKeys[day];
      if (key?.currentContext != null) {
        final box = key!.currentContext!.findRenderObject() as RenderBox?;
        if (box != null) {
          final position = box.localToGlobal(Offset.zero);
          if (position.dy >= 0 && position.dy <= 300) {
            if (widget.controller.selectedDay != day) {
              widget.controller.selectDay(day);
            }
            break;
          }
        }
      }
    }
  }

  Future<void> _scrollToDay(String dayCode) async {
    widget.controller.selectDay(dayCode);

    if (_viewMode == 2) {
      final key = _dayKeys[dayCode];
      if (key?.currentContext != null) {
        _isManualScrolling = true;
        await Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _isManualScrolling = false;
      }
    }
  }

  void _handleVerMasPressed() {
    setState(() {
      _viewMode = _viewMode == 0 ? 2 : 0;
    });
  }

  Future<void> _handleScheduleItemTap(ScheduleItem item) async {
    if (item.location != ScheduleItem.facultyEntranceLocation) return;
    final openDirections = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item.title),
        content: Text('Ubicación: ${item.location}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Llévame'),
          ),
        ],
      ),
    );
    if (!mounted || openDirections != true) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DirectionsPage(
          initialDestination: DirectionsDestination.facultyEntrance,
          locationRepository: widget.locationRepository,
        ),
      ),
    );
  }

  Future<void> _handleScheduleItemDelete(ScheduleItem item) async {
    if (!widget.controller.isRegistered || !item.isSavedEvent) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: Text('¿Quieres quitar "${item.title}" de tu horario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;
    final removed = await widget.controller.removeUserEvent(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removed
              ? 'Evento "${item.title}" eliminado del horario'
              : 'No se ha podido eliminar el evento',
        ),
      ),
    );
  }

  Future<void> _handleAuthButtonPressed() async {
    if (widget.controller.isRegistered) {
      final success = await widget.controller.logout();
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthSelectionScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se ha podido cerrar la sesión')),
        );
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return PopScope(
          canPop: _viewMode == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_viewMode == 2) {
              setState(() {
                _viewMode = 0;
              });
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              title: Text(
                _viewMode == 0 ? '' : 'Horario Semanal',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              actions: [
                IconButton(
                  tooltip: widget.controller.isRegistered
                      ? 'Cerrar sesión'
                      : 'Iniciar sesión',
                  icon: Icon(
                    widget.controller.isRegistered
                        ? Icons.logout
                        : Icons.account_circle,
                    size: 30,
                    color: widget.controller.isRegistered
                        ? Colors.red.shade600
                        : Colors.grey.shade600,
                  ),
                  onPressed: _handleAuthButtonPressed,
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_viewMode == 0) ...[
                            DayBlock(
                              dayCode: widget.controller.selectedDay,
                              controller: widget.controller,
                              showHeaderChip: true,
                              showHorizontalDays: false,
                              isDetailView: false,
                              onDaySelected: _scrollToDay,
                              onItemTap: _handleScheduleItemTap,
                              onItemDelete: _handleScheduleItemDelete,
                            ),
                          ] else ...[
                            ...['L', 'M', 'X', 'J', 'V'].map((day) {
                              return Padding(
                                key: _dayKeys[day],
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: DayBlock(
                                  dayCode: day,
                                  controller: widget.controller,
                                  showHeaderChip: day == 'L',
                                  showHorizontalDays: false,
                                  isDetailView: true,
                                  onDaySelected: _scrollToDay,
                                  onItemTap: _handleScheduleItemTap,
                                  onItemDelete: _handleScheduleItemDelete,
                                ),
                              );
                            }),
                          ],
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _handleVerMasPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF64B5F6),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _viewMode == 2 ? 'VER MENOS' : 'VER MÁS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          if (_viewMode == 0) ...[
                            const SizedBox(height: 20),
                            ActionButton(
                              icon: Icons.search,
                              label: 'Explorar facultad',
                              color: Colors.blue.shade600,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const InsideView(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            ActionButton(
                              icon: Icons.location_on,
                              label: 'Llévame a algún sitio',
                              color: Colors.teal.shade600,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DirectionsPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            ActionButton(
                              icon: Icons.diamond_outlined,
                              label: 'Explorar eventos',
                              color: Colors.purple.shade600,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        widget.eventsPageBuilder?.call(
                                          context,
                                        ) ??
                                        EventsMainPage(
                                          username: widget.controller.username,
                                        ),
                                  ),
                                );
                                if (!mounted) return;
                                await widget.controller.loadSchedule();
                              },
                            ),
                            const SizedBox(height: 10),
                            ActionButton(
                              icon: Icons.help_outline,
                              label: 'No encuentro lo que quiero hacer',
                              color: Colors.deepOrange.shade600,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MiscellaneousPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_viewMode == 2)
                    FloatingDayPicker(
                      selectedDay: widget.controller.selectedDay,
                      onDaySelected: _scrollToDay,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
