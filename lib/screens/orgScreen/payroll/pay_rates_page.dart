import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mk_app/api/api_client.dart';
import 'package:mk_app/widgets/pay_rate_dialog.dart';
import 'package:mk_app/widgets/user_avatar.dart';

/// Admin-only: set each crew member's hourly pay rate. Feeds the Payroll
/// calculator, where the rate is applied automatically.
class PayRatesPage extends StatefulWidget {
  final AuthResult session;
  const PayRatesPage({required this.session, super.key});

  @override
  State<PayRatesPage> createState() => _PayRatesPageState();
}

class _PayRatesPageState extends State<PayRatesPage> {
  late Future<List<EmployeeDetail>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ApiClient.getEmployeesWithRates(token: widget.session.token, adminId: widget.session.userId);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  Future<void> _editRate(EmployeeDetail employee) async {
    final result = await showPayRateDialog(
      context: context,
      name: employee.fullName,
      currentRate: employee.payRate,
    );

    if (result == null || !mounted) return;

    try {
      await ApiClient.updatePayRate(
        token: widget.session.token,
        adminId: widget.session.userId,
        employeeId: employee.id,
        payRate: result,
      );
      if (!mounted) return;
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pay rates', style: typography.display.xl2.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Applied automatically in payroll calculations',
                style: typography.body.sm.copyWith(color: colors.mutedForeground),
              ),
              const SizedBox(height: 12),
              FTextField(
                control: FTextFieldControl.managed(
                  onChange: (v) => setState(() => _query = v.text),
                ),
                hint: 'Search crew',
                prefixBuilder: (context, style, variants) => FTextField.prefixIconBuilder(
                  context,
                  style,
                  variants,
                  Icon(FLucideIcons.search, size: 16, color: colors.mutedForeground),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<EmployeeDetail>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: FCircularProgress());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(snapshot.error.toString(), style: TextStyle(color: colors.error)),
                  ),
                );
              }

              final employees = (snapshot.data ?? const <EmployeeDetail>[])
                  .where((e) => e.fullName.toLowerCase().contains(_query.toLowerCase()))
                  .toList();

              if (employees.isEmpty) {
                return Center(
                  child: Text(
                    'No crew found.',
                    style: typography.body.sm.copyWith(color: colors.mutedForeground),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: employees.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final employee = employees[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _editRate(employee),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              UserAvatar(fullName: employee.fullName, photoUrl: employee.photoUrl),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(employee.fullName, style: typography.body.sm),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colors.secondary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      employee.payRate == null
                                          ? 'Set rate'
                                          : '\$${employee.payRate!.toStringAsFixed(2)}/h',
                                      style: typography.body.sm.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(Icons.edit, size: 14, color: colors.mutedForeground),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
