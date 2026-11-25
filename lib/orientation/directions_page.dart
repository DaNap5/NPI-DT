import 'package:npi/storage/local_store.dart';
import 'package:flutter/material.dart';
import 'package:npi/orientation/location_client.dart';
import 'package:npi/orientation/directions_flow_view_model.dart';
import 'package:npi/orientation/origin_map_page.dart';
import 'package:npi/orientation/widgets/location_warning_overlay.dart';
import 'package:npi/orientation/widgets/waypoint_guide.dart';
import 'package:npi/qr/qr_scanner_screen.dart';

class DirectionsPage extends StatefulWidget {
  const DirectionsPage({
    super.key,
    this.initialDestination,
    this.locationClient,
    required this.store,
  });

  final LocalStore store;
  final DirectionsDestination? initialDestination;
  final LocationClient? locationClient;

  @override
  State<DirectionsPage> createState() => _DirectionsPageState();
}

class _DirectionsPageState extends State<DirectionsPage> {
  static const _choiceColor = Color(0xFF0D47A1);
  static const _secondaryChoiceColor = Color(0xFFBBDEFB);
  late final DirectionsFlowViewModel _viewModel = DirectionsFlowViewModel(
    locationClient: widget.locationClient ?? LocationClient(),
    initialDestination: widget.initialDestination,
  );
  bool _locationWarningShown = false;
  OverlayEntry? _locationWarningEntry;
  bool _arrivalDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onFlowChanged);
    if (widget.initialDestination != null) {
      _viewModel.checkLocation();
    }
  }

  @override
  void dispose() {
    final warning = _locationWarningEntry;
    _locationWarningEntry = null;
    warning?.remove();
    _viewModel.removeListener(_onFlowChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onFlowChanged() {
    _showLocationWarningIfNeeded();
    _showArrivalPromptIfNeeded();
  }

  void _goBack() {
    if (widget.initialDestination != null) {
      Navigator.of(context).pop();
      return;
    }
    if (_viewModel.canGoBack) {
      _viewModel.goBack();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showLocationWarningIfNeeded() {
    if (!_viewModel.waypointLocationUnavailable) {
      _locationWarningShown = false;
      _locationWarningEntry?.remove();
      _locationWarningEntry = null;
      return;
    }
    if (_locationWarningShown || _locationWarningEntry != null) return;
    _locationWarningShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_viewModel.waypointLocationUnavailable) return;
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => LocationWarningOverlay(
          onDismissed: () {
            if (_locationWarningEntry == entry) {
              entry.remove();
              _locationWarningEntry = null;
            }
          },
        ),
      );
      _locationWarningEntry = entry;
      Overlay.of(context, rootOverlay: true).insert(entry);
    });
  }

  void _showArrivalPromptIfNeeded() {
    if (_arrivalDialogOpen || _viewModel.pendingArrivalWaypointIndex == null) {
      return;
    }
    _arrivalDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final target = _viewModel.takePendingArrivalPrompt();
      if (target == null) {
        _arrivalDialogOpen = false;
        return;
      }
      final arrived = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Has llegado?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sí'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      _arrivalDialogOpen = false;
      if (arrived == true && _viewModel.confirmArrival(target)) _goHome();
    });
  }

  Future<void> _openOriginMap() async {
    final selected = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OriginMapPage(store: widget.store)),
    );
    if (mounted && selected == true) _viewModel.startGuideFromClassroom();
  }

  Future<void> _openQrScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const QrScannerScreen()),
    );
    if (mounted && result != null) {
      _viewModel.startGuideFromClassroom();
    }
  }

  Widget _choices(
    String question,
    List<({String label, VoidCallback onPressed})> options, {
    Set<String> highlightedLabels = const {},
  }) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(question, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 28),
        for (final option in options) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: option.onPressed,
              style: FilledButton.styleFrom(
                backgroundColor:
                    highlightedLabels.isNotEmpty &&
                        !highlightedLabels.contains(option.label)
                    ? _secondaryChoiceColor
                    : _choiceColor,
                foregroundColor:
                    highlightedLabels.isNotEmpty &&
                        !highlightedLabels.contains(option.label)
                    ? const Color(0xFF0D47A1)
                    : Colors.white,
                minimumSize: const Size.fromHeight(84),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(option.label, textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _farFromFaculty() {
    final destination = switch (_viewModel.destination) {
      DirectionsDestination.auxiliaryBuilding => 'Edificio auxiliar',
      _ => 'ETSIIT',
    };
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Parece que estás lejos de la ETSIIT',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: _choiceColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(84),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Icons.map_outlined),
            label: Text('Google Maps: $destination'),
          ),
        ),
      ],
    );
  }

  Widget _currentScreen() {
    return switch (_viewModel.stage) {
      DirectionsStage.destinationArea => _choices(
        '¿El sitio está dentro o fuera de la facultad?',
        [
          (
            label: 'Dentro de la facultad',
            onPressed: () => _viewModel.chooseDestinationArea(inside: true),
          ),
          (
            label: 'Fuera de la facultad',
            onPressed: () => _viewModel.chooseDestinationArea(inside: false),
          ),
        ],
      ),
      DirectionsStage.insideDestinations => _choices(
        '¿A dónde vas?',
        [
          (label: 'Secretaría', onPressed: () {}),
          (label: 'Conserjería', onPressed: () {}),
          (label: 'Biblioteca', onPressed: () {}),
          (label: 'Cafetería', onPressed: () {}),
          (label: 'Comedor', onPressed: () {}),
          (
            label: 'Puerta de la facultad',
            onPressed: () {
              _viewModel.chooseFacultyEntrance();
              _viewModel.checkLocation();
            },
          ),
        ],
        highlightedLabels: const {'Puerta de la facultad'},
      ),
      DirectionsStage.outsideDestinations => _choices(
        '¿A dónde vas?',
        [
          (label: 'CSIRC', onPressed: () {}),
          (label: 'Facultad de Ciencias', onPressed: () {}),
          (
            label: 'Edificio auxiliar',
            onPressed: _viewModel.chooseAuxiliaryBuilding,
          ),
        ],
        highlightedLabels: const {'Edificio auxiliar'},
      ),
      DirectionsStage.entranceChoice => _choices(
        'Ve a la entrada principal de la facultad',
        [
          (
            label: 'Ya estoy en la Entrada',
            onPressed: _viewModel.startGuideFromEntrance,
          ),
          (label: 'Llévame a la Entrada', onPressed: _viewModel.checkLocation),
        ],
      ),
      DirectionsStage.checkingLocation => const Center(
        child: CircularProgressIndicator(
          semanticsLabel: 'Comprobando ubicación',
        ),
      ),
      DirectionsStage.locationUnavailable => _choices('¿Dónde estás?', [
        (
          label: 'Estoy en la ETSIIT',
          onPressed: () => _viewModel.chooseManualLocation(near: true),
        ),
        (
          label: 'Estoy lejos de la ETSIIT',
          onPressed: () => _viewModel.chooseManualLocation(near: false),
        ),
      ]),
      DirectionsStage.farFromFaculty => _farFromFaculty(),
      DirectionsStage.suggestedOrigin => _choices('¿Estás en el aula 2.7?', [
        (label: 'Sí', onPressed: _viewModel.startGuideFromClassroom),
        (label: 'No', onPressed: _viewModel.chooseOriginMethod),
      ]),
      DirectionsStage.originMethod => _choices(
        '¿Cómo quieres indicar tu origen?',
        [
          (label: 'Escanear un QR', onPressed: _openQrScanner),
          (label: 'Seleccionar en el mapa', onPressed: _openOriginMap),
        ],
      ),
      DirectionsStage.waypointGuide => WaypointGuide(
        waypoints: _viewModel.waypoints,
        currentIndex: _viewModel.waypointIndex,
        onPrevious: _viewModel.previousWaypoint,
        onNext: _viewModel.nextWaypoint,
        onHome: _goHome,
        distanceMeters: _viewModel.waypointDistanceMeters,
        waypointReached: _viewModel.waypointReached,
        automaticValidation: _viewModel.usesAutomaticWaypointValidation,
        locationUnavailable: _viewModel.waypointLocationUnavailable,
        trackedWaypointName: _viewModel.trackedWaypointName,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return PopScope(
          canPop: widget.initialDestination != null || !_viewModel.canGoBack,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _viewModel.canGoBack) _viewModel.goBack();
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Llévame a algún sitio'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Atrás',
                onPressed: _goBack,
              ),
              actions: _viewModel.stage == DirectionsStage.farFromFaculty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Volver a inicio',
                        onPressed: _goHome,
                      ),
                    ]
                  : null,
            ),
            body: SafeArea(child: _currentScreen()),
          ),
        );
      },
    );
  }
}
