import 'package:flutter/material.dart';
import 'package:hms_app/models/dtos/customer_short_detail.dart';
import 'package:hms_app/repositories/user_repository.dart';
import 'package:hms_app/widgets/app_drawer.dart';

class BookingSearchView extends StatefulWidget {
  const BookingSearchView({super.key});

  @override
  State<BookingSearchView> createState() => _BookingSearchViewState();
}

class _BookingSearchViewState extends State<BookingSearchView> {
  final _userRepository = UserRepository();
  final _searchController = TextEditingController();
  List<CustomerShortDetail> _allCustomers = [];
  List<CustomerShortDetail> _filteredCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await _userRepository.getAllCustomers();
      if (mounted) {
        setState(() {
          _allCustomers = customers;
          _filteredCustomers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error loading customers: $e');
      }
    }
  }

  void _filterCustomers() {
    final query = _searchController.text.trim();
    setState(() {
      _filteredCustomers = query.isEmpty
          ? _allCustomers
          : _allCustomers
              .where((c) => c.phone.contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm khách hàng')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nhập số điện thoại',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: isDark
                        ? colorScheme.outline.withValues(alpha: 0.6)
                        : colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: isDark
                        ? colorScheme.outline.withValues(alpha: 0.6)
                        : colorScheme.outline,
                  ),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                ? const Center(child: Text('Không tìm thấy khách hàng'))
                : ListView.builder(
                    itemCount: _filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _filteredCustomers[index];
                      return _CustomerCard(
                        customer: customer,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/customer-bookings/${customer.userId}',
                          arguments: customer,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Customer card widget ──────────────────────────────────────────────────────

class _CustomerCard extends StatelessWidget {
  final CustomerShortDetail customer;
  final VoidCallback onTap;

  const _CustomerCard({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: (customer.avatar != null &&
                        customer.avatar!.isNotEmpty)
                    ? NetworkImage(customer.avatar!)
                    : null,
                child: (customer.avatar == null || customer.avatar!.isEmpty)
                    ? const Icon(Icons.person, size: 28)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
