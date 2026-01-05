import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/activity.dart';
import '../../../viewmodels/officer_activity_view_model.dart';
import 'officer_add_activity_screen.dart';
import 'officer_view_activity_screen.dart';
import 'officer_edit_activity_screen.dart';

class OfficerListActivitiesScreen extends StatelessWidget {
  const OfficerListActivitiesScreen({super.key});

  static Widget withProvider() {
    return ChangeNotifierProvider(
      create: (_) => OfficerActivityViewModel()..loadActivities(),
      child: const OfficerListActivitiesScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OfficerActivityViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Manage Activities',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                ),
                onPressed: () => _showNotifications(context),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('activities')
                          .where('status', isEqualTo: 'Assigned')
                          .snapshots(),
                  builder: (context, assignedSnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('activity_submissions')
                              .where('status', isEqualTo: 'Pending')
                              .snapshots(),
                      builder: (context, submissionSnapshot) {
                        return StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('payments')
                                  .where('status', isEqualTo: 'Pending Payment')
                                  .snapshots(),
                          builder: (context, paymentSnapshot) {
                            final total =
                                (assignedSnapshot.data?.docs.length ?? 0) +
                                (submissionSnapshot.data?.docs.length ?? 0) +
                                (paymentSnapshot.data?.docs.length ?? 0);

                            if (total == 0) return const SizedBox.shrink();

                            return Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                total > 9 ? '9+' : '$total',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(viewModel),
          _buildFilterTabs(viewModel),
          Expanded(child: _buildContent(context, viewModel)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OfficerAddActivityScreen.withProvider(),
            ),
          );
          if (result == true) {
            viewModel.loadActivities();
          }
        },
        backgroundColor: const Color(0xFF0066FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar(OfficerActivityViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: viewModel.onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search by title, preacher...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(OfficerActivityViewModel viewModel) {
    final filters = ['All', 'Assigned', 'Submitted', 'Approved', 'Rejected'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children:
            filters.map((filter) {
              final isSelected = viewModel.statusFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => viewModel.onStatusFilterChanged(filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF0066FF)
                              : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    OfficerActivityViewModel viewModel,
  ) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(child: Text(viewModel.errorMessage!));
    }

    if (viewModel.activities.isEmpty) {
      return const Center(child: Text('No activities found.'));
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadActivities(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: viewModel.activities.length,
        itemBuilder: (context, index) {
          return _buildActivityCard(
            context,
            viewModel,
            viewModel.activities[index],
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    OfficerActivityViewModel viewModel,
    Activity activity,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusBadge(activity.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  activity.assignedPreacherName ?? 'Not assigned',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  activity.location,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(activity.activityDate),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => OfficerViewActivityScreen.withProvider(
                            activity: activity,
                          ),
                    ),
                  );
                  if (result == true) {
                    viewModel.loadActivities();
                  }
                },
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('View'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0066FF),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => OfficerEditActivityScreen.withProvider(
                            activity: activity,
                          ),
                    ),
                  );
                  if (result == true) {
                    viewModel.loadActivities();
                  }
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0066FF),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed:
                    () => _showDeleteConfirmation(context, viewModel, activity),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Available':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        status = 'Pending';
        break;
      case 'Assigned':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      case 'Submitted':
        bgColor = const Color(0xFFFFF4CC);
        textColor = const Color(0xFFB58100);
        break;
      case 'Approved':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        break;
      case 'Rejected':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFB91C1C);
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    OfficerActivityViewModel viewModel,
    Activity activity,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Activity'),
            content: Text(
              'Are you sure you want to delete "${activity.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await viewModel.deleteActivity(activity.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Activity deleted'
                              : 'Failed to delete activity',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Clear All',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: StreamBuilder<QuerySnapshot>(
                                    stream:
                                        FirebaseFirestore.instance
                                            .collection('activities')
                                            .where(
                                              'status',
                                              isEqualTo: 'Assigned',
                                            )
                                            .snapshots(),
                                    builder: (context, assignedSnapshot) {
                                      return StreamBuilder<QuerySnapshot>(
                                        stream:
                                            FirebaseFirestore.instance
                                                .collection(
                                                  'activity_submissions',
                                                )
                                                .where(
                                                  'status',
                                                  isEqualTo: 'Pending',
                                                )
                                                .snapshots(),
                                        builder: (context, submissionSnapshot) {
                                          return StreamBuilder<QuerySnapshot>(
                                            stream:
                                                FirebaseFirestore.instance
                                                    .collection('payments')
                                                    .where(
                                                      'status',
                                                      isEqualTo:
                                                          'Pending Payment',
                                                    )
                                                    .snapshots(),
                                            builder: (
                                              context,
                                              paymentSnapshot,
                                            ) {
                                              final assignedCount =
                                                  assignedSnapshot
                                                      .data
                                                      ?.docs
                                                      .length ??
                                                  0;
                                              final submissionCount =
                                                  submissionSnapshot
                                                      .data
                                                      ?.docs
                                                      .length ??
                                                  0;
                                              final paymentCount =
                                                  paymentSnapshot
                                                      .data
                                                      ?.docs
                                                      .length ??
                                                  0;
                                              final total =
                                                  assignedCount +
                                                  submissionCount +
                                                  paymentCount;

                                              return Text(
                                                '$total New',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('activities')
                                  .where('status', isEqualTo: 'Assigned')
                                  .snapshots(),
                          builder: (context, assignedSnapshot) {
                            return StreamBuilder<QuerySnapshot>(
                              stream:
                                  FirebaseFirestore.instance
                                      .collection('activity_submissions')
                                      .where('status', isEqualTo: 'Pending')
                                      .snapshots(),
                              builder: (context, submissionSnapshot) {
                                return StreamBuilder<QuerySnapshot>(
                                  stream:
                                      FirebaseFirestore.instance
                                          .collection('payments')
                                          .where(
                                            'status',
                                            isEqualTo: 'Pending Payment',
                                          )
                                          .snapshots(),
                                  builder: (context, paymentSnapshot) {
                                    if (assignedSnapshot.connectionState ==
                                            ConnectionState.waiting ||
                                        submissionSnapshot.connectionState ==
                                            ConnectionState.waiting ||
                                        paymentSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    final assigned =
                                        assignedSnapshot.data?.docs ?? [];
                                    final submissions =
                                        submissionSnapshot.data?.docs ?? [];
                                    final payments =
                                        paymentSnapshot.data?.docs ?? [];

                                    if (assigned.isEmpty &&
                                        submissions.isEmpty &&
                                        payments.isEmpty) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.notifications_off,
                                              size: 64,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No new notifications',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return ListView(
                                      controller: scrollController,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      children: [
                                        ...assigned.map((doc) {
                                          final data =
                                              doc.data()
                                                  as Map<String, dynamic>;
                                          final updatedAt =
                                              (data['updatedAt'] as Timestamp?)
                                                  ?.toDate() ??
                                              DateTime.now();
                                          final timeAgo = _getTimeAgo(
                                            updatedAt,
                                          );

                                          return _buildNotificationItem(
                                            icon: Icons.person_add,
                                            iconColor: Colors.purple,
                                            title: 'New Application',
                                            message:
                                                '${data['assignedPreacherName']} applied for ${data['title']}',
                                            time: timeAgo,
                                            isUnread: true,
                                            onTap: () => Navigator.pop(context),
                                          );
                                        }),
                                        ...submissions.map((doc) {
                                          final data =
                                              doc.data()
                                                  as Map<String, dynamic>;
                                          final submittedAt =
                                              (data['submittedAt'] as Timestamp)
                                                  .toDate();
                                          final timeAgo = _getTimeAgo(
                                            submittedAt,
                                          );

                                          return _buildNotificationItem(
                                            icon: Icons.assignment,
                                            iconColor: Colors.blue,
                                            title: 'New Evidence Submission',
                                            message:
                                                '${data['preacherName']} submitted evidence for activity',
                                            time: timeAgo,
                                            isUnread: true,
                                            onTap: () => Navigator.pop(context),
                                          );
                                        }),
                                        ...payments.map((doc) {
                                          final data =
                                              doc.data()
                                                  as Map<String, dynamic>;
                                          final requestDate =
                                              (data['requestDate'] as Timestamp)
                                                  .toDate();
                                          final timeAgo = _getTimeAgo(
                                            requestDate,
                                          );

                                          return _buildNotificationItem(
                                            icon: Icons.payment,
                                            iconColor: Colors.green,
                                            title: 'Payment Request',
                                            message:
                                                '${data['preacherName']} - RM ${data['amount']}',
                                            time: timeAgo,
                                            isUnread: true,
                                            onTap: () => Navigator.pop(context),
                                          );
                                        }),
                                        const SizedBox(height: 20),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isUnread ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
