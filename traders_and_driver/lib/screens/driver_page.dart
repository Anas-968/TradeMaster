import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme_controller.dart';

const Color primaryColor = Color(0xFF1A237E);

class DriverPage extends StatefulWidget {
  const DriverPage({super.key});

  @override
  State<DriverPage> createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    DriverLoadStore.instance.refresh();
  }

  final List<Widget> _pages = const [
    DriverDashboard(),
    AvailableLoadsPage(),
    DriverJobsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Find Loads',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'My Jobs'),
        ],
      ),
    );
  }
}

/// Load data shown in the driver dashboard.
class DriverLoad {
  DriverLoad({
    required this.id,
    required this.product,
    required this.from,
    required this.to,
    required this.weight,
    required this.urgent,
    this.status = 'Available',
    this.driverId,
    this.deliveredAt,
  });

  final int id;
  final String product;
  final String from;
  final String to;
  final String weight;
  final bool urgent;
  String status;
  final String? driverId;
  final DateTime? deliveredAt;

  factory DriverLoad.fromMap(Map<String, dynamic> row) => DriverLoad(
    id: (row['id'] as num).toInt(),
    product: row['product']?.toString() ?? 'Load',
    from: row['pickup_location']?.toString() ?? '',
    to: row['delivery_location']?.toString() ?? '',
    weight: row['weight']?.toString() ?? '',
    urgent: false,
    status: row['status']?.toString() ?? 'Available',
    driverId: row['driver_id']?.toString(),
    deliveredAt: DateTime.tryParse(row['delivered_at']?.toString() ?? ''),
  );
}

class DriverLoadStore extends ChangeNotifier {
  DriverLoadStore._();

  static final DriverLoadStore instance = DriverLoadStore._();

  final List<DriverLoad> loads = [];
  bool isLoading = false;
  String? error;

  Future<void> refresh() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final rows = await Supabase.instance.client
          .from('loads')
          .select()
          .order('created_at', ascending: false);
      loads
        ..clear()
        ..addAll(
          (rows as List).map(
            (row) => DriverLoad.fromMap(Map<String, dynamic>.from(row)),
          ),
        );
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<DriverLoad> get availableLoads =>
      loads.where((load) => load.status == 'Available').toList();

  List<DriverLoad> get acceptedLoads => loads
      .where(
        (load) =>
            (load.status == 'Accepted' || load.status == 'In transit') &&
            load.driverId == Supabase.instance.client.auth.currentUser?.id,
      )
      .toList();

  List<DriverLoad> get deliveredLoads => loads
      .where((load) => load.status == 'Delivered' &&
          load.driverId == Supabase.instance.client.auth.currentUser?.id)
      .toList();

  Future<void> acceptLoad(DriverLoad load) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw StateError('Please sign in again.');
    await Supabase.instance.client.rpc(
      'accept_load',
      params: {'p_load_id': load.id},
    );
    final i = loads.indexWhere((item) => item.id == load.id);
    if (i >= 0) {
      loads[i].status = 'Accepted';
      loads[i] = DriverLoad(
        id: load.id,
        product: load.product,
        from: load.from,
        to: load.to,
        weight: load.weight,
        urgent: load.urgent,
        status: 'Accepted',
        driverId: userId,
      );
    }
    notifyListeners();
  }

  Future<void> completeLoad(DriverLoad load) async {
    await Supabase.instance.client.rpc('complete_load', params: {'p_load_id': load.id});
    final i = loads.indexWhere((item) => item.id == load.id);
    if (i >= 0) {
      loads[i] = DriverLoad(id: load.id, product: load.product, from: load.from,
        to: load.to, weight: load.weight, urgent: load.urgent,
        status: 'Delivered', driverId: load.driverId, deliveredAt: DateTime.now());
    }
    notifyListeners();
  }
}

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        user?.userMetadata?['full_name'] ?? user?.phone ?? 'Driver';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Driver Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Reset password',
            icon: const Icon(Icons.lock_reset),
            onPressed: () => Navigator.pushNamed(context, '/reset-password'),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Log out?'),
                  content: const Text(
                    'You will need to log in again to continue.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Log out'),
                    ),
                  ],
                ),
              );
              if (shouldLogout != true || !context.mounted) return;
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: DriverLoadStore.instance,
        builder: (context, _) {
          final store = DriverLoadStore.instance;
          if (store.isLoading && store.loads.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: store.refresh,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $displayName',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find loads and start earning',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLoadsPieChart(
                    availableLoads: store.availableLoads.length,
                    acceptedJobs: store.acceptedLoads.length,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.45,
                    children: [
                      _buildStatCard(
                        Icons.account_balance_wallet,
                        'Jobs Accepted',
                        '${store.acceptedLoads.length}',
                        Colors.orange,
                      ),
                      _buildStatCard(Icons.star, 'Rating', '4.8', Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Recent Bids',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...store.loads
                      .where((load) =>
                          load.status == 'Available' ||
                          load.status == 'Accepted' ||
                          load.status == 'In transit')
                      .take(3)
                      .map(
                        (load) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(
                              Icons.local_shipping,
                              color: primaryColor,
                            ),
                            title: Text(
                              'Load #${load.id}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(load.status),
                            trailing: load.status == 'Available'
                                ? TextButton(
                                    onPressed: () =>
                                        showLoadDetails(context, load),
                                    child: const Text('Awaiting'),
                                  )
                                : const Chip(
                                    label: Text('Accepted'),
                                    backgroundColor: Color(0xFFC8E6C9),
                                  ),
                            onTap: () => showLoadDetails(context, load),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildLoadsPieChart({
    required int availableLoads,
    required int acceptedJobs,
  }) {
    final total = availableLoads + acceptedJobs;
    final safeTotal = total == 0 ? 1 : total;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jobs Overview',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Available loads compared with accepted jobs',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 190,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 38,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                            value: availableLoads.toDouble(),
                            title:
                                '${(availableLoads / safeTotal * 100).round()}%',
                            color: Colors.blue,
                            radius: 55,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          PieChartSectionData(
                            value: acceptedJobs.toDouble(),
                            title:
                                '${(acceptedJobs / safeTotal * 100).round()}%',
                            color: Colors.green,
                            radius: 55,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _chartLegend(
                          color: Colors.blue,
                          label: 'Available Loads',
                          value: '$availableLoads',
                        ),
                        const SizedBox(height: 18),
                        _chartLegend(
                          color: Colors.green,
                          label: 'Accepted Jobs',
                          value: '$acceptedJobs',
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Total: $total jobs',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  static Widget _chartLegend({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 11,
          height: 11,
          margin: const EdgeInsets.only(top: 4, right: 7),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildStatCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showLoadDetails(BuildContext context, DriverLoad load) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final accepted = load.status == 'Accepted' || load.status == 'In transit';
        return AlertDialog(
          title: Text('Load #${load.id} details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Product', load.product),
                _detailRow('Pickup location', load.from),
                _detailRow('Delivery location', load.to),
                const SizedBox(height: 8),
                _detailRow('Weight', load.weight),
                _detailRow('Priority', load.urgent ? 'Urgent' : 'Normal'),
                _detailRow('Status', load.status),
                const SizedBox(height: 8),
                const Text(
                  'Confirm the pickup location and destination before accepting.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            if (!accepted)
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await DriverLoadStore.instance.acceptLoad(load);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Load #${load.id} accepted successfully.',
                          ),
                        ),
                      );
                  } catch (e) {
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst('Exception: ', ''),
                          ),
                        ),
                      );
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Accept Order'),
              )
            else if (load.status == 'Delivered')
              const Chip(avatar: Icon(Icons.check_circle, color: Colors.green), label: Text('Delivered'))
            else
              const Chip(
                avatar: Icon(Icons.check_circle, color: Colors.green),
                label: Text('Already accepted'),
              ),
          ],
        );
      },
    ),
  );
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(flex: 6, child: Text(value)),
      ],
    ),
  );
}

class AvailableLoadsPage extends StatelessWidget {
  const AvailableLoadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Available Loads',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: DriverLoadStore.instance,
        builder: (context, _) {
          final store = DriverLoadStore.instance;
          final loads = store.availableLoads;
          if (store.isLoading && store.loads.isEmpty)
            return const Center(child: CircularProgressIndicator());
          if (store.error != null && store.loads.isEmpty)
            return Center(
              child: Text('Could not load available jobs. ${store.error}'),
            );
          if (loads.isEmpty) {
            return const Center(
              child: Text('There are no available loads right now.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: loads.length,
            itemBuilder: (context, index) {
              final load = loads[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              load.product,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (load.urgent)
                            const Chip(
                              label: Text('Urgent'),
                              backgroundColor: Color(0xFFC8E6C9),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('From: ${load.from}  â†’  To: ${load.to}'),
                      const SizedBox(height: 8),
                      Text('Weight: ${load.weight}'),
                      const SizedBox(height: 8),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => showLoadDetails(context, load),
                              child: const Text('View Details'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => showLoadDetails(context, load),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Accept Order'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DriverJobsPage extends StatelessWidget {
  const DriverJobsPage({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('My Jobs', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            bottom: const TabBar(tabs: [Tab(text: 'Active'), Tab(text: 'Delivered')]),
          ),
          body: AnimatedBuilder(
            animation: DriverLoadStore.instance,
            builder: (context, _) {
              final store = DriverLoadStore.instance;
              if (store.isLoading && store.loads.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return TabBarView(children: [
                _activeJobs(context, store),
                _deliveredJobs(store),
              ]);
            },
          ),
        ),
      );

  Widget _activeJobs(BuildContext context, DriverLoadStore store) {
    final jobs = store.acceptedLoads;
    if (jobs.isEmpty) return const Center(child: Text('No active jobs.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final load = jobs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.local_shipping_outlined, color: primaryColor),
                const SizedBox(width: 10),
                Expanded(child: Text(load.product, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16))),
                Chip(label: Text(load.status)),
              ]),
              const SizedBox(height: 8),
              Text('Load #${load.id}  •  ${load.weight}'),
              const SizedBox(height: 6),
              Text('${load.from}  ?  ${load.to}'),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: () => _confirmDelivered(context, store, load),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirm delivery'),
              )),
            ]),
          ),
        );
      },
    );
  }

  Widget _deliveredJobs(DriverLoadStore store) {
    final jobs = store.deliveredLoads;
    if (jobs.isEmpty) return const Center(child: Text('Delivered orders will appear here.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final load = jobs[index];
        final date = load.deliveredAt?.toLocal();
        final completed = date == null
            ? 'Delivery confirmed'
            : 'Delivered ${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.receipt_long, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(child: Text('Delivery receipt  •  #${load.id}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                const Icon(Icons.verified, color: Colors.green),
              ]),
              const Divider(height: 24),
              _receiptRow('Item', load.product),
              _receiptRow('Route', '${load.from} ? ${load.to}'),
              _receiptRow('Weight', load.weight.isEmpty ? 'Not specified' : load.weight),
              _receiptRow('Status', 'Delivered'),
              _receiptRow('Completed', completed),
            ]),
          ),
        );
      },
    );
  }

  Widget _receiptRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 92, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ]),
      );

  Future<void> _confirmDelivered(BuildContext context, DriverLoadStore store, DriverLoad load) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm delivery?'),
        content: Text('Confirm that “${load.product}” (load #${load.id}) has reached ${load.to}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Not yet')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.check),
            label: const Text('Confirm delivered'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await store.completeLoad(load);
      if (context.mounted) {
        DefaultTabController.of(context).animateTo(1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery confirmed. Receipt added to Delivered.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not confirm delivery: $e')));
      }
    }
  }
}