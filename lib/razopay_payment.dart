import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayPayment extends ConsumerStatefulWidget {
  const RazorpayPayment({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RazorpayPaymentState();
}

class _RazorpayPaymentState extends ConsumerState<RazorpayPayment> {
  late Razorpay _razorpay;
  TextEditingController controller = TextEditingController();
  void checkout(amount) {
    if (amount != null && amount.toString().isNotEmpty) {
      double parsedAmount = double.tryParse(amount.toString()) ?? 0;
      if (parsedAmount <= 0) {
        Fluttertoast.showToast(
            msg: 'Please enter a valid amount',
            toastLength: Toast.LENGTH_SHORT);
        return;
      }

      int amountInPaise = (parsedAmount * 100).toInt();

      // Modified options for test environment
      var option = {
        'key': 'rzp_test_xzSIqwmnAVFhxu',
        'amount': amountInPaise,
        'name': 'dumde',
        'description': 'Test Payment',
        'prefill': {
          'contact': '9999999999',
          'email': 'test@example.com',
          'upi': 'success@razorpay'
        },
        'theme': {
          'color': '#3399cc',
        },
        'method': {
          'netbanking': true,
          'card': true,
          'upi': true,
          'wallet': true
        },
        'send_sms_hash': true,
        'remember_customer': true
      };

      try {
        debugPrint('Opening Razorpay with options: ${option.toString()}');
        _razorpay.open(option);
      } catch (e) {
        debugPrint('Razorpay error: ${e.toString()}');
        Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
      }
    } else {
      Fluttertoast.showToast(
          msg: 'Please enter an amount', toastLength: Toast.LENGTH_SHORT);
    }
  }

  void handlePaymentSuccess(PaymentSuccessResponse response) {
    Fluttertoast.showToast(
        msg: 'Payment Success ${response.paymentId!}',
        toastLength: Toast.LENGTH_SHORT);
  }

  void handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(
        msg: 'Payment Fail ${response.message!}',
        toastLength: Toast.LENGTH_SHORT);
  }

  void handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(
        msg: 'External Wallet ${response.walletName!}',
        toastLength: Toast.LENGTH_SHORT);
  }

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: const Text('Razorpay Payment',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50),
              const Text(
                'Enter Payment Amount',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon:
                      const Icon(Icons.currency_rupee, color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => checkout(controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
