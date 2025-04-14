import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qr_flutter/qr_flutter.dart';

final paymentStatusProvider =
    StateProvider<PaymentStatus>((ref) => PaymentStatus.initial);

enum PaymentStatus { initial, pending, success, failed }

class QRPayment extends ConsumerStatefulWidget {
  const QRPayment({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _QRPaymentState();
}

class _QRPaymentState extends ConsumerState<QRPayment> {
  final double fixedAmount = 1400.0;
  String _paymentId = '';
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();

    // Start the QR generation and state update after widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initiateQRPayment(fixedAmount.toString());
    });
  }

  @override
  void dispose() {
    super.dispose();
    _statusCheckTimer?.cancel();
  }

  void initiateQRPayment(String amount) {
    if (amount.isEmpty ||
        double.tryParse(amount) == null ||
        double.tryParse(amount)! <= 0) {
      Fluttertoast.showToast(msg: 'Invalid fixed amount');
      return;
    }

    _paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
    ref.read(paymentStatusProvider.notifier).state = PaymentStatus.pending;
    _startPaymentStatusCheck();
  }

  void _startPaymentStatusCheck() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (timer.tick > 5) {
        _statusCheckTimer?.cancel();
        ref.read(paymentStatusProvider.notifier).state = PaymentStatus.success;
        handlePaymentSuccess();
      }
    });
  }

  void handlePaymentSuccess() {
    ref.read(paymentStatusProvider.notifier).state = PaymentStatus.success;
    Fluttertoast.showToast(
      msg: 'Payment Successful: $_paymentId',
      toastLength: Toast.LENGTH_LONG,
      backgroundColor: Colors.green,
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ref.read(paymentStatusProvider.notifier).state = PaymentStatus.initial;
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentStatus = ref.watch(paymentStatusProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close)),
      ),
      body: _buildQRCodeScreen(paymentStatus),
    );
  }

  Widget _buildQRCodeScreen(PaymentStatus status) {
    String upiString =
        'upi://pay?pa=receiver@upi&pn=Merchant%20Name&am=$fixedAmount&tn=Payment%20for%20services&tr=$_paymentId';

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStatusIndicator(status),
          const SizedBox(height: 20),
          Text(
            '₹$fixedAmount',
            style: const TextStyle(
                fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: upiString,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Scan with any UPI app',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              _statusCheckTimer?.cancel();
              ref.read(paymentStatusProvider.notifier).state =
                  PaymentStatus.initial;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel Payment',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(PaymentStatus status) {
    String message;
    Color color;
    IconData icon;

    switch (status) {
      case PaymentStatus.pending:
        message = 'Waiting for payment...';
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      case PaymentStatus.success:
        message = 'Payment successful!';
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case PaymentStatus.failed:
        message = 'Payment failed';
        color = Colors.red;
        icon = Icons.error;
        break;
      case PaymentStatus.initial:
      default:
        message = 'Initializing payment...';
        color = Colors.blue;
        icon = Icons.refresh;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Text(
            message,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (status == PaymentStatus.pending) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
