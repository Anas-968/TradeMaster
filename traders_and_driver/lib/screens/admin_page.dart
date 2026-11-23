import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme_controller.dart';
import '../language_controller.dart';
import 'support_chat_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;
  List<Widget> get _pages => [
    AdminDashboard(),
    AdminUsersPage(),
    AdminReportsPage(),
    SupportChatPage(),
  ];

  @override
  void initState() {
    super.initState();
    AppLanguageController.instance.addListener(_onLanguageChanged);
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppLanguageController.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

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
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: appText('Dashboard'),
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: appText('Users')),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: appText('Reports'),
          ),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: appText('Support')),
        ],
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<Map<String, dynamic>> _metrics = _loadAdminMetrics();

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        user?.userMetadata?['full_name'] ?? user?.phone ?? 'Admin';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          appText('Admin Panel'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: appText('Refresh'),
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _metrics = _loadAdminMetrics();
              });
            },
          ),
          _resetPasswordButton(context),
          _logoutButton(context),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _metrics,
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
                  '${appText('Welcome, ')}$displayName',
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
                  childAspectRatio: 1.1,
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
                const SizedBox(height: 24),
                Text(
                  appText('Marketplace activity'),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.payments_outlined),
                        ),
                        title: Text(appText('Marketplace order value')),
                        subtitle: Text('${metrics['orders']} total loads'),
                        trailing: Text(
                          '${_formatOmr(metrics['orderTotal'])} OMR',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => _openOrders(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.local_shipping_outlined),
                        title: Text(appText('Active loads')),
                        trailing: Text(
                          '${metrics['activeLoads']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => _openOrders(context),
                      ),
                      ListTile(
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text(appText('Delivered loads')),
                        trailing: Text(
                          '${metrics['deliveredLoads']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => _openOrders(context),
                      ),
                      ListTile(
                        leading: const Icon(Icons.pending_actions),
                        title: Text(appText('Unassigned loads')),
                        trailing: Text(
                          '${metrics['unassignedLoads']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => _openOrders(context),
                      ),
                    ],
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
    tooltip: appText('Logout'),
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
    tooltip: appText('Reset password'),
    icon: const Icon(Icons.lock_reset),
    onPressed: () => Navigator.pushNamed(context, '/reset-password'),
  );

  Future<bool?> _confirmLogout(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(appText('Log out?')),
      content: Text(appText('You will need to log in again to continue.')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(appText('Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(appText('Log out')),
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
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 5),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                appText(title),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openUsers(BuildContext context, {String? type}) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => AdminUsersPage(initialType: type)));

  void _openOrders(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AdminOrdersPage()));
}

String _formatOmr(dynamic amount) =>
    ((amount is num ? amount : num.tryParse('$amount')) ?? 0).toStringAsFixed(
      3,
    );

Future<Map<String, dynamic>> _loadAdminMetrics() async {
  final db = Supabase.instance.client;
  final profiles = await db.from('profiles').select('user_type');
  final loads = await db.from('loads').select('status, price_omr, driver_id');
  final users = List<Map<String, dynamic>>.from(profiles);
  final jobs = List<Map<String, dynamic>>.from(loads);
  return {
    'users': users.length,
    'traders': users.where((u) => u['user_type'] == 'Trader').length,
    'drivers': users.where((u) => u['user_type'] == 'Driver').length,
    'orders': jobs.length,
    'orderTotal': jobs.fold<num>(
      0,
      (sum, job) => sum + ((job['price_omr'] as num?) ?? 0),
    ),
    'activeLoads': jobs
        .where(
          (job) =>
              job['status'] == 'Available' ||
              job['status'] == 'Accepted' ||
              job['status'] == 'In transit',
        )
        .length,
    'deliveredLoads': jobs.where((job) => job['status'] == 'Delivered').length,
    'unassignedLoads': jobs
        .where(
          (job) => job['driver_id'] == null && job['status'] == 'Available',
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
  void initState() {
    super.initState();
    _filter = widget.initialType ?? 'All';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      final usersFuture = _loadUsers();
      if (mounted) {
        setState(() {
          _users = usersFuture;
        });
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${appText('Could not update user: ')}$error')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          appText('Manage Users'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
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
            final typeMatches =
                _filter == 'All' || user['user_type'] == _filter;
            final haystack = '${user['full_name'] ?? ''} ${user['phone'] ?? ''}'
                .toLowerCase();
            return typeMatches && haystack.contains(_query.toLowerCase());
          }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: appText('Search by name or phone'),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final type in ['All', 'Trader', 'Driver', 'Admin'])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(
                            '$type (${type == 'All' ? allUsers.length : allUsers.where((u) => u['user_type'] == type).length})',
                          ),
                          selected: _filter == type,
                          onSelected: (_) => setState(() => _filter = type),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: users.isEmpty
                    ? Center(child: Text(appText('No matching users.')))
                    : RefreshIndicator(
                        onRefresh: () async {
                          final usersFuture = _loadUsers();
                          setState(() {
                            _users = usersFuture;
                          });
                          await usersFuture;
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
                                  child: Text(
                                    name.isEmpty ? '?' : name[0].toUpperCase(),
                                  ),
                                ),
                                title: Text(
                                  name.isEmpty
                                      ? user['phone']?.toString() ?? 'User'
                                      : name,
                                ),
                                subtitle: Text(
                                  '${user['user_type']} · ${active ? 'Active' : 'Suspended'}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Switch(
                                      value: active,
                                      onChanged:
                                          user['id'] ==
                                              Supabase
                                                  .instance
                                                  .client
                                                  .auth
                                                  .currentUser
                                                  ?.id
                                          ? null
                                          : (value) => _toggle(user, value),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showUserDetails(Map<String, dynamic> user) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AdminUserDialog(user: user),
    );
    if (mounted) {
      final usersFuture = _loadUsers();
      setState(() {
        _users = usersFuture;
      });
    }
  }
}

class _AdminUserDialog extends StatefulWidget {
  const _AdminUserDialog({required this.user});
  final Map<String, dynamic> user;
  @override
  State<_AdminUserDialog> createState() => _AdminUserDialogState();
}

class _AdminUserDialogState extends State<_AdminUserDialog> {
  late final _name = TextEditingController(
    text: widget.user['full_name']?.toString() ?? '',
  );
  late final _phone = TextEditingController(
    text: widget.user['phone']?.toString() ?? '',
  );
  late String _type = widget.user['user_type']?.toString() ?? 'Trader';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'full_name': _name.text.trim(),
            'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            'user_type': _type,
          })
          .eq('id', widget.user['id']);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${appText('Could not save user: ')}$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(appText('User details')),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailLine('Account ID', '${widget.user['id']}'),
          _detailLine('Joined', '${widget.user['created_at'] ?? 'Unknown'}'),
          _detailLine(
            'Last updated',
            '${widget.user['updated_at'] ?? 'Unknown'}',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: appText('Full name')),
          ),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: appText('Phone')),
          ),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: InputDecoration(labelText: appText('Account section')),
            items: [
              DropdownMenuItem(value: 'Trader', child: Text(appText('Trader'))),
              DropdownMenuItem(value: 'Driver', child: Text(appText('Driver'))),
              DropdownMenuItem(value: 'Admin', child: Text(appText('Admin'))),
            ],
            onChanged:
                widget.user['id'] ==
                    Supabase.instance.client.auth.currentUser?.id
                ? null
                : (value) {
                    if (value != null) setState(() => _type = value);
                  },
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadUserOrders('${widget.user['id']}'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const LinearProgressIndicator();
              if (snapshot.hasError)
                return Text('${appText('Order history unavailable: ')}${snapshot.error}');
              final orders = snapshot.data ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order history (${orders.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  for (final order in orders.take(5))
                    Text(
                      '#${order['id']} | ${order['product']} | ${order['status']} | ${_formatOmr(order['price_omr'])} OMR',
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: Text(appText('Close')),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Saving...' : 'Save changes'),
      ),
    ],
  );
}

Widget _detailLine(String label, String value) => Padding(
  padding: const EdgeInsets.only(bottom: 4),
  child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
);

Future<List<Map<String, dynamic>>> _loadUserOrders(String id) async {
  final result = await Supabase.instance.client
      .from('loads')
      .select()
      .or('trader_id.eq.$id,driver_id.eq.$id')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(result);
}

Future<List<Map<String, dynamic>>> _loadOrdersWithProfiles() async {
  final response = await Supabase.instance.client
      .from('loads')
      .select()
      .order('created_at', ascending: false);
  final orders = List<Map<String, dynamic>>.from(response);
  final profileIds = <String>{};
  for (final order in orders) {
    profileIds.add('${order['trader_id']}');
    final driverId = order['driver_id'];
    if (driverId != null) profileIds.add('$driverId');
  }
  if (profileIds.isEmpty) return orders;

  final profileRows = await Supabase.instance.client
      .from('profiles')
      .select('id, full_name, phone')
      .inFilter('id', profileIds.toList());
  final profiles = {
    for (final profile in profileRows) '${profile['id']}': profile,
  };
  for (final order in orders) {
    order['trader_profile'] = profiles['${order['trader_id']}'];
    final driverId = order['driver_id'];
    order['driver_profile'] = driverId == null ? null : profiles['$driverId'];
  }
  return orders;
}

String _contactName(dynamic profile) {
  if (profile is! Map) return appText('Unknown');
  final name = profile['full_name']?.toString().trim() ?? '';
  return name.isEmpty ? 'Unnamed user' : name;
}

String _contactPhone(dynamic profile) {
  if (profile is! Map) return appText('No phone number');
  final phone = profile['phone']?.toString().trim() ?? '';
  return phone.isEmpty ? 'No phone number' : phone;
}

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(appText('Marketplace orders')),
      backgroundColor: const Color(0xFF1A237E),
      foregroundColor: Colors.white,
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadOrdersWithProfiles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: Text('${appText('Could not load orders: ')}${snapshot.error}'),
          );
        final orders = snapshot.data ?? [];
        final total = orders.fold<num>(
          0,
          (sum, order) => sum + ((order['price_omr'] as num?) ?? 0),
        );
        return Column(
          children: [
            Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                title: Text('${orders.length} total orders'),
                subtitle: Text(appText('Combined order value')),
                trailing: Text(
                  '${_formatOmr(total)} OMR',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.local_shipping),
                      ),
                      title: Text('#${order['id']} | ${order['product']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order['status']} | ${order['pickup_location']} to ${order['delivery_location']}',
                          ),
                          Text(
                            '${appText('Trader: ')}${_contactName(order['trader_profile'])} | Phone: ${_contactPhone(order['trader_profile'])}',
                          ),
                          Text(
                            order['driver_id'] == null
                                ? 'Accepted driver: Not assigned'
                                : 'Accepted driver: ${_contactName(order['driver_profile'])} | Phone: ${_contactPhone(order['driver_profile'])}',
                          ),
                        ],
                      ),
                      trailing: Text('${_formatOmr(order['price_omr'])} OMR'),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  late Future<_ReportData> _report = _loadDriverReports();

  Future<void> _refresh() async {
    final next = _loadDriverReports();
    setState(() {
      _report = next;
    });
    try {
      await next;
    } catch (_) {
      // The FutureBuilder shows the error.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        appText('Reports'),
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color(0xFF1A237E),
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          tooltip: appText('Refresh'),
          icon: const Icon(Icons.refresh),
          onPressed: _refresh,
        ),
      ],
    ),
    body: FutureBuilder<_ReportData>(
      future: _report,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Could not load driver reports. Apply supabase/schema.sql and confirm administrator access.\n\n${snapshot.error}',
                  ),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _refresh, child: Text(appText('Retry'))),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data!;
        final drivers = data.drivers;
        final allLoads = drivers.expand(_loadsOf).toList();
        final delivered = allLoads
            .where((load) => load['status'] == 'Delivered')
            .length;
        final totalValue = allLoads.fold<num>(
          0,
          (sum, load) => sum + ((load['price_omr'] as num?) ?? 0),
        );
        final hasAccounts = data.traderCount + drivers.length > 0;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                appText('Driver activity'),
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                appText('Load history and performance for every registered driver.'),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appText('Account mix'),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      if (hasAccounts)
                        SizedBox(
                          height: 190,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 36,
                              sections: [
                                if (data.traderCount > 0)
                                  PieChartSectionData(
                                    value: data.traderCount.toDouble(),
                                    title: 'Traders ${data.traderCount}',
                                    color: Colors.green,
                                    radius: 52,
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                if (drivers.isNotEmpty)
                                  PieChartSectionData(
                                    value: drivers.length.toDouble(),
                                    title: 'Drivers ${drivers.length}',
                                    color: Colors.orange,
                                    radius: 52,
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(appText('No traders or drivers yet.')),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Text('${appText('Traders: ')}${data.traderCount}'),
                          Text('${appText('Drivers: ')}${drivers.length}'),
                          Text('${appText('Assigned loads: ')}${allLoads.length}'),
                          Text('${appText('Delivered: ')}$delivered'),
                          Text('${appText('Load value: ')}${_formatOmr(totalValue)} OMR'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (drivers.isEmpty)
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(appText('No drivers registered yet.')),
                  ),
                ),
              for (final driver in drivers) _DriverReportCard(driver: driver),
            ],
          ),
        );
      },
    ),
  );
}

class _ReportData {
  const _ReportData({required this.drivers, required this.traderCount});
  final List<Map<String, dynamic>> drivers;
  final int traderCount;
}

List<Map<String, dynamic>> _loadsOf(Map<String, dynamic> driver) {
  final raw = driver['loads'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((load) => Map<String, dynamic>.from(load))
      .toList();
}

Future<_ReportData> _loadDriverReports() async {
  final db = Supabase.instance.client;
  final profileRows = await db
      .from('profiles')
      .select('id, full_name, phone, user_type, is_active')
      .inFilter('user_type', ['Trader', 'Driver']);
  final profiles = profileRows
      .map((row) => Map<String, dynamic>.from(row))
      .toList();
  final drivers = profiles
      .where((profile) => profile['user_type'] == 'Driver')
      .toList();
  final traderCount = profiles
      .where((profile) => profile['user_type'] == 'Trader')
      .length;

  final loadsByDriver = <String, List<Map<String, dynamic>>>{};
  if (drivers.isNotEmpty) {
    final driverIds = drivers.map((driver) => '${driver['id']}').toList();
    final loadRows = await db
        .from('loads')
        .select()
        .inFilter('driver_id', driverIds)
        .order('created_at', ascending: false);
    for (final row in loadRows) {
      final load = Map<String, dynamic>.from(row);
      loadsByDriver
          .putIfAbsent('${load['driver_id']}', () => <Map<String, dynamic>>[])
          .add(load);
    }
  }
  for (final driver in drivers) {
    driver['loads'] =
        loadsByDriver['${driver['id']}'] ?? <Map<String, dynamic>>[];
  }
  return _ReportData(drivers: drivers, traderCount: traderCount);
}

String _driverName(Map<String, dynamic> driver, String fallback) {
  final name = driver['full_name']?.toString().trim() ?? '';
  if (name.isNotEmpty) return name;
  final phone = driver['phone']?.toString().trim() ?? '';
  return phone.isNotEmpty ? phone : fallback;
}

bool _isActiveLoad(Map<String, dynamic> load) =>
    load['status'] == 'Accepted' || load['status'] == 'In transit';

class _DriverReportCard extends StatelessWidget {
  const _DriverReportCard({required this.driver});
  final Map<String, dynamic> driver;

  @override
  Widget build(BuildContext context) {
    final loads = _loadsOf(driver);
    final name = _driverName(driver, 'Unnamed driver');
    final completed = loads
        .where((load) => load['status'] == 'Delivered')
        .length;
    final active = loads.where(_isActiveLoad).length;
    final value = loads.fold<num>(
      0,
      (sum, load) => sum + ((load['price_omr'] as num?) ?? 0),
    );
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
        ),
        title: Text(name),
        subtitle: Text(
          '${loads.length} loads - $completed delivered - $active active - ${_formatOmr(value)} OMR',
        ),
        children: [
          if (loads.isEmpty)
            ListTile(title: Text(appText('No assigned loads yet'))),
          for (final load in loads)
            ListTile(
              dense: true,
              isThreeLine: true,
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text('#${load['id']} ${load['product'] ?? 'Load'}'),
              subtitle: Text(
                '${load['pickup_location'] ?? 'Unknown'} to ${load['delivery_location'] ?? 'Unknown'} - ${load['status'] ?? 'Unknown'}\nWeight: ${load['weight'] ?? 'Unknown'} - Created: ${_reportDate(load['created_at'])}',
              ),
              trailing: Text('${_formatOmr(load['price_omr'])} OMR'),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: TextButton.icon(
                onPressed: () => _downloadDriverReport(context, driver),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(appText('Print / Download PDF')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _reportDate(dynamic value) {
  final date = DateTime.tryParse('$value')?.toLocal();
  if (date == null) return appText('Unknown');
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

Future<void> _downloadDriverReport(
  BuildContext context,
  Map<String, dynamic> driver,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final loads = _loadsOf(driver);
    final name = _driverName(driver, 'Driver');
    final delivered = loads
        .where((load) => load['status'] == 'Delivered')
        .length;
    final active = loads.where(_isActiveLoad).length;
    final total = loads.fold<num>(
      0,
      (sum, load) => sum + ((load['price_omr'] as num?) ?? 0),
    );
    final isActive = driver['is_active'] as bool? ?? true;
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        build: (pw.Context pdfContext) => <pw.Widget>[
          pw.Text(
            'Driver Activity Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Driver: $name'),
          pw.Text('Phone: ${driver['phone'] ?? 'Not provided'}'),
          pw.Text('Account status: ${isActive ? 'Active' : 'Suspended'}'),
          pw.Text(
            'Report generated: ${_reportDate(DateTime.now().toIso8601String())}',
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Loads: ${loads.length} | Delivered: $delivered | Active: $active | Total load value: ${_formatOmr(total)} OMR',
          ),
          pw.SizedBox(height: 16),
          if (loads.isEmpty) pw.Text('No loads assigned to this driver.'),
          if (loads.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: <String>[
                'ID / Product',
                'Route',
                'Status',
                'Weight',
                'OMR',
                'Created',
              ],
              data: loads
                  .map(
                    (load) => <String>[
                      '#${load['id']} ${load['product'] ?? ''}',
                      '${load['pickup_location'] ?? ''} to ${load['delivery_location'] ?? ''}',
                      '${load['status'] ?? ''}',
                      '${load['weight'] ?? ''}',
                      _formatOmr(load['price_omr']),
                      _reportDate(load['created_at']),
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 8),
            ),
        ],
      ),
    );
    final bytes = await document.save();
    final slug = '${driver['full_name'] ?? driver['id']}'.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    await Printing.layoutPdf(
      name: 'driver_${slug}_report.pdf',
      onLayout: (_) async => bytes,
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('${appText('Could not create PDF: ')}$error')),
    );
  }
}
