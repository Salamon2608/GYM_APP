import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gym_management/core/theme/app_theme.dart';
import 'package:gym_management/features/member/providers/payment_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gym_management/core/router/app_router.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentHistoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        title: const Text('Payment History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.memberDashboard);
            }
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(paymentHistoryProvider.future),
        color: AppTheme.primaryColor,
        backgroundColor: AppTheme.cardDark,
        child: paymentsAsync.when(
          data: (payments) {
            if (payments.isEmpty) {
              return _buildEmptyState();
            }
            return _buildPaymentsContent(payments);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
          error: (err, stack) => _buildErrorState(err),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: AppTheme.textSecondary.withValues(alpha: 0.4),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 16),
              Text(
                'No Payment Records Found',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Once you make a purchase, it will appear here.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(Object err) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load payments',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(paymentHistoryProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsContent(List<Map<String, dynamic>> payments) {
    // Calculate summary statistics
    final completedPayments = payments.where((p) => p['status'] == 'completed');
    final totalSpent = completedPayments.fold<double>(
      0.0,
      (sum, p) => sum + (double.tryParse(p['amount']?.toString() ?? '0') ?? 0.0),
    );
    final totalCount = completedPayments.length;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: payments.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSummaryHeader(totalSpent, totalCount);
        }
        final payment = payments[index - 1];
        return _buildPaymentCard(payment).animate().fadeIn(
          delay: (index * 50).ms,
          duration: 300.ms,
          curve: Curves.easeOut,
        ).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildSummaryHeader(double totalSpent, int totalCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.15),
            AppTheme.cardDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Investment',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '₹${totalSpent.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Transactions',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalCount Paid',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final planName = payment['plan_name'] ?? 'Custom Plan';
    final amount = payment['amount'] ?? '0.00';
    final status = payment['status'] ?? 'pending';
    final rawDate = payment['created_at'] ?? '';
    final parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(parsedDate);
    final receiptNumber = payment['receipt_number'] ?? 'N/A';
    final method = payment['method'] ?? 'online';

    Color statusColor;
    IconData statusIcon;
    switch (status.toString().toLowerCase()) {
      case 'completed':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'failed':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.error_outline;
        break;
      default:
        statusColor = AppTheme.accentColor;
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppTheme.borderDark,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () => _showReceiptBottomSheet(payment['id']),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        planName,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '₹$amount',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            status.toString().toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppTheme.borderDark, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Receipt: $receiptNumber',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontFamily: 'Courier',
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          method.toString().toLowerCase() == 'cash'
                              ? Icons.money_rounded
                              : Icons.payment_rounded,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          method.toString().toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReceiptBottomSheet(String paymentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.scaffoldDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final receiptAsync = ref.watch(paymentReceiptProvider(paymentId));

            return Container(
              padding: const EdgeInsets.all(24.0),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: receiptAsync.when(
                data: (receipt) => _buildReceiptDetails(receipt),
                loading: () => const SizedBox(
                  height: 250,
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                ),
                error: (err, stack) => SizedBox(
                  height: 250,
                  child: Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReceiptDetails(Map<String, dynamic> receipt) {
    final gymName = receipt['gym_name'] ?? 'TRACEFIT Partner Gym';
    final gymAddress = receipt['gym_address'] ?? 'N/A';
    final gymPhone = receipt['gym_phone'] ?? 'N/A';
    final planName = receipt['plan_name'] ?? 'Membership Plan';
    final receiptNumber = receipt['receipt_number'] ?? 'N/A';
    final amount = receipt['amount'] ?? '0.00';
    final method = receipt['method'] ?? 'online';
    final transactionId = receipt['transaction_id'] ?? 'N/A';
    final orderId = receipt['razorpay_order_id'] ?? 'N/A';
    final status = receipt['status'] ?? 'completed';
    final date = DateTime.tryParse(receipt['created_at'] ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
    final memberName = receipt['member_name'] ?? 'Valued Member';
    final memberEmail = receipt['member_email'] ?? 'N/A';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Receipt Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.borderDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  'TRACEFIT',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Official Payment Receipt',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Gym & Date Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gymName,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (gymAddress != 'N/A') ...[
                      const SizedBox(height: 4),
                      Text(
                        gymAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (gymPhone != 'N/A') ...[
                      const SizedBox(height: 4),
                      Text(
                        'Phone: $gymPhone',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RECEIPT NO',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    receiptNumber,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: AppTheme.borderDark, height: 32),

          // Member Details
          Text(
            'BILLED TO',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            memberName,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            memberEmail,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const Divider(color: AppTheme.borderDark, height: 32),

          // Purchase Summary Table
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ITEM DESCRIPTION',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'AMOUNT',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$planName Membership',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '₹$amount',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Paid',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹$amount',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Payment Details Meta
          Text(
            'TRANSACTION METADATA',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildMetaRow('Date & Time', formattedDate),
          _buildMetaRow('Payment Method', method.toString().toUpperCase()),
          _buildMetaRow('Status', status.toString().toUpperCase()),
          if (transactionId != 'N/A') _buildMetaRow('Transaction ID', transactionId),
          if (orderId != 'N/A') _buildMetaRow('Razorpay Order ID', orderId),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _downloadReceiptPdf(receipt),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cardDark,
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.borderDark),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _downloadReceiptPdf(Map<String, dynamic> receipt) async {
    final pdf = pw.Document();

    final gymName = receipt['gym_name'] ?? 'TRACEFIT Partner Gym';
    final gymAddress = receipt['gym_address'] ?? 'N/A';
    final planName = receipt['plan_name'] ?? 'Membership Plan';
    final amount = receipt['amount'] ?? '0.00';
    final method = receipt['method'] ?? 'online';
    final status = receipt['status'] ?? 'completed';
    final date = DateTime.tryParse(receipt['created_at'] ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
    final receiptNumber = receipt['receipt_number'] ?? 'N/A';
    final memberName = receipt['member_name'] ?? 'Valued Member';
    final memberEmail = receipt['member_email'] ?? 'N/A';
    final transactionId = receipt['transaction_id'] ?? 'N/A';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TRACEFIT', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange)),
                    pw.Text('PAYMENT RECEIPT', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
                  ]
                )
              ),
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILLED TO', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                      pw.SizedBox(height: 5),
                      pw.Text(memberName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text(memberEmail, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('GYM DETAILS', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                      pw.SizedBox(height: 5),
                      pw.Text(gymName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      if (gymAddress != 'N/A') pw.Text(gymAddress, style: pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Table.fromTextArray(
                context: context,
                border: const pw.TableBorder(
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                  horizontalInside: pw.BorderSide(color: PdfColors.grey300),
                ),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellHeight: 35,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                },
                data: <List<String>>[
                  <String>['ITEM DESCRIPTION', 'AMOUNT'],
                  <String>['$planName Membership', 'INR $amount'],
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total Paid: ', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('INR $amount', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange)),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Text('TRANSACTION DETAILS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
              pw.SizedBox(height: 10),
              pw.Text('Receipt No: $receiptNumber', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Date: $formattedDate', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Payment Method: ${method.toString().toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Status: ${status.toString().toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
              if (transactionId != 'N/A') pw.Text('Transaction ID: $transactionId', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 40),
              pw.Center(child: pw.Text('Thank you for choosing Tracefit!', style: pw.TextStyle(color: PdfColors.grey600, fontStyle: pw.FontStyle.italic))),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'receipt_$receiptNumber.pdf');
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontFamily: value.startsWith('TF-') || value.startsWith('pay_') || value.startsWith('order_')
                    ? 'Courier'
                    : null,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
