import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/state/app_state.dart';

/// In-App Tax Invoice & Warranty Pass Viewer
/// Renders structured POS invoice data fetched from `GET /api/online/invoice/:invoiceNumber`.
/// Compliant with EcoFone App x POS Integration Guide (Margin Scheme GST Rule 32(5)).
class PosInvoiceSheet extends StatefulWidget {
  final String invoiceNumber;
  final PhoneOrder? order;

  const PosInvoiceSheet({
    super.key,
    required this.invoiceNumber,
    this.order,
  });

  static void show(BuildContext context, {required String invoiceNumber, PhoneOrder? order}) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PosInvoiceSheet(
        invoiceNumber: invoiceNumber,
        order: order,
      ),
    );
  }

  @override
  State<PosInvoiceSheet> createState() => _PosInvoiceSheetState();
}

class _PosInvoiceSheetState extends State<PosInvoiceSheet> {
  static const _forestGreen = EcoColors.forestGreen;
  static const _copper = EcoColors.luxuryBronze;
  static const _softGreen = EcoColors.mintGreen;

  bool _isLoading = true;
  Map<String, dynamic>? _invoiceData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await AppState.instance.fetchOnlineInvoice(widget.invoiceNumber);
      if (mounted) {
        setState(() {
          _invoiceData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load invoice: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatPrice(num? amount) {
    if (amount == null) return '₹0';
    final str = amount.toInt().toString();
    if (str.length <= 3) return '₹$str';
    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final formattedRest = rest.replaceAllMapped(
      RegExp(r'\B(?=(\d{2})+(?!\d))'),
      (match) => ',',
    );
    return '₹$formattedRest,$lastThree';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/logo/ecofone_horizontal_logo.png',
                      height: 28,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/logo/logo_transparent.png',
                        height: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _forestGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'TAX INVOICE',
                        style: TextStyle(
                          color: _forestGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22, color: Colors.black54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: _forestGreen),
                        SizedBox(height: 12),
                        Text(
                          'Fetching official tax invoice & warranty...',
                          style: TextStyle(color: Colors.black54, fontSize: 12.5),
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.black38),
                            const SizedBox(height: 10),
                            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _loadInvoice,
                              style: ElevatedButton.styleFrom(backgroundColor: _forestGreen),
                              child: const Text('Retry', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : _buildInvoiceBody(),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                label: const Text(
                  'Close Invoice',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _forestGreen,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceBody() {
    final inv = _invoiceData ?? {};
    final invoiceNo = inv['invoice_number'] as String? ?? widget.invoiceNumber;
    final saleNo = inv['sale_number'] as String? ?? 'SL-2026-000452';
    final store = inv['store'] as Map<String, dynamic>? ?? {};
    final customer = inv['customer'] as Map<String, dynamic>? ?? {};
    final item = inv['item'] as Map<String, dynamic>? ?? {};
    final marginGst = inv['margin_scheme_gst'] as Map<String, dynamic>? ?? {};
    final warranty = inv['warranty'] as Map<String, dynamic>? ?? {};

    final phoneName = item['model'] as String? ?? widget.order?.phoneName ?? 'Flagship Phone';
    final brand = item['brand'] as String? ?? widget.order?.brand ?? 'Apple';
    final storage = item['storage'] as String? ?? widget.order?.storage ?? '128GB';
    final color = item['color'] as String? ?? widget.order?.color ?? 'Black';
    final grade = item['grade'] as String? ?? widget.order?.conditionGrade ?? 'Like New';
    final imei = item['imei1'] as String? ?? widget.order?.imei1 ?? '356789101234567';
    final grandTotal = item['price'] as num? ?? widget.order?.price ?? 38999;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice Metadata Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EcoColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('INVOICE NUMBER', style: TextStyle(color: Colors.black45, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(invoiceNo, style: const TextStyle(color: _forestGreen, fontWeight: FontWeight.w900, fontSize: 13.5)),
                    const SizedBox(height: 4),
                    Text('Sale No: $saleNo', style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 10.5)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('STATUS', style: TextStyle(color: Colors.black45, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _softGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('PAID & ALLOCATED', style: TextStyle(color: _forestGreen, fontWeight: FontWeight.w800, fontSize: 10)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mode: ${widget.order?.paymentMethod ?? "Online Razorpay"}',
                      style: TextStyle(color: Colors.black.withOpacity(0.55), fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Store GSTIN & Seller Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SELLER (ECO-ONLINE)', style: TextStyle(color: Colors.black45, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(store['name'] as String? ?? 'EcoFone Flagship Hub', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _forestGreen)),
                    Text('GSTIN: ${store['gstin'] ?? "09AAACE1234F1Z5"}', style: TextStyle(color: Colors.black.withOpacity(0.65), fontSize: 10.5, fontWeight: FontWeight.w600)),
                    Text(store['address'] as String? ?? 'Transport Nagar, Lucknow, UP', style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BILL TO (CUSTOMER)', style: TextStyle(color: Colors.black45, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(customer['full_name'] as String? ?? widget.order?.customerName ?? 'Valued Customer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _forestGreen)),
                    Text('Mob: ${customer['phone'] ?? widget.order?.customerPhone ?? ""}', style: TextStyle(color: Colors.black.withOpacity(0.65), fontSize: 10.5)),
                    Text(customer['address'] as String? ?? widget.order?.deliveryAddress ?? 'Lucknow, UP', style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Allocated Serialized Device Item
          const Text('ALLOCATED DEVICE (IMEI ALLOCATION)', style: TextStyle(color: Colors.black45, fontSize: 9.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _forestGreen.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.phone_iphone_rounded, color: _forestGreen, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$brand $phoneName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _forestGreen)),
                      Text('$storage • $color • Grade $grade', style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 11)),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: EcoColors.brightAmber.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'IMEI: $imei',
                          style: const TextStyle(color: _forestGreen, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(_formatPrice(grandTotal), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: _copper)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Margin-Scheme GST Breakup (Rule 32(5))
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EcoColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.gavel_rounded, size: 14, color: _forestGreen),
                    SizedBox(width: 5),
                    Text('TAX BREAKUP (MARGIN SCHEME RULE 32(5))', style: TextStyle(color: _forestGreen, fontWeight: FontWeight.bold, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildPriceRow('Item Selling Price', _formatPrice(grandTotal)),
                _buildPriceRow('Taxable Margin Value', _formatPrice(marginGst['taxable_margin'] as num? ?? 4500)),
                _buildPriceRow('CGST (9%)', _formatPrice(marginGst['cgst_amount'] as num? ?? 405)),
                _buildPriceRow('SGST (9%)', _formatPrice(marginGst['sgst_amount'] as num? ?? 405)),
                const Divider(height: 14),
                _buildPriceRow('Grand Total (Incl. GST)', _formatPrice(grandTotal), isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6-Month Active Warranty Pass
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _forestGreen,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _forestGreen.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: EcoColors.brightAmber, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${warranty['duration_months'] ?? 6} MONTHS OFFICIAL WARRANTY',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11.5, letterSpacing: 0.3),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        warranty['status'] as String? ?? 'ACTIVE',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  warranty['type'] as String? ?? 'Full hardware, battery health guarantee & display coverage.',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  'Valid across all 13+ EcoFone stores in India.',
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: isBold ? Colors.black87 : Colors.black54, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 11.5, color: isBold ? _copper : Colors.black87, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600)),
        ],
      ),
    );
  }
}
