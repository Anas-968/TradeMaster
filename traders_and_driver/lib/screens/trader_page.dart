import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme_controller.dart';
import 'admin_page.dart';

class TraderPage extends StatefulWidget {
  const TraderPage({super.key});

  @override
  State<TraderPage> createState() => _TraderPageState();
}

class _TraderPageState extends State<TraderPage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const TraderDashboard(),
    const AddProductPage(),
    const TraderProductsPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectAdmin());
  }

  Future<void> _redirectAdmin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('user_type')
          .eq('id', user.id)
          .maybeSingle();
      final profileRole = (profile?['user_type'] as String?)
          ?.trim()
          .toLowerCase();
      final adminFlag = user.appMetadata['is_admin'];
      final isAdmin = profileRole == 'admin' ||
          adminFlag == true ||
          adminFlag?.toString().toLowerCase() == 'true';
      if (isAdmin && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const AdminPage()),
          (route) => false,
        );
      }
    } catch (error) {
      debugPrint('Could not verify role on TraderPage: $error');
    }
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Add Product',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'My Products',
          ),
        ],
      ),
    );
  }
}

class TraderDashboard extends StatelessWidget {
  const TraderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final displayName =
        user?.userMetadata?['full_name'] ?? user?.phone ?? 'Trader';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trader Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [const ThemeToggleButton(), _resetPasswordButton(context), _logoutButton(context)],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: user == null
            ? Future.value([])
            : Supabase.instance.client
                  .from('loads')
                  .select()
                  .eq('trader_id', user.id)
                  .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load dashboard data: ${snapshot.error}'),
              ),
            );
          final loads = snapshot.data ?? [];
          final activeLoads = loads
              .where(
                (load) =>
                    load['status'] == 'Accepted' ||
                    load['status'] == 'In transit',
              )
              .length;
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
                const SizedBox(height: 8),
                Text(
                  'Manage your products and find drivers',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                  children: [
                    _buildStatCard(
                      Icons.inventory,
                      'Total Products',
                      '${loads.length}',
                      Colors.blue,
                    ),
                    _buildStatCard(
                      Icons.local_shipping,
                      'Active Deliveries',
                      '$activeLoads',
                      Colors.green,
                    ),
                    _buildStatCard(
                      Icons.attach_money,
                      'Delivered Loads',
                      '${loads.where((load) => load['status'] == 'Delivered').length}',
                      Colors.orange,
                    ),
                    _buildStatCard(
                      Icons.people,
                      'Loads Accepted',
                      '${loads.where((load) => load['driver_id'] != null).length}',
                      Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Recent Loads',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: loads.take(5).length,
                  itemBuilder: (context, index) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(
                        Icons.shopping_bag,
                        color: Color(0xFF1A237E),
                      ),
                      title: Text(
                        'Load #${loads[index]['id']} · ${loads[index]['product']}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${loads[index]['pickup_location']} → ${loads[index]['delivery_location']}',
                      ),
                      trailing: Chip(
                        label: Text(loads[index]['status'].toString()),
                        backgroundColor: Colors.orangeAccent,
                      ),
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

  Widget _buildStatCard(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _product = TextEditingController();
  final _description = TextEditingController();
  final _pickup = TextEditingController();
  final _delivery = TextEditingController();
  final _weight = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _product.dispose();
    _description.dispose();
    _pickup.dispose();
    _delivery.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _postLoad() async {
    if (!_formKey.currentState!.validate()) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('loads').insert({
        'trader_id': user.id,
        'product': _product.text.trim(),
        'description': _description.text.trim(),
        'pickup_location': _pickup.text.trim(),
        'delivery_location': _delivery.text.trim(),
        'weight': _weight.text.trim(),
      });
      for (final controller in [
        _product,
        _description,
        _pickup,
        _delivery,
        _weight,
      ]) {
        controller.clear();
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Load posted. Drivers can now accept it.'),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not post load: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Product',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _field(_product, 'Product name'),
                const SizedBox(height: 16),
                _field(
                  _description,
                  'Description',
                  required: false,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _field(_pickup, 'Pickup location'),
                const SizedBox(height: 16),
                _field(_delivery, 'Delivery location'),
                const SizedBox(height: 16),
                _field(_weight, 'Load weight'),
                const SizedBox(height: 16),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _postLoad,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _saving ? 'Posting…' : 'Post Load',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
    bool number = false,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    keyboardType: number
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    maxLines: maxLines,
    validator: (value) {
      if (required && (value == null || value.trim().isEmpty))
        return 'Enter $label';
      if (number &&
          (double.tryParse(value ?? '') == null || double.parse(value!) < 0))
        return 'Enter a valid amount';
      return null;
    },
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class TraderProductsPage extends StatefulWidget {
  const TraderProductsPage({super.key});

  @override
  State<TraderProductsPage> createState() => _TraderProductsPageState();
}

class _TraderProductsPageState extends State<TraderProductsPage> {
  Future<List<Map<String, dynamic>>> _loadRows() async =>
      await Supabase.instance.client.from('loads').select()
          .eq('trader_id', Supabase.instance.client.auth.currentUser!.id)
          .order('created_at', ascending: false);

  late Future<List<Map<String, dynamic>>> _rows = _loadRows();

  Future<void> _edit(Map<String, dynamic> load) async {
    final fields = [
      TextEditingController(text: load['product']?.toString()),
      TextEditingController(text: load['description']?.toString()),
      TextEditingController(text: load['pickup_location']?.toString()),
      TextEditingController(text: load['delivery_location']?.toString()),
      TextEditingController(text: load['weight']?.toString()),
    ];
    final labels = ['Product', 'Description', 'Pickup location', 'Delivery location', 'Weight'];
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text('Edit load #${load['id']}'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < fields.length; i++) Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(controller: fields[i], maxLines: i == 1 ? 3 : 1,
            decoration: InputDecoration(labelText: labels[i], border: const OutlineInputBorder())),
        ),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save'))],
    ));
    if (confirmed == true) {
      try {
        await Supabase.instance.client.rpc('update_available_load', params: {
          'p_load_id': load['id'], 'p_product': fields[0].text.trim(),
          'p_description': fields[1].text.trim(), 'p_pickup_location': fields[2].text.trim(),
          'p_delivery_location': fields[3].text.trim(), 'p_weight': fields[4].text.trim(),
        });
        setState(() => _rows = _loadRows());
      } catch (e) { _message('Could not update load: $e'); }
    }
    for (final field in fields) { field.dispose(); }
  }

  Future<void> _delete(Map<String, dynamic> load) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete this load?'),
      content: Text('Load #${load['id']} will be removed if no driver has accepted it.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))],
    ));
    if (confirmed != true) return;
    try {
      await Supabase.instance.client.rpc('delete_available_load', params: {'p_load_id': load['id']});
      setState(() => _rows = _loadRows());
    } catch (e) { _message('Could not delete load: $e'); }
  }

  void _message(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Products',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _rows,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
              child: Text('Could not load your posts: ${snapshot.error}'),
            );
          final rows = snapshot.data ?? [];
          if (rows.isEmpty)
            return const Center(
              child: Text('You have not posted any loads yet.'),
            );
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final load = rows[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(
                    Icons.local_shipping,
                    color: Color(0xFF1A237E),
                  ),
                  title: Text(load['product']?.toString() ?? 'Load'),
                  subtitle: Text(
                    '${load['pickup_location']} → ${load['delivery_location']}\n${load['status']}',
                  ),
                  isThreeLine: true,
                  trailing: load['status'] == 'Available'
                      ? PopupMenuButton<String>(
                          onSelected: (action) => action == 'edit' ? _edit(load) : _delete(load),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
