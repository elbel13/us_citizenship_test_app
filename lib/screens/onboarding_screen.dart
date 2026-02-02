import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../main.dart';

/// Main onboarding flow screen with PageView navigation
class OnboardingScreen extends StatefulWidget {
  final OnboardingService onboardingService;

  const OnboardingScreen({Key? key, required this.onboardingService})
    : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  late int _currentPage;
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();

  // User selections
  String? _selectedUILanguage;
  String? _selectedStudyLanguage;
  String? _selectedYear;
  String? _selectedState;
  String? _selectedZipCode;
  GovernmentOfficials? _officials;

  bool _isLoading = false;
  List<String> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _currentPage = widget.onboardingService.currentStep;
    _pageController = PageController(initialPage: _currentPage);

    // Load saved selections
    _selectedUILanguage = widget.onboardingService.uiLanguage;
    _selectedStudyLanguage = widget.onboardingService.studyLanguage;
    _selectedYear = widget.onboardingService.questionYear;
    _selectedState = widget.onboardingService.userState;
    _selectedZipCode = widget.onboardingService.userZipCode;

    _loadAvailableYears();
  }

  Future<void> _loadAvailableYears() async {
    final years = await _databaseService.getAvailableQuestionYears();
    setState(() {
      _availableYears = years;
      // Set default year if not already set
      if (_selectedYear == null && years.isNotEmpty) {
        _selectedYear = years.first;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToNextPage() async {
    // Save current step progress
    await widget.onboardingService.setCurrentStep(_currentPage);

    // Get total number of pages
    final totalPages = _getTotalPages();

    if (_currentPage < totalPages - 1) {
      setState(() {
        _currentPage++;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      await widget.onboardingService.setCurrentStep(_currentPage);
    } else {
      // Complete onboarding
      await _completeOnboarding();
    }
  }

  Future<void> _goToPreviousPage() async {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      await widget.onboardingService.setCurrentStep(_currentPage);
    }
  }

  int _getTotalPages() {
    // Base pages: Language, Year, Location
    int total = 3;

    // Add study language page if UI language is not English
    if (_selectedUILanguage != null && _selectedUILanguage != 'en') {
      total++;
    }

    return total;
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load questions for selected year
      if (_selectedYear != null) {
        await _databaseService.loadQuestionsForYear(_selectedYear!, 'en');
      }

      // Update location-specific answers if we have officials
      if (_officials != null) {
        await _databaseService.updateLocationSpecificAnswers(
          governor: _officials!.governor,
          senator1: _officials!.senator1,
          senator2: _officials!.senator2,
          representative: _officials!.representative,
          state: _officials!.state,
        );
      }

      // Mark onboarding as complete
      await widget.onboardingService.completeOnboarding();

      // Navigate to main menu
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error completing setup: $e')));
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Setting up your app...'),
            ],
          ),
        ),
      );
    }

    final totalPages = _getTotalPages();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(value: (_currentPage + 1) / totalPages),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: _buildPages(),
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: _goToPreviousPage,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 80),
                  Text(
                    'Step ${_currentPage + 1} of $totalPages',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  ElevatedButton.icon(
                    onPressed: _canProceed() ? _goToNextPage : null,
                    icon: Icon(
                      _currentPage == totalPages - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                    ),
                    label: Text(
                      _currentPage == totalPages - 1 ? 'Finish' : 'Next',
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

  List<Widget> _buildPages() {
    final pages = <Widget>[];

    // Page 0: Language Selection
    pages.add(_buildLanguageSelectionPage());

    // Page 1: Study Language Selection (conditional)
    if (_selectedUILanguage != null && _selectedUILanguage != 'en') {
      pages.add(_buildStudyLanguageSelectionPage());
    }

    // Page N-1: Year Selection
    pages.add(_buildYearSelectionPage());

    // Page N: Location Setup
    pages.add(_buildLocationSetupPage());

    return pages;
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _selectedUILanguage != null;
      case 1:
        // Study language page (only if UI language is not English)
        if (_selectedUILanguage != 'en') {
          return _selectedStudyLanguage != null;
        }
        return _selectedYear != null;
      case 2:
        // Could be year or location depending on if study language was shown
        if (_selectedUILanguage != 'en') {
          return _selectedYear != null;
        }
        return _selectedState != null && _officials != null;
      case 3:
        return _selectedState != null && _officials != null;
      default:
        return false;
    }
  }

  Widget _buildLanguageSelectionPage() {
    return _OnboardingPageLayout(
      title: 'Welcome!',
      subtitle: 'Select your preferred language for the app interface',
      child: Column(
        children: [
          _LanguageOption(
            languageCode: 'en',
            languageName: 'English',
            isSelected: _selectedUILanguage == 'en',
            onTap: () async {
              setState(() {
                _selectedUILanguage = 'en';
                _selectedStudyLanguage = 'en'; // Auto-set study language
              });
              await widget.onboardingService.setUILanguage('en');
              await widget.onboardingService.setStudyLanguage('en');
              if (mounted) {
                USCitizenshipTestApp.setLocale(context, const Locale('en'));
              }
            },
          ),
          const SizedBox(height: 12),
          _LanguageOption(
            languageCode: 'es',
            languageName: 'Español (Spanish)',
            isSelected: _selectedUILanguage == 'es',
            onTap: () async {
              setState(() {
                _selectedUILanguage = 'es';
              });
              await widget.onboardingService.setUILanguage('es');
              if (mounted) {
                USCitizenshipTestApp.setLocale(context, const Locale('es'));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudyLanguageSelectionPage() {
    return _OnboardingPageLayout(
      title: 'Study Materials Language',
      subtitle:
          'The citizenship test is conducted in English. We recommend studying in English for best preparation.',
      child: Column(
        children: [
          _LanguageOption(
            languageCode: 'en',
            languageName: 'Study in English (Recommended)',
            isSelected: _selectedStudyLanguage == 'en',
            onTap: () async {
              setState(() {
                _selectedStudyLanguage = 'en';
              });
              await widget.onboardingService.setStudyLanguage('en');
            },
          ),
          const SizedBox(height: 12),
          _LanguageOption(
            languageCode: _selectedUILanguage ?? 'es',
            languageName:
                'Study in ${_selectedUILanguage == 'es' ? 'Spanish' : 'Selected Language'}',
            subtitle: 'Currently only English materials are available',
            isSelected: _selectedStudyLanguage == _selectedUILanguage,
            isEnabled: false, // Disabled for now
            onTap: () async {
              // TODO: Enable when translations are available
            },
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelectionPage() {
    return _OnboardingPageLayout(
      title: 'Test Version',
      subtitle:
          'Select the citizenship test version based on when your application was filed. USCIS updates the test periodically.',
      child: Column(
        children: _availableYears.map((year) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _YearOption(
              year: year,
              isSelected: _selectedYear == year,
              isLatest: year == _availableYears.first,
              onTap: () async {
                setState(() {
                  _selectedYear = year;
                });
                await widget.onboardingService.setQuestionYear(year);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLocationSetupPage() {
    return _OnboardingPageLayout(
      title: 'Location Setup',
      subtitle:
          'We need your location to provide accurate information about your local government officials',
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.location_on, size: 48, color: Colors.blue),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final position = await _locationService
                            .getCurrentPosition();
                        if (position != null) {
                          // TODO: Reverse geocode to get state
                          // For now, show manual entry
                          _showManualLocationEntry();
                        }
                      } catch (e) {
                        _showManualLocationEntry();
                      }
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use My Location'),
                  ),
                  const SizedBox(height: 8),
                  const Text('or', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _showManualLocationEntry,
                    icon: const Icon(Icons.edit_location),
                    label: const Text('Enter Zip Code'),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedState != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(height: 8),
                    Text(
                      'Location set: $_selectedState',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_selectedZipCode != null)
                      Text('Zip Code: $_selectedZipCode'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showManualLocationEntry() {
    showDialog(
      context: context,
      builder: (context) {
        String zipCode = '';
        return AlertDialog(
          title: const Text('Enter Your Zip Code'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Zip Code',
              hintText: '12345',
            ),
            keyboardType: TextInputType.number,
            maxLength: 5,
            onChanged: (value) {
              zipCode = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (zipCode.length == 5) {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final officials = await _locationService
                      .getOfficialsFromZipCode(zipCode);
                  if (officials != null) {
                    setState(() {
                      _selectedZipCode = zipCode;
                      _selectedState = officials.state;
                      _officials = officials;
                    });
                    await widget.onboardingService.setLocation(
                      state: officials.state,
                      zipCode: zipCode,
                    );
                    if (mounted) {
                      navigator.pop();
                    }
                  } else {
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Invalid zip code')),
                      );
                    }
                  }
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}

// Helper widgets

class _OnboardingPageLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _OnboardingPageLayout({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String languageCode;
  final String languageName;
  final String? subtitle;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _LanguageOption({
    Key? key,
    required this.languageCode,
    required this.languageName,
    this.subtitle,
    required this.isSelected,
    this.isEnabled = true,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Radio<String>(
                value: languageCode,
                groupValue: isSelected ? languageCode : null,
                onChanged: isEnabled ? (_) => onTap() : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isEnabled ? null : Colors.grey,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearOption extends StatelessWidget {
  final String year;
  final bool isSelected;
  final bool isLatest;
  final VoidCallback onTap;

  const _YearOption({
    Key? key,
    required this.year,
    required this.isSelected,
    required this.isLatest,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Radio<String>(
                value: year,
                groupValue: isSelected ? year : null,
                onChanged: (_) => onTap(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          year,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        if (isLatest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Latest',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLatest
                          ? 'Current test version (for recent applications)'
                          : 'Previous test version',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
