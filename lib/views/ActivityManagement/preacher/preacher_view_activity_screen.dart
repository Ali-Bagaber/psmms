import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/activity.dart';
import '../../../models/activity_submission.dart';
import '../../../viewmodels/preacher_activity_view_model.dart';

class PreacherViewActivityScreen extends StatelessWidget {
  final Activity activity;

  const PreacherViewActivityScreen({super.key, required this.activity});

  static Widget withProvider({required Activity activity}) {
    return ChangeNotifierProvider(
      create: (_) => PreacherActivityViewModel(),
      child: PreacherViewActivityScreen(activity: activity),
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Activity Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildStatusBadge(activity.status),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Schedule',
                children: [
                  _buildInfoRow(
                    Icons.calendar_today,
                    DateFormat('dd MMM yyyy').format(activity.activityDate),
                  ),
                  _buildInfoRow(
                    Icons.access_time,
                    '${activity.startTime} - ${activity.endTime}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Activity Type',
                children: [
                  Text(
                    activity.activityType,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Topic',
                children: [
                  Text(
                    activity.topic.isEmpty
                        ? 'No topic specified'
                        : activity.topic,
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          activity.topic.isEmpty ? Colors.grey : Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Location',
                children: [
                  _buildDetailRow(
                    Icons.location_on_outlined,
                    'Address',
                    activity.location,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.place_outlined,
                    'Venue',
                    activity.venue,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _openMap(context),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('View on Map'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (activity.specialRequirements.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Special Requirements',
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              activity.specialRequirements,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.blue.shade900,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              if (activity.status == 'Submitted') ...[
                const SizedBox(height: 16),
                FutureBuilder<ActivitySubmission?>(
                  future: viewModel.getActivitySubmission(activity.activityId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      return _buildSubmissionCard(snapshot.data!);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String displayText = status;

    switch (status) {
      case 'Assigned':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      case 'Submitted':
        bgColor = const Color(0xFFFFF4CC);
        textColor = const Color(0xFFB58100);
        displayText = 'Pending Review';
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0066FF)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? 'Not specified' : value,
                style: TextStyle(
                  fontSize: 15,
                  color: value.isEmpty ? Colors.grey : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openMap(BuildContext context) async {
    try {
      // Try to open in Google Maps app first, then fallback to browser
      final query = Uri.encodeComponent(activity.location);
      final googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$query';
      final uri = Uri.parse(googleMapsUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open map'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening map: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSubmissionCard(ActivitySubmission submission) {
    return _buildInfoCard(
      title: 'Evidence Photos',
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: submission.photoUrls.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                height: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(submission.photoUrls[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Submitted: ${DateFormat('dd MMM yyyy, HH:mm').format(submission.submittedAt)}',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
