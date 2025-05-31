import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/emergency_contact.dart';
import '../services/database_service.dart';

class EmergencyContactsPage extends StatefulWidget {
  final String patientId;

  const EmergencyContactsPage({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final contacts = await _dbService.getEmergencyContacts(widget.patientId);
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading contacts: $e')),
      );
    }
  }

  Future<void> _addContact() async {
    final result = await showDialog<EmergencyContact>(
      context: context,
      builder: (context) => const AddContactDialog(),
    );

    if (result != null) {
      try {
        await _dbService.addEmergencyContact(widget.patientId, result);
        _loadContacts();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding contact: $e')),
        );
      }
    }
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbService.deleteEmergencyContact(widget.patientId, contact.id);
        _loadContacts();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting contact: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No emergency contacts added yet',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Contact'),
                        onPressed: _addContact,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: contact.isPrimary ? Colors.red : Colors.grey,
                        child: Text(contact.name[0]),
                      ),
                      title: Text(contact.name),
                      subtitle: Text('${contact.relationship} - ${contact.phoneNumber}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!contact.isPrimary)
                            IconButton(
                              icon: const Icon(Icons.star_border),
                              onPressed: () async {
                                try {
                                  await _dbService.setPrimaryContact(
                                    widget.patientId,
                                    contact.id,
                                  );
                                  _loadContacts();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteContact(contact),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddContactDialog extends StatefulWidget {
  const AddContactDialog({Key? key}) : super(key: key);

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phoneNumber = '';
  String _relationship = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Emergency Contact'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => v?.isEmpty ?? true ? 'Please enter a name' : null,
              onChanged: (v) => _name = v,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              validator: (v) => v?.isEmpty ?? true ? 'Please enter a phone number' : null,
              onChanged: (v) => _phoneNumber = v,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Relationship'),
              validator: (v) => v?.isEmpty ?? true ? 'Please enter relationship' : null,
              onChanged: (v) => _relationship = v,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: const Text('Add'),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                context,
                EmergencyContact(
                  id: const Uuid().v4(),
                  name: _name,
                  phoneNumber: _phoneNumber,
                  relationship: _relationship,
                ),
              );
            }
          },
        ),
      ],
    );
  }
} 