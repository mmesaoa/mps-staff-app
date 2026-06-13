import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_staff_app/shared/widgets/main_scaffold.dart';
import 'package:intl/intl.dart';
import 'package:school_erp_staff_app/shared/widgets/shimmer_loading.dart';
import 'leave_providers.dart';

class AdminLeaveApprovalScreen extends ConsumerStatefulWidget {
  const AdminLeaveApprovalScreen({super.key});

  @override
  ConsumerState<AdminLeaveApprovalScreen> createState() => _AdminLeaveApprovalScreenState();
}

class _AdminLeaveApprovalScreenState extends ConsumerState<AdminLeaveApprovalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(int leaveId, String status) async {
    String? remarks;
    
    if (status == 'rejected') {
      final remarksController = TextEditingController();
      final bool? confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject Leave'),
          content: TextField(
            controller: remarksController,
            decoration: const InputDecoration(
              labelText: 'Remarks (Optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
      remarks = remarksController.text;
    }

    try {
      await ref.read(leaveRepositoryProvider).updateLeaveStatus(
        leaveId: leaveId,
        status: status,
        remarks: remarks,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave request $status successfully'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          )
        );
      }
      
      // Refresh the list
      ref.invalidate(allLeaveRequestsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveRequestsAsync = ref.watch(allLeaveRequestsProvider);

    return MainScaffold(
      title: 'Staff Leave Approval',
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue.shade800,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue.shade800,
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
                Tab(text: 'Rejected'),
              ],
            ),
          ),
          Expanded(
            child: leaveRequestsAsync.when(
              loading: () => SkeletonLoaders.cardList(),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(err.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(allLeaveRequestsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (requests) {
                final pending = requests.where((r) => r['status'] == 'pending').toList();
                final approved = requests.where((r) => r['status'] == 'approved').toList();
                final rejected = requests.where((r) => r['status'] == 'rejected').toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(pending, true),
                    _buildList(approved, false),
                    _buildList(rejected, false),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<dynamic> requests, bool isPending) {
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.beach_access, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No Leave Requests',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'There are no ${isPending ? 'pending' : 'leave'} requests in this category.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allLeaveRequestsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index];
          
          final staffName = req['staff'] != null && req['staff']['user'] != null 
              ? req['staff']['user']['name'] 
              : 'Unknown Staff';
              
          final staffIdCard = req['staff'] != null ? req['staff']['staff_id_card'] : '';
          
          final startDate = DateTime.parse(req['start_date']);
          final endDate = DateTime.parse(req['end_date']);
          final applyDate = DateTime.parse(req['apply_date']);
          final leaveType = req['leave_type'] != null ? req['leave_type']['name'] : 'Leave';
          final days = req['days'] ?? 1;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                staffName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (staffIdCard.isNotEmpty)
                                Text(
                                  staffIdCard,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            leaveType,
                            style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDateColumn('From', startDate),
                        _buildDateColumn('To', endDate),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Duration', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('$days Day(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Reason: ${req['reason']}',
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Applied On: ${DateFormat('d MMM yyyy').format(applyDate)}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _updateStatus(req['id'], 'rejected'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateStatus(req['id'], 'approved'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateColumn(String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          DateFormat('d MMM, yyyy').format(date),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
