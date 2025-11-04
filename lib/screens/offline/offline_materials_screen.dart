import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/offline_manager.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';

class OfflineMaterialsScreen extends StatefulWidget {
  const OfflineMaterialsScreen({super.key});

  @override
  State<OfflineMaterialsScreen> createState() => _OfflineMaterialsScreenState();
}

class _OfflineMaterialsScreenState extends State<OfflineMaterialsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OfflineManager _offlineManager = OfflineManager();
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkConnectivity();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final isOnline = await _offlineManager.isOnline();
    setState(() {
      _isOnline = isOnline;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Materials'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text(
                _isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: _isOnline ? Colors.green[700] : Colors.orange[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              backgroundColor: _isOnline ? Colors.green[50] : Colors.orange[50],
              side: BorderSide(
                color: _isOnline ? Colors.green : Colors.orange,
                width: 1,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkConnectivity,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Content', icon: Icon(Icons.book)),
            Tab(text: 'Assignments', icon: Icon(Icons.assignment)),
            Tab(text: 'Announcements', icon: Icon(Icons.campaign)),
          ],
        ),
      ),
      body: FutureBuilder<StudentModel?>(
        future: databaseService.getStudentById(authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Student data not found'));
          }

          final student = snapshot.data!;

          return FutureBuilder<String?>(
            future: databaseService.getStudentPrimaryClassId(student.uid),
            builder: (context, classSnapshot) {
              final classId = classSnapshot.data ?? '';
              return TabBarView(
                controller: _tabController,
                children: [
                  _OfflineContentTab(classId: classId),
                  _OfflineAssignmentsTab(classId: classId),
                  _OfflineAnnouncementsTab(classId: classId),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton:
          _isOnline
              ? FloatingActionButton.extended(
                onPressed: _showDownloadOptions,
                icon: const Icon(Icons.download),
                label: const Text('Download'),
              )
              : null,
    );
  }

  void _showDownloadOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Download for Offline Access',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.book, color: Colors.blue),
                  title: const Text('Download All Content'),
                  subtitle: const Text('Study materials and resources'),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadAllContent();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.orange),
                  title: const Text('Download Assignments'),
                  subtitle: const Text('Assignment details and files'),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadAllAssignments();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.campaign, color: Colors.green),
                  title: const Text('Download Announcements'),
                  subtitle: const Text('Latest announcements and notices'),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadAllAnnouncements();
                  },
                ),
                const SizedBox(height: 16),
                FutureBuilder<String>(
                  future: _offlineManager.getOfflineStorageSize(),
                  builder: (context, snapshot) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storage, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Storage used: ${snapshot.data ?? "Calculating..."}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _downloadAllContent() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Downloading content...'),
              ],
            ),
          ),
    );

    // Simulate download process
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content downloaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _downloadAllAssignments() async {
    // Similar implementation for assignments
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Downloading assignments...'),
              ],
            ),
          ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignments downloaded successfully!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _downloadAllAnnouncements() async {
    // Similar implementation for announcements
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Downloading announcements...'),
              ],
            ),
          ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcements downloaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class _OfflineContentTab extends StatelessWidget {
  final String classId;

  const _OfflineContentTab({required this.classId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OfflineContent>>(
      future: OfflineManager().getOfflineContent(classId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final content = snapshot.data ?? [];

        if (content.isEmpty) {
          return const _EmptyOfflineState(
            icon: Icons.book_outlined,
            title: 'No Offline Content',
            subtitle: 'Download content to access it offline',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: content.length,
          itemBuilder: (context, index) {
            final item = content[index];
            return _OfflineContentCard(content: item);
          },
        );
      },
    );
  }
}

class _OfflineAssignmentsTab extends StatelessWidget {
  final String classId;

  const _OfflineAssignmentsTab({required this.classId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OfflineAssignment>>(
      future: OfflineManager().getOfflineAssignments(classId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final assignments = snapshot.data ?? [];

        if (assignments.isEmpty) {
          return const _EmptyOfflineState(
            icon: Icons.assignment_outlined,
            title: 'No Offline Assignments',
            subtitle: 'Download assignments to access them offline',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            return _OfflineAssignmentCard(assignment: assignment);
          },
        );
      },
    );
  }
}

class _OfflineAnnouncementsTab extends StatelessWidget {
  final String classId;

  const _OfflineAnnouncementsTab({required this.classId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OfflineAnnouncement>>(
      future: OfflineManager().getOfflineAnnouncements(classId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final announcements = snapshot.data ?? [];

        if (announcements.isEmpty) {
          return const _EmptyOfflineState(
            icon: Icons.campaign_outlined,
            title: 'No Offline Announcements',
            subtitle: 'Download announcements to access them offline',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            return _OfflineAnnouncementCard(announcement: announcement);
          },
        );
      },
    );
  }
}

class _OfflineContentCard extends StatelessWidget {
  final OfflineContent content;

  const _OfflineContentCard({required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.book, color: Colors.blue),
        ),
        title: Text(content.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content.type),
            const SizedBox(height: 4),
            Text(
              'Downloaded: ${_formatDate(content.downloadedAt)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: () => _openContent(context, content),
        ),
        isThreeLine: true,
      ),
    );
  }

  void _openContent(BuildContext context, OfflineContent content) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(content.title),
            content: SingleChildScrollView(child: Text(content.content)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _OfflineAssignmentCard extends StatelessWidget {
  final OfflineAssignment assignment;

  const _OfflineAssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.assignment, color: Colors.orange),
        ),
        title: Text(assignment.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(assignment.description),
            const SizedBox(height: 4),
            if (assignment.dueDate != null)
              Text(
                'Due: ${_formatDate(assignment.dueDate!)}',
                style: TextStyle(color: Colors.red[600]),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        isThreeLine: true,
        onTap: () => _showAssignmentDetails(context, assignment),
      ),
    );
  }

  void _showAssignmentDetails(
    BuildContext context,
    OfflineAssignment assignment,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(assignment.title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(assignment.description),
                  if (assignment.dueDate != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Due Date: ${_formatDate(assignment.dueDate!)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _OfflineAnnouncementCard extends StatelessWidget {
  final OfflineAnnouncement announcement;

  const _OfflineAnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.campaign, color: Colors.green),
        ),
        title: Text(announcement.title),
        subtitle: Text(announcement.content),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        isThreeLine: true,
        onTap: () => _showAnnouncementDetails(context, announcement),
      ),
    );
  }

  void _showAnnouncementDetails(
    BuildContext context,
    OfflineAnnouncement announcement,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(announcement.title),
            content: SingleChildScrollView(child: Text(announcement.content)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}

class _EmptyOfflineState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyOfflineState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                _getIllustrationUrl(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, size: 80, color: Colors.grey[400]),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getIllustrationUrl() {
    switch (icon) {
      case Icons.book_outlined:
        return 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400&h=400&fit=crop&crop=center';
      case Icons.assignment_outlined:
        return 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=400&h=400&fit=crop&crop=center';
      case Icons.campaign_outlined:
        return 'https://images.unsplash.com/photo-1552664730-d307ca884978?w=400&h=400&fit=crop&crop=center';
      default:
        return 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400&h=400&fit=crop&crop=center';
    }
  }
}
