import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';

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
  final _addressController = TextEditingController(text: '21 Crown St, Wollongong NSW');
  final _truckController = TextEditingController(text: 'Truck 04 · 4T Pantech');
  final _notesController = TextEditingController();

  DateTime _date = DateTime.now();
  FTime _startTime = const FTime(9, 0);
  String _jobType = 'Office';
  final List<String> _crew = [];

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

  String _initialsOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Future<void> _addCrew() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add crew member'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<Employee>>(
            future: _employeesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              final available = (snapshot.data ?? [])
                  .where((e) => !_crew.contains(e.fullName))
                  .toList();
              if (available.isEmpty) {
                return const Text('no employees available');
              }
              return SizedBox(
                height: 320,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: available.length,
                  itemBuilder: (context, index) {
                    final employee = available[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(_initialsOf(employee.fullName))),
                      title: Text(employee.fullName),
                      onTap: () => Navigator.of(context).pop(employee.fullName),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() => _crew.add(name));
    }
  }

  void _publish({required bool draft}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(draft ? 'Saved as draft' : 'Published to crew')),
    );
    Navigator.of(context).pop();
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
            // ─── Header: байгууллагын лого/нэр + дэлгэцийн гарчиг ───
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
                            child: _PickerRow(
                              leading: FAvatar.raw(
                                size: 28,
                                style: const .delta(backgroundColor: Color(0xFF2E609A)),
                                child: Text(_initialsOf(widget.session.fullName)),
                              ),
                              text: widget.session.fullName,
                              onTap: () {},
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
                          for (final name in _crew)
                            _CrewChip(
                              name: name,
                              initials: _initialsOf(name),
                              onRemove: () => setState(() => _crew.remove(name)),
                            ),
                          FButton(
                            variant: .ghost,
                            size: .sm,
                            mainAxisSize: .min,
                            onPress: _addCrew,
                            child: const Text('+ Add crew'),
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
                    onPress: () => _publish(draft: true),
                    child: const Text('Save as draft'),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    onPress: () => _publish(draft: false),
                    child: const Text('Publish to crew'),
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

/// "Lead" мэт avatar + текст-тэй, дарж болдог мөр (одоогоор зөвхөн харагдацын түвшинд).
class _PickerRow extends StatelessWidget {
  final Widget leading;
  final String text;
  final VoidCallback onTap;
  const _PickerRow({required this.leading, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: context.theme.typography.body.sm.copyWith(color: colors.foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

/// "Crew" жагсаалт дахь нэг гишүүний chip (устгах 'x'-тэй).
class _CrewChip extends StatelessWidget {
  final String name;
  final String initials;
  final VoidCallback onRemove;
  const _CrewChip({required this.name, required this.initials, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 6, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FAvatar.raw(
            size: 22,
            style: const .delta(backgroundColor: Color(0xFF2E609A)),
            child: Text(initials, style: const TextStyle(fontSize: 10)),
          ),
          const SizedBox(width: 6),
          Text(name, style: context.theme.typography.body.xs.copyWith(color: colors.foreground)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}
