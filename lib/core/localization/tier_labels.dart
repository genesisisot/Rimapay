import '../providers/auth_provider.dart';
import 'l10n.dart';

/// Translated tier name. Names match the Account Tiers screen:
/// Basic → Standard → Premium (tier0 is the pre-KYC underbanking account).
extension TierLabel on TierLevel {
  String label(AppL10n t) => switch (this) {
        TierLevel.tier0 => t.underbankingAccount,
        TierLevel.tier1 => t.tierBasic,
        TierLevel.tier2 => t.tierStandard,
        TierLevel.tier3 => t.tierPremium,
      };
}
