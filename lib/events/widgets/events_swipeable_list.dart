import 'package:flutter/material.dart';
import 'package:npi/input/event_tilt_input.dart';
import 'package:npi/events/events_view_model.dart';
import 'package:npi/events/swipe_deck_view_model.dart';
import 'package:npi/events/widgets/event_card.dart';
import 'package:npi/events/widgets/swipe_background.dart';
import 'package:npi/events/widgets/swipeable_card_wrapper.dart';
import 'package:npi/events/widgets/tilt_tutorial_overlay.dart';

class EventsSwipeableList extends StatefulWidget {
  const EventsSwipeableList({
    super.key,
    required this._viewModel,
    this.startTutorial = false,
    this.tutorialRun = 0,
    this.active = true,
  });

  final EventsViewModel _viewModel;
  final bool startTutorial;
  final int tutorialRun;
  final bool active;

  @override
  State<EventsSwipeableList> createState() => _EventsSwipeableListState();
}

class _EventsSwipeableListState extends State<EventsSwipeableList>
    with WidgetsBindingObserver {
  late final SwipeDeckViewModel _deckViewModel;
  late final EventTiltInput _input;

  @override
  void initState() {
    super.initState();
    _deckViewModel = SwipeDeckViewModel(widget._viewModel);
    _input = EventTiltInput(
      onSave: _deckViewModel.saveByTilt,
      onDiscard: _deckViewModel.discardByTilt,
      onProgress: _deckViewModel.showTiltProgress,
      onCancel: _deckViewModel.snapBack,
      onUnavailable: () {
        _deckViewModel.tutorialManager.skip();
      },
    );
    _deckViewModel.addListener(_syncInput);
    WidgetsBinding.instance.addObserver(this);
    if (widget.active) _input.start();
    if (widget.startTutorial && _input.isSupported) {
      _deckViewModel.resetTutorial();
    }
    _syncInput();
  }

  void _syncInput() {
    _input.suspended = !_deckViewModel.acceptsTilt;
    _input.enabled = !_deckViewModel.tutorialManager.isPanPhase;
    if (!_input.enabled) _input.reset();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.active) {
      _input.start();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _input.stop();
    }
  }

  @override
  void didUpdateWidget(covariant EventsSwipeableList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _input.start();
    if (!widget.active && oldWidget.active) _input.stop();
    if (_input.isSupported &&
        widget.startTutorial &&
        (!oldWidget.startTutorial ||
            widget.tutorialRun != oldWidget.tutorialRun)) {
      _deckViewModel.resetTutorial();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _input.dispose();
    _deckViewModel.removeListener(_syncInput);
    _deckViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ListenableBuilder(
      listenable: widget._viewModel,
      builder: (context, _) {
        final events = widget._viewModel.events;

        if (events.isEmpty) {
          return const Center(child: Text('No hay más eventos disponibles.'));
        }

        final topEvent = events.last;

        return ListenableBuilder(
          listenable: _deckViewModel,
          builder: (context, _) {
            return Scaffold(
              body: Stack(
                children: [
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        SwipeBackground(
                          dragOffset: _deckViewModel.dragOffset,
                          progress: _deckViewModel.swipeProgress,
                        ),
                        SwipeableCardWrapper(
                          dragOffset: _deckViewModel.dragOffset,
                          rotation: _deckViewModel.rotation,
                          isAnimating:
                              _deckViewModel.isProcessingSwipe ||
                              _deckViewModel.isSnappingBack,
                          onPanStart: _deckViewModel.handlePanStart,
                          onPanUpdate: (details) => _deckViewModel
                              .handlePanUpdate(details, screenWidth),
                          onPanEnd: (details) =>
                              _deckViewModel.handlePanEnd(details, screenWidth),
                          child: SizedBox(
                            width: screenWidth,
                            child: EventCard(
                              key: ValueKey('card_${topEvent.id}'),
                              event: topEvent,
                              showBookmarks: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: TiltTutorialOverlay(
                      tutorialManager: _deckViewModel.tutorialManager,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
