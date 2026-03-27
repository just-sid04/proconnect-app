import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/wallet_provider.dart';
import '../../utils/theme.dart';
import '../../models/wallet_transaction_model.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _referralController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadWalletData();
    });
  }

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
  }

  void _copyReferralCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied to clipboard!')),
    );
  }

  Future<void> _applyReferral() async {
    final code = _referralController.text.trim();
    if (code.isEmpty) return;

    final wp = context.read<WalletProvider>();
    final success = await wp.applyReferral(code);

    if (mounted) {
      if (success) {
        _referralController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Referral code applied! Bonus credited.'), backgroundColor: AppTheme.successColor),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(wp.error ?? 'Failed to apply code'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyMid,
      appBar: AppBar(
        title: Text('ProConnect Wallet', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.navyDeep,
        elevation: 0,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wp, _) {
          if (wp.isLoading && wp.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }

          return RefreshIndicator(
            onRefresh: wp.loadWalletData,
            color: AppTheme.accentColor,
            child: CustomScrollView(
              slivers: [
                // ── Balance Card ──────────────────────────────────────────
                SliverToBoxAdapter(child: _buildBalanceCard(wp.balance)),

                // ── Referral Section ──────────────────────────────────────
                SliverToBoxAdapter(child: _buildReferralSection(wp.referralCode)),

                // ── Apply Referral ────────────────────────────────────────
                SliverToBoxAdapter(child: _buildApplyReferralRow()),

                // ── Transactions Header ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text(
                      'Transaction History',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ),
                ),

                // ── Transactions List ─────────────────────────────────────
                if (wp.transactions.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('No transactions yet', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _TransactionTile(transaction: wp.transactions[index]),
                      childCount: wp.transactions.length,
                    ),
                  ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.glowShadow(AppTheme.primaryColor, blur: 20, spread: -4),
        border: Border.all(color: AppTheme.accentColor.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Available Balance', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '1 ProCredit = ₹1.00',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralSection(String? code) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.navySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Text(
            'Invite Friends & Earn',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Give ₹50, Get ₹25 when they complete their first booking.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _copyReferralCode(code ?? ''),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.navyMid,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withAlpha(60), style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    code ?? '-------',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryColor, letterSpacing: 2),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.copy_rounded, color: AppTheme.primaryColor, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyReferralRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _referralController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter referral code',
                hintStyle: const TextStyle(color: AppTheme.textHint),
                filled: true,
                fillColor: AppTheme.navySurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.dividerColor)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _applyReferral,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == 'credit';
    final color = isCredit ? AppTheme.successColor : AppTheme.errorColor;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.navySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSourceLabel(transaction.source),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                Text(
                  DateFormat('MMM dd, hh:mm a').format(transaction.createdAt),
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(0)}',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  String _getSourceLabel(String source) {
    switch (source) {
      case 'referral':
        return 'Referral Bonus';
      case 'booking_payment':
        return 'Booking Payment';
      case 'refund':
        return 'Refund';
      case 'bonus':
        return 'Welcome Bonus';
      case 'admin':
        return 'Admin Correction';
      default:
        return 'Wallet Update';
    }
  }
}
