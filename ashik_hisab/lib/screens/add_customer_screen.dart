import 'package:flutter/material.dart';

import '../db/db_helper.dart';

/// কাস্টমার যোগ/এডিট ফর্ম — LedgerScreen ও CustomerDetailScreen থেকে ব্যবহৃত।
class AddCustomerScreen extends StatefulWidget {
  final Map<String, Object?>? existing;
  const AddCustomerScreen({super.key, this.existing});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?['name'] as String? ?? '');
  late final TextEditingController _phone = TextEditingController(
      text: widget.existing?['phone'] as String? ?? '');
  late final TextEditingController _address = TextEditingController(
      text: widget.existing?['address'] as String? ?? '');

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final row = <String, Object?>{
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'address': _address.text.trim(),
    };
    final db = DbHelper.instance;
    if (widget.existing == null) {
      row['created_at'] = DateTime.now().millisecondsSinceEpoch;
      await db.insertCustomer(row);
    } else {
      await db.updateCustomer(widget.existing!['id'] as int, row);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'কাস্টমার এডিট' : 'নতুন কাস্টমার',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'নাম *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'নাম লিখুন' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'ফোন নম্বর',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _address,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ঠিকানা',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(editing ? 'আপডেট করুন' : 'সংরক্ষণ করুন'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
