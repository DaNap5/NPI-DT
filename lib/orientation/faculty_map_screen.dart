import 'location_client.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:npi/orientation/directions_page.dart';
import 'package:npi/orientation/map_zone.dart';
import 'package:npi/orientation/directions_flow_view_model.dart';
import 'package:npi/orientation/faculty_map_view_model.dart';
import 'package:npi/orientation/widgets/floor_map.dart';
import 'package:npi/orientation/widgets/inside_orientation_tutorial.dart';
import 'package:npi/orientation/widgets/zone_info_panel.dart';
import 'package:npi/storage/local_store.dart';
import 'package:npi/input/floor_motion_input.dart';

import 'data/floors.dart';

class FacultyMapScreen extends StatefulWidget {
  const FacultyMapScreen({
    super.key,
    this.title = 'Vista superior de la ETSIIT',
    this.initialFloorIndex = 1,
    this.additionalZonesByFloor = const {},
    this.onZoneSelected,
    this.locationClient,
    required this.store,
  });

  final String title;
  final int initialFloorIndex;
  final Map<int, List<MapZone>> additionalZonesByFloor;
  final Future<void> Function(MapZone zone)? onZoneSelected;
  final LocationClient? locationClient;
  final LocalStore store;

  @override
  State<FacultyMapScreen> createState() => _FacultyMapScreenState();
}

class _FacultyMapScreenState extends State<FacultyMapScreen>
    with WidgetsBindingObserver {
  final _transformation = TransformationController();
  final _mapKey = GlobalKey();
  bool _preloaded = false;
  MapZone? _selectedZone;
  Timer? _selectionTimer;
  int _selectionGeneration = 0;
  bool _tutorialCheckStarted = false;

  late final FacultyMapViewModel _viewModel;
  late final FloorMotionInput _motionInput;
  int _lastInputFeedbackId = 0;
  int get _floorIndex => _viewModel.floorIndex;

  int _lastFloorIndex = 1;
  int _lastFeedbackId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_preloaded) {
      _preloaded = true;

      for (final floor in orientationFloors) {
        precacheImage(AssetImage('assets/orientation/${floor.asset}'), context);
      }
    }

    if (!_tutorialCheckStarted) {
      _tutorialCheckStarted = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTutorialIfNeeded();
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _lastFloorIndex = widget.initialFloorIndex.clamp(0, 6);

    _viewModel = FacultyMapViewModel(
      initialFloorIndex: widget.initialFloorIndex,
    );

    _viewModel.addListener(_onViewModelChanged);
    _motionInput = FloorMotionInput(
      onUp: _viewModel.nextFloor,
      onDown: _viewModel.previousFloor,
    );
    _motionInput.addListener(_onInputChanged);
    WidgetsBinding.instance.addObserver(this);
    _motionInput.start();
  }

  void _onInputChanged() {
    if (!mounted) return;
    if (_lastInputFeedbackId != _motionInput.feedbackId) {
      _lastInputFeedbackId = _motionInput.feedbackId;
      _viewModel.showFeedback(
        _motionInput.feedbackMessage,
        _motionInput.feedbackType == null
            ? null
            : MapFeedbackType.values.byName(_motionInput.feedbackType!.name),
      );
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _motionInput.start();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _motionInput.stop();
    }
  }

  Future<void> _openTutorial() async {
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => InsideOrientationTutorial(input: _motionInput),
    );

    if (!mounted) return;

    if (completed == true) {
      try {
        await widget.store.completeFloorTutorial();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo guardar el tutorial.')),
          );
        }
      }
    }
  }

  Future<void> _showTutorialIfNeeded() async {
    final tutorialCompleted = widget.store.floorTutorialCompleted;

    if (!mounted || tutorialCompleted || !_motionInput.isSupported) return;

    await _openTutorial();
  }

  void _onViewModelChanged() {
    if (!mounted) return;

    if (_lastFloorIndex != _viewModel.floorIndex) {
      _lastFloorIndex = _viewModel.floorIndex;
      HapticFeedback.mediumImpact();
      _selectedZone = null;
    }

    if (_lastFeedbackId != _viewModel.feedbackId) {
      _lastFeedbackId = _viewModel.feedbackId;
      _playFeedbackSound(_viewModel.feedbackType);
      if (_viewModel.feedbackType == MapFeedbackType.error) {
        HapticFeedback.heavyImpact();
      }
    }

    setState(() {});
  }

  void _playFeedbackSound(MapFeedbackType? type) {
    switch (type) {
      case MapFeedbackType.success:
        SystemSound.play(SystemSoundType.click);
        break;

      case MapFeedbackType.warning:
      case MapFeedbackType.error:
        SystemSound.play(SystemSoundType.alert);
        break;

      case null:
        break;
    }
  }

  Widget _buildFeedbackBanner(BuildContext context) {
    final message = _viewModel.feedbackMessage;
    final type = _viewModel.feedbackType;

    if (message == null || type == null) {
      return const SizedBox.shrink();
    }

    final Color backgroundColor;
    final Color foregroundColor;
    final IconData icon;

    switch (type) {
      case MapFeedbackType.success:
        backgroundColor = Colors.green.shade100;
        foregroundColor = Colors.green.shade900;
        icon = Icons.check_circle_outline;

      case MapFeedbackType.warning:
        backgroundColor = Colors.orange.shade100;
        foregroundColor = Colors.orange.shade900;
        icon = Icons.warning_amber_rounded;

      case MapFeedbackType.error:
        backgroundColor = Colors.red.shade100;
        foregroundColor = Colors.red.shade900;
        icon = Icons.error_outline;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Container(
          key: ValueKey(_viewModel.feedbackId),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: foregroundColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motionInput.removeListener(_onInputChanged);
    _motionInput.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();

    _selectionTimer?.cancel();
    _transformation.dispose();

    super.dispose();
  }

  Future<void> _selectZone(MapZone zone) async {
    _selectionTimer?.cancel();
    final generation = ++_selectionGeneration;
    setState(() => _selectedZone = zone);
    _selectionTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted && generation == _selectionGeneration) {
        setState(() => _selectedZone = null);
      }
    });
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted || generation != _selectionGeneration) return;
    await widget.onZoneSelected?.call(zone);
  }

  Future<void> _openZone(MapZone zone) async {
    if (_selectedZone != null) return;
    final floorName = orientationFloors[_floorIndex].name;
    setState(() => _selectedZone = zone);
    var openDirections = false;
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Cerrar información',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (dialogContext, animation, secondaryAnimation) => SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: (constraints.maxWidth * .85).clamp(0.0, 360.0),
                height: constraints.maxHeight,
                child: ZoneInfoPanel(
                  zone: zone,
                  floorName: floorName,
                  onClose: () => Navigator.of(dialogContext).pop(),
                  onDirections: () {
                    if (zone.id != 'faculty-entrance') return;
                    openDirections = true;
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ),
            ),
          ),
        ),
        transitionBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
      );
    } finally {
      if (mounted) setState(() => _selectedZone = null);
    }
    if (mounted && openDirections) {
      _motionInput.stop();
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => DirectionsPage(
            store: widget.store,
            initialDestination: DirectionsDestination.facultyEntrance,
            locationClient: widget.locationClient,
          ),
        ),
      );
      if (mounted) _motionInput.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final floor = orientationFloors[_floorIndex];
    final floorZones = floor.zones;
    final additionalZones = widget.additionalZonesByFloor[_floorIndex];
    final zones = additionalZones == null
        ? floorZones
        : [...floorZones, ...additionalZones];
    final screen = MediaQuery.sizeOf(context);
    final compact = screen.width > screen.height && screen.shortestSide < 600;
    final map = ClipRect(
      key: _mapKey,
      child: InteractiveViewer(
        transformationController: _transformation,
        minScale: 1,
        maxScale: 4,
        child: SizedBox.expand(
          child: FloorMap(
            asset: 'assets/orientation/${floor.asset}',
            label: 'ETSIIT: planta ${floor.name}',
            zones: zones,
            selectedZoneId: _selectedZone?.id,
            onZoneTap: widget.onZoneSelected == null ? _openZone : _selectZone,
            onPolygonTap: widget.onZoneSelected == null
                ? _openZone
                : _selectZone,
          ),
        ),
      ),
    );

    final legend = SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final zone in zones)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 12, color: zone.color),
                  const SizedBox(width: 6),
                  Text('${zone.number}. ${zone.name}'),
                ],
              ),
            ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            key: const ValueKey('recalibrate-tutorial-button'),
            tooltip: 'Tutorial y calibración',
            icon: const Icon(Icons.tune),
            onPressed: _motionInput.isSupported ? _openTutorial : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_viewModel.feedbackMessage != null)
              _buildFeedbackBanner(context),
            Expanded(
              child: compact
                  ? Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(child: map),
                              legend,
                            ],
                          ),
                        ),
                        SizedBox(
                          key: const ValueKey('compact-floor-controls'),
                          width: 64,
                          child: Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      child: RotatedBox(
                                        quarterTurns: 3,
                                        child: Column(
                                          children: [
                                            Text(
                                              'Planta: ${floor.name}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Inclina hacia adelante para bajar',
                                              textAlign: TextAlign.center,
                                            ),
                                            const Text(
                                              'Inclina hacia atrás para subir',
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 24,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            for (var i = 6; i >= 0; i--)
                                              Semantics(
                                                selected: i == _floorIndex,
                                                label:
                                                    orientationFloors[i].name,
                                                child: Text(
                                                  const [
                                                    'S',
                                                    'B',
                                                    '1',
                                                    '2',
                                                    '3',
                                                    '4',
                                                    '5',
                                                  ][i],
                                                  key: ValueKey(
                                                    'floor-label-$i',
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: i == _floorIndex
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color: i == _floorIndex
                                                        ? Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Semantics(
                                label: 'Restablecer vista',
                                child: IconButton(
                                  key: const ValueKey('reset-map-view'),
                                  onPressed: _resetView,
                                  icon: const Icon(Icons.center_focus_strong),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: map),
                        legend,
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'Planta: ${floor.name}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  _floorSlider(floor.name),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Inclina el teléfono hacia adelante para bajar',
                                    textAlign: TextAlign.center,
                                  ),
                                  const Text(
                                    'Inclina el teléfono hacia atrás para subir',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _resetView,
                                icon: const Icon(Icons.center_focus_strong),
                                label: const Text('Restablecer vista'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetView() => _transformation.value = Matrix4.identity();

  Widget _floorSlider(String name) => Slider(
    value: _floorIndex.toDouble(),
    min: 0,
    max: 6,
    divisions: 6,
    label: name,
    semanticFormatterCallback: (value) => orientationFloors[value.round()].name,
    onChanged: (value) {
      _selectionTimer?.cancel();
      _selectionGeneration++;

      _viewModel.setFloor(value.round());

      setState(() {
        _selectedZone = null;
      });
    },
  );
}
