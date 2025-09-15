import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';

class OrganizerOnboardingScreen extends StatefulWidget {
  const OrganizerOnboardingScreen({super.key});

  @override
  State<OrganizerOnboardingScreen> createState() => _OrganizerOnboardingScreenState();
}

class _OrganizerOnboardingScreenState extends State<OrganizerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  
  String _selectedPaymentMethod = 'bank';
  String? _selectedBank;
  String? _selectedMobileProvider;
  bool _isLoading = false;

  final List<Map<String, String>> _banks = [
    {'name': 'Access Bank', 'code': '044'},
    {'name': 'GTBank', 'code': '058'},
    {'name': 'First Bank', 'code': '011'},
    {'name': 'UBA', 'code': '033'},
    {'name': 'Zenith Bank', 'code': '057'},
    {'name': 'Fidelity Bank', 'code': '070'},
    {'name': 'FCMB', 'code': '214'},
    {'name': 'Sterling Bank', 'code': '232'},
    {'name': 'Unity Bank', 'code': '215'},
    {'name': 'Keystone Bank', 'code': '082'},
  ];

  final List<Map<String, String>> _mobileProviders = [
    {'name': 'MTN Mobile Money', 'code': 'mtn'},
    {'name': 'Airtel Money', 'code': 'airtel'},
    {'name': 'Vodafone Cash', 'code': 'vodafone'},
    {'name': 'Tigo Cash', 'code': 'tigo'},
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _accountNumberController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? subaccountCode;
      
      if (_selectedPaymentMethod == 'bank' && _selectedBank != null) {
        final bankCode = _banks.firstWhere((bank) => bank['name'] == _selectedBank)['code']!;
        
        subaccountCode = await SupabaseService.createOrganizerSubaccount(
          organizerId: authProvider.currentUser!.userId,
          businessName: _businessNameController.text.trim(),
          accountNumber: _accountNumberController.text.trim(),
          bankCode: bankCode, mobileMoneyCode: '',
        );
      } else if (_selectedPaymentMethod == 'mobile' && _selectedMobileProvider != null) {
        final providerCode = _mobileProviders.firstWhere((provider) => provider['name'] == _selectedMobileProvider)['code']!;
        
        subaccountCode = await SupabaseService.createOrganizerSubaccount(
          organizerId: authProvider.currentUser!.userId,
          businessName: _businessNameController.text.trim(),
          accountNumber: _mobileNumberController.text.trim(),
          bankCode: providerCode,
          mobileMoneyCode: providerCode,
        );
      }

      if (subaccountCode != null && mounted) {
        // Mark onboarding as complete
        await SupabaseService.updateUserProfile(
          authProvider.currentUser!.copyWith(
            preferences: {
              'onboarding_completed': true,
              'payment_setup': true,
            },
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment setup completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to dashboard
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/organizer/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                
                // Header
                Text(
                  'Complete Your Setup',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up your payment details to receive earnings from ticket sales. Snaptic takes 20% and you keep 80%.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                
                const SizedBox(height: 32),

                // Business Name
                TextFormField(
                  controller: _businessNameController,
                  decoration: InputDecoration(
                    labelText: 'Business/Organization Name *',
                    hintText: 'Enter your business name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(
                      Icons.business,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your business name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Payment Method Selection
                Text(
                  'Payment Method *',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'bank',
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
                        title: const Text('Bank Account'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        value: 'mobile',
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
                        title: const Text('Mobile Money'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // Bank Account Details
                if (_selectedPaymentMethod == 'bank') ...[
                  // Bank Selection
                  DropdownButtonFormField<String>(
                    value: _selectedBank,
                    decoration: InputDecoration(
                      labelText: 'Select Bank *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(
                        Icons.account_balance,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    items: _banks.map((bank) {
                      return DropdownMenuItem<String>(
                        value: bank['name'],
                        child: Text(bank['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBank = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select your bank';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Account Number
                  TextFormField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Account Number *',
                      hintText: 'Enter your account number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(
                        Icons.account_balance_wallet,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your account number';
                      }
                      if (value.length != 10) {
                        return 'Account number must be 10 digits';
                      }
                      return null;
                    },
                  ),
                ],

                // Mobile Money Details
                if (_selectedPaymentMethod == 'mobile') ...[
                  // Mobile Provider Selection
                  DropdownButtonFormField<String>(
                    value: _selectedMobileProvider,
                    decoration: InputDecoration(
                      labelText: 'Mobile Money Provider *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(
                        Icons.phone_android,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    items: _mobileProviders.map((provider) {
                      return DropdownMenuItem<String>(
                        value: provider['name'],
                        child: Text(provider['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMobileProvider = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select your mobile money provider';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Mobile Number
                  TextFormField(
                    controller: _mobileNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number *',
                      hintText: 'Enter your mobile number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(
                        Icons.phone,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your mobile number';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 32),

                // Revenue Split Information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Revenue Split',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '80%',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'You Keep',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 40,
                            color: Theme.of(context).dividerColor,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '20%',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Snaptic Fee',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Payments are automatically split and transferred to your account after each ticket sale.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Complete Setup Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Complete Setup',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Skip for now option
                TextButton(
                  onPressed: () {
                    // Allow skip but remind them later
                    Navigator.of(context).pushReplacementNamed('/organizer/dashboard');
                  },
                  child: Text(
                    'Skip for now (You can set this up later)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}