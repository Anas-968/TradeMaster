import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme_controller.dart';
import '../language_controller.dart';
import 'admin_page.dart';
import 'assistant_chat_page.dart';

const List<String> omanLocations = [
  'Muscat',
  'Muttrah',
  'Seeb',
  'Bawshar',
  'Al Amarat',
  'Quriyat',
  'Salalah',
  'Sohar',
  'Shinas',
  'Liwa',
  'Saham',
  'Al Khaburah',
  'Suwaiq',
  'Barka',
  'Rustaq',
  'Nakhal',
  'Nizwa',
  'Bahla',
  'Izki',
  'Adam',
  'Ibra',
  'Sur',
  'Bidiyah',
  'Al Mudhaibi',
  'Ibri',
  'Yanqul',
  'Buraimi',
  'Khasab',
  'Dibba',
  'Haima',
  'Duqm',
  'Mahout',
];
const List<String> demoPaymentMethods = [
  'Cash on delivery',
  'Bank transfer',
  'Card (demo)',
  'Mobile wallet (demo)',
];

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
    const AssistantChatPage(),
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
      final isAdmin =
          profileRole == 'admin' ||
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
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'AI Help',
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
          appText('Trader Dashboard'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          const ThemeToggleButton(),
          _resetPasswordButton(context),
          _logoutButton(context),
        ],
      ),
      body: user == null
          ? Center(child: Text(appText('Sign in to view your dashboard.')))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('loads')
                  .stream(primaryKey: ['id'])
                  .eq('trader_id', user.id)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError)
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load dashboard data: ${snapshot.error}',
                      ),
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
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, $displayName',
                                  style: GoogleFonts.poppins(
                                    fontSize: 23,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A237E),
                                  ),
                                ),
                                Text(
                                  'Here is what is happening with your orders.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2E7D32),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'LIVE',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                            'Total Orders',
                            '${loads.length}',
                            Colors.blue,
                            onTap: () => _openTraderLoads(
                              context,
                              'Total Orders',
                              loads,
                            ),
                          ),
                          _buildStatCard(
                            Icons.local_shipping,
                            'Active Deliveries',
                            '$activeLoads',
                            Colors.green,
                            onTap: () => _openTraderLoads(
                              context,
                              'Active Deliveries',
                              loads
                                  .where(
                                    (load) =>
                                        load['status'] == 'Accepted' ||
                                        load['status'] == 'In transit',
                                  )
                                  .toList(),
                            ),
                          ),
                          _buildStatCard(
                            Icons.attach_money,
                            'Delivered Loads',
                            '${loads.where((load) => load['status'] == 'Delivered').length}',
                            Colors.orange,
                            onTap: () => _openTraderLoads(
                              context,
                              'Delivered Loads',
                              loads
                                  .where(
                                    (load) => load['status'] == 'Delivered',
                                  )
                                  .toList(),
                            ),
                          ),
                          _buildStatCard(
                            Icons.people,
                            'Loads Accepted',
                            '${loads.where((load) => load['driver_id'] != null).length}',
                            Colors.purple,
                            onTap: () => _openTraderLoads(
                              context,
                              'Loads Accepted',
                              loads
                                  .where((load) => load['driver_id'] != null)
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Real-Time Activity',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (loads.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No order activity yet. Post a load to get started.',
                            ),
                          ),
                        )
                      else
                        ...loads
                            .take(8)
                            .map((load) => _activityCard(context, load)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _activityCard(BuildContext context, Map<String, dynamic> load) {
    final status = load['status']?.toString() ?? 'Available';
    final (icon, color, update) = switch (status) {
      'Accepted' => (
        Icons.person_add_alt_1,
        const Color(0xFF1565C0),
        'A driver accepted this order',
      ),
      'In transit' => (
        Icons.local_shipping_outlined,
        const Color(0xFFEF6C00),
        'Your order is on the way',
      ),
      'Delivered' => (
        Icons.task_alt,
        const Color(0xFF2E7D32),
        'Order delivered successfully',
      ),
      _ => (
        Icons.inventory_2_outlined,
        const Color(0xFF5E35B1),
        'Order posted and open to drivers',
      ),
    };
    final timestampValue = status == 'Delivered'
        ? load['delivered_at']
        : (status == 'Accepted' || status == 'In transit'
              ? load['accepted_at']
              : load['created_at']);
    final created = DateTime.tryParse(
      timestampValue?.toString() ?? '',
    )?.toLocal();
    final timestamp = created == null
        ? 'Recently'
        : '${created.day.toString().padLeft(2, '0')}/${created.month.toString().padLeft(2, '0')}/${created.year} · ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: load['driver_id'] == null
            ? CircleAvatar(
                backgroundColor: color.withValues(alpha: .12),
                child: Icon(icon, color: color),
              )
            : InkWell(
                onTap: () => _showDriverDetails(context, load),
                borderRadius: BorderRadius.circular(24),
                child: CircleAvatar(
                  backgroundColor: color.withValues(alpha: .12),
                  child: Icon(Icons.person_outline, color: color),
                ),
              ),
        title: Text(
          'Load #${load['id']} · ${load['product'] ?? 'Order'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(update, style: GoogleFonts.poppins(fontSize: 12)),
              Text(
                '${load['pickup_location'] ?? 'Pickup'} to ${load['delivery_location'] ?? 'Delivery'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                timestamp,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        trailing: Chip(
          label: Text(status),
          backgroundColor: color.withValues(alpha: .12),
          labelStyle: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _showDriverDetails(
    BuildContext context,
    Map<String, dynamic> load,
  ) async {
    final driverId = load['driver_id']?.toString();
    if (driverId == null) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => FutureBuilder<Map<String, dynamic>?>(
        future: Supabase.instance.client
            .rpc('get_load_driver_details', params: {'p_load_id': load['id']})
            .then(
              (data) =>
                  data == null ? null : Map<String, dynamic>.from(data as Map),
            ),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final fullName = profile?['full_name']?.toString().trim() ?? '';
          return AlertDialog(
            title: const Text('Driver details'),
            content: snapshot.connectionState == ConnectionState.waiting
                ? const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : snapshot.hasError
                ? Text('Could not load driver details: ${snapshot.error}')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _driverInfoRow(
                        Icons.person_outline,
                        'Name',
                        fullName.isEmpty ? 'Driver' : fullName,
                      ),
                      const SizedBox(height: 12),
                      _driverInfoRow(
                        Icons.phone_outlined,
                        'Phone',
                        profile?['phone']?.toString() ?? 'Not provided',
                      ),
                      const SizedBox(height: 12),
                      _driverInfoRow(
                        Icons.local_shipping_outlined,
                        'Load',
                        '#${load['id']} - ${load['product'] ?? 'Order'}',
                      ),
                      if (load['accepted_at'] != null) ...[
                        const SizedBox(height: 12),
                        _driverInfoRow(
                          Icons.schedule,
                          'Accepted',
                          _formatLoadDate(load['accepted_at']),
                        ),
                      ],
                    ],
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _driverInfoRow(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: const Color(0xFF1A237E)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ],
  );

  String _formatLoadDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'Recently';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
    Color color, {
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTraderLoads(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> loads,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TraderLoadsPage(title: title, loads: loads),
      ),
    );
  }
}

class TraderLoadsPage extends StatelessWidget {
  const TraderLoadsPage({super.key, required this.title, required this.loads});

  final String title;
  final List<Map<String, dynamic>> loads;

  String _formatOmr(dynamic value) =>
      (value is num ? value : num.tryParse('$value') ?? 0).toStringAsFixed(3);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      backgroundColor: const Color(0xFF1A237E),
      foregroundColor: Colors.white,
    ),
    body: loads.isEmpty
        ? Center(child: Text('No ${title.toLowerCase()} found.'))
        : ListView.builder(
            itemCount: loads.length,
            itemBuilder: (context, index) {
              final load = loads[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.local_shipping),
                  ),
                  title: Text('#${load['id']} | ${load['product'] ?? 'Order'}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${load['status'] ?? 'Available'} | ${load['pickup_location'] ?? 'Pickup'} to ${load['delivery_location'] ?? 'Delivery'}',
                      ),
                      Text(
                        load['driver_id'] == null
                            ? 'Accepted driver: Not assigned'
                            : 'Accepted driver: Assigned',
                      ),
                    ],
                  ),
                  trailing: Text('${_formatOmr(load['price_omr'])} OMR'),
                ),
              );
            },
          ),
  );
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
  String? _pickup;
  String? _delivery;
  final _weight = TextEditingController();
  final _price = TextEditingController();
  String _paymentMethod = demoPaymentMethods.first;
  bool _saving = false;

  @override
  void dispose() {
    _product.dispose();
    _description.dispose();
    _weight.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _postLoad() async {
    if (!_formKey.currentState!.validate()) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final publish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Publish load?'),
        content: const Text(
          'Your load will be visible to drivers for up to 90 days. If it has not been removed earlier, it will be automatically deleted from the marketplace after that.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Review'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Publish load'),
          ),
        ],
      ),
    );
    if (publish != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('loads').insert({
        'trader_id': user.id,
        'product': _product.text.trim(),
        'description': _description.text.trim(),
        'pickup_location': _pickup,
        'delivery_location': _delivery,
        'weight': _weight.text.trim(),
        'price_omr': double.parse(_price.text.trim()),
        'payment_method': _paymentMethod,
      });
      for (final controller in [_product, _description, _weight, _price]) {
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
        automaticallyImplyLeading: false,
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
                _locationField(
                  'Pickup location',
                  _pickup,
                  (value) => setState(() => _pickup = value),
                ),
                const SizedBox(height: 16),
                _locationField(
                  'Delivery location',
                  _delivery,
                  (value) => setState(() => _delivery = value),
                ),
                const SizedBox(height: 16),
                _field(_weight, 'Load weight (kg or tons)'),
                const SizedBox(height: 16),
                _field(_price, 'Price (OMR)', number: true),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment method',
                    border: OutlineInputBorder(),
                  ),
                  items: demoPaymentMethods
                      .map(
                        (method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ),
                      )
                      .toList(),
                  onChanged: (method) {
                    if (method != null) setState(() => _paymentMethod = method);
                  },
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Project demo only. No payment is processed.',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ),
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

  Widget _locationField(
    String label,
    String? value,
    ValueChanged<String?> onChanged,
  ) => DropdownButtonFormField<String>(
    value: value,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    items: omanLocations
        .map(
          (location) =>
              DropdownMenuItem(value: location, child: Text(location)),
        )
        .toList(),
    onChanged: onChanged,
    validator: (value) => value == null ? 'Enter $label' : null,
  );
}

class TraderProductsPage extends StatefulWidget {
  const TraderProductsPage({super.key});

  @override
  State<TraderProductsPage> createState() => _TraderProductsPageState();
}

class _TraderProductsPageState extends State<TraderProductsPage> {
  Stream<List<Map<String, dynamic>>> _loadRows() => Supabase.instance.client
      .from('loads')
      .stream(primaryKey: ['id'])
      .eq('trader_id', Supabase.instance.client.auth.currentUser!.id)
      .order('created_at', ascending: false);

  late Stream<List<Map<String, dynamic>>> _rows = _loadRows();

  Future<void> _edit(Map<String, dynamic> load) async {
    final fields = [
      TextEditingController(text: load['product']?.toString()),
      TextEditingController(text: load['description']?.toString()),
      TextEditingController(text: load['weight']?.toString()),
      TextEditingController(text: load['price_omr']?.toString() ?? ''),
    ];
    String? pickup = omanLocations.contains(load['pickup_location'])
        ? load['pickup_location'] as String
        : null;
    String? delivery = omanLocations.contains(load['delivery_location'])
        ? load['delivery_location'] as String
        : null;
    String paymentMethod = demoPaymentMethods.contains(load['payment_method'])
        ? load['payment_method'] as String
        : demoPaymentMethods.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit load #${load['id']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: fields[0],
                    decoration: const InputDecoration(
                      labelText: 'Product',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: fields[1],
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DropdownButtonFormField<String>(
                    value: pickup,
                    decoration: const InputDecoration(
                      labelText: 'Pickup location',
                      border: OutlineInputBorder(),
                    ),
                    items: omanLocations
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => pickup = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DropdownButtonFormField<String>(
                    value: delivery,
                    decoration: const InputDecoration(
                      labelText: 'Delivery location',
                      border: OutlineInputBorder(),
                    ),
                    items: omanLocations
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => delivery = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: fields[2],
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg or tons)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: fields[3],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Price (OMR)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment method',
                      border: OutlineInputBorder(),
                    ),
                    items: demoPaymentMethods
                        .map(
                          (method) => DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          ),
                        )
                        .toList(),
                    onChanged: (method) {
                      if (method != null)
                        setDialogState(() => paymentMethod = method);
                    },
                  ),
                ),
                const Text(
                  'Project demo only. No payment is processed.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed:
                  pickup == null ||
                      delivery == null ||
                      double.tryParse(fields[3].text.trim()) == null ||
                      double.parse(fields[3].text.trim()) < 0
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      try {
        await Supabase.instance.client.rpc(
          'update_available_load',
          params: {
            'p_load_id': load['id'],
            'p_product': fields[0].text.trim(),
            'p_description': fields[1].text.trim(),
            'p_pickup_location': pickup!,
            'p_delivery_location': delivery!,
            'p_weight': fields[2].text.trim(),
            'p_price_omr': double.parse(fields[3].text.trim()),
            'p_payment_method': paymentMethod,
          },
        );
        setState(() => _rows = _loadRows());
      } catch (e) {
        _message('Could not update load: $e');
      }
    }
    for (final field in fields) {
      field.dispose();
    }
  }

  Future<void> _delete(Map<String, dynamic> load) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this load?'),
        content: Text(
          'Load #${load['id']} will be permanently removed from the marketplace.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client.rpc(
        'delete_trader_load',
        params: {'p_load_id': load['id']},
      );
      setState(() => _rows = _loadRows());
    } catch (e) {
      _message('Could not delete load: $e');
    }
  }

  Future<void> _showDriverDetails(Map<String, dynamic> load) async {
    final driverId = load['driver_id']?.toString();
    if (driverId == null) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => FutureBuilder<Map<String, dynamic>?>(
        future: Supabase.instance.client
            .rpc('get_load_driver_details', params: {'p_load_id': load['id']})
            .then(
              (data) =>
                  data == null ? null : Map<String, dynamic>.from(data as Map),
            ),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final name = profile?['full_name']?.toString().trim() ?? '';
          return AlertDialog(
            title: const Text('Driver details'),
            content: snapshot.connectionState == ConnectionState.waiting
                ? const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : snapshot.hasError
                ? Text('Could not load driver details: ${snapshot.error}')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _driverInfoRow(
                        Icons.person_outline,
                        'Name',
                        name.isEmpty ? 'Driver' : name,
                      ),
                      const SizedBox(height: 12),
                      _driverInfoRow(
                        Icons.phone_outlined,
                        'Phone',
                        profile?['phone']?.toString() ?? 'Not provided',
                      ),
                      if (load['accepted_at'] != null) ...[
                        const SizedBox(height: 12),
                        _driverInfoRow(
                          Icons.schedule,
                          'Accepted',
                          _formatLoadDate(load['accepted_at']),
                        ),
                      ],
                    ],
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _driverInfoRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 20, color: const Color(0xFF1A237E)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ],
  );

  String _formatLoadDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'Recently';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _message(String message) {
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _rows,
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
                  leading: load['driver_id'] == null
                      ? const Icon(
                          Icons.local_shipping,
                          color: Color(0xFF1A237E),
                        )
                      : IconButton(
                          tooltip: 'View driver details',
                          onPressed: () => _showDriverDetails(load),
                          icon: const Icon(
                            Icons.person_search_outlined,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                  title: Text(load['product']?.toString() ?? 'Load'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${load['pickup_location']} to ${load['delivery_location']}',
                      ),
                      Text('${load['status']}'),
                      if (load['expires_at'] != null)
                        Text(
                          'Expires ${_formatLoadDate(load['expires_at'])}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (load['status'] == 'Available' ||
                          load['status'] == 'Delivered')
                        PopupMenuButton<String>(
                          onSelected: (action) =>
                              action == 'edit' ? _edit(load) : _delete(load),
                          itemBuilder: (_) => [
                            if (load['status'] == 'Available')
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          enabled: true,
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
