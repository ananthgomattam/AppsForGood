import 'package:flutter/material.dart';

import '../data/medication.dart';
import '../database/database_helper.dart';
import '../frontend/account_store.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final _dosageController = TextEditingController();
  final _timeController = TextEditingController(text: '20:00');
  final _startDateController = TextEditingController();
  final _notesController = TextEditingController();

  List<Medication> _savedPlans = const [];
  Set<String> _favoriteMeds = <String>{};
  String? _selectedMedication;
  int _frequencyCount = 1;
  String _frequencyUnit = 'day';
  bool _saving = false;

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

  @override
  void initState() {
    super.initState();
    _startDateController.text = _formatDate(DateTime.now());
    _loadFavorites();
    _loadSavedPlans();
  }

  @override
  void dispose() {
    _dosageController.dispose();
    _timeController.dispose();
    _startDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

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

  Future<void> _loadFavorites() async {
    final favorites = await FrontendAccountStore.instance.getFavoriteMedications();
    if (!mounted) return;
    setState(() {
      _favoriteMeds = favorites.toSet();
    });
  }

  Future<void> _toggleFavorite(String genericName) async {
    await FrontendAccountStore.instance.toggleFavoriteMedication(genericName);
    if (!mounted) return;
    setState(() {
      if (_favoriteMeds.contains(genericName)) {
        _favoriteMeds.remove(genericName);
      } else {
        _favoriteMeds.add(genericName);
      }
    });
  }

  Future<void> _loadSavedPlans() async {
    final plans = await DatabaseHelper.instance.getAllMedications();
    if (!mounted) return;
    setState(() {
      _savedPlans = plans;
    });
  }

  Future<void> _addMedicationPlan() async {
    if (_selectedMedication == null ||
        _dosageController.text.trim().isEmpty ||
        _timeController.text.trim().isEmpty ||
        _startDateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select medication, dosage, time, and start date first.')),
      );
      return;
    }

    setState(() => _saving = true);

    final plan = Medication(
      name: _selectedMedication!,
      dosage: _dosageController.text.trim(),
      frequencyCount: _frequencyCount,
      frequencyUnit: _frequencyUnit,
      timesList: _timeController.text.trim(),
      startDate: _startDateController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseHelper.instance.insertMedication(plan);
    await _loadSavedPlans();

    if (!mounted) return;

    setState(() {
      _dosageController.clear();
      _notesController.clear();
      _selectedMedication = null;
      _saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medication saved to backend.')),
    );
  }

  void _openMedicationPicker() {
    final searchController = TextEditingController();
    String query = '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _catalog
                .where((item) => item.searchableLabel.contains(query.toLowerCase()))
                .toList()
              ..sort((a, b) {
                final aFav = _favoriteMeds.contains(a.generic);
                final bFav = _favoriteMeds.contains(b.generic);
                if (aFav != bFav) return aFav ? -1 : 1;
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
                                final isFavorite = _favoriteMeds.contains(med.generic);
                                return ListTile(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  tileColor: const Color(0xFFFFFBFF),
                                  title: Text(med.generic),
                                  subtitle: med.brands.isNotEmpty
                                      ? Text('Also: ${med.brands}')
                                      : const Text('No listed brand aliases'),
                                  onTap: () {
                                    setState(() => _selectedMedication = med.generic);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medication')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
            InkWell(
              onTap: _openMedicationPicker,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  suffixIcon: Icon(Icons.arrow_drop_down_circle_outlined),
                ),
                child: Text(
                  _selectedMedication ?? 'Choose from medication list',
                  style: TextStyle(
                    color: _selectedMedication == null
                        ? Theme.of(context).hintColor
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
            if (_favoriteMeds.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _favoriteMeds
                      .map(
                        (med) => ActionChip(
                          avatar: const Icon(Icons.favorite, color: Colors.pinkAccent, size: 16),
                          label: Text(med),
                          onPressed: () => setState(() => _selectedMedication = med),
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
                    initialValue: _frequencyCount,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: const [1, 2, 3, 4]
                        .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                        .toList(),
                    onChanged: (value) => setState(() => _frequencyCount = value ?? 1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _frequencyUnit,
                    decoration: const InputDecoration(labelText: 'Per'),
                    items: const [
                      DropdownMenuItem(value: 'day', child: Text('Day')),
                      DropdownMenuItem(value: 'week', child: Text('Week')),
                    ],
                    onChanged: (value) => setState(() => _frequencyUnit = value ?? 'day'),
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
                onPressed: _saving ? null : _addMedicationPlan,
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
            Expanded(
              child: _savedPlans.isEmpty
                  ? const Center(child: Text('No medications added yet. Start by selecting one above.'))
                  : ListView.builder(
                      itemCount: _savedPlans.length,
                      itemBuilder: (context, index) {
                        final plan = _savedPlans[index];
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
                                await _loadSavedPlans();
                              },
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
  }
}

class _MedicationCatalogItem {
  final String generic;
  final String brands;

  const _MedicationCatalogItem({required this.generic, required this.brands});

  String get searchableLabel => '$generic $brands'.toLowerCase();
}
