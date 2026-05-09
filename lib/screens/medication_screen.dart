import 'package:flutter/material.dart';

import '../data/medication.dart';
import '../database/database_helper.dart';
import '../frontend/account_store.dart';
import '../services/medication_notification_service.dart';
//Copilot: "Explain the key Flutter patterns for implementing a medication form screen with TextEditingControllers, ModalBottomSheet with search, favorites management, date pickers, and database persistence."
// The MedicationScreen is a stateful widget that allows users to create and manage their medication plans. It provides a form for adding new medications, including fields for dosage, frequency, start date, and notes. The screen also displays a list of existing medication plans and allows users to delete them. The medication data is stored locally using the DatabaseHelper, and reminders are managed through the MedicationNotificationService. Users can also mark medications as favorites for quick access when creating new plans.
class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}
// The _MedicationScreenState class manages the state of the MedicationScreen, including form input controllers, the list of medication plans, and the set of favorite medications. It handles user interactions such as adding new medication plans, picking start dates, toggling favorites, and loading/saving data from the local database. The build method constructs the UI for the screen, including the form for adding medications and the list of existing plans.
class _MedicationScreenState extends State<MedicationScreen> {
  final _dosageController = TextEditingController();
  final _timeController = TextEditingController(text: '20:00');
  final _startDateController = TextEditingController();
  final _notesController = TextEditingController();
// The _plans variable holds the list of medication plans retrieved from the local database, while the _favorites set contains the generic names of medications that the user has marked as favorites for quick access. The _selectedMed variable tracks the currently selected medication name in the form, and the _freqCount and _freqUnit variables manage the frequency of medication intake. The _saving boolean is used to indicate when a medication plan is being saved to prevent duplicate submissions.
  List<Medication> _plans = const [];
  Set<String> _favorites = <String>{};
  String? _selectedMed;
  int _freqCount = 1;
  String _freqUnit = 'day';
  bool _saving = false;
// The _catalog variable is a static list of available medications, each represented by a _MedicationCatalogItem that includes the generic name and associated brand names. This catalog is used to populate the medication picker when adding new plans, allowing users to search for medications by either their generic or brand names. The catalog is currently hardcoded but could be extended in the future to load from an external source or API.
  final List<_MedicationCatalogItem> _catalog = const [
    _MedicationCatalogItem(generic: 'Acetazolamide', brands: 'Diamox'),
    _MedicationCatalogItem(generic: 'Brivaracetam', brands: 'Briviact'),
    _MedicationCatalogItem(generic: 'Cannabidiol', brands: 'Epidyolex'),
    _MedicationCatalogItem(generic: 'Carbamazepine', brands: 'Curatil, Tegretol, Tegretol Prolonged Release'),
    _MedicationCatalogItem(generic: 'Cenobamate', brands: 'Ontozry'),
    _MedicationCatalogItem(generic: 'Clobazam', brands: 'Frisium, Perizam, Tapclob, Zacco'),
    _MedicationCatalogItem(generic: 'Clonazepam', brands: ''),
    _MedicationCatalogItem(generic: 'Eslicarbazepine', brands: 'Zebinix'),
    _MedicationCatalogItem(generic: 'Ethosuximide', brands: 'Emeside, Epesri'),
    _MedicationCatalogItem(generic: 'Everolimus', brands: ''),
    _MedicationCatalogItem(generic: 'Fenfluramine', brands: 'Fintepla'),
    _MedicationCatalogItem(generic: 'Gabapentin', brands: 'Neurontin'),
    _MedicationCatalogItem(generic: 'Lacosamide', brands: 'Vimpat'),
    _MedicationCatalogItem(generic: 'Lamotrigine', brands: 'Lamictal'),
    _MedicationCatalogItem(generic: 'Levetiracetam', brands: 'Desitrend, Eltam, Keppra'),
    _MedicationCatalogItem(generic: 'Oxcarbazepine', brands: 'Trileptal'),
    _MedicationCatalogItem(generic: 'Perampanel', brands: ''),
    _MedicationCatalogItem(generic: 'Phenobarbital', brands: ''),
    _MedicationCatalogItem(generic: 'Phenytoin', brands: 'Epanutin, Phenytoin Sodium Flynn'),
    _MedicationCatalogItem(generic: 'Piracetam', brands: 'Nootropil'),
    _MedicationCatalogItem(generic: 'Pregabalin', brands: 'Alzain, Lyrica'),
    _MedicationCatalogItem(generic: 'Primidone', brands: 'Enodama'),
    _MedicationCatalogItem(generic: 'Rufinamide', brands: ''),
    _MedicationCatalogItem(generic: 'Sodium valproate', brands: 'Dyzantil, Epilim, Epilim Chrono, Epilim Chronosphere, Episenta, Epival'),
    _MedicationCatalogItem(generic: 'Stiripentol', brands: 'Diacomit'),
    _MedicationCatalogItem(generic: 'Tiagabine', brands: 'Gabitril'),
    _MedicationCatalogItem(generic: 'Topiramate', brands: 'Topamax'),
    _MedicationCatalogItem(generic: 'Valproic acid', brands: 'Convulex, Dyzantil, Epilim Chrono, Epilim Chronosphere'),
    _MedicationCatalogItem(generic: 'Vigabatrin', brands: 'Kigabeq, Sabril'),
    _MedicationCatalogItem(generic: 'Zonisamide', brands: 'Desizon, Zonegran'),
  ];
// The initState method initializes the state of the MedicationScreen by setting the default start date to the current date and loading the user's favorite medications and existing medication plans from the local database. This ensures that when the screen is first displayed, it is populated with relevant data for the user to interact with.
  @override
  void initState() {
    super.initState();
    _startDateController.text = _formatDate(DateTime.now());
    _getFavorites();
    _getPlans();
  }
// The dispose method is overridden to clean up the TextEditingController instances when the widget is removed from the widget tree. This is important to prevent memory leaks and ensure that resources are properly released when the screen is no longer in use.
  @override
  void dispose() {
    _dosageController.dispose();
    _timeController.dispose();
    _startDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }
// The _formatDate method takes a DateTime object and formats it as a string in the 'YYYY-MM-DD' format. This is used to display the selected start date in the form and to ensure that the date is stored in a consistent format in the database.
  String _formatDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
// The _pickStartDate method displays a date picker dialog to the user, allowing them to select a start date for their medication plan. The initial date shown in the picker is either the currently selected start date or the current date if no date is selected. The user can choose a date within a range of two years in the past to five years in the future. Once a date is picked, it is formatted and displayed in the start date field of the form.
  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_startDateController.text) ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      _startDateController.text = _formatDate(picked);
    });
  }
// The _getFavorites method retrieves the list of favorite medications for the current user from the FrontendAccountStore and updates the local _favorites set. This allows the UI to display which medications are marked as favorites and to provide quick access to them when creating new medication plans.
  Future<void> _getFavorites() async {
    final list = await FrontendAccountStore.instance.getFavoriteMedications();
    if (!mounted) return;
    setState(() {
      _favorites = list.toSet();
    });
  }
// The _toggleFavorite method toggles the favorite status of a medication by its generic name. It updates the backend through the FrontendAccountStore and then updates the local _favorites set accordingly. This allows users to mark or unmark medications as favorites, which can be reflected in the UI for quick selection when adding new medication plans.
  Future<void> _toggleFavorite(String genericName) async {
    await FrontendAccountStore.instance.toggleFavoriteMedication(genericName);
    if (!mounted) return;
    setState(() {
      if (_favorites.contains(genericName)) {
        _favorites.remove(genericName);
      } else {
        _favorites.add(genericName);
      }
    });
  }
// The _getPlans method retrieves all medication plans for the current user from the local database using the DatabaseHelper. It updates the local _plans list with the retrieved data, allowing the UI to display the existing medication plans. If there is an error during retrieval, it logs the error and sets the _plans list to empty to ensure that the UI does not attempt to display invalid data.
  Future<void> _getPlans() async {
    try {
      final plans = await DatabaseHelper.instance.getAllMedications();
      if (!mounted) return;
      setState(() {
        _plans = plans;
      });
    } catch (e, st) {
      debugPrint('Failed to load medication plans: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() {
        _plans = [];
      });
    }
  }
// The _addPlan method is responsible for adding a new medication plan based on the user's input in the form. It first checks if all required fields are filled out, and if not, it shows a SnackBar prompting the user to complete the form. If the form is valid, it creates a Medication object with the input data and saves it to the local database using the DatabaseHelper. After saving, it synchronizes medication reminders through the MedicationNotificationService and reloads the list of plans to reflect the new addition. Finally, it clears the form fields and shows a confirmation SnackBar to the user.
  Future<void> _addPlan() async {
    if (_selectedMed == null ||
        _dosageController.text.trim().isEmpty ||
        _timeController.text.trim().isEmpty ||
        _startDateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select medication, dosage, time, and start date first.')),
      );
      return;
    }

    setState(() => _saving = true);

    final username = await FrontendAccountStore.instance.getCurrentUsername() ?? 'unknown';
    final plan = Medication(
      username: username,
      name: _selectedMed!,
      dosage: _dosageController.text.trim(),
      frequencyCount: _freqCount,
      frequencyUnit: _freqUnit,
      timesList: _timeController.text.trim(),
      startDate: _startDateController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseHelper.instance.insertMedication(plan);
    await MedicationNotificationService.instance.syncMedicationReminders();
    await _getPlans();

    if (!mounted) return;

    setState(() {
      _dosageController.clear();
      _notesController.clear();
      _selectedMed = null;
      _saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medication saved to backend.')),
    );
  }
// The _openMedicationPicker method displays a modal bottom sheet that allows the user to search for and select a medication from the catalog. It includes a search field that filters the list of medications based on the generic and brand names. The medications are displayed in a list, with favorites shown at the top. Tapping on a medication selects it for the form, while tapping the favorite icon toggles its favorite status. This provides an intuitive interface for users to find and select their medications when creating new plans.
  void _openMedicationPicker() {
    final searchController = TextEditingController();
    String query = '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = <_MedicationCatalogItem>[];
            final q = query.toLowerCase();
            for (final item in _catalog) {
              if (item.searchableLabel.contains(q)) {
                filtered.add(item);
              }
            }
            filtered.sort((a, b) {
              final aFav = _favorites.contains(a.generic);
              final bFav = _favorites.contains(b.generic);
              if (aFav != bFav) {
                return aFav ? -1 : 1;
              }
              return a.generic.compareTo(b.generic);
            });

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: 480,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Medication', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search generic or brand name',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          query = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No medications found.'))
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final med = filtered[index];
                                final isFavorite = _favorites.contains(med.generic);
                                return ListTile(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  tileColor: const Color(0xFFFFFBFF),
                                  title: Text(med.generic),
                                  subtitle: med.brands.isNotEmpty
                                      ? Text('Also: ${med.brands}')
                                      : const Text('No listed brand aliases'),
                                  onTap: () {
                                    setState(() => _selectedMed = med.generic);
                                    Navigator.pop(context);
                                  },
                                  trailing: IconButton(
                                    tooltip: isFavorite ? 'Unfavorite' : 'Favorite',
                                    onPressed: () async {
                                      await _toggleFavorite(med.generic);
                                      setModalState(() {});
                                    },
                                    icon: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorite ? Colors.pinkAccent : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
// The build method constructs the UI for the MedicationScreen, including the form for adding new medication plans and the list of existing plans. It uses various Flutter widgets such as Scaffold, AppBar, ListView, Card, TextField, DropdownButtonFormField, and ElevatedButton to create an intuitive and user-friendly interface. The form includes fields for selecting a medication, entering dosage and frequency information, picking a start date, and adding optional notes. Below the form, it displays a list of existing medication plans with options to delete them.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medication')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEDAF5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.medication_outlined, color: Color(0xFF660066)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Build a reliable medication plan with reminders and notes.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/medication-safety'),
                icon: const Icon(Icons.info_outline),
                label: const Text('Medication safety info'),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _openMedicationPicker,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  suffixIcon: Icon(Icons.arrow_drop_down_circle_outlined),
                ),
                child: Text(
                  _selectedMed ?? 'Choose from medication list',
                  style: TextStyle(
                    color: _selectedMed == null
                        ? Theme.of(context).hintColor
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
            if (_favorites.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _favorites
                      .map(
                        (med) => ActionChip(
                          avatar: const Icon(Icons.favorite, color: Colors.pinkAccent, size: 16),
                          label: Text(med),
                          onPressed: () => setState(() => _selectedMed = med),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(labelText: 'Dosage (e.g. 500 mg)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _freqCount,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: const [1, 2, 3, 4]
                        .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                        .toList(),
                    onChanged: (value) => setState(() => _freqCount = value ?? 1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _freqUnit,
                    decoration: const InputDecoration(labelText: 'Per'),
                    items: const [
                      DropdownMenuItem(value: 'day', child: Text('Day')),
                      DropdownMenuItem(value: 'week', child: Text('Week')),
                    ],
                    onChanged: (value) => setState(() => _freqUnit = value ?? 'day'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _startDateController,
              readOnly: true,
              onTap: _pickStartDate,
              decoration: const InputDecoration(
                labelText: 'Start Date',
                suffixIcon: Icon(Icons.calendar_month_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(labelText: 'Primary Reminder Time (HH:MM)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _addPlan,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Add Medication'),
              ),
            ),
            const SizedBox(height: 16),
            if (_plans.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No medications added yet. Start by selecting one above.')),
              )
            else
              ListView.builder(
                itemCount: _plans.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final plan = _plans[index];
                  return Card(
                    child: ListTile(
                      title: Text('${plan.name} - ${plan.dosage}'),
                      subtitle: Text(
                        '${plan.frequencyCount} per ${plan.frequencyUnit} • ${plan.timesList} • starts ${plan.startDate}'
                        '${(plan.notes ?? '').isEmpty ? '' : '\n${plan.notes}'}',
                      ),
                      isThreeLine: (plan.notes ?? '').isNotEmpty,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          if (plan.id == null) return;
                          await DatabaseHelper.instance.deleteMedication(plan.id!);
                          await MedicationNotificationService.instance.syncMedicationReminders();
                          await _getPlans();
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
// The _MedicationCatalogItem class represents an item in the medication catalog, containing the generic name and associated brand names. It also provides a searchableLabel getter that combines the generic and brand names into a single lowercase string for easy searching and filtering in the medication picker.
class _MedicationCatalogItem {
  final String generic;
  final String brands;

  const _MedicationCatalogItem({required this.generic, required this.brands});

  String get searchableLabel => '$generic $brands'.toLowerCase();
}
