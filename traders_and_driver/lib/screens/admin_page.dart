import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme_controller.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = const [
    AdminDashboard(),
    AdminUsersPage(),
    AdminReportsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF1A237E),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        user?.userMetadata?['full_name'] ?? user?.phone ?? 'Admin';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Panel',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [const ThemeToggleButton(), _resetPasswordButton(context), _logoutButton(context)],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadAdminMetrics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Apply supabase/schema.sql and confirm administrator access.\n\n${snapshot.error}',
                ),
              ),
            );
          final metrics = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $displayName',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _buildAdminCard(
                      Icons.person,
                      'Total Users',
                      '${metrics['users']}',
                      Colors.blue,
                      onTap: () => _openUsers(context),
                    ),
                    _buildAdminCard(
                      Icons.business,
                      'Traders',
                      '${metrics['traders']}',
                      Colors.green,
                      onTap: () => _openUsers(context, type: 'Trader'),
                    ),
                    _buildAdminCard(
                      Icons.local_shipping,
                      'Drivers',
                      '${metrics['drivers']}',
                      Colors.orange,
                      onTap: () => _openUsers(context, type: 'Driver'),
                    ),
                    _buildAdminCard(
                      Icons.shopping_cart,
                      'Active Orders',
                      '${metrics['activeLoads']}',
                      Colors.purple,
                      onTap: () => _openOrders(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
                  title: const Text('Marketplace order value'),
                  subtitle: Text('${metrics['orders']} total orders'),
                  trailing: Text('${_formatOmr(metrics['orderTotal'])} OMR', style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => _openOrders(context),
                )),
                const SizedBox(height: 24),
                Text(
                  'Marketplace activity',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: metrics['traders']!.toDouble(),
                          title: 'Traders',
                          color: Colors.green,
                          radius: 58,
                        ),
                        PieChartSectionData(
                          value: metrics['drivers']!.toDouble(),
                          title: 'Drivers',
                          color: Colors.orange,
                          radius: 58,
                        ),
                      ],
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

  Widget _logoutButton(BuildContext context) => IconButton(
    tooltip: 'Logout',
    icon: const Icon(Icons.logout),
    onPressed: () async {
      final shouldLogout = await _confirmLogout(context);
      if (shouldLogout != true || !context.mounted) return;
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    },
  );

  Widget _resetPasswordButton(BuildContext context) => IconButton(
    tooltip: 'Reset password',
    icon: const Icon(Icons.lock_reset),
    onPressed: () => Navigator.pushNamed(context, '/reset-password'),
  );

  Future<bool?> _confirmLogout(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('You will need to log in again to continue.'),
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

  Widget _buildAdminCard(
    IconData icon,
    String title,
    String value,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      )),
    );
  }

  void _openUsers(BuildContext context, {String? type}) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => AdminUsersPage(initialType: type)),
  );

  void _openOrders(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AdminOrdersPage()),
  );
}

String _formatOmr(dynamic amount) =>
    ((amount is num ? amount : num.tryParse('$amount')) ?? 0).toStringAsFixed(3);

Future<Map<String, dynamic>> _loadAdminMetrics() async {
  final db = Supabase.instance.client;
  final profiles = await db.from('profiles').select('user_type');
  final loads = await db.from('loads').select('status, price_omr');
  final users = List<Map<String, dynamic>>.from(profiles);
  final jobs = List<Map<String, dynamic>>.from(loads);
  return {
    'users': users.length,
    'traders': users.where((u) => u['user_type'] == 'Trader').length,
    'drivers': users.where((u) => u['user_type'] == 'Driver').length,
    'orders': jobs.length,
    'orderTotal': jobs.fold<num>(0, (sum, job) => sum + ((job['price_omr'] as num?) ?? 0)),
    'activeLoads': jobs
        .where(
          (job) =>
              job['status'] == 'Available' ||
              job['status'] == 'Accepted' ||
              job['status'] == 'In transit',
        )
        .length,
  };
}

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key, this.initialType});
  final String? initialType;

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  String _filter = 'All';
  String _query = '';
  final _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _users = _loadUsers();

  @override
  void initState() { super.initState(); _filter = widget.initialType ?? 'All'; }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<List<Map<String, dynamic>>> _loadUsers() async {
    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _toggle(Map<String, dynamic> user, bool active) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'is_active': active})
          .eq('id', user['id']);
      if (mounted) setState(() => _users = _loadUsers());
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update user: $error')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Users',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _users,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load users. Apply supabase/schema.sql and configure administrator access.\n\n${snapshot.error}',
                ),
              ),
            );
          final allUsers = snapshot.data ?? [];
          final users = allUsers.where((user) {
            final typeMatches = _filter == 'All' || user['user_type'] == _filter;
            final haystack = '${user['full_name'] ?? ''} ${user['phone'] ?? ''}'.toLowerCase();
            return typeMatches && haystack.contains(_query.toLowerCase());
          }).toList();
          return Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by name or phone', border: OutlineInputBorder()),
            )),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              for (final type in ['All', 'Trader', 'Driver', 'Admin'])
                Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(
                  label: Text('$type (${type == 'All' ? allUsers.length : allUsers.where((u) => u['user_type'] == type).length})'),
                  selected: _filter == type, onSelected: (_) => setState(() => _filter = type),
                )),
            ])),
            Expanded(child: users.isEmpty ? const Center(child: Text('No matching users.')) : RefreshIndicator(
            onRefresh: () async {
              setState(() => _users = _loadUsers());
              await _users;
            },
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final name = user['full_name']?.toString() ?? '';
                final active = user['is_active'] as bool? ?? true;
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    onTap: () => _showUserDetails(user),
                    leading: CircleAvatar(
                      child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
                    ),
                    title: Text(
                      name.isEmpty ? user['phone']?.toString() ?? 'User' : name,
                    ),
                    subtitle: Text(
                      '${user['user_type']} · ${active ? 'Active' : 'Suspended'}',
                    ),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Switch(value: active, onChanged: user['id'] == Supabase.instance.client.auth.currentUser?.id ? null : (value) => _toggle(user, value)),
                      const Icon(Icons.chevron_right),
                    ]),
                  ),
                );
              },
            ),
          )),
          ]);
        },
      ),
    );
  }

  Future<void> _showUserDetails(Map<String, dynamic> user) async {
    await showDialog<void>(context: context, builder: (_) => _AdminUserDialog(user: user));
    if (mounted) setState(() => _users = _loadUsers());
  }
}

class _AdminUserDialog extends StatefulWidget {
  const _AdminUserDialog({required this.user});
  final Map<String, dynamic> user;
  @override
  State<_AdminUserDialog> createState() => _AdminUserDialogState();
}

class _AdminUserDialogState extends State<_AdminUserDialog> {
  late final _name = TextEditingController(text: widget.user['full_name']?.toString() ?? '');
  late final _phone = TextEditingController(text: widget.user['phone']?.toString() ?? '');
  late String _type = widget.user['user_type']?.toString() ?? 'Trader';
  bool _saving = false;

  @override
  void dispose() { _name.dispose(); _phone.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('profiles').update({
        'full_name': _name.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'user_type': _type,
      }).eq('id', widget.user['id']);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save user: $error')));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('User details'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _detailLine('Account ID', '${widget.user['id']}'),
      _detailLine('Joined', '${widget.user['created_at'] ?? 'Unknown'}'),
      _detailLine('Last updated', '${widget.user['updated_at'] ?? 'Unknown'}'),
      const SizedBox(height: 12),
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
      TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
      DropdownButtonFormField<String>(value: _type, decoration: const InputDecoration(labelText: 'Account section'), items: const [DropdownMenuItem(value: 'Trader', child: Text('Trader')), DropdownMenuItem(value: 'Driver', child: Text('Driver')), DropdownMenuItem(value: 'Admin', child: Text('Admin'))], onChanged: widget.user['id'] == Supabase.instance.client.auth.currentUser?.id ? null : (value) { if (value != null) setState(() => _type = value); }),
      const SizedBox(height: 12),
      FutureBuilder<List<Map<String, dynamic>>>(future: _loadUserOrders('${widget.user['id']}'), builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
        if (snapshot.hasError) return Text('Order history unavailable: ${snapshot.error}');
        final orders = snapshot.data ?? [];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Order history (${orders.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
          for (final order in orders.take(5)) Text('#${order['id']} | ${order['product']} | ${order['status']} | ${_formatOmr(order['price_omr'])} OMR'),
        ]);
      }),
    ])),
    actions: [TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Close')), FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving...' : 'Save changes'))],
  );
}

Widget _detailLine(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('$label: $value', style: const TextStyle(fontSize: 12)));

Future<List<Map<String, dynamic>>> _loadUserOrders(String id) async {
  final result = await Supabase.instance.client.from('loads').select().or('trader_id.eq.$id,driver_id.eq.$id').order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(result);
}

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Marketplace orders'), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client.from('loads').select().order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Could not load orders: ${snapshot.error}'));
        final orders = snapshot.data ?? [];
        final total = orders.fold<num>(0, (sum, order) => sum + ((order['price_omr'] as num?) ?? 0));
        return Column(children: [
          Card(margin: const EdgeInsets.all(12), child: ListTile(title: Text('${orders.length} total orders'), subtitle: const Text('Combined order value'), trailing: Text('${_formatOmr(total)} OMR', style: const TextStyle(fontWeight: FontWeight.bold)))),
          Expanded(child: ListView.builder(itemCount: orders.length, itemBuilder: (context, index) {
            final order = orders[index];
            return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.local_shipping)),
              title: Text('#${order['id']} | ${order['product']}'),
              subtitle: Text('${order['status']} | ${order['pickup_location']} to ${order['delivery_location']}\nTrader ${order['trader_id']} | Driver ${order['driver_id'] ?? 'Unassigned'}'),
              isThreeLine: true,
              trailing: Text('${_formatOmr(order['price_omr'])} OMR'),
            ));
          })),
        ]);
      },
    ),
  );
}

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reports',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Supabase.instance.client.from('profiles').select('user_type'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
              child: Text(
                'Could not load report data. Apply supabase/schema.sql.\n${snapshot.error}',
              ),
            );
          final users = snapshot.data ?? [];
          final traders = users.where((u) => u['user_type'] == 'Trader').length;
          final drivers = users.where((u) => u['user_type'] == 'Driver').length;
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.insert_chart,
                    size: 80,
                    color: Color(0xFF1A237E),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Registered users: ${users.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Traders: $traders  ·  Drivers: $drivers',
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 220,
                    width: 300,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: traders == 0 && drivers == 0
                                ? 1
                                : traders.toDouble(),
                            title: 'Traders $traders',
                            color: Colors.green,
                            radius: 58,
                          ),
                          PieChartSectionData(
                            value: traders == 0 && drivers == 0
                                ? 1
                                : drivers.toDouble(),
                            title: 'Drivers $drivers',
                            color: Colors.orange,
                            radius: 58,
                          ),
                        ],
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
}
