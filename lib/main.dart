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
      deletedCustomers: await widget.repository.deletedCustomers(),
      deletedProspects: await widget.repository.deletedProspects(),
    );
  }

  String _initialPage() {
    if (!kIsWeb) return '대시보드';
    return switch (Uri.base.queryParameters['page']) {
      'customer-registration' => '고객등록',
      'customers' => '고객DB',
      'prospects' => '가망고객',
      'trash' => '휴지통',
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
      '휴지통' => TrashPage(
        repository: widget.repository,
        deletedCustomers: data.deletedCustomers,
        deletedProspects: data.deletedProspects,
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
  final List<Customer> deletedCustomers;
  final List<Prospect> deletedProspects;

  const _HomeData({
    required this.summary,
    required this.customers,
    required this.prospects,
    required this.deletedCustomers,
    required this.deletedProspects,
  });
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ('\uB300\uC2DC\uBCF4\uB4DC', Icons.dashboard_rounded),
      ('\uACE0\uAC1D\uB4F1\uB85D', Icons.person_add_alt_1_rounded),
      ('\uACE0\uAC1DDB', Icons.table_chart_rounded),
      ('\uAC00\uB9DD\uACE0\uAC1D', Icons.groups_rounded),
      ('\uD734\uC9C0\uD1B5', Icons.delete_outline_rounded),
    ];
    return Container(
      width: 300,
      color: HamsterColors.brown,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/byopet_icon.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\uBD64\uD3AB',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'CRM',
                              style: TextStyle(
                                color: HamsterColors.cream,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              '\uBA54\uB274',
              style: TextStyle(
                color: HamsterColors.cream,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            for (final page in pages)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton.tonalIcon(
                  onPressed: () => onSelected(page.$1),
                  icon: Icon(page.$2, size: 23),
                  label: Text(page.$1),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 62),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.centerLeft,
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                    backgroundColor: selected == page.$1
                        ? HamsterColors.gold
                        : HamsterColors.cream.withValues(alpha: 0.14),
                    foregroundColor: selected == page.$1
                        ? HamsterColors.brown
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
            const SizedBox(height: 10),
            _MonthlyValueLegend(monthly: monthly),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
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

class _MonthlyValueLegend extends StatelessWidget {
  const _MonthlyValueLegend({required this.monthly});

  final List<MonthlySettlement> monthly;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in monthly.where(
          (item) => item.adoptionCount > 0 || item.purchaseCount > 0,
        ))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: HamsterColors.cream.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: HamsterColors.line),
            ),
            child: Text(
              '${item.month}\uC6D4 \uBD84\uC591 ${item.adoptionCount} \u00B7 \uAD6C\uB9E4 ${item.purchaseCount}',
              style: const TextStyle(
                color: HamsterColors.brown,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({required this.monthly});

  final List<MonthlySettlement> monthly;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,###\uC6D0');
    final yearRevenue = monthly.fold<int>(0, (sum, item) => sum + item.revenue);
    final yearCost = monthly.fold<int>(0, (sum, item) => sum + item.cost);
    final yearProfit = yearRevenue - yearCost;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\uC815\uC0B0\uD604\uD669',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _SettlementLine(
              label: '\uB9E4\uCD9C',
              value: money.format(yearRevenue),
              color: HamsterColors.gold,
            ),
            const SizedBox(height: 8),
            _SettlementLine(
              label: '\uC6D0\uAC00',
              value: money.format(yearCost),
              color: HamsterColors.softBrown,
            ),
            const SizedBox(height: 8),
            _SettlementLine(
              label: '\uC190\uC775',
              value: money.format(yearProfit),
              color: yearProfit >= 0 ? HamsterColors.mint : Colors.redAccent,
              emphasize: true,
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: HamsterColors.line),
            const SizedBox(height: 10),
            ...monthly
                .where((m) => m.revenue != 0 || m.cost != 0)
                .map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: m.month == DateTime.now().month
                            ? HamsterColors.cream.withValues(alpha: 0.55)
                            : HamsterColors.input,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: HamsterColors.line),
                      ),
                      child: Text(
                        '${m.month}\uC6D4  \uB9E4\uCD9C ${money.format(m.revenue)} / \uC6D0\uAC00 ${money.format(m.cost)} / \uC190\uC775 ${money.format(m.profit)}',
                        style: TextStyle(
                          color: m.profit >= 0
                              ? HamsterColors.brown
                              : Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _SettlementLine extends StatelessWidget {
  const _SettlementLine({
    required this.label,
    required this.value,
    required this.color,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: emphasize ? 0.32 : 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: const TextStyle(
                color: HamsterColors.softBrown,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: HamsterColors.brown,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
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
  String gender = '\uBBF8\uC785\uB825';

  @override
  void dispose() {
    for (final c in [name, phone, adoption, purchase, revenue, cost, memo]) {
      c.dispose();
    }
    super.dispose();
  }

  void _clear() {
    for (final c in [name, phone, adoption, purchase, revenue, cost, memo]) {
      c.clear();
    }
    setState(() {
      date = DateTime.now();
      gender = '\uBBF8\uC785\uB825';
    });
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\uACE0\uAC1D\uBA85\uC744 \uC785\uB825\uD574 \uC8FC\uC138\uC694.',
          ),
        ),
      );
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
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            '\uD310\uB9E4\uB97C \uCD95\uD558\uD569\uB2C8\uB2E4',
          ),
          content: const Text(
            '\uACE0\uAC1D \uB4F1\uB85D\uC774 \uC644\uB8CC\uB418\uC5C8\uC2B5\uB2C8\uB2E4.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('\uD655\uC778'),
            ),
          ],
        ),
      );
    }
    _clear();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\uACE0\uAC1D\uB4F1\uB85D',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '\uACE0\uAC1D \uC815\uBCF4, \uAD6C\uB9E4 \uB0B4\uC5ED, \uBA54\uBAA8\uB97C \uD55C \uD654\uBA74\uC5D0\uC11C \uBC14\uB85C \uC785\uB825\uD569\uB2C8\uB2E4.',
                        style: TextStyle(
                          color: HamsterColors.softBrown,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('\uC785\uB825 \uCD08\uAE30\uD654'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(130, 52),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('\uACE0\uAC1D \uC800\uC7A5'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(130, 52),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _CustomerEntryCard(
              date: date,
              onDateChanged: (v) => setState(() => date = v),
              name: name,
              gender: gender,
              onGenderChanged: (v) => setState(() => gender = v),
              phone: phone,
              adoption: adoption,
              purchase: purchase,
              revenue: revenue,
              cost: cost,
              memo: memo,
            ),
            const SizedBox(height: 16),
            _CustomerEntryActions(onSave: _save, onClear: _clear),
          ],
        );
      },
    );
  }
}

class _CustomerEntryCard extends StatelessWidget {
  const _CustomerEntryCard({
    required this.date,
    required this.onDateChanged,
    required this.name,
    required this.gender,
    required this.onGenderChanged,
    required this.phone,
    required this.adoption,
    required this.purchase,
    required this.revenue,
    required this.cost,
    required this.memo,
  });

  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final TextEditingController name;
  final String gender;
  final ValueChanged<String> onGenderChanged;
  final TextEditingController phone;
  final TextEditingController adoption;
  final TextEditingController purchase;
  final TextEditingController revenue;
  final TextEditingController cost;
  final TextEditingController memo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 16.0;
            final columns = (constraints.maxWidth / 236).floor().clamp(1, 4);
            final fieldWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(
                  icon: Icons.badge_rounded,
                  title: '\uAE30\uBCF8 \uC815\uBCF4',
                  subtitle:
                      '\uACE0\uAC1D \uC2DD\uBCC4\uC5D0 \uD544\uC694\uD55C \uB0B4\uC6A9\uC744 \uBA3C\uC800 \uCC44\uC6CC \uC8FC\uC138\uC694.',
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    _DateButton(
                      label: '\uB0A0\uC9DC',
                      date: date,
                      width: fieldWidth,
                      onChanged: onDateChanged,
                    ),
                    _Field(
                      label: '\uACE0\uAC1D\uBA85',
                      controller: name,
                      width: fieldWidth,
                    ),
                    _Dropdown(
                      label: '\uC131\uBCC4',
                      value: gender,
                      width: fieldWidth,
                      values: const ['\uBBF8\uC785\uB825', '\uB0A8', '\uC5EC'],
                      onChanged: onGenderChanged,
                    ),
                    _Field(
                      label: '\uD734\uB300\uD3F0\uBC88\uD638',
                      controller: phone,
                      width: fieldWidth,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const _SectionTitle(
                  icon: Icons.shopping_bag_rounded,
                  title: '\uBD84\uC591 \u00B7 \uAD6C\uB9E4 \u00B7 \uC815\uC0B0',
                  subtitle:
                      '\uB300\uC2DC\uBCF4\uB4DC \uC9D1\uACC4\uC5D0 \uBC14\uB85C \uBC18\uC601\uB418\uB294 \uAE08\uC561 \uC815\uBCF4\uC785\uB2C8\uB2E4.',
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    _Field(
                      label: '\uBD84\uC591',
                      controller: adoption,
                      width: fieldWidth,
                    ),
                    _Field(
                      label: '\uAD6C\uB9E4',
                      controller: purchase,
                      width: fieldWidth,
                    ),
                    _Field(
                      label: '\uB9E4\uCD9C',
                      controller: revenue,
                      number: true,
                      width: fieldWidth,
                    ),
                    _Field(
                      label: '\uC6D0\uAC00',
                      controller: cost,
                      number: true,
                      width: fieldWidth,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const _SectionTitle(
                  icon: Icons.edit_note_rounded,
                  title: '\uC0C1\uB2F4 \uBA54\uBAA8',
                  subtitle:
                      '\uC0AC\uC721 \uC548\uB0B4, \uC7AC\uBC29\uBB38 \uC608\uC815, \uD2B9\uC774\uC0AC\uD56D\uC744 \uB113\uAC8C \uB0A8\uACA8 \uC8FC\uC138\uC694.',
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: memo,
                  minLines: 7,
                  maxLines: 9,
                  decoration: const InputDecoration(
                    labelText: '\uBA54\uBAA8',
                    hintText:
                        '\uC608: \uCC98\uC74C \uD0A4\uC6B0\uB294 \uACE0\uAC1D / \uD1A0\uC694\uC77C \uC7AC\uBC29\uBB38 \uC608\uC815 / \uCF00\uC774\uC9C0 \uC138\uD2B8 \uAD00\uC2EC',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CustomerEntryActions extends StatelessWidget {
  const _CustomerEntryActions({required this.onSave, required this.onClear});

  final VoidCallback onSave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/byopet_icon.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '\uB4F1\uB85D \uC804 \uCCB4\uD06C',
              style: TextStyle(
                color: HamsterColors.brown,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const _CheckLine(
              '\uACE0\uAC1D\uBA85\uC740 \uD544\uC218 \uC785\uB825',
            ),
            const _CheckLine(
              '\uB9E4\uCD9C/\uC6D0\uAC00\uB294 \uC22B\uC790\uB85C \uC785\uB825',
            ),
            const _CheckLine(
              '\uBA54\uBAA8\uB294 \uACE0\uAC1DDB \uC0C1\uC138\uBCF4\uAE30\uC5D0\uC11C \uD655\uC778',
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_rounded),
              label: const Text('\uACE0\uAC1D \uC800\uC7A5'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 64),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('\uC785\uB825 \uCD08\uAE30\uD654'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: HamsterColors.gold.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: HamsterColors.brown),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: HamsterColors.brown,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: HamsterColors.softBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: HamsterColors.mint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: HamsterColors.brown,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerDbPage extends StatefulWidget {
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

  @override
  State<CustomerDbPage> createState() => _CustomerDbPageState();
}

class _CustomerDbPageState extends State<CustomerDbPage> {
  DateTimeRange? dateFilter;

  List<Customer> get filteredCustomers {
    final range = dateFilter;
    if (range == null) return widget.customers;
    return widget.customers.where((customer) {
      final date = DateTime.tryParse(customer.date);
      if (date == null) return false;
      final day = DateTime(date.year, date.month, date.day);
      final start = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      final end = DateTime(range.end.year, range.end.month, range.end.day);
      return !day.isBefore(start) && !day.isAfter(end);
    }).toList();
  }

  String get dateFilterLabel {
    final range = dateFilter;
    if (range == null) return '\uB0A0\uC9DC \uD544\uD130';
    final start = DateFormat('MM/dd').format(range.start);
    final end = DateFormat('MM/dd').format(range.end);
    return '$start - $end';
  }

  Future<void> _pickDateFilter() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: dateFilter,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: HamsterColors.brown,
            secondary: HamsterColors.gold,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => dateFilter = picked);
  }

  void _clearDateFilter() {
    setState(() => dateFilter = null);
  }

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
    await widget.repository.updateCustomer(updated);
    widget.onChanged();
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
        title: const Text('\uC0AD\uC81C \uD655\uC778'),
        content: const Text(
          '\uC0AD\uC81C\uD558\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('\uCDE8\uC18C'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('\uD655\uC778'),
          ),
        ],
      ),
    );
    if (confirmed != true || customer.id == null) return;
    await widget.repository.softDeleteCustomer(customer.id!);
    widget.onChanged();
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
    final money = NumberFormat('#,###\uC6D0');
    final visibleCustomers = filteredCustomers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\uACE0\uAC1DDB',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 360,
              child: _SearchBar(
                controller: widget.searchController,
                onSearch: widget.onChanged,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pickDateFilter,
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: Text(dateFilterLabel),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(138, 52),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (dateFilter != null)
              IconButton.filledTonal(
                onPressed: _clearDateFilter,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: '\uB0A0\uC9DC \uD544\uD130 \uD574\uC81C',
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
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
                          label: _TableHeader('\uAD00\uB9AC', width: 106),
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
                      rows: visibleCustomers
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
    final compactStyle = IconButton.styleFrom(
      minimumSize: const Size(30, 30),
      fixedSize: const Size(30, 30),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      iconSize: 17,
    );
    return SizedBox(
      width: 106,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: '\uC0C1\uC138',
            child: IconButton(
              onPressed: onDetail,
              style: compactStyle,
              icon: const Icon(Icons.visibility_rounded),
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: '\uC218\uC815',
            child: IconButton(
              onPressed: onEdit,
              style: compactStyle,
              icon: const Icon(Icons.edit_rounded),
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: '\uC0AD\uC81C',
            child: IconButton(
              onPressed: onDelete,
              style: compactStyle,
              color: Colors.redAccent,
              icon: const Icon(Icons.delete_rounded),
            ),
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
    final money = NumberFormat('#,###\uC6D0');
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
    final money = NumberFormat('#,###\uC6D0');
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
      title: const Text('\uACE0\uAC1D \uC218\uC815'),
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
                label: '\uC131\uBCC4',
                value: gender,
                values: const ['\uBBF8\uC785\uB825', '\uB0A8', '\uC5EC'],
                onChanged: (v) => setState(() => gender = v),
              ),
              _Field(
                label: '\uD734\uB300\uD3F0\uBC88\uD638',
                controller: phone,
              ),
              _Field(label: '\uBD84\uC591', controller: adoption),
              _Field(label: '\uAD6C\uB9E4', controller: purchase),
              _Field(label: '\uB9E4\uCD9C', controller: revenue, number: true),
              _Field(label: '\uC6D0\uAC00', controller: cost, number: true),
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
        FilledButton(onPressed: _save, child: const Text('\uC800\uC7A5')),
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
                label: '\uBC29\uBB38\uC608\uC815',
                date: visitDate,
                onChanged: (v) => setState(() => visitDate = v),
              ),
              _Field(label: '\uACE0\uAC1D\uBA85', controller: name),
              _Dropdown(
                label: '\uC131\uBCC4',
                value: gender,
                values: const ['\uBBF8\uC785\uB825', '\uB0A8', '\uC5EC'],
                onChanged: (v) => setState(() => gender = v),
              ),
              _Field(
                label: '\uD734\uB300\uD3F0\uBC88\uD638',
                controller: phone,
              ),
              _Field(label: '\uBD84\uC591', controller: adoption),
              _Field(label: '\uAD6C\uB9E4', controller: purchase),
              _Field(label: '\uB9E4\uCD9C', controller: revenue, number: true),
              _Field(label: '\uC6D0\uAC00', controller: cost, number: true),
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
        FilledButton(onPressed: _save, child: const Text('\uC800\uC7A5')),
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
        title: const Text('\uC0AD\uC81C \uD655\uC778'),
        content: const Text(
          '\uC0AD\uC81C\uD558\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('\uCDE8\uC18C'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('\uD655\uC778'),
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
    final money = NumberFormat('#,###\uC6D0');
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
                  label: '\uBC29\uBB38\uC608\uC815',
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
                    DataColumn(label: _TableHeader('\uAD00\uB9AC', width: 106)),
                    DataColumn(
                      label: _TableHeader(
                        '\uC0C1\uB2F4\uB0A0\uC9DC',
                        width: 92,
                      ),
                    ),
                    DataColumn(
                      label: _TableHeader(
                        '\uBC29\uBB38\uC608\uC815',
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

class TrashPage extends StatelessWidget {
  const TrashPage({
    super.key,
    required this.repository,
    required this.deletedCustomers,
    required this.deletedProspects,
    required this.onChanged,
  });

  final CrmStore repository;
  final List<Customer> deletedCustomers;
  final List<Prospect> deletedProspects;
  final VoidCallback onChanged;

  Future<bool> _confirm(BuildContext context, String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('\uD655\uC778'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('\uCDE8\uC18C'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('\uD655\uC778'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _restoreCustomer(BuildContext context, Customer customer) async {
    final id = customer.id;
    if (id == null) return;
    await repository.restoreCustomer(id);
    onChanged();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\uACE0\uAC1D\uC744 \uBCF5\uAD6C\uD588\uC2B5\uB2C8\uB2E4.',
          ),
        ),
      );
    }
  }

  Future<void> _restoreProspect(BuildContext context, Prospect prospect) async {
    final id = prospect.id;
    if (id == null) return;
    await repository.restoreProspect(id);
    onChanged();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\uAC00\uB9DD\uACE0\uAC1D\uC744 \uBCF5\uAD6C\uD588\uC2B5\uB2C8\uB2E4.',
          ),
        ),
      );
    }
  }

  Future<void> _hardDeleteCustomer(
    BuildContext context,
    Customer customer,
  ) async {
    final id = customer.id;
    if (id == null) return;
    if (!await _confirm(
      context,
      '\uC644\uC804 \uC0AD\uC81C\uD558\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?',
    )) {
      return;
    }
    await repository.hardDeleteCustomer(id);
    onChanged();
  }

  Future<void> _hardDeleteProspect(
    BuildContext context,
    Prospect prospect,
  ) async {
    final id = prospect.id;
    if (id == null) return;
    if (!await _confirm(
      context,
      '\uC644\uC804 \uC0AD\uC81C\uD558\uC2DC\uACA0\uC2B5\uB2C8\uAE4C?',
    )) {
      return;
    }
    await repository.hardDeleteProspect(id);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          '\uD734\uC9C0\uD1B5',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        const Text(
          '\uD544\uC694\uD560 \uB54C \uC218\uB3D9\uC73C\uB85C \uBCF5\uAD6C\uD558\uAC70\uB098 \uC644\uC804 \uC0AD\uC81C\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4.',
          style: TextStyle(
            color: HamsterColors.softBrown,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _TrashCustomerTable(
          customers: deletedCustomers,
          onRestore: (customer) => _restoreCustomer(context, customer),
          onHardDelete: (customer) => _hardDeleteCustomer(context, customer),
        ),
        const SizedBox(height: 16),
        _TrashProspectTable(
          prospects: deletedProspects,
          onRestore: (prospect) => _restoreProspect(context, prospect),
          onHardDelete: (prospect) => _hardDeleteProspect(context, prospect),
        ),
      ],
    );
  }
}

class _TrashCustomerTable extends StatelessWidget {
  const _TrashCustomerTable({
    required this.customers,
    required this.onRestore,
    required this.onHardDelete,
  });

  final List<Customer> customers;
  final ValueChanged<Customer> onRestore;
  final ValueChanged<Customer> onHardDelete;

  @override
  Widget build(BuildContext context) {
    return _TrashCard(
      title: '\uACE0\uAC1DDB',
      emptyText:
          '\uC0AD\uC81C\uB41C \uACE0\uAC1D\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
      isEmpty: customers.isEmpty,
      child: DataTable(
        headingRowHeight: 38,
        dataRowMinHeight: 42,
        dataRowMaxHeight: 42,
        horizontalMargin: 8,
        columnSpacing: 12,
        columns: const [
          DataColumn(label: _TableHeader('\uAD00\uB9AC', width: 160)),
          DataColumn(label: _TableHeader('\uC0AD\uC81C\uC77C', width: 150)),
          DataColumn(label: _TableHeader('\uACE0\uAC1D\uBA85', width: 120)),
          DataColumn(
            label: _TableHeader('\uD734\uB300\uD3F0\uBC88\uD638', width: 130),
          ),
          DataColumn(label: _TableHeader('\uBA54\uBAA8', width: 420)),
        ],
        rows: customers
            .map(
              (c) => DataRow(
                cells: [
                  DataCell(
                    _TrashActions(
                      onRestore: () => onRestore(c),
                      onHardDelete: () => onHardDelete(c),
                    ),
                  ),
                  DataCell(_TableText(c.deletedAt ?? '-', width: 150)),
                  DataCell(_TableText(c.customerName, width: 120)),
                  DataCell(_TableText(c.phone, width: 130)),
                  DataCell(_TableText(c.memo, width: 420)),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TrashProspectTable extends StatelessWidget {
  const _TrashProspectTable({
    required this.prospects,
    required this.onRestore,
    required this.onHardDelete,
  });

  final List<Prospect> prospects;
  final ValueChanged<Prospect> onRestore;
  final ValueChanged<Prospect> onHardDelete;

  @override
  Widget build(BuildContext context) {
    return _TrashCard(
      title: '\uAC00\uB9DD\uACE0\uAC1D',
      emptyText:
          '\uC0AD\uC81C\uB41C \uAC00\uB9DD\uACE0\uAC1D\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
      isEmpty: prospects.isEmpty,
      child: DataTable(
        headingRowHeight: 38,
        dataRowMinHeight: 42,
        dataRowMaxHeight: 42,
        horizontalMargin: 8,
        columnSpacing: 12,
        columns: const [
          DataColumn(label: _TableHeader('\uAD00\uB9AC', width: 160)),
          DataColumn(label: _TableHeader('\uC0AD\uC81C\uC77C', width: 150)),
          DataColumn(label: _TableHeader('\uACE0\uAC1D\uBA85', width: 120)),
          DataColumn(
            label: _TableHeader('\uD734\uB300\uD3F0\uBC88\uD638', width: 130),
          ),
          DataColumn(label: _TableHeader('\uBA54\uBAA8', width: 420)),
        ],
        rows: prospects
            .map(
              (p) => DataRow(
                cells: [
                  DataCell(
                    _TrashActions(
                      onRestore: () => onRestore(p),
                      onHardDelete: () => onHardDelete(p),
                    ),
                  ),
                  DataCell(_TableText(p.deletedAt ?? '-', width: 150)),
                  DataCell(_TableText(p.customerName, width: 120)),
                  DataCell(_TableText(p.phone, width: 130)),
                  DataCell(_TableText(p.memo, width: 420)),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TrashCard extends StatelessWidget {
  const _TrashCard({
    required this.title,
    required this.emptyText,
    required this.isEmpty,
    required this.child,
  });

  final String title;
  final String emptyText;
  final bool isEmpty;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(child: Text(emptyText)),
              )
            else
              Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: child,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrashActions extends StatelessWidget {
  const _TrashActions({required this.onRestore, required this.onHardDelete});

  final VoidCallback onRestore;
  final VoidCallback onHardDelete;

  @override
  Widget build(BuildContext context) {
    final compactStyle = TextButton.styleFrom(
      minimumSize: const Size(58, 32),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return SizedBox(
      width: 160,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: onRestore,
            style: compactStyle,
            child: const Text('\uBCF5\uAD6C'),
          ),
          TextButton(
            onPressed: onHardDelete,
            style: compactStyle,
            child: const Text('\uC644\uC804\uC0AD\uC81C'),
          ),
        ],
      ),
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
    this.width = 220,
  });
  final String label;
  final TextEditingController controller;
  final bool number;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
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
    this.width = 220,
  });
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
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
    this.width = 220,
  });
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
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
