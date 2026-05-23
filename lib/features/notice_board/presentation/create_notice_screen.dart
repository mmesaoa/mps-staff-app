import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:school_erp_staff_app/features/attendance/presentation/attendance_providers.dart';
import 'notice_providers.dart';

class CreateNoticeScreen extends ConsumerStatefulWidget {
  const CreateNoticeScreen({super.key});

  @override
  ConsumerState<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends ConsumerState<CreateNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _recipientType = 'all'; // Default recipient
  dynamic _selectedClass;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitNotice() async {
    if (_formKey.currentState!.validate()) {
      // Additional validation for class selection
      if (_recipientType == 'class' && _selectedClass == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a class.')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        await ref.read(createNoticeControllerProvider).submitNotice(
              title: _titleController.text,
              content: _contentController.text,
              publishedAt: DateFormat('yyyy-MM-dd').format(DateTime.now()),
              recipientType: _recipientType,
              noticableId: _selectedClass?['id'],
            );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notice published successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // We need the list of classes for the dropdown
    final classesState = ref.watch(classesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Notice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (value) => (value?.isEmpty ?? true) ? 'Please enter a title.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                validator: (value) => (value?.isEmpty ?? true) ? 'Please enter the notice content.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _recipientType,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Users')),
                  DropdownMenuItem(value: 'parents', child: Text('All Parents')),
                  DropdownMenuItem(value: 'class', child: Text('A Specific Class')),
                ],
                onChanged: (value) {
                  setState(() {
                    _recipientType = value!;
                    _selectedClass = null; // Reset class selection
                  });
                },
                decoration: const InputDecoration(labelText: 'Publish To', border: OutlineInputBorder()),
              ),
              if (_recipientType == 'class') ...[
                const SizedBox(height: 16),
                classesState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Could not load classes: $err'),
                  data: (classes) => DropdownButtonFormField<dynamic>(
                    value: _selectedClass,
                    items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c['name']))).toList(),
                    onChanged: (value) => setState(() => _selectedClass = value),
                    decoration: const InputDecoration(labelText: 'Select Class', border: OutlineInputBorder()),
                    validator: (value) => (_recipientType == 'class' && value == null) ? 'Please select a class.' : null,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: _isLoading ? null : _submitNotice,
                child: _isLoading
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                    : const Text('Publish Notice'),
              )
            ],
          ),
        ),
      ),
    );
  }
}