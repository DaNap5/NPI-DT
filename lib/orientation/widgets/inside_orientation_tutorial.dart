import 'package:flutter/material.dart';

import 'package:npi/input/floor_motion_input.dart';

class InsideOrientationTutorial extends StatefulWidget {
  const InsideOrientationTutorial({super.key, required this.input});

  final FloorMotionInput input;

  @override
  State<InsideOrientationTutorial> createState() =>
      _InsideOrientationTutorialState();
}

class _InsideOrientationTutorialState extends State<InsideOrientationTutorial> {
  int _currentStep = 0;

  static const _flipUpImage =
      'assets/floor_movement_gesture_tutorial/flip_up.jpg';
  static const _flipDownImage =
      'assets/floor_movement_gesture_tutorial/flip_down.jpg';

  @override
  void initState() {
    super.initState();
    widget.input.setTutorialOpen(true);
  }

  @override
  void dispose() {
    widget.input.setTutorialOpen(false);
    super.dispose();
  }

  static const _steps = [
    (
      title: 'Subir de planta',
      description:
          'Para subir una planta, inclina el teléfono hacia atrás '
          'con un movimiento firme y controlado.',
      imageAsset: _flipUpImage,
      icon: Icons.keyboard_double_arrow_up,
    ),
    (
      title: 'Bajar de planta',
      description:
          'Para bajar una planta, inclina el teléfono hacia delante '
          'con un movimiento firme y controlado.',
      imageAsset: _flipDownImage,
      icon: Icons.keyboard_double_arrow_down,
    ),
    (
      title: '¡Ya estás preparado!',
      description:
          'Antes de empezar, vamos a calibrar los sensores de tu teléfono '
          'para adaptar la detección de movimientos a tu forma de utilizarlo.',
      imageAsset: null,
      icon: Icons.phone_android,
    ),
  ];

  bool get _isLastStep => _currentStep == _steps.length - 1;

  void _nextStep() {
    if (!_isLastStep) {
      setState(() => _currentStep++);
      return;
    }

    widget.input.startCalibration();
    setState(() => _currentStep++);
  }

  void _previousStep() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
  }

  void _finishTutorial() {
    widget.input.activateMotionDetection();
    Navigator.of(context).pop(true);
  }

  void _retryCalibration() {
    widget.input.startCalibration();
  }

  Widget _buildVisualIndicator(
    ThemeData theme, {
    String? imageAsset,
    required IconData fallbackIcon,
    Color? iconColor,
  }) {
    if (imageAsset != null) {
      return Image.asset(imageAsset, height: 150, fit: BoxFit.contain);
    }

    return Icon(
      fallbackIcon,
      size: 76,
      color: iconColor ?? theme.colorScheme.primary,
    );
  }

  Widget _buildCalibrationContent(
    BuildContext context,
    FloorMotionInput viewModel,
  ) {
    switch (viewModel.calibrationStep) {
      case FloorMotionCalibrationStep.idle:
      case FloorMotionCalibrationStep.resting:
        return _buildRestStage(context, viewModel);

      case FloorMotionCalibrationStep.movingUp:
        return _buildGestureStage(
          context,
          viewModel: viewModel,
          imageAsset: _flipUpImage,
          icon: Icons.keyboard_double_arrow_up,
          title: 'Calibrar subida',
          description:
              'Inclina el teléfono hacia atrás 3 veces de forma firme '
              'y vuelve a la posición inicial tras cada gesto.',
          completed: viewModel.upGesturesCompleted,
        );

      case FloorMotionCalibrationStep.movingDown:
        return _buildGestureStage(
          context,
          viewModel: viewModel,
          imageAsset: _flipDownImage,
          icon: Icons.keyboard_double_arrow_down,
          title: 'Calibrar bajada',
          description:
              'Inclina el teléfono hacia delante 3 veces de forma firme '
              'y vuelve a la posición inicial tras cada gesto.',
          completed: viewModel.downGesturesCompleted,
        );

      case FloorMotionCalibrationStep.completed:
        return _buildStage(
          context,
          icon: Icons.check_circle_outline,
          title: '¡Calibración completada!',
          description:
              'Los sensores se han calibrado correctamente. '
              'Ya puedes utilizar los movimientos para cambiar de planta.',
          buttonText: 'Empezar',
          onPressed: _finishTutorial,
        );

      case FloorMotionCalibrationStep.failed:
        return _buildStage(
          context,
          icon: Icons.warning_amber_rounded,
          title: 'No se pudo calibrar',
          description:
              viewModel.calibrationMessage ??
              'No se han obtenido mediciones fiables. '
                  'Vamos a intentarlo de nuevo.',
          buttonText: 'Repetir calibración',
          onPressed: _retryCalibration,
        );
    }
  }

  Widget _buildRestStage(BuildContext context, FloorMotionInput viewModel) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.phone_android, size: 76, color: theme.colorScheme.primary),
        const SizedBox(height: 20),
        Text(
          'Mantén el teléfono quieto',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Sujeta el teléfono en una posición cómoda sin moverlo '
          'durante un par de segundos.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: viewModel.restProgress,
            minHeight: 8,
          ),
        ),
        if (viewModel.calibrationMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            viewModel.calibrationMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildGestureStage(
    BuildContext context, {
    required FloorMotionInput viewModel,
    required String imageAsset,
    required IconData icon,
    required String title,
    required String description,
    required int completed,
  }) {
    final theme = Theme.of(context);

    final String statusText;
    final Color statusColor;

    if (viewModel.isCapturingGesture) {
      statusText = 'Registrando movimiento...';
      statusColor = theme.colorScheme.primary;
    } else if (viewModel.readyForNextGesture) {
      statusText = 'Listo: realiza el gesto ahora';
      statusColor = Colors.green.shade700;
    } else {
      statusText = 'Vuelve a la posición inicial...';
      statusColor = theme.colorScheme.secondary;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildVisualIndicator(
          theme,
          imageAsset: imageAsset,
          fallbackIcon: icon,
          iconColor: viewModel.isCapturingGesture
              ? theme.colorScheme.tertiary
              : theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          description,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final isDone = index < completed;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isDone
                    ? Colors.green.shade600
                    : theme.colorScheme.outline,
                size: 28,
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusText,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
          ),
        ),
        if (viewModel.calibrationMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            viewModel.calibrationMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildStage(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 76, color: theme.colorScheme.primary),
        const SizedBox(height: 20),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          description,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: onPressed, child: Text(buttonText)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(
          _currentStep < _steps.length
              ? 'Cómo moverte por el edificio'
              : 'Calibración de movimientos',
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 320,
          child: _currentStep < _steps.length
              ? _buildTutorialContent(context, theme)
              : AnimatedBuilder(
                  animation: widget.input,
                  builder: (context, child) {
                    return _buildCalibrationContent(context, widget.input);
                  },
                ),
        ),
        actions: _currentStep < _steps.length
            ? [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _previousStep,
                    child: const Text('Anterior'),
                  ),
                FilledButton(
                  onPressed: _nextStep,
                  child: Text(_isLastStep ? 'Calibrar' : 'Siguiente'),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildTutorialContent(BuildContext context, ThemeData theme) {
    final step = _steps[_currentStep];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Column(
            key: ValueKey(_currentStep),
            children: [
              _buildVisualIndicator(
                theme,
                imageAsset: step.imageAsset,
                fallbackIcon: step.icon,
              ),
              const SizedBox(height: 20),
              Text(
                step.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                step.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _steps.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: index == _currentStep ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: index == _currentStep
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
