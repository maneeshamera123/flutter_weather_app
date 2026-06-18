import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final users = await _userService.getAllUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('No users found.'))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final name = user['name'] as String? ?? 'Unknown';
                    final email = user['email'] as String? ?? 'No email';
                    final isAdmin = user['is_admin'] == true;
                    final fcmToken = user['fcmToken'] as String?;
                    final location = user['location'] as String? ?? 'their city';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAdmin ? Colors.blue.shade700 : Colors.grey.shade400,
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isAdmin)
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Chip(
                                  label: Text('Admin', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.notifications_active, color: Colors.orange),
                              onPressed: () async {
                                if (fcmToken == null || fcmToken.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('User does not have a notification token')),
                                  );
                                  return;
                                }
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sending alert...')),
                                );

                                final success = await _notificationService.sendWeatherAlert(fcmToken, location);
                                
                                if (mounted) {
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Alert sent successfully!', style: TextStyle(color: Colors.green))),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to send alert.', style: TextStyle(color: Colors.red))),
                                    );
                                  }
                                }
                              },
                              tooltip: 'Send Weather Alert',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
