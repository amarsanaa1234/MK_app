import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';

/// "Save as draft" дарахад хадгалагдах локал төлөв (backend рүү явахгүй,
/// зөвхөн апп ажиллаж байх хугацаанд, дараагийн удаа "New job" нээхэд сэргээгдэнэ).
class _JobDraft {
  DateTime? date;
  FTime? startTime;
  String? address;
  String? jobType;
  String? truck;
  String? notes;
  String? leaderId;
  List<String> crewIds = [];
}

final _draft = _JobDraft();

/// Доороос гарч ирэх "шинэ ажлын зар нэмэх" sheet-ийг нээнэ.
void openNewPostSheet(BuildContext context, AuthResult session) {
  showFSheet(
    context: context,
    side: .btt,
    // Дэлгэцийн 90%-ийг эзэлнэ.
    mainAxisMaxRatio: 0.9,
    builder: (context) => NewPostSheet(session: session),
  );
}

class NewPostSheet extends StatefulWidget {
  final AuthResult session;
  const NewPostSheet({required this.session, super.key});

  @override
  State<NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<NewPostSheet> {
  late final _addressController = TextEditingController(
    text: _draft.address ?? '21 Crown St, Wollongong NSW',
  );
  late final _truckController = TextEditingController(
    text: _draft.truck ?? 'Truck 04 · 4T Pantech',
  );
  late final _notesController = TextEditingController(text: _draft.notes ?? '');

  late DateTime _date = _draft.date ?? DateTime.now();
  late FTime _startTime = _draft.startTime ?? const FTime(9, 0);
  late String _jobType = _draft.jobType ?? 'Office';
  Employee? _leader;
  Set<Employee> _crew = {};
  bool _submitting = false;

  static const _jobTypes = ['Residential', 'Office', 'Piano & specialty', 'Interstate'];

  late final Future<List<Employee>> _employeesFuture;

  @override
  void initState() {
    super.initState();
    _employeesFuture = ApiClient.getEmployeeList(widget.session.token);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _truckController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// "Save as draft" backend рүү огт хадгалахгүй — одоогийн бөглөсөн бүх
  /// талбарыг (сонгосон lead/crew-ийн хамт) локал `_draft`-д хадгалаад
  /// sheet-ийг хаана. Дараагийн удаа "New job" нээхэд эргээд сэргээгдэнэ.
  void _saveDraftLocally() {
    _draft
      ..date = _date
      ..startTime = _startTime
      ..address = _addressController.text
      ..jobType = _jobType
      ..truck = _truckController.text
      ..notes = _notesController.text
      ..leaderId = _leader?.id
      ..crewIds = _crew.map((e) => e.id).toList();

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Saved as draft')));
  }

  Future<void> _publish() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Site address is required')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiClient.createJobAd(
        token: widget.session.token,
        workDate: _date,
        startHour: _startTime.hour,
        startMinute: _startTime.minute,
        addressLine: _addressController.text.trim(),
        jobType: _jobType,
        leaderId: _leader?.id,
        truck: _truckController.text.trim(),
        crewIds: _crew.map((e) => e.id).toList(),
        notes: _notesController.text.trim(),
      );
      // Амжилттай publish хийгдсэн тул хадгалагдсан drafts-ыг цэвэрлэнэ.
      _draft
        ..date = null
        ..startTime = null
        ..address = null
        ..jobType = null
        ..truck = null
        ..notes = null
        ..leaderId = null
        ..crewIds = [];
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Published to crew')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'M',
                      style: typography.body.sm.copyWith(
                        color: colors.primaryForeground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'MK Removals',
                    style: typography.body.md.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text('New job', style: typography.body.sm.copyWith(color: colors.mutedForeground)),
                ],
              ),
            ),
            FDivider(style: .delta(color: colors.border)),
            // ─── Маягт ───
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New job',
                      style: typography.display.xl2.copyWith(
                        color: colors.foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Publishing notifies every crew member added below',
                      style: typography.body.sm.copyWith(color: colors.mutedForeground),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: FDateField(
                            label: const Text('Date'),
                            selectionControl: FDateSelectionControl.managedSingle(
                              initial: _date,
                              toggleable: false,
                              onChange: (date) => setState(() => _date = date ?? _date),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FTimeField(
                            label: const Text('Start time'),
                            control: FTimeFieldControl.managed(
                              initial: _startTime,
                              onChange: (time) => setState(() => _startTime = time ?? _startTime),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    FTextField(
                      control: FTextFieldControl.managed(controller: _addressController),
                      label: const Text('Site address'),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Job type',
                      style: typography.body.sm.copyWith(
                        color: colors.mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _JobTypeSelector(
                      options: _jobTypes,
                      selected: _jobType,
                      onSelect: (type) => setState(() => _jobType = type),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _FieldLabel(
                            label: 'Lead',
                            child: FutureBuilder<List<Employee>>(
                              future: _employeesFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState != ConnectionState.done) {
                                  return const SizedBox(height: 44);
                                }
                                // Эхний удаад л draft-аас сэргээнэ (FSelect-ийн
                                // `initial` зөвхөн үүсэх мөчид л уншигддаг).
                                if (_leader == null && _draft.leaderId != null) {
                                  for (final e in snapshot.data ?? const []) {
                                    if (e.id == _draft.leaderId) {
                                      _leader = e;
                                      break;
                                    }
                                  }
                                }
                                return FSelect<Employee>.searchBuilder(
                                  hint: 'Select lead',
                                  format: (e) => e.fullName,
                                  control: FSelectControl<Employee>.managed(
                                    initial: _leader,
                                    onChange: (e) => setState(() => _leader = e),
                                  ),
                                  filter: (query) async {
                                    final employees = await _employeesFuture;
                                    return query.isEmpty
                                        ? employees
                                        : employees.where(
                                            (e) => e.fullName.toLowerCase().contains(
                                              query.toLowerCase(),
                                            ),
                                          );
                                  },
                                  contentBuilder: (context, _, employees) => [
                                    for (final e in employees) .item(title: Text(e.fullName), value: e),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FieldLabel(
                            label: 'Truck',
                            child: FTextField(
                              control: FTextFieldControl.managed(controller: _truckController),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Crew',
                      style: typography.body.sm.copyWith(
                        color: colors.mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: colors.muted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FutureBuilder<List<Employee>>(
                            future: _employeesFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState != ConnectionState.done) {
                                return const SizedBox(height: 24, width: 120);
                              }
                              // Эхний удаад л draft-аас сэргээнэ (FMultiSelect-ийн
                              // `initial` зөвхөн үүсэх мөчид л уншигддаг).
                              if (_crew.isEmpty && _draft.crewIds.isNotEmpty) {
                                _crew = (snapshot.data ?? const [])
                                    .where((e) => _draft.crewIds.contains(e.id))
                                    .toSet();
                              }
                              return FMultiSelect<Employee>.searchBuilder(
                                hint: const Text('Select crew'),
                                format: (e) => Text(e.fullName),
                                control: FMultiValueControl<Employee>.managed(
                                  initial: _crew,
                                  onChange: (selected) => setState(() => _crew = selected),
                                ),
                                filter: (query) async {
                                  final employees = await _employeesFuture;
                                  return query.isEmpty
                                      ? employees
                                      : employees.where(
                                          (e) => e.fullName.toLowerCase().contains(
                                            query.toLowerCase(),
                                          ),
                                        );
                                },
                                contentBuilder: (context, _, employees) => [
                                  for (final e in employees) .item(title: Text(e.fullName), value: e),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    FTextField.multiline(
                      control: FTextFieldControl.managed(controller: _notesController),
                      label: const Text('Notes'),
                      hint: 'Loading dock access after 8am, ask for building manager on arrival...',
                      minLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            FDivider(style: .delta(color: colors.border)),
            // ─── Footer товчнууд ───
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton(
                    variant: .ghost,
                    onPress: _submitting ? null : _saveDraftLocally,
                    child: const Text('Save as draft'),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    onPress: _submitting ? null : _publish,
                    child: _submitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Publish to crew'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Lead"/"Truck" шиг талбарын дээр label тавьдаг жижиг helper.
class _FieldLabel extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldLabel({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.theme.typography.body.sm.copyWith(
          color: context.theme.colors.mutedForeground,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      child,
    ],
  );
}

/// "Job type" сегментчилсэн сонголт.
class _JobTypeSelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  const _JobTypeSelector({required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: option == selected ? colors.background : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    option,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.xs.copyWith(
                      color: option == selected ? colors.foreground : colors.mutedForeground,
                      fontWeight: option == selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
