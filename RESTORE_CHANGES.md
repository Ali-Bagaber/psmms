# Complete Module Restoration Guide

## Status: PARTIAL - Manual Steps Required

### ✅ COMPLETED Changes:
1. Android Gradle Plugin updated to 8.9.1
2. Kotlin version updated to 2.1.0  
3. Gradle wrapper updated to 8.11.1
4. NDK disabled in build.gradle.kts
5. Google Maps API key added: AIzaSyC11ZjVTVJjRVVppyCqV5gtF_B8PKnVj5w
6. url_launcher dependency added to pubspec.yaml
7. Map default location changed to Pekan, Malaysia (3.4918, 103.3976)
8. Image picker limit increased from 3 to 10 photos
9. Upload minimum changed from 3 to 1 photo
10. File size restriction text removed

### ⚠️ MISSING - Need Manual Implementation:

#### 1. Enhanced Map Features (map_location_picker.dart)
**Missing**: Category search buttons, zoom controls, current location button, nearby markers

**Add after line 150 (after map widget):**
```dart
// Horizontal category buttons
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: Row(
    children: [
      _buildCategoryButton('Restaurant', Icons.restaurant),
      SizedBox(width: 8),
      _buildCategoryButton('Gas Station', Icons.local_gas_station),
      SizedBox(width: 8),
      _buildCategoryButton('Grocery', Icons.shopping_cart),
      SizedBox(width: 8),
      _buildCategoryButton('Hospital', Icons.local_hospital),
      SizedBox(width: 8),
      _buildCategoryButton('School', Icons.school),
    ],
  ),
),

// Add method:
Widget _buildCategoryButton(String label, IconData icon) {
  return OutlinedButton.icon(
    onPressed: () => _searchNearbyPlaces(label.toLowerCase()),
    icon: Icon(icon, size: 18),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}

// Add floating buttons on map:
Stack in GoogleMap widget with:
- Positioned zoom in/out buttons (right: 16, top: 100/160)
- Positioned current location button (right: 16, top: 220)

// Add method:
Future<void> _searchNearbyPlaces(String category) async {
  // Implementation using geocoding
}
```

#### 2. Real-time Notifications (officer_list_activities_screen.dart)
**Missing**: Complete notification system with StreamBuilder

**Replace notification button onPressed:**
```dart
IconButton(
  icon: const Icon(Icons.notifications_outlined, color: Colors.black),
  onPressed: () => _showNotifications(context),
),

// Add method:
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Header with count badge
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('activities')
                          .where('status', isEqualTo: 'Assigned')
                          .snapshots(),
                      builder: (context, assignedSnapshot) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('activity_submissions')
                              .where('status', isEqualTo: 'Pending')
                              .snapshots(),
                          builder: (context, submissionSnapshot) {
                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('payments')
                                  .where('status', isEqualTo: 'Pending Payment')
                                  .snapshots(),
                              builder: (context, paymentSnapshot) {
                                final total = (assignedSnapshot.data?.docs.length ?? 0) +
                                            (submissionSnapshot.data?.docs.length ?? 0) +
                                            (paymentSnapshot.data?.docs.length ?? 0);
                                return Text('$total New', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold));
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
            // List with three StreamBuilders
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('activities').where('status', isEqualTo: 'Assigned').snapshots(),
                builder: (context, assignedSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('activity_submissions').where('status', isEqualTo: 'Pending').snapshots(),
                    builder: (context, submissionSnapshot) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('payments').where('status', isEqualTo: 'Pending Payment').snapshots(),
                        builder: (context, paymentSnapshot) {
                          final assigned = assignedSnapshot.data?.docs ?? [];
                          final submissions = submissionSnapshot.data?.docs ?? [];
                          final payments = paymentSnapshot.data?.docs ?? [];
                          
                          if (assigned.isEmpty && submissions.isEmpty && payments.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
                                  SizedBox(height: 16),
                                  Text('No new notifications', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                                ],
                              ),
                            );
                          }
                          
                          return ListView(
                            controller: scrollController,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              // New Applications
                              ...assigned.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                                return _buildNotificationItem(
                                  icon: Icons.person_add,
                                  iconColor: Colors.purple,
                                  title: 'New Application',
                                  message: '${data['assignedPreacherName']} applied for ${data['title']}',
                                  time: _getTimeAgo(updatedAt),
                                  isUnread: true,
                                  onTap: () => Navigator.pop(context),
                                );
                              }),
                              // Evidence Submissions
                              ...submissions.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final submittedAt = (data['submittedAt'] as Timestamp).toDate();
                                return _buildNotificationItem(
                                  icon: Icons.assignment,
                                  iconColor: Colors.blue,
                                  title: 'New Evidence Submission',
                                  message: '${data['preacherName']} submitted evidence for activity',
                                  time: _getTimeAgo(submittedAt),
                                  isUnread: true,
                                  onTap: () => Navigator.pop(context),
                                );
                              }),
                              // Payment Requests
                              ...payments.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final requestDate = (data['requestDate'] as Timestamp).toDate();
                                return _buildNotificationItem(
                                  icon: Icons.payment,
                                  iconColor: Colors.green,
                                  title: 'Payment Request',
                                  message: '${data['preacherName']} - RM ${data['amount']}',
                                  time: _getTimeAgo(requestDate),
                                  isUnread: true,
                                  onTap: () => Navigator.pop(context),
                                );
                              }),
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
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
  if (difference.inHours < 24) return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
  if (difference.inDays < 7) return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
  return DateFormat('MMM d').format(dateTime);
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
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isUnread ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                SizedBox(height: 4),
                Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                SizedBox(height: 4),
                Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          if (isUnread)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    ),
  );
}
```

**Add import**: `import 'package:cloud_firestore/cloud_firestore.dart';`

#### 3. View Details Button (preacher_assign_activity_screen.dart)
**Missing**: View Details button with DraggableScrollableSheet

**In _buildActivityCard, replace the Apply button with two buttons:**
```dart
Row(
  children: [
    Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => _showActivityDetails(context, activity),
        child: Text('View Details'),
      ),
    ),
    SizedBox(width: 8),
    Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF0066FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                content: Text(success ? 'Applied successfully' : 'Failed to apply'),
                backgroundColor: success ? Colors.green : Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Text('Apply', style: TextStyle(color: Colors.white)),
      ),
    ),
  ],
),

// Add method:
void _showActivityDetails(BuildContext context, Activity activity) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Activity Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildDetailRow(Icons.event, 'Activity Type', activity.activityType),
                  _buildDetailRow(Icons.title, 'Title', activity.title),
                  _buildDetailRow(Icons.calendar_today, 'Date', DateFormat('dd MMM yyyy').format(activity.activityDate)),
                  _buildDetailRow(Icons.access_time, 'Time', '${activity.startTime} - ${activity.endTime}'),
                  _buildDetailRow(Icons.location_on, 'Location', activity.location),
                  _buildDetailRow(Icons.place, 'Venue', activity.venue),
                  _buildDetailRow(Icons.topic, 'Topic', activity.topic),
                  SizedBox(height: 16),
                  if (activity.specialRequirements.isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              SizedBox(width: 8),
                              Text('Special Requirements', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(activity.specialRequirements),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 24),
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
    padding: EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    ),
  );
}
```

#### 4. Change Tab Label (preacher_list_activities_screen.dart)
**Line 61**: Change `'Pending'` to `'Assigned'`
```dart
final statuses = ['Upcoming', 'Assigned', 'Approved', 'Rejected'];
```

#### 5. Status Badge Changes (officer_list_activities_screen.dart & officer_view_activity_screen.dart)
**In _buildStatusBadge method, update the 'Available' case:**
```dart
case 'Available':
  status = 'Pending';
  bgColor = Color(0xFFFEF3C7);
  textColor = Color(0xFF92400E);
  break;
```

#### 6. View on Map Button (preacher_view_activity_screen.dart)
**Missing**: url_launcher implementation

**Add import:** `import 'package:url_launcher/url_launcher.dart';`

**Add method:**
```dart
Future<void> _openMap() async {
  final lat = activity.location.split(',')[0]; // Parse from stored location
  final lng = activity.location.split(',')[1];
  final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open map')),
      );
    }
  }
}
```

**Add button in UI:**
```dart
OutlinedButton.icon(
  onPressed: _openMap,
  icon: Icon(Icons.map_outlined),
  label: Text('View on Map'),
  style: OutlinedButton.styleFrom(
    minimumSize: Size(double.infinity, 48),
  ),
),
```

## Next Steps:
1. Run `flutter pub get` to install url_launcher
2. Manually add the code sections above to their respective files
3. Run `flutter clean` then `flutter run`
4. Test all features: maps, notifications, upload, view details, status labels

## Files Requiring Manual Edits:
- lib/views/activity/widgets/map_location_picker.dart
- lib/views/activity/officer/officer_list_activities_screen.dart  
- lib/views/activity/officer/officer_view_activity_screen.dart
- lib/views/activity/preacher/preacher_assign_activity_screen.dart
- lib/views/activity/preacher/preacher_list_activities_screen.dart
- lib/views/activity/preacher/preacher_view_activity_screen.dart
