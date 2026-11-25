import 'package:flutter/material.dart';
import 'package:npi/auth/session_state.dart';
import 'package:npi/storage/local_store.dart';

import 'event_catalog.dart';
import 'events_view_model.dart';
import 'widgets/event_card.dart';

class DiscardedEventsScreen extends StatefulWidget {
  const DiscardedEventsScreen({
    super.key,
    required this.session,
    required this.store,
    required this.catalog,
  });
  final SessionState session;
  final LocalStore store;
  final EventCatalog catalog;
  @override
  State<DiscardedEventsScreen> createState() => _DiscardedEventsScreenState();
}

class _DiscardedEventsScreenState extends State<DiscardedEventsScreen> {
  late final EventsViewModel _viewModel;
  @override
  void initState() {
    super.initState();
    _viewModel = EventsViewModel(
      session: widget.session,
      store: widget.store,
      catalog: widget.catalog,
      discardedOnly: true,
    );
    _viewModel.loadEvents();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Eventos Descartados')),
    body: ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_viewModel.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_viewModel.error!),
                TextButton(
                  onPressed: _viewModel.loadEvents,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        if (_viewModel.events.isEmpty) {
          return const Center(child: Text('No hay eventos disponibles.'));
        }
        return ListView(
          children: [
            for (final event in _viewModel.events)
              EventCard(
                key: ValueKey(event.id),
                event: event,
                showBookmarks: widget.session.isSignedIn,
                isSaving: _viewModel.isMutating,
                onBookmark: () async {
                  try {
                    await _viewModel.saveEvent(event);
                  } catch (_) {
                    /* Error is displayed by the viewmodel. */
                  }
                },
              ),
          ],
        );
      },
    ),
  );
}
