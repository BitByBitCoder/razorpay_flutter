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
  TextEditingController amountController = TextEditingController();
  bool _showQRCode = false;
  String _paymentId = '';
  Timer? _statusCheckTimer;

  @override
  void dispose() {
    super.dispose();
    amountController.dispose();
    _statusCheckTimer?.cancel();
  }

  void initiateQRPayment(String amount) {
    if (amount.isEmpty ||
        double.tryParse(amount) == null ||
        double.tryParse(amount)! <= 0) {
      Fluttertoast.showToast(msg: 'Please enter a valid amount');
      return;
    }

    _paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
    ref.read(paymentStatusProvider.notifier).state = PaymentStatus.pending;
    setState(() => _showQRCode = true);
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
        setState(() => _showQRCode = false);
        ref.read(paymentStatusProvider.notifier).state = PaymentStatus.initial;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentStatus = ref.watch(paymentStatusProvider);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('QR Payment', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _showQRCode
          ? _buildQRCodeScreen(paymentStatus)
          : _buildPaymentInputScreen(),
    );
  }

  Widget _buildPaymentInputScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.qr_code_scanner, size: 60, color: Colors.blue),
          const SizedBox(height: 20),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 20),
            decoration: InputDecoration(
              labelText: 'Amount (₹)',
              labelStyle: TextStyle(color: Colors.blue[200]),
              prefixIcon:
                  const Icon(Icons.currency_rupee, color: Colors.white70),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => initiateQRPayment(amountController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child:
                const Text('Generate QR Code', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeScreen(PaymentStatus status) {
    double amount = double.tryParse(amountController.text) ?? 0;
    String upiString =
        'upi://pay?pa=receiver@upi&pn=Merchant%20Name&am=$amount&tn=Payment%20for%20services&tr=$_paymentId';

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStatusIndicator(status),
          const SizedBox(height: 20),
          Text(
            '₹${amountController.text}',
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
              setState(() => _showQRCode = false);
              ref.read(paymentStatusProvider.notifier).state =
                  PaymentStatus.initial;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel Payment', style: TextStyle(fontSize: 16)),
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
