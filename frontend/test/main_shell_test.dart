import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixops_frontend/core/models/user_model.dart';
import 'package:fixops_frontend/user/providers/auth_provider.dart';
import 'package:fixops_frontend/user/providers/notification_provider.dart';
import 'package:fixops_frontend/user/providers/ticket_provider.dart';
import 'package:fixops_frontend/user/views/main_shell.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('mobile navigation has at least two destinations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => _TestAuthProvider(),
          ),
          ChangeNotifierProvider<TicketProvider>(
            create: (_) => _TestTicketProvider(),
          ),
          ChangeNotifierProvider<NotificationProvider>(
            create: (_) => _TestNotificationProvider(),
          ),
        ],
        child: const MaterialApp(home: MainShell()),
      ),
    );

    final navigation = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navigation.items.length, greaterThanOrEqualTo(2));
    expect(navigation.items.map((item) => item.label), contains('Account'));
  });
}

class _TestAuthProvider extends AuthProvider {
  @override
  UserModel? get currentUser => UserModel(
    id: 'user-id',
    email: 'user@example.com',
    fullName: 'Test User',
    role: 'USER',
    department: 'IT',
    isActive: true,
  );
}

class _TestTicketProvider extends TicketProvider {
  @override
  Future<void> fetchTickets() async {}
}

class _TestNotificationProvider extends NotificationProvider {
  @override
  Future<void> fetchNotifications() async {}
}
