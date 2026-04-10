import pathlib
import openpyxl

project = pathlib.Path(__file__).resolve().parents[1]
wb = openpyxl.load_workbook(project / 'seizure_patient_data.xlsx', data_only=True)
ws = wb['Typical']
out = project / 'lib/data/test_dataset.dart'

lines = []
lines.append('class TestDailyEntry {')
lines.append('  final String date;')
lines.append('  final double sleepHours;')
lines.append('  final int sleepQuality;')
lines.append('  final int sleepInterruptions;')
lines.append('  final int stressLevel;')
lines.append('  final int dietQuality;')
lines.append('  final bool medicationAdherence;')
lines.append('  final bool drugUse;')
lines.append('  final bool hormonalChanges;')
lines.append('  final int seizureCount;')
lines.append('')
lines.append('  const TestDailyEntry({')
lines.append('    required this.date,')
lines.append('    required this.sleepHours,')
lines.append('    required this.sleepQuality,')
lines.append('    required this.sleepInterruptions,')
lines.append('    required this.stressLevel,')
lines.append('    required this.dietQuality,')
lines.append('    required this.medicationAdherence,')
lines.append('    required this.drugUse,')
lines.append('    required this.hormonalChanges,')
lines.append('    required this.seizureCount,')
lines.append('  });')
lines.append('}')
lines.append('')
lines.append("const String fixedDatasetProfileName = 'Typical';")
lines.append('')
lines.append('const List<TestDailyEntry> fixedTestDataset = [')

for row in ws.iter_rows(min_row=3, values_only=True):
    if row[0] is None:
        continue

    date = str(row[0])
    sleep_h = float(row[1] or 0.0)
    sleep_q = int(round(float(row[2] or 0.0)))
    sleep_i = int(round(float(row[3] or 0.0)))
    stress = int(round(float(row[4] or 0.0)))
    diet = int(round(float(row[5] or 0.0)))
    meds = str(row[6]).strip().lower() == 'true'
    drug = str(row[7]).strip().lower() == 'true'
    horm = str(row[8]).strip().lower() == 'true'
    seizure = 1 if str(row[9]).strip().lower() == 'true' else 0

    lines.append('  TestDailyEntry(')
    lines.append(f"    date: '{date}',")
    lines.append(f'    sleepHours: {sleep_h:.1f},')
    lines.append(f'    sleepQuality: {sleep_q},')
    lines.append(f'    sleepInterruptions: {sleep_i},')
    lines.append(f'    stressLevel: {stress},')
    lines.append(f'    dietQuality: {diet},')
    lines.append(f'    medicationAdherence: {str(meds).lower()},')
    lines.append(f'    drugUse: {str(drug).lower()},')
    lines.append(f'    hormonalChanges: {str(horm).lower()},')
    lines.append(f'    seizureCount: {seizure},')
    lines.append('  ),')

lines.append('];')
out.write_text('\n'.join(lines), encoding='utf-8')
print(f'Wrote {out}')
