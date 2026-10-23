import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

const Color primaryColor = Color(0xFF1A237E);
const String currency = 'OMR';

String formatOmaniRial(double amount) => 'OMR ${amount.toStringAsFixed(3)}';

class DriverPage extends StatefulWidget {
  const DriverPage({super.key});

  @override
  State<DriverPage> createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  int _selectedIndex = 0;

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
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'My Jobs',
          ),
        ],
      ),
    );
  }
}

/// Demo data for the UI. Replace this list with your Supabase table data
/// when you are ready to connect real orders.
class DriverLoad {
  DriverLoad({
    required this.id,
    required this.product,
    required this.from,
    required this.to,
    required this.weight,
    required this.payment,
    required this.urgent,
    required this.fromLatitude,
    required this.fromLongitude,
    required this.toLatitude,
    required this.toLongitude,
    this.status = 'Available',
  });

  final int id;
  final String product;
  final String from;
  final String to;
  final String weight;
  final double payment;
  final bool urgent;
  final double fromLatitude;
  final double fromLongitude;
  final double toLatitude;
  final double toLongitude;
  String status;
}

class DriverLoadStore extends ChangeNotifier {
  DriverLoadStore._();

  static final DriverLoadStore instance = DriverLoadStore._();

  final List<DriverLoad> loads = [
    DriverLoad(
      id: 2001,
      product: 'Food Supplies',
      from: 'Warehouse A',
      to: 'Muscat',
      weight: '500 kg',
      payment: 77.000,
      urgent: true,
      fromLatitude: 23.6100,
      fromLongitude: 58.5400,
      toLatitude: 23.5880,
      toLongitude: 58.3829,
    ),
    DriverLoad(
      id: 2002,
      product: 'Electronics',
      from: 'Warehouse B',
      to: 'Nizwa',
      weight: '320 kg',
      payment: 115.500,
      urgent: false,
      fromLatitude: 23.6100,
      fromLongitude: 58.5400,
      toLatitude: 22.9333,
      toLongitude: 57.5333,
    ),
    DriverLoad(
      id: 2003,
      product: 'Furniture',
      from: 'Warehouse C',
      to: 'Sohar',
      weight: '700 kg',
      payment: 154.000,
      urgent: true,
      fromLatitude: 23.6100,
      fromLongitude: 58.5400,
      toLatitude: 24.3410,
      toLongitude: 56.7290,
    ),
    DriverLoad(
      id: 2004,
      product: 'Clothing',
      from: 'Warehouse D',
      to: 'Sur',
      weight: '250 kg',
      payment: 57.750,
      urgent: false,
      fromLatitude: 23.6100,
      fromLongitude: 58.5400,
      toLatitude: 22.5667,
      toLongitude: 59.5289,
    ),
    DriverLoad(
      id: 2005,
      product: 'Building Materials',
      from: 'Warehouse E',
      to: 'Ibri',
      weight: '900 kg',
      payment: 192.500,
      urgent: false,
      fromLatitude: 23.6100,
      fromLongitude: 58.5400,
      toLatitude: 23.2257,
      toLongitude: 56.5157,
    ),
    DriverLoad(
      id: 2006,
      product: 'Medical Supplies',
      from: 'Warehouse F',
      to: 'Salalah',
      weight: '400 kg',
      payment: 231.000,
      urgent: true,
      fromLatitude: 23.6100,
      fromLongitude: 58.5400,
      toLatitude: 17.0151,
      toLongitude: 54.0924,
    ),
  ];

  List<DriverLoad> get availableLoads =>
      loads.where((load) => load.status == 'Available').toList();

  List<DriverLoad> get acceptedLoads =>
      loads.where((load) => load.status == 'Accepted').toList();

  void acceptLoad(DriverLoad load) {
    if (load.status != 'Available') return;
    load.status = 'Accepted';
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
          return SingleChildScrollView(
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
                      'Total Earned',
                      formatOmaniRial(492.800),
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
                ...store.loads.take(3).map(
                  (load) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.local_shipping, color: primaryColor),
                      title: Text(
                        'Load #${load.id}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${formatOmaniRial(load.payment)} • ${load.status}',
                      ),
                      trailing: load.status == 'Available'
                          ? TextButton(
                              onPressed: () => showLoadDetails(context, load),
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
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
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
                            title: '${(availableLoads / safeTotal * 100).round()}%',
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
                            title: '${(acceptedJobs / safeTotal * 100).round()}%',
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
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
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
        final accepted = load.status == 'Accepted';
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
                _LoadDistance(load: load),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _openMap(context, load),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('View route on map'),
                ),
                _detailRow('Weight', load.weight),
                _detailRow('Payment', formatOmaniRial(load.payment)),
                _detailRow('Priority', load.urgent ? 'Urgent' : 'Normal'),
                _detailRow('Status', load.status),
                const SizedBox(height: 8),
                const Text(
                  'Please check the pickup location, destination, and payment before accepting.',
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
                onPressed: () {
                  DriverLoadStore.instance.acceptLoad(load);
                  setDialogState(() {});
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Load #${load.id} accepted successfully.'),
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Accept Order'),
              )
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

class _LoadDistance extends StatelessWidget {
  const _LoadDistance({required this.load});

  final DriverLoad load;

  @override
  Widget build(BuildContext context) {
    final meters = Geolocator.distanceBetween(
      load.fromLatitude,
      load.fromLongitude,
      load.toLatitude,
      load.toLongitude,
    );
    final km = meters / 1000;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.route, color: primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Approximate straight-line distance',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('${km.toStringAsFixed(1)} km'),
                const Text(
                  'Road distance may be longer. Coordinates are demo values.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openMap(BuildContext context, DriverLoad load) async {
  final url = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&origin=${load.fromLatitude},${load.fromLongitude}'
    '&destination=${load.toLatitude},${load.toLongitude}'
    '&travelmode=driving',
  );

  final opened = await launchUrl(
    url,
    mode: LaunchMode.externalApplication,
  );

  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the map. Please try again.')),
    );
  }
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
          final loads = DriverLoadStore.instance.availableLoads;
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
                      Text('From: ${load.from}  →  To: ${load.to}'),
                      const SizedBox(height: 8),
                      Text('Weight: ${load.weight}'),
                      const SizedBox(height: 8),
                      Text(
                        'Payment: ${formatOmaniRial(load.payment)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Jobs',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: DriverLoadStore.instance,
        builder: (context, _) {
          final jobs = DriverLoadStore.instance.acceptedLoads;
          if (jobs.isEmpty) {
            return const Center(
              child: Text('You have not accepted any loads yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final load = jobs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.work_history, color: primaryColor),
                  title: Text(
                    'Load #${load.id} — ${load.product}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${load.from} → ${load.to}\n'
                    'Payment: ${formatOmaniRial(load.payment)}\n'
                    'Status: ${load.status}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'View details',
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => showLoadDetails(context, load),
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
