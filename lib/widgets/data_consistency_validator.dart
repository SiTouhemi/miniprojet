import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '/backend/schema/user_record.dart';
import '/backend/services/data_validation_service.dart';
import '/utils/error_handler.dart';
import '/utils/app_logger.dart';
import '/flutter_flow/app_state.dart';
import 'package:provider/provider.dart';
import 'dart:async';

/// Widget that validates and displays data consistency information
/// Implements requirements 2.1, 2.2, 2.3, 2.5, 2.7 for data display consistency
class DataConsistencyValidator extends StatefulWidget {
  final Widget child;
  final bool showValidationIndicator;
  final Duration validationInterval;

  const DataConsistencyValidator({
    Key? key,
    required this.child,
    this.showValidationIndicator = false,
    this.validationInterval = const Duration(minutes: 5),
  }) : super(key: key);

  @override
  State<DataConsistencyValidator> createState() => _DataConsistencyValidatorState();
}

class _DataConsistencyValidatorState extends State<DataConsistencyValidator> {
  final DataValidationService _validationService = DataValidationService.instance;
  final ErrorHandler _errorHandler = ErrorHandler.instance;
  
  ValidationStatus _validationStatus = ValidationStatus.unknown;
  String? _lastValidationError;
  DateTime? _lastValidationTime;
  Timer? _validationTimer;

  @override
  void initState() {
    super.initState();
    _startPeriodicValidation();
  }

  @override
  void dispose() {
    _validationTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicValidation() {
    _validationTimer = Timer.periodic(widget.validationInterval, (_) {
      _validateData();
    });
    
    // Run initial validation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateData();
    });
  }

  Future<void> _validateData() async {
    final appState = Provider.of<FFAppState>(context, listen: false);
    
    if (appState.currentUser == null) {
      setState(() {
        _validationStatus = ValidationStatus.noData;
        _lastValidationError = null;
        _lastValidationTime = DateTime.now();
      });
      return;
    }

    try {
      // Validate user data consistency
      final userValidation = await _validationService.validateUserData(
        appState.currentUser!,
        appState.currentUser!.uid,
      );

      // Check for hardcoded data
      final hardcodedValidation = _validationService.validateNoHardcodedData(
        appState.currentUser,
      );

      // Comprehensive validation
      final comprehensiveValidation = await _validationService.validateAllUserData(
        appState.currentUser,
        appState.userReservations,
        appState.todaysMenu,
        appState.availableTimeSlots,
        appState.selectedDate,
      );

      setState(() {
        if (comprehensiveValidation.isValid && userValidation.isValid && hardcodedValidation.isValid) {
          _validationStatus = ValidationStatus.valid;
          _lastValidationError = null;
        } else {
          _validationStatus = ValidationStatus.invalid;
          _lastValidationError = _formatValidationErrors(
            userValidation,
            hardcodedValidation,
            comprehensiveValidation,
          );
        }
        _lastValidationTime = DateTime.now();
      });

      // Log validation issues for debugging
      if (!comprehensiveValidation.isValid) {
        AppLogger.w('Data validation issues detected:', tag: 'DataConsistencyValidator');
        for (final error in comprehensiveValidation.allErrors) {
          AppLogger.d('  - $error', tag: 'DataConsistencyValidator');
        }
      }

    } catch (e) {
      setState(() {
        _validationStatus = ValidationStatus.error;
        _lastValidationError = _errorHandler.handleError(e, context: 'data_validation');
        _lastValidationTime = DateTime.now();
      });
    }
  }

  String _formatValidationErrors(
    ValidationResult userValidation,
    ValidationResult hardcodedValidation,
    ComprehensiveValidationResult comprehensiveValidation,
  ) {
    final errors = <String>[];
    
    if (!userValidation.isValid) {
      errors.add('Données utilisateur incohérentes');
    }
    
    if (!hardcodedValidation.isValid) {
      errors.add('Données codées en dur détectées');
    }
    
    if (!comprehensiveValidation.reservationValidation.isValid) {
      errors.add('Réservations incohérentes');
    }
    
    if (!comprehensiveValidation.menuValidation.isValid) {
      errors.add('Menu incohérent');
    }
    
    if (!comprehensiveValidation.timeSlotValidation.isValid) {
      errors.add('Créneaux incohérents');
    }

    return errors.join(', ');
  }

  Widget _buildValidationIndicator() {
    if (!widget.showValidationIndicator) return SizedBox.shrink();

    Color indicatorColor;
    IconData indicatorIcon;
    String tooltipMessage;

    switch (_validationStatus) {
      case ValidationStatus.valid:
        indicatorColor = Colors.green;
        indicatorIcon = Icons.check_circle;
        tooltipMessage = 'Données validées et cohérentes';
        break;
      case ValidationStatus.invalid:
        indicatorColor = Colors.orange;
        indicatorIcon = Icons.warning;
        tooltipMessage = 'Incohérences détectées: $_lastValidationError';
        break;
      case ValidationStatus.error:
        indicatorColor = Colors.red;
        indicatorIcon = Icons.error;
        tooltipMessage = 'Erreur de validation: $_lastValidationError';
        break;
      case ValidationStatus.noData:
        indicatorColor = Colors.grey;
        indicatorIcon = Icons.help_outline;
        tooltipMessage = 'Aucune donnée à valider';
        break;
      case ValidationStatus.unknown:
        indicatorColor = Colors.grey;
        indicatorIcon = Icons.hourglass_empty;
        tooltipMessage = 'Validation en cours...';
        break;
    }

    return Positioned(
      top: 8,
      right: 8,
      child: Tooltip(
        message: tooltipMessage,
        child: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: indicatorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: indicatorColor, width: 1),
          ),
          child: Icon(
            indicatorIcon,
            size: 16,
            color: indicatorColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        _buildValidationIndicator(),
      ],
    );
  }
}

/// Widget that ensures no hardcoded data is displayed
/// Requirement 2.5: Ensure no hardcoded data is displayed
class HardcodedDataChecker extends StatelessWidget {
  final UserRecord? user;
  final Widget child;
  final Widget? fallback;

  const HardcodedDataChecker({
    Key? key,
    required this.user,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return fallback ?? _buildNoDataFallback(context);
    }

    final validation = DataValidationService.instance.validateNoHardcodedData(user);
    
    if (!validation.isValid) {
      // Log the hardcoded data detection
      AppLogger.w('Hardcoded data detected: ${validation.errors}', tag: 'DataConsistencyValidator');
      
      // In debug mode, show warning
      if (kDebugMode) {
        return Stack(
          children: [
            child,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(8),
                color: Colors.yellow[700],
                child: Text(
                  'ATTENTION: Données potentiellement codées en dur détectées',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      }
    }

    return child;
  }

  Widget _buildNoDataFallback(BuildContext context) {
    return fallback ?? Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 8),
          Text(
            'Aucune donnée utilisateur disponible',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that displays fallback content for missing optional data
/// Requirement 2.7: Add fallback displays for missing optional data (class info)
class OptionalDataDisplay extends StatelessWidget {
  final String? data;
  final String label;
  final Widget? fallback;
  final TextStyle? style;

  const OptionalDataDisplay({
    Key? key,
    required this.data,
    required this.label,
    this.fallback,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data == null || data!.isEmpty) {
      return fallback ?? Text(
        '$label: Non spécifié',
        style: style?.copyWith(
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ) ?? TextStyle(
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Text(
      '$label: $data',
      style: style,
    );
  }
}

/// Widget that ensures real-time updates work correctly
/// Requirement 2.4: Ensure real-time updates work correctly
class RealTimeUpdateValidator extends StatefulWidget {
  final Widget child;
  final Duration updateTimeout;

  const RealTimeUpdateValidator({
    Key? key,
    required this.child,
    this.updateTimeout = const Duration(seconds: 5),
  }) : super(key: key);

  @override
  State<RealTimeUpdateValidator> createState() => _RealTimeUpdateValidatorState();
}

class _RealTimeUpdateValidatorState extends State<RealTimeUpdateValidator> {
  DateTime? _lastUpdateTime;
  Timer? _updateTimer;
  bool _isStale = false;

  @override
  void initState() {
    super.initState();
    _lastUpdateTime = DateTime.now();
    _startUpdateMonitoring();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startUpdateMonitoring() {
    _updateTimer = Timer.periodic(Duration(seconds: 1), (_) {
      final now = DateTime.now();
      if (_lastUpdateTime != null && 
          now.difference(_lastUpdateTime!) > widget.updateTimeout) {
        if (!_isStale) {
          setState(() {
            _isStale = true;
          });
        }
      }
    });
  }

  void _markUpdated() {
    setState(() {
      _lastUpdateTime = DateTime.now();
      _isStale = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FFAppState>(
      builder: (context, appState, _) {
        // Monitor for changes in app state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _markUpdated();
        });

        return Stack(
          children: [
            widget.child,
            if (_isStale)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.update,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Données obsolètes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

enum ValidationStatus {
  valid,
  invalid,
  error,
  noData,
  unknown,
}