import 'package:flutter/material.dart';
import 'package:npi/auth/session_state.dart';
import 'package:npi/storage/local_store.dart';

import 'event_catalog.dart';
import 'events_view_model.dart';
import 'discarded_events_screen.dart';
import 'widgets/events_swipeable_list.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({
    super.key,
    required this.session,
    required this.store,
    required this.catalog,
  });
  final SessionState session;
  final LocalStore store;
  final EventCatalog catalog;
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late final EventsViewModel _viewModel;
  bool _startTutorial = false;
  int _tutorialRun = 0;
  bool _inputActive = true;

  @override
  void initState() {
    super.initState();
    _viewModel = EventsViewModel(
      session: widget.session,
      store: widget.store,
      catalog: widget.catalog,
    );
    _viewModel.loadEvents();
    _startTutorial = !widget.store.eventsTutorialSeen;
    if (_startTutorial) _markTutorialSeen();
  }

  Future<void> _markTutorialSeen() async {
    try {
      await widget.store.markEventsTutorialSeen();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el tutorial.')),
        );
      }
    }
  }

  Future<void> _reset() async {
    try {
      await _viewModel.resetEvents();
      if (mounted) {
        setState(() {
          _startTutorial = true;
          _tutorialRun++;
        });
      }
    } catch (_) {
      /* The viewmodel exposes the failed operation for retry. */
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        actions: [
          TextButton(
            onPressed: _viewModel.isMutating ? null : _reset,
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: () async {
              setState(() => _inputActive = false);
              await Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => DiscardedEventsScreen(
                    session: widget.session,
                    store: widget.store,
                    catalog: widget.catalog,
                  ),
                ),
              );
              if (mounted) {
                setState(() => _inputActive = true);
                await _viewModel.loadEvents();
              }
            },
            child: const Text('Discarded events'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_viewModel.error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(child: Text(_viewModel.error!)),
                  TextButton(
                    onPressed: _viewModel.loadEvents,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                EventsSwipeableList(
                  viewModel: _viewModel,
                  startTutorial: _startTutorial,
                  tutorialRun: _tutorialRun,
                  active: _inputActive,
                ),
                if (_viewModel.isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
