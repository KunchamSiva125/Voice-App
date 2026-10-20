import 'package:flutter/material.dart';
import '../models/customer_model.dart';

class DisambiguationSheet extends StatelessWidget {
  final List<CustomerModel> customers;
  final Function(CustomerModel selected) onSelect;
  final VoidCallback onCancel;

  const DisambiguationSheet({
    Key? key,
    required this.customers,
    required this.onSelect,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'సరైన కస్టమర్‌ను ఎంచుకోండి',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onCancel,
              ),
            ],
          ),
          const Text(
            'Select the correct customer from identical matches:',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: customers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final customer = customers[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFEF3C7),
                    child: Text(
                      customer.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    customer.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text(
                    customer.phoneNumber ?? (customer.notes ?? 'No phone'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${customer.balanceInRupees.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: customer.outstandingBalancePaise > 0
                              ? const Color(0xFFE11D48)
                              : const Color(0xFF059669),
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        'బాకీ',
                        style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  onTap: () => onSelect(customer),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
