import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/activity.dart';
import '../../../viewmodels/preacher_activity_view_model.dart';

class PreacherAssignActivityScreen extends StatelessWidget {
  final String preacherId;
  final String preacherName;

  const PreacherAssignActivityScreen({
    super.key,
    required this.preacherId,
    required this.preacherName,
  });

  static Widget withProvider({
    required String preacherId,
    required String preacherName,
  }) {
    return ChangeNotifierProvider(
      create: (_) => PreacherActivityViewModel()..loadAvailableActivities(),
      child: PreacherAssignActivityScreen(
        preacherId: preacherId,
        preacherName: preacherName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PreacherActivityViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          'Available Activities',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.black),
                onPressed: () => _showNotifications(context),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('activities')
                      .where('assignedPreacherId', isEqualTo: preacherId)
                      .where('status', isEqualTo: 'Assigned')
                      .snapshots(),
                  builder: (context, assignedSnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('activity_submissions')
                          .where('preacherId', isEqualTo: preacherId)
                          .where('status', whereIn: ['Approved', 'Rejected'])
                          .snapshots(),
                      builder: (context, reviewSnapshot) {
                        final assignedCount = assignedSnapshot.data?.docs.length ?? 0;
                        final reviewCount = reviewSnapshot.data?.docs.length ?? 0;
                        final total = assignedCount + reviewCount;
                        
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
    );
  }

  Widget _buildSearchBar(PreacherActivityViewModel viewModel) {
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
          hintText: 'Search by topic, location...',
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

  Widget _buildFilterTabs(PreacherActivityViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          _buildFilterChip(
            'Nearest',
            viewModel.filterType == ActivityFilterType.nearest,
            () => viewModel.onFilterTypeChanged(ActivityFilterType.nearest),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Newest',
            viewModel.filterType == ActivityFilterType.newest,
            () => viewModel.onFilterTypeChanged(ActivityFilterType.newest),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Urgent',
            viewModel.filterType == ActivityFilterType.urgent,
            () => viewModel.onFilterTypeChanged(ActivityFilterType.urgent),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label == 'Nearest')
              const Icon(Icons.near_me, size: 16, color: Colors.white),
            if (label == 'Newest')
              Icon(
                Icons.access_time,
                size: 16,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            if (label == 'Urgent')
              Icon(
                Icons.priority_high,
                size: 16,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    PreacherActivityViewModel viewModel,
  ) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(child: Text(viewModel.errorMessage!));
    }

    if (viewModel.availableActivities.isEmpty) {
      return const Center(child: Text('No available activities found.'));
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadAvailableActivities(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.availableActivities.length,
        itemBuilder: (context, index) {
          return _buildActivityCard(
            context,
            viewModel,
            viewModel.availableActivities[index],
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    PreacherActivityViewModel viewModel,
    Activity activity,
  ) {
    final isUrgent = activity.urgency == 'Urgent';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUrgent ? Border.all(color: Colors.red, width: 2) : null,
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
              if (isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Urgent',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                '${DateFormat('dd MMM yyyy').format(activity.activityDate)}, ${activity.startTime} - ${activity.endTime}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
          const SizedBox(height: 8),
          Text(
            activity.topic,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _showActivityDetails(context, activity),
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    final success = await viewModel.applyForActivity(
                      activity.activityId,
                      activity.id,
                      preacherId,
                      preacherName,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Applied successfully'
                                : 'Failed to apply',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showActivityDetails(BuildContext context, Activity activity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
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
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Activity Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildDetailRow(
                              Icons.category,
                              'Activity Type',
                              activity.activityType,
                            ),
                            _buildDetailRow(
                              Icons.title,
                              'Title',
                              activity.title,
                            ),
                            _buildDetailRow(
                              Icons.calendar_today,
                              'Date',
                              DateFormat(
                                'dd MMM yyyy',
                              ).format(activity.activityDate),
                            ),
                            _buildDetailRow(
                              Icons.access_time,
                              'Time',
                              '${activity.startTime} - ${activity.endTime}',
                            ),
                            _buildDetailRow(
                              Icons.location_on,
                              'Location',
                              activity.location,
                            ),
                            _buildDetailRow(
                              Icons.place,
                              'Venue',
                              activity.venue,
                            ),
                            _buildDetailRow(
                              Icons.topic,
                              'Topic',
                              activity.topic,
                            ),
                            const SizedBox(height: 16),
                            if (activity.specialRequirements.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Special Requirements',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(activity.specialRequirements),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('activities')
                                .where('assignedPreacherId', isEqualTo: preacherId)
                                .where('status', isEqualTo: 'Assigned')
                                .snapshots(),
                            builder: (context, assignedSnapshot) {
                              return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('activity_submissions')
                                    .where('preacherId', isEqualTo: preacherId)
                                    .where('status', whereIn: ['Approved', 'Rejected'])
                                    .snapshots(),
                                builder: (context, reviewSnapshot) {
                                  final assignedCount = assignedSnapshot.data?.docs.length ?? 0;
                                  final reviewCount = reviewSnapshot.data?.docs.length ?? 0;
                                  final total = assignedCount + reviewCount;
                                  
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
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('activities')
                      .where('assignedPreacherId', isEqualTo: preacherId)
                      .where('status', isEqualTo: 'Assigned')
                      .snapshots(),
                  builder: (context, assignedSnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('activity_submissions')
                          .where('preacherId', isEqualTo: preacherId)
                          .where('status', whereIn: ['Approved', 'Rejected'])
                          .snapshots(),
                      builder: (context, reviewSnapshot) {
                        if (assignedSnapshot.connectionState == ConnectionState.waiting ||
                            reviewSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final assigned = assignedSnapshot.data?.docs ?? [];
                        final reviewed = reviewSnapshot.data?.docs ?? [];

                        if (assigned.isEmpty && reviewed.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No new notifications',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            ...assigned.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                              final timeAgo = _getTimeAgo(updatedAt);
                              
                              return _buildNotificationItem(
                                icon: Icons.check_circle,
                                iconColor: Colors.green,
                                title: 'Activity Assigned',
                                message: 'You have been assigned to "${data['title']}"',
                                time: timeAgo,
                                isUnread: true,
                                onTap: () => Navigator.pop(context),
                              );
                            }),
                            ...reviewed.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final reviewedAt = (data['reviewedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                              final timeAgo = _getTimeAgo(reviewedAt);
                              final status = data['status'] as String;
                              
                              return _buildNotificationItem(
                                icon: status == 'Approved' ? Icons.check_circle : Icons.cancel,
                                iconColor: status == 'Approved' ? Colors.green : Colors.red,
                                title: 'Evidence ${status}',
                                message: 'Your evidence submission has been ${status.toLowerCase()}',
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
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
