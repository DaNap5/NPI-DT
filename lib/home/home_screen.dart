import 'package:flutter/material.dart';
import 'package:npi/orientation/location_client.dart';

import 'package:npi/auth/sign_in_screen.dart';
import 'package:npi/events/events_screen.dart';
import 'package:npi/miscellaneous/miscellaneous_page.dart';
import 'package:npi/orientation/directions_page.dart';
import 'package:npi/orientation/directions_flow_view_model.dart';
import 'package:npi/orientation/faculty_map_screen.dart';

import 'package:npi/home/home_view_model.dart';
import 'package:npi/home/schedule_item.dart';
import 'package:npi/auth/session_state.dart';
import 'package:npi/storage/local_store.dart';
import 'package:npi/events/event_catalog.dart';
import 'package:npi/home/widgets/action_button.dart';
import 'package:npi/home/widgets/day_block.dart';
import 'package:npi/home/widgets/floating_day_picker.dart';

class HomeScreen extends StatefulWidget {
  final SessionState session;
  final LocalStore store;
  final EventCatalog catalog;
  final LocationClient? locationClient;
  final WidgetBuilder? eventsPageBuilder;

  const HomeScreen({
    super.key,
    required this.session,
    required this.store,
    required this.catalog,
    this.locationClient,
    this.eventsPageBuilder,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _viewModel;
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

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(
      session: widget.session,
      store: widget.store,
      catalog: widget.catalog,
    );
    _viewModel.loadSchedule();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
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
            if (_viewModel.selectedDay != day) {
              _viewModel.selectDay(day);
            }
            break;
          }
        }
      }
    }
  }

  Future<void> _scrollToDay(String dayCode) async {
    _viewModel.selectDay(dayCode);

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
          store: widget.store,
          initialDestination: DirectionsDestination.facultyEntrance,
          locationClient: widget.locationClient,
        ),
      ),
    );
  }

  Future<void> _handleScheduleItemDelete(ScheduleItem item) async {
    if (!_viewModel.isRegistered || !item.isSavedEvent) return;

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
    final removed = await _viewModel.removeUserEvent(item.id);
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
    if (_viewModel.isRegistered) {
      final success = await _viewModel.logout();
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => SignInScreen(
              session: widget.session,
              store: widget.store,
              catalog: widget.catalog,
            ),
          ),
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
        MaterialPageRoute(
          builder: (context) => SignInScreen(
            session: widget.session,
            store: widget.store,
            catalog: widget.catalog,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
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
                  tooltip: _viewModel.isRegistered
                      ? 'Cerrar sesión'
                      : 'Iniciar sesión',
                  icon: Icon(
                    _viewModel.isRegistered
                        ? Icons.logout
                        : Icons.account_circle,
                    size: 30,
                    color: _viewModel.isRegistered
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
                          if (_viewModel.error != null) Text(_viewModel.error!),
                          if (_viewMode == 0) ...[
                            DayBlock(
                              dayCode: _viewModel.selectedDay,
                              controller: _viewModel,
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
                                  controller: _viewModel,
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
                                    builder: (context) =>
                                        FacultyMapScreen(store: widget.store),
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
                                        DirectionsPage(store: widget.store),
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
                                        EventsScreen(
                                          session: widget.session,
                                          store: widget.store,
                                          catalog: widget.catalog,
                                        ),
                                  ),
                                );
                                if (!mounted) return;
                                await _viewModel.loadSchedule();
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
                      selectedDay: _viewModel.selectedDay,
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
