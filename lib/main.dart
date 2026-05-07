import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:hamster_crm_app/core/database/app_database.dart';
import 'package:hamster_crm_app/core/theme/app_theme.dart';
import 'package:hamster_crm_app/data/models/customer.dart';
import 'package:hamster_crm_app/data/models/prospect.dart';
import 'package:hamster_crm_app/data/repositories/crm_repository.dart';

void main() {
  final CrmStore repository = kIsWeb
      ? InMemoryCrmRepository.seeded()
      : CrmRepository(AppDatabase());
  runApp(HamsterCrmApp(repository: repository));
}

class HamsterCrmApp extends StatelessWidget {
  const HamsterCrmApp({super.key, required this.repository});

  final CrmStore repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '뵤펫 CRM',
      debugShowCheckedModeBanner: false,
      theme: buildHamsterTheme(),
      home: HamsterHomePage(repository: repository),
    );
  }
}

class HamsterHomePage extends StatefulWidget {
  const HamsterHomePage({super.key, required this.repository});

  final CrmStore repository;

  @override
  State<HamsterHomePage> createState() => _HamsterHomePageState();
}

class _HamsterHomePageState extends State<HamsterHomePage> {
  late String selectedPage = _initialPage();
  late Future<_HomeData> _dataFuture = _load();
  final searchController = TextEditingController();

  Future<_HomeData> _load() async {
    return _HomeData(
      summary: await widget.repository.dashboardSummary(),
      customers: await widget.repository.customers(
        query: searchController.text,
      ),
      prospects: await widget.repository.prospects(
        query: searchController.text,
      ),
    );
  }

  String _initialPage() {
    if (!kIsWeb) return '대시보드';
    return switch (Uri.base.queryParameters['page']) {
      'customer-registration' => '고객등록',
      'customers' => '고객DB',
      'prospects' => '가망고객',
      _ => '대시보드',
    };
  }

  void _refresh() {
    setState(() {
      _dataFuture = _load();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            selected: selectedPage,
            onSelected: (page) => setState(() => selectedPage = page),
          ),
          Expanded(
            child: FutureBuilder<_HomeData>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data;
                if (data == null) {
                  return const Center(child: Text('데이터를 불러오지 못했습니다.'));
                }
                return Padding(
                  padding: const EdgeInsets.all(28),
                  child: _content(data),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(_HomeData data) {
    return switch (selectedPage) {
      '고객등록' => CustomerFormPage(
        repository: widget.repository,
        onSaved: _refresh,
      ),
      '고객DB' => CustomerDbPage(
        repository: widget.repository,
        customers: data.customers,
        searchController: searchController,
        onChanged: _refresh,
      ),
      '가망고객' => ProspectsPage(
        repository: widget.repository,
        prospects: data.prospects,
        searchController: searchController,
        onChanged: _refresh,
      ),
      _ => _DashboardPage(data: data),
    };
  }
}

class _HomeData {
  final DashboardSummary summary;
  final List<Customer> customers;
  final List<Prospect> prospects;

  const _HomeData({
    required this.summary,
    required this.customers,
    required this.prospects,
  });
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final pages = ['대시보드', '고객등록', '고객DB', '가망고객'];
    return Container(
      width: 250,
      color: HamsterColors.brown,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/golden_hamster_mascot.png',
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '뵤펫',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '로컬 오프라인 CRM',
            style: TextStyle(color: HamsterColors.cream),
          ),
          const SizedBox(height: 30),
          for (final page in pages)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FilledButton.tonal(
                onPressed: () => onSelected(page),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  alignment: Alignment.centerLeft,
                  backgroundColor: selected == page
                      ? HamsterColors.gold
                      : HamsterColors.cream.withValues(alpha: 0.14),
                  foregroundColor: selected == page
                      ? HamsterColors.brown
                      : Colors.white,
                ),
                child: Text(
                  page,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          const Spacer(),
          const Text(
            '혼자 쓰는 PC용\n로그인 없이 바로 시작',
            style: TextStyle(color: HamsterColors.cream, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({required this.data});

  final _HomeData data;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,###\uC6D0');
    return ListView(
      children: [
        Text(
          '\uB300\uC2DC\uBCF4\uB4DC',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              '\uACE0\uAC1DDB',
              '${data.summary.totalCustomers}\uBA85',
            ),
            _MetricCard(
              '\uAC00\uB9DD\uACE0\uAC1D',
              '${data.summary.totalProspects}\uBA85',
            ),
            _MetricCard(
              '\uC774\uBC88\uB2EC \uB9E4\uCD9C',
              money.format(data.summary.monthRevenue),
            ),
            _MetricCard(
              '\uC774\uBC88\uB2EC \uC21C\uC774\uC775',
              money.format(data.summary.monthProfit),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1060;
            final chart = _MonthlyTrendChart(monthly: data.summary.monthly);
            final settlement = _SettlementCard(monthly: data.summary.monthly);
            if (!wide) {
              return Column(
                children: [chart, const SizedBox(height: 14), settlement],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: chart),
                const SizedBox(width: 14),
                Expanded(flex: 5, child: settlement),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _RankingCard(
                title: '\uC774\uBC88\uB2EC \uBD84\uC591 \uC21C\uC704',
                items: data.summary.adoptionRanking,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _RankingCard(
                title: '\uC774\uBC88\uB2EC \uAD6C\uB9E4 \uC21C\uC704',
                items: data.summary.purchaseRanking,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MonthlyTrendChart extends StatelessWidget {
  const _MonthlyTrendChart({required this.monthly});

  final List<MonthlySettlement> monthly;

  @override
  Widget build(BuildContext context) {
    final maxValue = monthly.fold<double>(1, (max, item) {
      final value = item.adoptionCount > item.purchaseCount
          ? item.adoptionCount
          : item.purchaseCount;
      return value > max ? value.toDouble() : max;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\uC6D4\uBCC4 \uBD84\uC591 / \uAD6C\uB9E4 \uCD94\uC774',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              '\uACE8\uB4DC: \uBD84\uC591 \u00B7 \uBBFC\uD2B8: \uAD6C\uB9E4',
              style: TextStyle(fontSize: 12, color: HamsterColors.softBrown),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  maxY: maxValue + 1,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: HamsterColors.line,
                      strokeWidth: 0.6,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) {
                          final month = value.toInt() + 1;
                          if (month < 1 || month > 12) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '$month\uC6D4',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < monthly.length; i++)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 3,
                        barRods: [
                          BarChartRodData(
                            toY: monthly[i].adoptionCount.toDouble(),
                            width: 8,
                            borderRadius: BorderRadius.circular(4),
                            color: HamsterColors.gold,
                          ),
                          BarChartRodData(
                            toY: monthly[i].purchaseCount.toDouble(),
                            width: 8,
                            borderRadius: BorderRadius.circular(4),
                            color: HamsterColors.mint,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({required this.monthly});

  final List<MonthlySettlement> monthly;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.compactCurrency(
      locale: 'ko_KR',
      symbol: '\u20A9',
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\uC815\uC0B0\uD604\uD669',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 34,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 32,
                horizontalMargin: 8,
                columnSpacing: 14,
                headingTextStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: HamsterColors.brown,
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 12,
                  color: HamsterColors.brown,
                ),
                columns: const [
                  DataColumn(label: Text('\uC6D4')),
                  DataColumn(label: Text('\uBD84\uC591')),
                  DataColumn(label: Text('\uAD6C\uB9E4')),
                  DataColumn(label: Text('\uB9E4\uCD9C')),
                  DataColumn(label: Text('\uC6D0\uAC00')),
                  DataColumn(label: Text('\uC21C\uC775')),
                ],
                rows: monthly
                    .map(
                      (m) => DataRow(
                        cells: [
                          DataCell(Text('${m.month}\uC6D4')),
                          DataCell(Text('${m.adoptionCount}')),
                          DataCell(Text('${m.purchaseCount}')),
                          DataCell(Text(money.format(m.revenue))),
                          DataCell(Text(money.format(m.cost))),
                          DataCell(Text(money.format(m.profit))),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerFormPage extends StatefulWidget {
  const CustomerFormPage({
    super.key,
    required this.repository,
    required this.onSaved,
  });

  final CrmStore repository;
  final VoidCallback onSaved;

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final adoption = TextEditingController();
  final purchase = TextEditingController();
  final revenue = TextEditingController();
  final cost = TextEditingController();
  final memo = TextEditingController();
  DateTime date = DateTime.now();
  String gender = '미입력';

  @override
  void dispose() {
    for (final c in [name, phone, adoption, purchase, revenue, cost, memo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('고객명을 입력해 주세요.')));
      return;
    }
    final now = DateTime.now().toIso8601String();
    await widget.repository.addCustomer(
      Customer(
        date: DateFormat('yyyy-MM-dd').format(date),
        customerName: name.text.trim(),
        gender: gender,
        phone: phone.text.trim(),
        adoption: adoption.text.trim(),
        purchase: purchase.text.trim(),
        revenue: _toInt(revenue.text),
        cost: _toInt(cost.text),
        memo: memo.text.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );
    widget.onSaved();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('고객DB에 저장했습니다.')));
    }
    for (final c in [name, phone, adoption, purchase, revenue, cost, memo]) {
      c.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('고객등록', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _DateButton(
                  label: '날짜',
                  date: date,
                  onChanged: (v) => setState(() => date = v),
                ),
                _Field(label: '고객명', controller: name),
                _Dropdown(
                  label: '성별',
                  value: gender,
                  values: const ['미입력', '남', '여'],
                  onChanged: (v) => setState(() => gender = v),
                ),
                _Field(label: '휴대폰번호', controller: phone),
                _Field(label: '분양', controller: adoption),
                _Field(label: '구매', controller: purchase),
                _Field(label: '매출', controller: revenue, number: true),
                _Field(label: '원가', controller: cost, number: true),
                SizedBox(
                  width: 700,
                  child: TextField(
                    controller: memo,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: '메모'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _save,
          icon: const Text('🐹'),
          label: const Text('고객 저장'),
        ),
      ],
    );
  }
}

class CustomerDbPage extends StatelessWidget {
  const CustomerDbPage({
    super.key,
    required this.repository,
    required this.customers,
    required this.searchController,
    required this.onChanged,
  });

  final CrmStore repository;
  final List<Customer> customers;
  final TextEditingController searchController;
  final VoidCallback onChanged;

  Future<void> _showDetail(BuildContext context, Customer customer) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _CustomerDetailDialog(customer: customer),
    );
  }

  Future<void> _edit(BuildContext context, Customer customer) async {
    final updated = await showDialog<Customer>(
      context: context,
      builder: (context) => _CustomerEditDialog(customer: customer),
    );
    if (updated == null) return;
    await repository.updateCustomer(updated);
    onChanged();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\uACE0\uAC1D \uC815\uBCF4\uB97C \uC218\uC815\uD588\uC2B5\uB2C8\uB2E4.',
          ),
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context, Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('\uACE0\uAC1D \uC218\uC815'),
        content: Text(
          '${customer.customerName} \uACE0\uAC1D\uC744 \uC0AD\uC81C\uD560\uAE4C\uC694?\n\uC0AD\uC81C\uD55C \uB370\uC774\uD130\uB294 \uC77C\uBC18 \uBAA9\uB85D\uC5D0\uC11C \uC228\uACA8\uC9D1\uB2C8\uB2E4.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('\uCDE8\uC18C'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('\uCDE8\uC18C'),
          ),
        ],
      ),
    );
    if (confirmed != true || customer.id == null) return;
    await repository.softDeleteCustomer(customer.id!);
    onChanged();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\uACE0\uAC1D\uC744 \uC0AD\uC81C\uD588\uC2B5\uB2C8\uB2E4.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,###?');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\uACE0\uAC1DDB',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 14),
        _SearchBar(controller: searchController, onSearch: onChanged),
        const SizedBox(height: 14),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowHeight: 38,
                      dataRowMinHeight: 42,
                      dataRowMaxHeight: 42,
                      horizontalMargin: 8,
                      columnSpacing: 12,
                      headingTextStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: HamsterColors.brown,
                      ),
                      dataTextStyle: const TextStyle(
                        fontSize: 12,
                        color: HamsterColors.brown,
                      ),
                      columns: const [
                        DataColumn(
                          label: _TableHeader('\uAD00\uB9AC', width: 160),
                        ),
                        DataColumn(
                          label: _TableHeader('\uB0A0\uC9DC', width: 86),
                        ),
                        DataColumn(
                          label: _TableHeader('\uACE0\uAC1D\uBA85', width: 76),
                        ),
                        DataColumn(
                          label: _TableHeader('\uC131\uBCC4', width: 44),
                        ),
                        DataColumn(
                          label: _TableHeader(
                            '\uD734\uB300\uD3F0\uBC88\uD638',
                            width: 116,
                          ),
                        ),
                        DataColumn(
                          label: _TableHeader('\uBD84\uC591', width: 120),
                        ),
                        DataColumn(
                          label: _TableHeader('\uAD6C\uB9E4', width: 130),
                        ),
                        DataColumn(
                          label: _TableHeader('\uB9E4\uCD9C', width: 86),
                        ),
                        DataColumn(
                          label: _TableHeader('\uC6D0\uAC00', width: 86),
                        ),
                        DataColumn(
                          label: _TableHeader('\uBA54\uBAA8', width: 420),
                        ),
                      ],
                      rows: customers
                          .map(
                            (c) => DataRow(
                              cells: [
                                DataCell(
                                  _RowActions(
                                    onDetail: () => _showDetail(context, c),
                                    onEdit: () => _edit(context, c),
                                    onDelete: () => _delete(context, c),
                                  ),
                                ),
                                DataCell(_TableText(c.date, width: 86)),
                                DataCell(_TableText(c.customerName, width: 76)),
                                DataCell(_TableText(c.gender, width: 44)),
                                DataCell(_TableText(c.phone, width: 116)),
                                DataCell(_TableText(c.adoption, width: 120)),
                                DataCell(_TableText(c.purchase, width: 130)),
                                DataCell(
                                  _TableText(
                                    money.format(c.revenue),
                                    width: 86,
                                  ),
                                ),
                                DataCell(
                                  _TableText(money.format(c.cost), width: 86),
                                ),
                                DataCell(_TableText(c.memo, width: 420)),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.text, {required this.width});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: Text(text, softWrap: false));
  }
}

class _TableText extends StatelessWidget {
  const _TableText(this.text, {required this.width});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.onDetail,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final compactStyle = TextButton.styleFrom(
      minimumSize: const Size(44, 32),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return SizedBox(
      width: 160,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: onDetail,
            style: compactStyle,
            child: const Text('\uC0C1\uC138'),
          ),
          TextButton(
            onPressed: onEdit,
            style: compactStyle,
            child: const Text('\uC218\uC815'),
          ),
          TextButton(
            onPressed: onDelete,
            style: compactStyle,
            child: const Text('\uC0AD\uC81C'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _CustomerDetailDialog extends StatelessWidget {
  const _CustomerDetailDialog({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,###?');
    return AlertDialog(
      title: Text('${customer.customerName} \uC0C1\uC138\uBCF4\uAE30'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('\uB0A0\uC9DC', customer.date),
            _InfoRow('\uC131\uBCC4', customer.gender),
            _InfoRow('\uD734\uB300\uD3F0\uBC88\uD638', customer.phone),
            _InfoRow('\uBD84\uC591', customer.adoption),
            _InfoRow('\uAD6C\uB9E4', customer.purchase),
            _InfoRow('\uB9E4\uCD9C', money.format(customer.revenue)),
            _InfoRow('\uC6D0\uAC00', money.format(customer.cost)),
            _InfoRow('\uC21C\uC775', money.format(customer.profit)),
            _InfoRow('\uBA54\uBAA8', customer.memo),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('\uCDE8\uC18C'),
        ),
      ],
    );
  }
}

class _ProspectDetailDialog extends StatelessWidget {
  const _ProspectDetailDialog({required this.prospect});

  final Prospect prospect;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,###?');
    return AlertDialog(
      title: Text('${prospect.customerName} \uC0C1\uC138\uBCF4\uAE30'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('\uC0C1\uB2F4\uB0A0\uC9DC', prospect.consultationDate),
            _InfoRow('\uBC29\uBB38\uC608\uC815', prospect.visitDate),
            _InfoRow('\uC131\uBCC4', prospect.gender),
            _InfoRow('\uD734\uB300\uD3F0\uBC88\uD638', prospect.phone),
            _InfoRow('\uBD84\uC591', prospect.adoption),
            _InfoRow('\uAD6C\uB9E4', prospect.purchase),
            _InfoRow('\uB9E4\uCD9C', money.format(prospect.revenue)),
            _InfoRow('\uC6D0\uAC00', money.format(prospect.cost)),
            _InfoRow('\uBA54\uBAA8', prospect.memo),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('\uCDE8\uC18C'),
        ),
      ],
    );
  }
}

class _CustomerEditDialog extends StatefulWidget {
  const _CustomerEditDialog({required this.customer});

  final Customer customer;

  @override
  State<_CustomerEditDialog> createState() => _CustomerEditDialogState();
}

class _CustomerEditDialogState extends State<_CustomerEditDialog> {
  late final name = TextEditingController(text: widget.customer.customerName);
  late final phone = TextEditingController(text: widget.customer.phone);
  late final adoption = TextEditingController(text: widget.customer.adoption);
  late final purchase = TextEditingController(text: widget.customer.purchase);
  late final revenue = TextEditingController(
    text: widget.customer.revenue.toString(),
  );
  late final cost = TextEditingController(
    text: widget.customer.cost.toString(),
  );
  late final memo = TextEditingController(text: widget.customer.memo);
  late DateTime date =
      DateTime.tryParse(widget.customer.date) ?? DateTime.now();
  late String gender = widget.customer.gender.isEmpty
      ? '\uBBF8\uC785\uB825'
      : widget.customer.gender;

  @override
  void dispose() {
    for (final c in [name, phone, adoption, purchase, revenue, cost, memo]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (name.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      widget.customer.copyWith(
        date: DateFormat('yyyy-MM-dd').format(date),
        customerName: name.text.trim(),
        gender: gender,
        phone: phone.text.trim(),
        adoption: adoption.text.trim(),
        purchase: purchase.text.trim(),
        revenue: _toInt(revenue.text),
        cost: _toInt(cost.text),
        memo: memo.text.trim(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('\uACE0\uAC1D \uC0AD\uC81C'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _DateButton(
                label: '\uB0A0\uC9DC',
                date: date,
                onChanged: (v) => setState(() => date = v),
              ),
              _Field(label: '\uACE0\uAC1D\uBA85', controller: name),
              _Dropdown(
                label: '\uB0A0\uC9DC',
                value: gender,
                values: const ['\uBBF8\uC785\uB825', '\uB0A8', '\uC5EC'],
                onChanged: (v) => setState(() => gender = v),
              ),
              _Field(
                label: '\uD734\uB300\uD3F0\uBC88\uD638',
                controller: phone,
              ),
              _Field(label: '\uB0A0\uC9DC', controller: adoption),
              _Field(label: '\uB0A0\uC9DC', controller: purchase),
              _Field(label: '\uB0A0\uC9DC', controller: revenue, number: true),
              _Field(label: '\uB0A0\uC9DC', controller: cost, number: true),
              SizedBox(
                width: 680,
                child: TextField(
                  controller: memo,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: '\uBA54\uBAA8'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('\uCDE8\uC18C'),
        ),
        FilledButton(onPressed: _save, child: const Text('\uCDE8\uC18C')),
      ],
    );
  }
}

class _ProspectEditDialog extends StatefulWidget {
  const _ProspectEditDialog({required this.prospect});

  final Prospect prospect;

  @override
  State<_ProspectEditDialog> createState() => _ProspectEditDialogState();
}

class _ProspectEditDialogState extends State<_ProspectEditDialog> {
  late final name = TextEditingController(text: widget.prospect.customerName);
  late final phone = TextEditingController(text: widget.prospect.phone);
  late final adoption = TextEditingController(text: widget.prospect.adoption);
  late final purchase = TextEditingController(text: widget.prospect.purchase);
  late final revenue = TextEditingController(
    text: widget.prospect.revenue.toString(),
  );
  late final cost = TextEditingController(
    text: widget.prospect.cost.toString(),
  );
  late final memo = TextEditingController(text: widget.prospect.memo);
  late DateTime consultationDate =
      DateTime.tryParse(widget.prospect.consultationDate) ?? DateTime.now();
  late DateTime visitDate =
      DateTime.tryParse(widget.prospect.visitDate) ?? DateTime.now();
  late String gender = widget.prospect.gender.isEmpty
      ? '\uBBF8\uC785\uB825'
      : widget.prospect.gender;

  @override
  void dispose() {
    for (final c in [name, phone, adoption, purchase, revenue, cost, memo]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (name.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      widget.prospect.copyWith(
        consultationDate: DateFormat('yyyy-MM-dd').format(consultationDate),
        visitDate: DateFormat('yyyy-MM-dd').format(visitDate),
        customerName: name.text.trim(),
        gender: gender,
        phone: phone.text.trim(),
        adoption: adoption.text.trim(),
        purchase: purchase.text.trim(),
        revenue: _toInt(revenue.text),
        cost: _toInt(cost.text),
        memo: memo.text.trim(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('\uAC00\uB9DD\uACE0\uAC1D \uC218\uC815'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _DateButton(
                label: '\uC0C1\uB2F4\uB0A0\uC9DC',
                date: consultationDate,
                onChanged: (v) => setState(() => consultationDate = v),
              ),
              _DateButton(
                label: '\uC0C1\uB2F4\uB0A0\uC9DC',
                date: visitDate,
                onChanged: (v) => setState(() => visitDate = v),
              ),
              _Field(label: '\uACE0\uAC1D\uBA85', controller: name),
              _Dropdown(
                label: '\uB0A0\uC9DC',
                value: gender,
                values: const ['\uBBF8\uC785\uB825', '\uB0A8', '\uC5EC'],
                onChanged: (v) => setState(() => gender = v),
              ),
              _Field(
                label: '\uD734\uB300\uD3F0\uBC88\uD638',
                controller: phone,
              ),
              _Field(label: '\uB0A0\uC9DC', controller: adoption),
              _Field(label: '\uB0A0\uC9DC', controller: purchase),
              _Field(label: '\uB0A0\uC9DC', controller: revenue, number: true),
              _Field(label: '\uB0A0\uC9DC', controller: cost, number: true),
              SizedBox(
                width: 680,
                child: TextField(
                  controller: memo,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: '\uBA54\uBAA8'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('\uCDE8\uC18C'),
        ),
        FilledButton(onPressed: _save, child: const Text('\uCDE8\uC18C')),
      ],
    );
  }
}

class ProspectsPage extends StatefulWidget {
  const ProspectsPage({
    super.key,
    required this.repository,
    required this.prospects,
    required this.searchController,
    required this.onChanged,
  });

  final CrmStore repository;
  final List<Prospect> prospects;
  final TextEditingController searchController;
  final VoidCallback onChanged;

  @override
  State<ProspectsPage> createState() => _ProspectsPageState();
}

class _ProspectsPageState extends State<ProspectsPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  DateTime consultationDate = DateTime.now();
  DateTime visitDate = DateTime.now();

  Future<void> _add() async {
    if (name.text.trim().isEmpty) return;
    final now = DateTime.now().toIso8601String();
    await widget.repository.addProspect(
      Prospect(
        consultationDate: DateFormat('yyyy-MM-dd').format(consultationDate),
        visitDate: DateFormat('yyyy-MM-dd').format(visitDate),
        customerName: name.text.trim(),
        phone: phone.text.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );
    name.clear();
    phone.clear();
    widget.onChanged();
  }

  Future<void> _showDetail(Prospect prospect) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ProspectDetailDialog(prospect: prospect),
    );
  }

  Future<void> _edit(Prospect prospect) async {
    final updated = await showDialog<Prospect>(
      context: context,
      builder: (context) => _ProspectEditDialog(prospect: prospect),
    );
    if (updated == null) return;
    await widget.repository.updateProspect(updated);
    widget.onChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\uAC00\uB9DD\uACE0\uAC1D \uC815\uBCF4\uB97C \uC218\uC815\uD588\uC2B5\uB2C8\uB2E4.',
          ),
        ),
      );
    }
  }

  Future<void> _delete(Prospect prospect) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('\uAC00\uB9DD\uACE0\uAC1D \uC0AD\uC81C'),
        content: Text(
          '${prospect.customerName} \uAC00\uB9DD\uACE0\uAC1D\uC744 \uC0AD\uC81C\uD560\uAE4C\uC694?\n\uC0AD\uC81C\uD55C \uB370\uC774\uD130\uB294 \uC77C\uBC18 \uBAA9\uB85D\uC5D0\uC11C \uC228\uACA8\uC9D1\uB2C8\uB2E4.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('\uCDE8\uC18C'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('\uCDE8\uC18C'),
          ),
        ],
      ),
    );
    if (confirmed != true || prospect.id == null) return;
    await widget.repository.softDeleteProspect(prospect.id!);
    widget.onChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\uAC00\uB9DD\uACE0\uAC1D\uC744 \uC0AD\uC81C\uD588\uC2B5\uB2C8\uB2E4.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,###?');
    return ListView(
      children: [
        Text(
          '\uAC00\uB9DD\uACE0\uAC1D',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 14),
        _SearchBar(
          controller: widget.searchController,
          onSearch: widget.onChanged,
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _DateButton(
                  label: '\uC0C1\uB2F4\uB0A0\uC9DC',
                  date: consultationDate,
                  onChanged: (v) => setState(() => consultationDate = v),
                ),
                _DateButton(
                  label: '\uC0C1\uB2F4\uB0A0\uC9DC',
                  date: visitDate,
                  onChanged: (v) => setState(() => visitDate = v),
                ),
                _Field(label: '\uACE0\uAC1D\uBA85', controller: name),
                _Field(
                  label: '\uD734\uB300\uD3F0\uBC88\uD638',
                  controller: phone,
                ),
                FilledButton(
                  onPressed: _add,
                  child: const Text('\uAC00\uB9DD\uACE0\uAC1D \uCD94\uAC00'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 38,
                  dataRowMinHeight: 42,
                  dataRowMaxHeight: 42,
                  horizontalMargin: 8,
                  columnSpacing: 12,
                  columns: const [
                    DataColumn(label: _TableHeader('\uAD00\uB9AC', width: 160)),
                    DataColumn(
                      label: _TableHeader(
                        '\uC0C1\uB2F4\uB0A0\uC9DC',
                        width: 92,
                      ),
                    ),
                    DataColumn(
                      label: _TableHeader(
                        '\uC0C1\uB2F4\uB0A0\uC9DC',
                        width: 92,
                      ),
                    ),
                    DataColumn(
                      label: _TableHeader('\uACE0\uAC1D\uBA85', width: 76),
                    ),
                    DataColumn(label: _TableHeader('\uC131\uBCC4', width: 44)),
                    DataColumn(
                      label: _TableHeader(
                        '\uD734\uB300\uD3F0\uBC88\uD638',
                        width: 116,
                      ),
                    ),
                    DataColumn(label: _TableHeader('\uBD84\uC591', width: 120)),
                    DataColumn(label: _TableHeader('\uAD6C\uB9E4', width: 130)),
                    DataColumn(label: _TableHeader('\uB9E4\uCD9C', width: 86)),
                    DataColumn(label: _TableHeader('\uC6D0\uAC00', width: 86)),
                    DataColumn(label: _TableHeader('\uBA54\uBAA8', width: 420)),
                  ],
                  rows: widget.prospects
                      .map(
                        (p) => DataRow(
                          cells: [
                            DataCell(
                              _RowActions(
                                onDetail: () => _showDetail(p),
                                onEdit: () => _edit(p),
                                onDelete: () => _delete(p),
                              ),
                            ),
                            DataCell(_TableText(p.consultationDate, width: 92)),
                            DataCell(_TableText(p.visitDate, width: 92)),
                            DataCell(_TableText(p.customerName, width: 76)),
                            DataCell(_TableText(p.gender, width: 44)),
                            DataCell(_TableText(p.phone, width: 116)),
                            DataCell(_TableText(p.adoption, width: 120)),
                            DataCell(_TableText(p.purchase, width: 130)),
                            DataCell(
                              _TableText(money.format(p.revenue), width: 86),
                            ),
                            DataCell(
                              _TableText(money.format(p.cost), width: 86),
                            ),
                            DataCell(_TableText(p.memo, width: 420)),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.title, this.value);
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: HamsterColors.softBrown),
              ),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.title, required this.items});
  final String title;
  final List<RankItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (items.isEmpty) const Text('아직 데이터가 없습니다.'),
            for (final item in items) Text('${item.label} · ${item.count}건'),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onSearch});
  final TextEditingController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: '검색'),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton(onPressed: onSearch, child: const Text('검색')),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () {
            controller.clear();
            onSearch();
          },
          child: const Text('초기화'),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.number = false,
  });
  final String label;
  final TextEditingController controller;
  final bool number;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: values
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (v) => v == null ? null : onChanged(v),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onChanged,
  });
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: OutlinedButton(
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            initialDate: date,
          );
          if (picked != null) onChanged(picked);
        },
        child: Text('$label: ${DateFormat('yyyy-MM-dd').format(date)}'),
      ),
    );
  }
}

int _toInt(String value) => int.tryParse(value.replaceAll(',', '').trim()) ?? 0;
