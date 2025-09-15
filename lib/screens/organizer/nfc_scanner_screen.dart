import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/nfc_service.dart';
import '../../services/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/ticket.dart';

class NfcScannerScreen extends StatefulWidget {
  const NfcScannerScreen({super.key});

  @override
  State<NfcScannerScreen> createState() => _NfcScannerScreenState();
}

class _NfcScannerScreenState extends State<NfcScannerScreen> with TickerProviderStateMixin {
  bool _isScanning = false;
  bool _nfcAvailable = false;
  String? _lastScannedUid;
  String? _scanResult;
  List<Ticket> _recentScans = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
    _initAnimations();
    _loadRecentScans();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkNfcAvailability() async {
    final available = await NfcService.isNfcAvailable();
    setState(() {
      _nfcAvailable = available;
    });
  }

  Future<void> _startScanning() async {
    if (!_nfcAvailable) {
      _showMessage('NFC is not available on this device', isError: true);
      return;
    }

    setState(() {
      _isScanning = true;
      _scanResult = null;
    });

    _pulseController.repeat(reverse: true);

    try {
      final uid = await NfcService.readNfcTag();
      
      if (uid != null) {
        setState(() {
          _lastScannedUid = uid;
        });
        
        await _checkTicket(uid);
      } else {
        _showMessage('Failed to read NFC tag', isError: true);
      }
    } catch (e) {
      _showMessage('Error scanning NFC: $e', isError: true);
    } finally {
      setState(() {
        _isScanning = false;
      });
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  Future<void> _loadRecentScans() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    try {
      // Get all events by this organizer
      final events = await SupabaseService.getEventsByOrganizer(
        authProvider.currentUser!.userId
      );
      
      if (events.isEmpty) return;

      // Get recent tickets for all organizer's events
      final allTickets = <Ticket>[];
      for (final event in events) {
        final eventTickets = await SupabaseService.getTicketsByEvent(event.id);
        allTickets.addAll(eventTickets);
      }

      // Sort by created date and take recent ones
      allTickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      setState(() {
        _recentScans = allTickets.take(10).toList();
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _checkTicket(String uid) async {
    try {
      final ticket = await SupabaseService.getTicketByUid(uid);
      
      if (ticket == null) {
        setState(() {
          _scanResult = 'Invalid ticket - UID not found';
        });
        _showValidationResult(false, 'Invalid Ticket', 'This NFC tag is not associated with any ticket.');
        return;
      }

      if (ticket.isCheckedIn) {
        setState(() {
          _scanResult = 'Already checked in';
        });
        _showValidationResult(false, 'Already Checked In', 'This ticket has already been used for entry.');
        return;
      }

      if (ticket.isActive) {
        // Check in the ticket
        await SupabaseService.updateTicketStatus(ticket.id, 'checked_in');
        
        // Add to recent scans
        setState(() {
          _scanResult = 'Valid ticket - Check-in successful';
          _recentScans.insert(0, ticket);
          if (_recentScans.length > 10) {
            _recentScans = _recentScans.take(10).toList();
          }
        });
        
        _showValidationResult(true, 'Check-in Successful', 'Welcome to the event!');
      } else {
        setState(() {
          _scanResult = 'Inactive ticket';
        });
        _showValidationResult(false, 'Inactive Ticket', 'This ticket is no longer valid.');
      }
    } catch (e) {
      setState(() {
        _scanResult = 'Error validating ticket: $e';
      });
      _showValidationResult(false, 'Validation Error', 'Failed to validate ticket. Please try again.');
    }
  }

  void _showValidationResult(bool isValid, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isValid ? Icons.check_circle : Icons.cancel,
              size: 64,
              color: isValid ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isValid ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (_lastScannedUid != null) ...[
              const SizedBox(height: 12),
              Text(
                'UID: $_lastScannedUid',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'NFC Scanner',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _nfcAvailable ? Icons.nfc : Icons.nfc_outlined,
                    color: _nfcAvailable 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    size: 28,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // NFC Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _nfcAvailable 
                      ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                      : Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _nfcAvailable 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _nfcAvailable ? Icons.check_circle : Icons.error,
                      color: _nfcAvailable 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nfcAvailable ? 'NFC Ready' : 'NFC Unavailable',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _nfcAvailable 
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                          Text(
                            _nfcAvailable 
                                ? 'Your device supports NFC scanning'
                                : 'NFC is not available on this device',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Scanner Animation/Interface
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isScanning ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isScanning 
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                  : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3,
                              ),
                            ),
                            child: Icon(
                              Icons.nfc,
                              size: 80,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Text(
                      _isScanning 
                          ? 'Hold NFC wristband near device...'
                          : 'Tap the button to scan NFC wristband',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Scan Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nfcAvailable && !_isScanning ? _startScanning : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isScanning 
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Scanning...'),
                                ],
                              )
                            : const Text(
                                'Start NFC Scan',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // Recent scans and stats
              if (_recentScans.isNotEmpty) ...[
                const SizedBox(height: 24),
                
                // Quick stats
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickStat(
                        'Total Scanned',
                        '${_recentScans.length}',
                        Icons.qr_code_scanner,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickStat(
                        'Checked In',
                        '${_recentScans.where((t) => t.isCheckedIn).length}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Recent scans list
                Container(
                  height: 200,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _recentScans.length.clamp(0, 5),
                          itemBuilder: (context, index) {
                            final ticket = _recentScans[index];
                            return _buildRecentScanItem(ticket);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Last scan result (if any)
              if (_scanResult != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _scanResult!.contains('successful') 
                        ? Colors.green.withValues(alpha: 0.1)
                        : _scanResult!.contains('Invalid') || _scanResult!.contains('Already')
                            ? Colors.red.withValues(alpha: 0.1)
                            : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _scanResult!.contains('successful') 
                          ? Colors.green
                          : _scanResult!.contains('Invalid') || _scanResult!.contains('Already')
                              ? Colors.red
                              : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _scanResult!.contains('successful') 
                                ? Icons.check_circle
                                : _scanResult!.contains('Invalid') || _scanResult!.contains('Already')
                                    ? Icons.error
                                    : Icons.info,
                            color: _scanResult!.contains('successful') 
                                ? Colors.green
                                : _scanResult!.contains('Invalid') || _scanResult!.contains('Already')
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Last Scan Result:',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _scanResult!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_lastScannedUid != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'UID: $_lastScannedUid',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScanItem(Ticket ticket) {
    final timeAgo = _getTimeAgo(ticket.createdAt);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ticket.isCheckedIn 
              ? Colors.green.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ticket.isCheckedIn ? Icons.check_circle : Icons.pending,
            color: ticket.isCheckedIn ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ticket #${ticket.id.substring(0, 8)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  timeAgo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            ticket.isCheckedIn ? 'Checked In' : 'Active',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ticket.isCheckedIn ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}