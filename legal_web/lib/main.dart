import 'package:flutter/material.dart';

// Auth screens
import 'screens/signin.dart';
import 'screens/signup.dart';
import 'screens/forgot_password.dart';
import 'screens/signup_success.dart';

// User screens
import 'screens/first_page.dart';
import 'screens/user_home.dart';
import 'screens/user_profile.dart';
import 'screens/user_bookings.dart';

// Lawyer screens
import 'screens/lawyer_dashboard.dart';
import 'screens/lawyer_profile.dart';
import 'screens/lawyer_availability.dart';
import 'screens/clients.dart';
import 'screens/lawyer_bookings.dart';

// Feature screens
import 'screens/ai_chatbot.dart';
import 'screens/payment_gateway.dart';

// Core screens
import 'screens/loading_screen.dart';

void main() {
  runApp(const LegalWebApp());
}

class LegalWebApp extends StatelessWidget {
  const LegalWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legal Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      initialRoute: '/loading',
      routes: {
        '/loading': (context) => const LoadingScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/signup-success': (context) => const SignUpSuccessScreen(),
        '/first-page': (context) => const FirstPage(),
        '/user-home': (context) => const UserHome(),
        '/ai-chatbot': (context) => const AIChatBotScreen(),
        '/lawyer-dashboard': (context) => const LawyerDashboard(),
        '/lawyer-profile': (context) => const LawyerProfile(),
        '/lawyer-availability': (context) => const LawyerAvailability(),
        '/clients-page': (context) => const ClientsPage(),
        '/lawyer-bookings': (context) => const LawyerBookings(),
        '/user-profile': (context) => const UserProfileScreen(),
        '/user-bookings': (context) => const UserBookingsScreen(),
        '/payment-gateway': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          
          if (args == null || args is! Map<String, dynamic>) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Invalid payment details provided'),
              ),
            );
          }
          
          return PaymentGatewayScreen(bookingDetails: args);
        },
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Not Found')),
          body: const Center(child: Text('The requested page does not exist')),
        ),
      ),
    );
  }
}
