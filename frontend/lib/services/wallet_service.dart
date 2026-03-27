import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_transaction_model.dart';

class WalletService {
  static final _supabase = Supabase.instance.client;

  static Future<double> getWalletBalance() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0.0;

    final response = await _supabase
        .from('profiles')
        .select('pro_credits')
        .eq('id', user.id)
        .single();
    
    return (response['pro_credits'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<String?> getReferralCode() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select('referral_code')
        .eq('id', user.id)
        .single();
    
    return response['referral_code'] as String?;
  }

  static Future<List<WalletTransaction>> getTransactionHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('wallet_transactions')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => WalletTransaction.fromJson(json)).toList();
  }

  static Future<void> applyReferralCode(String code) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase.rpc('process_referral_reward', params: {
      'referred_user_id': user.id,
      'code': code,
    });
  }
}
