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
      body: FutureBuilder<Map<String, int>>(
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
                    ),
                    _buildAdminCard(
                      Icons.business,
                      'Traders',
                      '${metrics['traders']}',
                      Colors.green,
                    ),
                    _buildAdminCard(
                      Icons.local_shipping,
                      'Drivers',
                      '${metrics['drivers']}',
                      Colors.orange,
                    ),
                    _buildAdminCard(
                      Icons.shopping_cart,
                      'Active Orders',
                      '${metrics['activeLoads']}',
                      Colors.purple,
                    ),
                  ],
                ),
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
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      ),
    );
  }
}

Future<Map<String, int>> _loadAdminMetrics() async {
  final db = Supabase.instance.client;
  final profiles = await db.from('profiles').select('user_type');
  final loads = await db.from('loads').select('status');
  final users = List<Map<String, dynamic>>.from(profiles);
  final jobs = List<Map<String, dynamic>>.from(loads);
  return {
    'users': users.length,
    'traders': users.where((u) => u['user_type'] == 'Trader').length,
    'drivers': users.where((u) => u['user_type'] == 'Driver').length,
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
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  late Future<List<Map<String, dynamic>>> _users = _loadUsers();

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
          final users = snapshot.data ?? [];
          if (users.isEmpty)
            return const Center(child: Text('No users found.'));
          return RefreshIndicator(
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
                    leading: CircleAvatar(
                      child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
                    ),
                    title: Text(
                      name.isEmpty ? user['phone']?.toString() ?? 'User' : name,
                    ),
                    subtitle: Text(
                      '${user['user_type']} · ${active ? 'Active' : 'Suspended'}',
                    ),
                    trailing: Switch(
                      value: active,
                      onChanged:
                          user['id'] ==
                              Supabase.instance.client.auth.currentUser?.id
                          ? null
                          : (value) => _toggle(user, value),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
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
