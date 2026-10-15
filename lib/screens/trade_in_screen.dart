import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecofone/core/theme/anim_utils.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/core/widgets/brand_logo.dart';
import 'package:ecofone/state/app_state.dart';

class TradeInScreen extends StatefulWidget {
  const TradeInScreen({super.key});

  @override
  State<TradeInScreen> createState() => _TradeInScreenState();
}

class _DeviceModel {
  final String name;
  final int basePrice128;
  final String brand;

  const _DeviceModel({
    required this.name,
    required this.basePrice128,
    required this.brand,
  });
}

class _TradeInScreenState extends State<TradeInScreen> {
  // Brand colors
  static const _bgColor = EcoColors.background;
  static const _forestGreen = EcoColors.forestGreen;
  static const _copper = EcoColors.vibrantOrange;
  static const _softGreen = EcoColors.mintGreen;

  // Brands and models
  final List<String> _brands = const ['Apple', 'Samsung', 'OnePlus', 'Google', 'Xiaomi'];
  late String _selectedBrand;

  final List<_DeviceModel> _allModels = const [
    _DeviceModel(name: 'iPhone 14 Pro', basePrice128: 52000, brand: 'Apple'),
    _DeviceModel(name: 'iPhone 13', basePrice128: 34000, brand: 'Apple'),
    _DeviceModel(name: 'iPhone 12', basePrice128: 24000, brand: 'Apple'),
    _DeviceModel(name: 'iPhone 11', basePrice128: 17000, brand: 'Apple'),
    _DeviceModel(name: 'Galaxy S23 Ultra', basePrice128: 56000, brand: 'Samsung'),
    _DeviceModel(name: 'Galaxy S22', basePrice128: 28000, brand: 'Samsung'),
    _DeviceModel(name: 'Galaxy Z Flip 4', basePrice128: 32000, brand: 'Samsung'),
    _DeviceModel(name: 'OnePlus 11', basePrice128: 31000, brand: 'OnePlus'),
    _DeviceModel(name: 'OnePlus 10 Pro', basePrice128: 23000, brand: 'OnePlus'),
    _DeviceModel(name: 'OnePlus Nord 3', basePrice128: 15000, brand: 'OnePlus'),
    _DeviceModel(name: 'Pixel 7 Pro', basePrice128: 35000, brand: 'Google'),
    _DeviceModel(name: 'Pixel 7', basePrice128: 26000, brand: 'Google'),
    _DeviceModel(name: 'Pixel 6a', basePrice128: 14000, brand: 'Google'),
    _DeviceModel(name: 'Redmi Note 12 Pro', basePrice128: 12000, brand: 'Xiaomi'),
    _DeviceModel(name: 'Xiaomi 13 Pro', basePrice128: 33000, brand: 'Xiaomi'),
  ];

  late _DeviceModel _selectedModel;
  String _selectedStorage = '128 GB';

  // Condition State
  bool _phoneTurnsOn = true;
  int _screenConditionIndex = 0; // 0: Flawless, 1: Minor Scratches, 2: Cracked/Lines
  int _bodyConditionIndex = 0;   // 0: Flawless, 1: Minor Scuffs, 2: Heavy Dents

  // Functional issues (true = defective)
  bool _cameraIssue = false;
  bool _batteryDegraded = false;
  bool _biometricsIssue = false;
  bool _speakerMicIssue = false;

  // Accessories included (true = yes, adds value)
  bool _hasOriginalCharger = true;
  bool _hasOriginalBox = true;
  bool _hasValidBill = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedBrand = _brands[0];
    _selectedModel = _allModels.firstWhere((m) => m.brand == _selectedBrand);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<_DeviceModel> get _filteredModels =>
      _allModels.where((m) => m.brand == _selectedBrand).toList();

  int _calculateQuote() {
    if (!_phoneTurnsOn) {
      return 2500; // Flat salvage value
    }

    int price = _selectedModel.basePrice128;

    // Storage tier adjustments
    if (_selectedStorage == '256 GB') {
      price += 3500;
    } else if (_selectedStorage == '512 GB') {
      price += 7000;
    }

    // Screen condition deduction
    if (_screenConditionIndex == 1) {
      price -= (price * 0.12).round();
    } else if (_screenConditionIndex == 2) {
      price -= (price * 0.38).round();
    }

    // Body condition deduction
    if (_bodyConditionIndex == 1) {
      price -= (price * 0.08).round();
    } else if (_bodyConditionIndex == 2) {
      price -= (price * 0.20).round();
    }

    // Functional defects
    if (_cameraIssue) price -= 2000;
    if (_batteryDegraded) price -= 1500;
    if (_biometricsIssue) price -= 2500;
    if (_speakerMicIssue) price -= 1000;

    // Accessories bonuses
    if (_hasOriginalCharger) price += 700;
    if (_hasOriginalBox) price += 500;
    if (_hasValidBill) price += 800;

    return price.clamp(2000, 150000);
  }

  int get _maxPossibleQuote {
    return _selectedModel.basePrice128 + 7000 + 700 + 500 + 800;
  }

  double get _valueRetentionRatio {
    final current = _calculateQuote();
    final maxP = _maxPossibleQuote;
    if (maxP <= 0) return 1.0;
    return (current / maxP).clamp(0.05, 1.0);
  }

  int get _totalBonusAmount {
    int bonus = 0;
    if (_hasOriginalCharger) bonus += 700;
    if (_hasOriginalBox) bonus += 500;
    if (_hasValidBill) bonus += 800;
    return bonus;
  }

  String _formatPrice(int price) {
    final str = price.toString();
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
    final finalQuote = _calculateQuote();

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _forestGreen, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: const EcoFoneHeaderLogo(
          emblemSize: 30,
          titleSize: 16,
          subtitleSize: 8.5,
          customSubtitle: 'Trade-in • Instant Cash',
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
            decoration: BoxDecoration(
              color: EcoColors.mintLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: EcoColors.mintBorder),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, color: EcoColors.mintGreen, size: 14),
                SizedBox(width: 3),
                Text(
                  '15-Min Payout',
                  style: TextStyle(
                    color: EcoColors.mintGreen,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. Animated Live Valuation Hero Card
                  _buildAnimatedHeroValuation(finalQuote),
                  const SizedBox(height: 18),

                  // B. Step 1: Device Model Selection
                  _buildSectionHeader(
                    stepNumber: '1',
                    title: 'Select Your Old Phone',
                    subtitle: 'Choose exact brand, model & storage capacity',
                  ),
                  const SizedBox(height: 12),
                  _buildBrandSelector(),
                  const SizedBox(height: 14),
                  _buildModelSelector(),
                  const SizedBox(height: 14),
                  _buildStorageSelector(),
                  const SizedBox(height: 22),

                  // C. Step 2: Health Assessment
                  _buildSectionHeader(
                    stepNumber: '2',
                    title: 'Physical & Functional Health',
                    subtitle: 'Accurate answers ensure guaranteed on-spot payout',
                  ),
                  const SizedBox(height: 12),
                  _buildPowerCheckCard(),

                  // Animated smooth crossfade when phone turns on/off
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 320),
                    firstCurve: Curves.easeOutCubic,
                    secondCurve: Curves.easeInCubic,
                    crossFadeState: _phoneTurnsOn
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Column(
                      children: [
                        const SizedBox(height: 14),
                        _buildScreenConditionCard(),
                        const SizedBox(height: 14),
                        _buildBodyConditionCard(),
                        const SizedBox(height: 14),
                        _buildFunctionalDefectsCard(),
                        const SizedBox(height: 14),
                        _buildAccessoriesBonusCard(),
                      ],
                    ),
                    secondChild: Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: EcoColors.softOrange,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: EcoColors.orangeBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.recycling_rounded, color: EcoColors.vibrantOrange, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Guaranteed E-Waste Salvage Value',
                                  style: TextStyle(
                                    color: EcoColors.forestGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Dead or non-functional phones are safely recycled with certified zero toxic landfill disposal.',
                                  style: TextStyle(
                                    color: EcoColors.forestGreen.withOpacity(0.7),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // D. Step 3: Guarantees & Eco Impact
                  _buildGuaranteedValuationPromiseCard(),
                  const SizedBox(height: 12),
                  _buildGuaranteesCard(),
                  const SizedBox(height: 20),
                  _buildEcoImpactCard(),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomStickyBar(finalQuote),
    );
  }

  // --- Animated Live Valuation Hero Card ---
  Widget _buildAnimatedHeroValuation(int quote) {
    final retentionPct = (_valueRetentionRatio * 100).round();
    final isDead = !_phoneTurnsOn;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _forestGreen,
            _forestGreen.withOpacity(0.92),
            const Color(0xFF143026),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _forestGreen.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: EcoColors.mintGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Live Benchmark Valuation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: EcoColors.brightAmber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: EcoColors.brightAmber.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_clock_rounded, size: 12, color: EcoColors.brightAmber),
                    SizedBox(width: 4),
                    Text(
                      '7-Day Price Lock',
                      style: TextStyle(
                        color: EcoColors.brightAmber,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Selected device title & calculation trigger
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${_selectedModel.name} • $_selectedStorage',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              BouncingWidget(
                scaleFactor: 0.94,
                onTap: () => _showCalculationBreakdownSheet(context, quote),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Breakdown',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Rolling Price Counter
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedPriceCounter(
                targetPrice: quote,
                duration: const Duration(milliseconds: 400),
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Instant Cash Payout',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Condition Retention Progress Bar
          if (!isDead) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Value Retention Ratio',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$retentionPct% Max Value',
                  style: const TextStyle(
                    color: EcoColors.mintGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: _valueRetentionRatio),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, ratio, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ratio > 0.75
                          ? EcoColors.mintGreen
                          : (ratio > 0.45 ? EcoColors.brightAmber : EcoColors.vibrantOrange),
                    ),
                  ),
                );
              },
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: EcoColors.brightAmber, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Salvage price applied. Safe green recycling guaranteed.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Bonus Cash Pill
          if (_totalBonusAmount > 0 && !isDead) ...[
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: EcoColors.mintGreen.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: EcoColors.mintGreen.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_circle_outline_rounded, size: 14, color: EcoColors.mintGreen),
                  const SizedBox(width: 6),
                  Text(
                    '+₹$_totalBonusAmount bonus included for accessories & invoice',
                    style: const TextStyle(
                      color: EcoColors.mintGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Calculation Breakdown Bottom Sheet ---
  void _showCalculationBreakdownSheet(BuildContext context, int finalQuote) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Price Calculation Breakdown',
                    style: TextStyle(
                      color: _forestGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatPrice(finalQuote),
                    style: const TextStyle(
                      color: _copper,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              _breakdownRow(
                title: 'Base Market Value (${_selectedModel.name})',
                value: _formatPrice(_selectedModel.basePrice128),
                isPositive: true,
              ),
              if (_selectedStorage == '256 GB')
                _breakdownRow(title: 'Storage Upgrade (256 GB)', value: '+₹3,500', isPositive: true)
              else if (_selectedStorage == '512 GB')
                _breakdownRow(title: 'Storage Upgrade (512 GB)', value: '+₹7,000', isPositive: true),
              if (!_phoneTurnsOn)
                _breakdownRow(title: 'Non-functional / Dead Deduction', value: '- Flat Salvage', isPositive: false)
              else ...[
                if (_screenConditionIndex == 1)
                  _breakdownRow(title: 'Screen (Minor Scratches)', value: '-12%', isPositive: false)
                else if (_screenConditionIndex == 2)
                  _breakdownRow(title: 'Screen (Cracked/Lines)', value: '-38%', isPositive: false),
                if (_bodyConditionIndex == 1)
                  _breakdownRow(title: 'Body (Minor Scuffs)', value: '-8%', isPositive: false)
                else if (_bodyConditionIndex == 2)
                  _breakdownRow(title: 'Body (Heavy Dents)', value: '-20%', isPositive: false),
                if (_cameraIssue)
                  _breakdownRow(title: 'Camera Issue', value: '-₹2,000', isPositive: false),
                if (_batteryDegraded)
                  _breakdownRow(title: 'Battery Health < 80%', value: '-₹1,500', isPositive: false),
                if (_biometricsIssue)
                  _breakdownRow(title: 'Face/Touch ID Fault', value: '-₹2,500', isPositive: false),
                if (_speakerMicIssue)
                  _breakdownRow(title: 'Speaker/Mic Fault', value: '-₹1,000', isPositive: false),
                if (_hasOriginalCharger)
                  _breakdownRow(title: 'Original Fast Charger Bonus', value: '+₹700', isPositive: true),
                if (_hasOriginalBox)
                  _breakdownRow(title: 'Original Box Bonus', value: '+₹500', isPositive: true),
                if (_hasValidBill)
                  _breakdownRow(title: 'Tax Invoice / Bill Bonus', value: '+₹800', isPositive: true),
              ],
              const Divider(),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.verified_rounded, color: _forestGreen, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Guaranteed on-spot UPI or Cash payment at any EcoFone store.',
                      style: TextStyle(
                        color: _forestGreen.withOpacity(0.7),
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _breakdownRow({
    required String title,
    required String value,
    required bool isPositive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: _forestGreen.withOpacity(0.85),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isPositive ? EcoColors.darkEmerald : Colors.red.shade700,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String stepNumber,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _forestGreen,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _forestGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: _forestGreen.withOpacity(0.65),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Brand Selector ---
  Widget _buildBrandSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. Select Brand',
          style: TextStyle(
            color: _forestGreen,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _brands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final brand = _brands[index];
              final isSelected = brand == _selectedBrand;
              final icon = switch (brand) {
                'Apple' => Icons.phone_iphone_rounded,
                'Samsung' => Icons.smartphone_rounded,
                'OnePlus' => Icons.flash_on_rounded,
                'Google' => Icons.grain_rounded,
                _ => Icons.devices_other_rounded,
              };

              return BouncingWidget(
                scaleFactor: 0.94,
                onTap: () {
                  if (_selectedBrand != brand) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedBrand = brand;
                      _selectedModel = _filteredModels.first;
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? _forestGreen : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _forestGreen : Colors.black.withOpacity(0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? _forestGreen.withOpacity(0.2) : Colors.black.withOpacity(0.03),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 15,
                        color: isSelected ? Colors.white : _forestGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        brand,
                        style: TextStyle(
                          color: isSelected ? Colors.white : _forestGreen,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Model Selector ---
  Widget _buildModelSelector() {
    final models = _filteredModels;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. Select Model',
          style: TextStyle(
            color: _forestGreen,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: models.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final model = models[index];
              final isSelected = model.name == _selectedModel.name;
              return BouncingWidget(
                scaleFactor: 0.95,
                onTap: () {
                  if (_selectedModel.name != model.name) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedModel = model);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 142,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? _copper.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? _copper : Colors.black.withOpacity(0.08),
                      width: isSelected ? 1.8 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? _copper.withOpacity(0.12) : Colors.black.withOpacity(0.02),
                        blurRadius: isSelected ? 6 : 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        model.name,
                        style: TextStyle(
                          color: isSelected ? _copper : _forestGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Up to ${_formatPrice(model.basePrice128 + 7000 + 2000)}',
                        style: TextStyle(
                          color: _forestGreen.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Storage Selector ---
  Widget _buildStorageSelector() {
    const storages = ['128 GB', '256 GB', '512 GB'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. Storage Capacity',
          style: TextStyle(
            color: _forestGreen,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: storages.map((storage) {
            final isSelected = storage == _selectedStorage;
            return Expanded(
              child: BouncingWidget(
                scaleFactor: 0.94,
                onTap: () {
                  if (_selectedStorage != storage) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedStorage = storage);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? _forestGreen : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _forestGreen : Colors.black.withOpacity(0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? _forestGreen.withOpacity(0.2) : Colors.black.withOpacity(0.02),
                        blurRadius: isSelected ? 6 : 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    storage,
                    style: TextStyle(
                      color: isSelected ? Colors.white : _forestGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- Power Check Card ---
  Widget _buildPowerCheckCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.power_settings_new_rounded, color: _forestGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Does the phone switch on & function?',
                style: TextStyle(
                  color: _forestGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _selectionChip(
                  label: 'Yes, works',
                  selected: _phoneTurnsOn,
                  onTap: () => setState(() => _phoneTurnsOn = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _selectionChip(
                  label: 'No, dead/broken',
                  selected: !_phoneTurnsOn,
                  onTap: () => setState(() => _phoneTurnsOn = false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Screen Condition Card ---
  Widget _buildScreenConditionCard() {
    final options = [
      ('Flawless', 'No scratch or dent', Icons.diamond_outlined),
      ('Minor Scratches', 'Light surface lines', Icons.phone_android_rounded),
      ('Cracked / Lines', 'Visible crack or bleed', Icons.broken_image_outlined),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.phone_android_rounded, color: _forestGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Screen Condition',
                style: TextStyle(
                  color: _forestGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(options.length, (index) {
              final (label, desc, icon) = options[index];
              final isSelected = _screenConditionIndex == index;
              return BouncingWidget(
                scaleFactor: 0.98,
                onTap: () => setState(() => _screenConditionIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? _copper.withOpacity(0.08) : _bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? _copper : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? _copper : _forestGreen.withOpacity(0.6),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          color: _forestGreen,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        desc,
                        style: TextStyle(
                          color: _forestGreen.withOpacity(0.55),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- Body Condition Card ---
  Widget _buildBodyConditionCard() {
    final options = [
      ('Flawless', 'Like new, no scratches', Icons.auto_awesome_rounded),
      ('Minor Scuffs', 'Normal pocket wear', Icons.shield_outlined),
      ('Heavy Dents', 'Bends or cracks on frame', Icons.hardware_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.crop_portrait_rounded, color: _forestGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Physical Body & Frame Condition',
                style: TextStyle(
                  color: _forestGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(options.length, (index) {
              final (label, desc, icon) = options[index];
              final isSelected = _bodyConditionIndex == index;
              return BouncingWidget(
                scaleFactor: 0.98,
                onTap: () => setState(() => _bodyConditionIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? _copper.withOpacity(0.08) : _bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? _copper : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? _copper : _forestGreen.withOpacity(0.6),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          color: _forestGreen,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        desc,
                        style: TextStyle(
                          color: _forestGreen.withOpacity(0.55),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- Functional Defects Card ---
  Widget _buildFunctionalDefectsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build_circle_outlined, color: _forestGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Functional Check (Select if defective)',
                style: TextStyle(
                  color: _forestGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _issueFilterChip(
                label: 'Camera Faulty',
                selected: _cameraIssue,
                onSelected: (val) => setState(() => _cameraIssue = val),
              ),
              _issueFilterChip(
                label: 'Battery < 80%',
                selected: _batteryDegraded,
                onSelected: (val) => setState(() => _batteryDegraded = val),
              ),
              _issueFilterChip(
                label: 'Face/Fingerprint Faulty',
                selected: _biometricsIssue,
                onSelected: (val) => setState(() => _biometricsIssue = val),
              ),
              _issueFilterChip(
                label: 'Speaker/Mic Issue',
                selected: _speakerMicIssue,
                onSelected: (val) => setState(() => _speakerMicIssue = val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _issueFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.red.shade700 : _forestGreen,
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Colors.red.shade50,
      backgroundColor: _bgColor,
      checkmarkColor: Colors.red.shade700,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? Colors.red.shade300 : Colors.black.withOpacity(0.08),
        ),
      ),
    );
  }

  // --- Accessories Bonus Card ---
  Widget _buildAccessoriesBonusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.add_shopping_cart_rounded, color: _forestGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Available Accessories (Get Bonus Cash)',
                style: TextStyle(
                  color: _forestGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _accessorySwitchRow(
            title: 'Original Fast Charger',
            bonus: '+₹700',
            value: _hasOriginalCharger,
            onChanged: (val) => setState(() => _hasOriginalCharger = val),
          ),
          const Divider(height: 16),
          _accessorySwitchRow(
            title: 'Original Box with IMEI',
            bonus: '+₹500',
            value: _hasOriginalBox,
            onChanged: (val) => setState(() => _hasOriginalBox = val),
          ),
          const Divider(height: 16),
          _accessorySwitchRow(
            title: 'Valid Tax Invoice / Bill',
            bonus: '+₹800',
            value: _hasValidBill,
            onChanged: (val) => setState(() => _hasValidBill = val),
          ),
        ],
      ),
    );
  }

  Widget _accessorySwitchRow({
    required String title,
    required String bonus,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _forestGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                bonus,
                style: const TextStyle(
                  color: _softGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: (newVal) {
            HapticFeedback.selectionClick();
            onChanged(newVal);
          },
          activeColor: _softGreen,
        ),
      ],
    );
  }

  Widget _selectionChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return BouncingWidget(
      scaleFactor: 0.95,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _forestGreen : _bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _forestGreen : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _forestGreen,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // --- Guaranteed Valuation Promise Card (Zero CO2) ---
  Widget _buildGuaranteedValuationPromiseCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _forestGreen.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _softGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_user_rounded, color: _forestGreen, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EcoFone Price Lock & Safe Wipe Guarantee',
                  style: TextStyle(
                    color: _forestGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Guaranteed on-spot UPI/Cash payout with 100% certified on-desk data wipe.',
                  style: TextStyle(
                    color: _forestGreen,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Guarantees Card ---
  Widget _buildGuaranteesCard() {
    final badges = [
      (Icons.payments_outlined, 'Instant On-Spot UPI'),
      (Icons.security_rounded, '100% Safe Data Wipe'),
      (Icons.local_shipping_outlined, 'Free Doorstep Pickup'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: badges.map((item) {
        final (icon, text) = item;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Icon(icon, color: _copper, size: 20),
                const SizedBox(height: 4),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _forestGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- Eco Impact Green Footprint Card ---
  Widget _buildEcoImpactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EcoColors.mintLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EcoColors.mintBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: EcoColors.mintGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.eco_rounded, color: _forestGreen, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Positive Green Footprint',
                      style: TextStyle(
                        color: _forestGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Circular electronics lifecycle with 0% toxic landfill',
                      style: TextStyle(
                        color: _forestGreen,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '18.4 kg',
                        style: TextStyle(
                          color: _forestGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'CO2 Offset',
                        style: TextStyle(
                          color: _forestGreen.withOpacity(0.65),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '100%',
                        style: TextStyle(
                          color: EcoColors.vibrantOrange,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Safe Recycling',
                        style: TextStyle(
                          color: _forestGreen.withOpacity(0.65),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '0 Days',
                        style: TextStyle(
                          color: _forestGreen,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Payout Delay',
                        style: TextStyle(
                          color: _forestGreen.withOpacity(0.65),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Compact Sleek Sticky Bottom Bar ---
  Widget _buildBottomStickyBar(int price) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: EcoColors.mintGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Estimated Payout',
                      style: TextStyle(
                        color: _forestGreen.withOpacity(0.6),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                AnimatedPriceCounter(
                  targetPrice: price,
                  textStyle: const TextStyle(
                    color: _copper,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: BouncingWidget(
                scaleFactor: 0.96,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showTradeInBookingSheet(context, price);
                },
                child: LuxuryShimmerSweep(
                  interval: const Duration(seconds: 4),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_forestGreen, EcoColors.darkEmerald],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _forestGreen.withOpacity(0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt_rounded, size: 17, color: EcoColors.brightAmber),
                        SizedBox(width: 6),
                        Text(
                          'Book 15-Min Payout',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Compact Sleek Trade-In Booking Bottom Sheet ---
  void _showTradeInBookingSheet(BuildContext context, int price) {
    final nameController = TextEditingController(text: AppState.instance.userName ?? '');
    final phoneController = TextEditingController(text: AppState.instance.userPhone ?? '');
    String method = 'In-Store Walk-in (15-Min Instant Payout)';
    final activeStore = AppState.instance.selectedStore;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isStoreMethod = method.startsWith('In-Store');
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 12,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Top Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Instant Phone Payout Pass',
                              style: TextStyle(
                                color: _forestGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_selectedModel.name} • $_selectedStorage',
                              style: TextStyle(
                                color: _forestGreen.withOpacity(0.65),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _copper.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _copper.withOpacity(0.3)),
                          ),
                          child: Text(
                            _formatPrice(price),
                            style: const TextStyle(
                              color: _copper,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Active Store Hub Mini Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                      decoration: BoxDecoration(
                        color: _forestGreen.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _forestGreen.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded, color: _forestGreen, size: 15),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Store Hub: ${activeStore.name} (${AppState.instance.getLiveDistanceFrom(activeStore)} km)',
                              style: const TextStyle(
                                color: _forestGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Sleek Segmented Payout Method Selector
                    const Text(
                      'Select Payout Mode',
                      style: TextStyle(color: _forestGreen, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => method = 'In-Store Walk-in (15-Min Instant Payout)'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isStoreMethod ? _forestGreen.withOpacity(0.08) : _bgColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isStoreMethod ? _forestGreen : Colors.black.withOpacity(0.08),
                                  width: isStoreMethod ? 1.5 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.flash_on_rounded,
                                    size: 14,
                                    color: isStoreMethod ? _forestGreen : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '15-Min Store Walk-in',
                                    style: TextStyle(
                                      color: isStoreMethod ? _forestGreen : Colors.grey.shade700,
                                      fontWeight: isStoreMethod ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => method = 'Free Doorstep Evaluation'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              decoration: BoxDecoration(
                                color: !isStoreMethod ? _forestGreen.withOpacity(0.08) : _bgColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: !isStoreMethod ? _forestGreen : Colors.black.withOpacity(0.08),
                                  width: !isStoreMethod ? 1.5 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_shipping_outlined,
                                    size: 14,
                                    color: !isStoreMethod ? _forestGreen : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Doorstep Pickup',
                                    style: TextStyle(
                                      color: !isStoreMethod ? _forestGreen : Colors.grey.shade700,
                                      fontWeight: !isStoreMethod ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Compact Input Fields
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Your Full Name',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number (for UPI Payout & SMS)',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Compact Confirm CTA Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final rawPhone = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
                          if (rawPhone.length < 10) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
                            );
                            return;
                          }
                          final custName = nameController.text.trim().isEmpty ? 'Valued Customer' : nameController.text.trim();
                          if (!AppState.instance.isLoggedIn) {
                            AppState.instance.login(
                              name: custName,
                              phone: '+91 $rawPhone',
                            );
                          }

                          final quoteId = 'ECO-TRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                          final screenCond = switch (_screenConditionIndex) {
                            1 => 'Minor Scratches',
                            2 => 'Cracked / Lines',
                            _ => 'Flawless',
                          };
                          final bodyCond = switch (_bodyConditionIndex) {
                            1 => 'Minor Scuffs',
                            2 => 'Heavy Dents',
                            _ => 'Flawless',
                          };

                          final tradeQuote = TradeInQuote(
                            quoteId: quoteId,
                            brand: _selectedBrand,
                            modelName: _selectedModel.name,
                            storage: _selectedStorage,
                            estimatedPayout: price,
                            screenCondition: screenCond,
                            bodyCondition: bodyCond,
                            turnsOn: _phoneTurnsOn,
                            cameraWorking: !_cameraIssue,
                            batteryHealthy: !_batteryDegraded,
                            biometricsWorking: !_biometricsIssue,
                            speakerWorking: !_speakerMicIssue,
                            hasCharger: _hasOriginalCharger,
                            hasBox: _hasOriginalBox,
                            hasBill: _hasValidBill,
                            customerName: custName,
                            customerPhone: '+91 $rawPhone',
                            storeId: activeStore.id,
                            storeName: activeStore.name,
                            payoutMethod: method,
                            createdAt: DateTime.now(),
                          );

                          AppState.instance.submitTradeInQuote(tradeQuote);

                          Navigator.of(sheetContext).pop();
                          _showSuccessDialog(context, price, method, quoteId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _forestGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirm Trade-in Pass',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, int price, String method, [String? quoteId]) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _softGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: _softGreen, size: 50),
              ),
              const SizedBox(height: 16),
              const Text(
                'Trade-in Order Confirmed!',
                style: TextStyle(
                  color: _forestGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (quoteId != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _forestGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Pass ID: $quoteId',
                    style: const TextStyle(
                      color: _forestGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Bring your ${_selectedModel.name} to ${AppState.instance.selectedStore.name}. Our bench engineer will verify the phone and transfer ${_formatPrice(price)} instantly via UPI or Cash.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _forestGreen.withOpacity(0.7),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop(); // Back to home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _copper,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

