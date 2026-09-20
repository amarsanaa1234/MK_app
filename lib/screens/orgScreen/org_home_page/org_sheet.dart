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

/// Доороос гарч ирэх "шинэ ажлын зар нэмэх" sheet-ийг нээнэ. [existingJob]
/// өгвөл шинэ зар үүсгэхийн оронд тухайн зарыг засварлана. Sheet хаагдахад
/// (draft хадгалсан ч, publish/save хийсэн ч) дуусах Future-ийг буцаана,
/// ингэснээр дуудагч тал (жишээ нь dashboard) жагсаалтаа шинэчилж болно.
Future<void> openNewPostSheet(BuildContext context, AuthResult session, {JobAdSummary? existingJob}) {
  return showFSheet(
    context: context,
    side: .btt,
    // Дэлгэцийн 90%-ийг эзэлнэ.
    mainAxisMaxRatio: 0.9,
    builder: (context) => NewPostSheet(session: session, existingJob: existingJob),
  );
}

class NewPostSheet extends StatefulWidget {
  final AuthResult session;
  final JobAdSummary? existingJob;
  const NewPostSheet({required this.session, this.existingJob, super.key});

  @override
  State<NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<NewPostSheet> {
  bool get _editing => widget.existingJob != null;

  late final _addressController = TextEditingController(
    text: widget.existingJob?.addressLine ?? _draft.address ?? '',
  );
  late final _truckController = TextEditingController(
    text: widget.existingJob?.truck ?? _draft.truck ?? 'Truck 04 · 4T Pantech',
  );
  late final _notesController = TextEditingController(
    text: widget.existingJob?.notes ?? _draft.notes ?? '',
  );

  late DateTime _date = widget.existingJob?.workDate ?? _draft.date ?? DateTime.now();
  late FTime _startTime = _parseStartTime(widget.existingJob?.startTime) ?? _draft.startTime ?? const FTime(9, 0);
  late String _jobType = (widget.existingJob?.jobType != null && _jobTypes.contains(widget.existingJob!.jobType))
      ? widget.existingJob!.jobType!
      : (_draft.jobType ?? 'Office');
  Employee? _leader;
  Set<Employee> _crew = {};
  bool _submitting = false;

  // Edit mode-д зориулсан анхны сонголтууд — шинэ зар үүсгэх үеийн `_draft`
  // singleton-той холилдохгүй байхын тулд тусад нь хадгална.
  late final String? _initialLeaderId = widget.existingJob?.leader?.id;
  late final List<String> _initialCrewIds =
      widget.existingJob?.crew.map((e) => e.id).toList() ?? const [];

  static const _jobTypes = ['Residential', 'Office', 'Piano & specialty', 'Interstate'];

  late final Future<List<Employee>> _employeesFuture;
  late Future<Set<String>> _busyEmployeeIdsFuture;

  static FTime? _parseStartTime(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return FTime(hour, minute);
  }

  @override
  void initState() {
    super.initState();
    _employeesFuture = ApiClient.getEmployeeList(widget.session.token);
    _busyEmployeeIdsFuture = _loadBusyEmployeeIds(_date);
  }

  /// Everyone already leading or crewing another job on [date] — so the same
  /// person can't accidentally be double-booked across two posts for one day.
  /// Excludes this job's own assignments when editing, since those aren't a
  /// conflict with themselves.
  Future<Set<String>> _loadBusyEmployeeIds(DateTime date) async {
    final jobs = await ApiClient.getJobAds(
      token: widget.session.token,
      adminId: widget.session.userId,
      from: date,
      to: date,
    );
    final busy = <String>{};
    for (final job in jobs) {
      if (_editing && job.id == widget.existingJob!.id) continue;
      if (job.leader != null) busy.add(job.leader!.id);
      for (final crewMember in job.crew) {
        busy.add(crewMember.id);
      }
    }
    return busy;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _truckController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// New-job flow-д зориулсан "Save as draft": backend рүү огт хадгалахгүй —
  /// одоогийн бөглөсөн бүх талбарыг (сонгосон lead/crew-ийн хамт) локал
  /// `_draft`-д хадгалаад sheet-ийг хаана. Дараагийн удаа "New job" нээхэд
  /// эргээд сэргээгдэнэ.
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

  /// Edit-job flow-д зориулсан "Save as draft": байгаа ажлын зарыг DRAFT
  /// төлөвтэйгээр шууд backend рүү хадгална (local stash биш, учир нь энд
  /// засварлаж буй зар аль хэдийн үнэхээр оршдог).
  Future<void> _submit({required bool draft}) async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Site address is required')));
      return;
    }
    if (_leader == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('A lead is required')));
      return;
    }

    setState(() => _submitting = true);
    try {
      if (_editing) {
        await ApiClient.updateJobAd(
          token: widget.session.token,
          adminId: widget.session.userId,
          jobAdId: widget.existingJob!.id,
          workDate: _date,
          startHour: _startTime.hour,
          startMinute: _startTime.minute,
          addressLine: _addressController.text.trim(),
          jobType: _jobType,
          leaderId: _leader?.id,
          truck: _truckController.text.trim(),
          crewIds: _crew.map((e) => e.id).toList(),
          notes: _notesController.text.trim(),
          draft: draft,
        );
      } else {
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
          draft: draft,
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
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(SnackBar(
        content: Text(_editing ? 'Job updated' : (draft ? 'Saved as draft' : 'Published to crew')),
      ));
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
                  Text(
                    _editing ? 'Edit job' : 'New job',
                    style: typography.body.sm.copyWith(color: colors.mutedForeground),
                  ),
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
                      _editing ? 'Edit job' : 'New job',
                      style: typography.display.xl2.copyWith(
                        color: colors.foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _editing
                          ? 'Changes are visible to every crew member on this job'
                          : 'Publishing notifies every crew member added below',
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
                              onChange: (date) => setState(() {
                                _date = date ?? _date;
                                _busyEmployeeIdsFuture = _loadBusyEmployeeIds(_date);
                              }),
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
                                // Эхний удаад л сэргээнэ (FSelect-ийн `initial`
                                // зөвхөн үүсэх мөчид л уншигддаг) — edit mode
                                // дээр байгаа ажлын ахлагчаас, эсвэл шинэ зар
                                // дээр хадгалагдсан draft-аас.
                                final leaderId = _editing ? _initialLeaderId : _draft.leaderId;
                                if (_leader == null && leaderId != null) {
                                  for (final e in snapshot.data ?? const []) {
                                    if (e.id == leaderId) {
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
                                    onChange: (e) => setState(() {
                                      _leader = e;
                                      // Lead-ээр сонгосон хүнийг crew-с автоматаар хасна —
                                      // нэг хүн хоёр дүрд зэрэг байж болохгүй.
                                      if (e != null) {
                                        _crew = _crew.where((c) => c.id != e.id).toSet();
                                      }
                                    }),
                                  ),
                                  filter: (query) async {
                                    final employees = await _employeesFuture;
                                    final busy = await _busyEmployeeIdsFuture;
                                    // Hide anyone already leading/crewing another job the same
                                    // day — but never hide whoever is currently picked here.
                                    final available = employees.where(
                                      (e) => !busy.contains(e.id) || e.id == _leader?.id,
                                    );
                                    return query.isEmpty
                                        ? available
                                        : available.where(
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
                              // Эхний удаад л сэргээнэ (FMultiSelect-ийн `initial`
                              // зөвхөн үүсэх мөчид л уншигддаг) — edit mode дээр
                              // байгаа багаас, эсвэл шинэ зар дээр хадгалагдсан
                              // draft-аас.
                              final crewIds = _editing ? _initialCrewIds : _draft.crewIds;
                              if (_crew.isEmpty && crewIds.isNotEmpty) {
                                _crew = (snapshot.data ?? const [])
                                    .where((e) => crewIds.contains(e.id))
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
                                  final busy = await _busyEmployeeIdsFuture;
                                  // Lead-ээр сонгогдсон хүн, мөн тухайн өдөр өөр ажлын зард
                                  // аль хэдийн орсон хүмүүсийг сонголтоос хасна (өөрөө сонгосон
                                  // crew гишүүдийг үл хамаарна).
                                  final selectable = employees.where(
                                    (e) =>
                                        e.id != _leader?.id &&
                                        (!busy.contains(e.id) || _crew.any((c) => c.id == e.id)),
                                  );
                                  return query.isEmpty
                                      ? selectable
                                      : selectable.where(
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
                    onPress: _submitting
                        ? null
                        : (_editing ? () => _submit(draft: true) : _saveDraftLocally),
                    child: const Text('Save as draft'),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    onPress: _submitting ? null : () => _submit(draft: false),
                    child: _submitting
                        ? const FCircularProgress(size: .xs)
                        : Text(_editing ? 'Save changes' : 'Publish to crew'),
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

/// Compact labels for the segmented control — the full descriptive string
/// (e.g. "Piano & specialty") is still what gets stored as the job type.
const _jobTypeShortLabels = {
  'Residential': 'Res.',
  'Office': 'Office',
  'Piano & specialty': 'Piano',
  'Interstate': 'Inter.',
};

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
                    _jobTypeShortLabels[option] ?? option,
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
