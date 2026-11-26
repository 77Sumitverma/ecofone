import 'package:flutter/material.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/models/user_profile.dart';

/// Displays either:
/// - For an existing user with saved Name/Address: an interactive suggestion card
///   showing their previously registered details with one-tap "Use Saved" / "Enter New"
/// - For a new user placing their first order: a clean prompt explaining their
///   name & delivery address will be saved once the order is placed.
class SavedCheckoutSuggestionCard extends StatelessWidget {
  final SavedCheckoutDetails? savedDetails;
  final bool isApplied;
  final VoidCallback onApplySaved;
  final VoidCallback onEnterNew;

  static const Color _forestGreen = EcoColors.forestGreen;
  static const Color _copper = Color(0xFFB45309);

  const SavedCheckoutSuggestionCard({
    super.key,
    required this.savedDetails,
    required this.isApplied,
    required this.onApplySaved,
    required this.onEnterNew,
  });

  @override
  Widget build(BuildContext context) {
    final details = savedDetails;
    if (details == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: EcoColors.brightAmber.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _copper.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _copper.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, color: _copper, size: 17),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'First Order Profile Setup',
                    style: TextStyle(
                      color: _forestGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Enter your full name & delivery address below. We will save them for quick suggestions on future orders.',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final displayParts = <String>[
      if (details.address.isNotEmpty) details.address,
      if (details.city.isNotEmpty &&
          !details.address.toLowerCase().contains(details.city.toLowerCase()))
        details.city,
      if (details.pincode.isNotEmpty &&
          !details.address.contains(details.pincode))
        details.pincode,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isApplied
            ? _forestGreen.withOpacity(0.08)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isApplied ? _forestGreen : EcoColors.mintGreen.withOpacity(0.55),
          width: isApplied ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: _forestGreen, size: 16),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Saved Details Suggestion',
                  style: TextStyle(
                    color: _forestGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isApplied ? _forestGreen : _copper.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isApplied ? 'Applied ✓' : 'Old Profile Data',
                  style: TextStyle(
                    color: isApplied ? Colors.white : _copper,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (details.name.isNotEmpty)
            Text(
              details.name,
              style: const TextStyle(
                color: _forestGreen,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          if (displayParts.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              displayParts.join(' • '),
              style: TextStyle(
                color: _forestGreen.withOpacity(0.75),
                fontSize: 11.5,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApplySaved,
                  icon: Icon(
                    isApplied ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                    size: 15,
                  ),
                  label: Text(
                    isApplied ? 'Using Saved Details' : 'Use Saved Details',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _forestGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (isApplied) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onEnterNew,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _copper,
                    side: BorderSide(color: _copper.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Enter New',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
