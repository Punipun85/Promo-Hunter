import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_routes.dart';
import '../../config/midtrans_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_experience_provider.dart';
import '../../services/midtrans_invoice_service.dart';
import '../../utils/date_formatter.dart';
import '../../utils/currency_formatter.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with WidgetsBindingObserver {
  Timer? _midtransSyncTimer;
  bool _isResumeSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_syncMidtransPayments(showFeedback: false));
    });
    _midtransSyncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      unawaited(_syncMidtransPayments(showFeedback: false));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncMidtransPayments(showFeedback: true));
    }
  }

  Future<void> _syncMidtransPayments({required bool showFeedback}) async {
    if (_isResumeSyncing) return;
    _isResumeSyncing = true;
    try {
      final approved = await context
          .read<DashboardExperienceProvider>()
          .syncSettledMidtransPayments();
      if (!mounted || !showFeedback || !approved) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Status pembayaran Midtrans sudah diperbarui setelah kembali ke aplikasi.',
            ),
          ),
        );
    } finally {
      _isResumeSyncing = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midtransSyncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final experience = context.watch<DashboardExperienceProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Topup & Langganan'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.monetization_on_outlined), text: 'Coin'),
              Tab(
                  icon: Icon(Icons.workspace_premium_outlined),
                  text: 'Premium'),
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Riwayat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CoinTab(
              experience: experience,
              isLoggedIn: auth.isLoggedIn,
            ),
            _PremiumTab(
              experience: experience,
              auth: auth,
            ),
            _TransactionHistoryTab(
              transactions: experience.paymentTransactions,
              isLoggedIn: auth.isLoggedIn,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinTab extends StatelessWidget {
  const _CoinTab({
    required this.experience,
    required this.isLoggedIn,
  });

  final DashboardExperienceProvider experience;
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _BalanceHeader(
          title: '${experience.coinBalance} Coin',
          subtitle:
              'Gunakan coin untuk membuka promo early access, main Mini Games, atau tukar voucher.',
          icon: Icons.monetization_on_outlined,
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.miniGame),
          icon: const Icon(Icons.sports_esports_outlined),
          label: const Text('Mini Games'),
        ),
        const SizedBox(height: 16),
        ...DashboardExperienceProvider.coinPackages.map(
          (package) => _PackageCard(
            title: package.name,
            badge: package.isRecommended ? 'Rekomendasi' : null,
            value: '${package.coins} coin',
            price: CurrencyFormatter.format(package.price),
            description: package.description,
            icon: Icons.toll_outlined,
            actionLabel: 'Topup',
            onTap: () async {
              if (!isLoggedIn) {
                await _showGuestRequiredDialog(context);
                return;
              }
              final auth = context.read<AuthProvider>();
              final user = auth.currentUser;
              if (user == null) return;
              final paid = await _showTransactionDialog(
                context,
                title: 'Konfirmasi Topup Coin',
                itemName: package.name,
                value: '${package.coins} coin',
                price: package.price,
                description:
                    'Coin akan masuk ke saldo akun setelah transaksi demo ini dikonfirmasi.',
                customerName: user.name,
                customerEmail: user.email,
                transactionType: 'coin_topup',
              );
              if (paid == null) return;
              final transaction = await experience.createCoinTopUpTransaction(
                package: package,
                userId: user.id,
                userName: user.name,
                userEmail: user.email,
                paymentMethod: paid.paymentMethod,
                proofFileName: paid.proofFileName,
                paymentReference: paid.paymentReference,
                paymentUrl: paid.paymentUrl,
              );
              final isAutoApproved =
                  await experience.waitForMidtransSettlement(transaction.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAutoApproved
                        ? 'Pembayaran berhasil. Coin sudah masuk ke wallet.'
                        : 'Invoice tersimpan. Menunggu konfirmasi Midtrans sandbox.',
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        const _SectionTitle(
          title: 'Tukar Voucher',
          subtitle:
              'Ambil voucher gratis atau kumpulkan coin dari Mini Games untuk voucher yang lebih besar.',
        ),
        const SizedBox(height: 12),
        ...DashboardExperienceProvider.voucherCatalog.map(
          (voucher) {
            final hasUnusedVoucher =
                experience.hasUnusedRedeemedVoucher(voucher.id);
            final hasUsedVoucher =
                experience.hasUsedRedeemedVoucher(voucher.id);
            final alreadyRedeemedFree = voucher.coinCost == 0 &&
                experience.hasRedeemedVoucher(voucher.id);
            final needsMoreCoins = experience.coinBalance < voucher.coinCost;
            final statusBadge = hasUnusedVoucher
                ? 'Sudah diklaim'
                : hasUsedVoucher
                    ? 'Sudah dipakai'
                    : voucher.coinCost == 0
                        ? 'Gratis'
                        : 'Voucher';
            final statusDescription = hasUnusedVoucher
                ? '${voucher.description} Voucher ini sudah kamu klaim, tapi belum dipakai.'
                : hasUsedVoucher
                    ? '${voucher.description} Voucher ini pernah dipakai sebelumnya.'
                    : voucher.description;
            return _PackageCard(
              title: voucher.title,
              badge: statusBadge,
              value: voucher.coinCost == 0
                  ? 'Tanpa coin'
                  : '${voucher.coinCost} coin',
              price: voucher.benefitLabel,
              description: statusDescription,
              icon: voucher.icon,
              actionLabel: alreadyRedeemedFree
                  ? hasUnusedVoucher
                      ? 'Sudah Diklaim'
                      : 'Sudah Dipakai'
                  : needsMoreCoins
                      ? 'Cari Coin'
                      : voucher.coinCost == 0
                          ? 'Ambil'
                          : 'Tukar',
              onTap: alreadyRedeemedFree
                  ? null
                  : needsMoreCoins
                      ? () async {
                          Navigator.pushNamed(context, AppRoutes.miniGame);
                        }
                      : () async {
                          final redemption =
                              await experience.redeemVoucher(voucher.id);
                          if (!context.mounted || redemption == null) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Voucher ${redemption.title} didapatkan. Kode: ${redemption.code}',
                              ),
                            ),
                          );
                        },
            );
          },
        ),
        if (experience.redeemedVouchers.isNotEmpty) ...[
          const SizedBox(height: 6),
          const _SectionTitle(
            title: 'Voucher Kamu',
            subtitle: 'Voucher yang sudah ditukar akan tersimpan di sini.',
          ),
          const SizedBox(height: 12),
          ...experience.redeemedVouchers.map(
            (voucher) => _RedeemedVoucherCard(voucher: voucher),
          ),
        ],
      ],
    );
  }
}

class _PremiumTab extends StatelessWidget {
  const _PremiumTab({
    required this.experience,
    required this.auth,
  });

  final DashboardExperienceProvider experience;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _BalanceHeader(
          title: experience.isPremium ? 'Premium Aktif' : 'Premium Belum Aktif',
          subtitle: experience.premiumStatusText,
          icon: Icons.workspace_premium_outlined,
        ),
        if (experience.isPremium) ...[
          const SizedBox(height: 14),
          _PremiumCountdownCard(experience: experience),
        ],
        const SizedBox(height: 18),
        ...DashboardExperienceProvider.subscriptionPlans.map(
          (plan) => _PackageCard(
            title: plan.name,
            badge: plan.isRecommended ? 'Paling hemat' : null,
            value: plan.durationLabel,
            price: CurrencyFormatter.format(plan.price),
            description: plan.description,
            icon: Icons.verified_outlined,
            actionLabel: experience.isPremium ? 'Perpanjang' : 'Langganan',
            onTap: () async {
              if (!auth.isLoggedIn) {
                await _showGuestRequiredDialog(context);
                return;
              }
              final paid = await _showTransactionDialog(
                context,
                title: experience.isPremium
                    ? 'Perpanjang Langganan'
                    : 'Konfirmasi Langganan',
                itemName: plan.name,
                value: plan.durationLabel,
                price: plan.price,
                description:
                    'Premium akan aktif setelah bukti pembayaran demo dikirim dan dikonfirmasi.',
                customerName: auth.currentUser!.name,
                customerEmail: auth.currentUser!.email,
                transactionType: 'subscription',
              );
              if (paid == null || auth.currentUser == null) return;
              final transaction =
                  await experience.createSubscriptionTransaction(
                plan: plan,
                userId: auth.currentUser!.id,
                userName: auth.currentUser!.name,
                userEmail: auth.currentUser!.email,
                paymentMethod: paid.paymentMethod,
                proofFileName: paid.proofFileName,
                paymentReference: paid.paymentReference,
                paymentUrl: paid.paymentUrl,
              );
              final isAutoApproved =
                  await experience.waitForMidtransSettlement(transaction.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAutoApproved
                        ? 'Pembayaran berhasil. Premium langsung aktif.'
                        : 'Invoice tersimpan. Menunggu konfirmasi Midtrans sandbox.',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TransactionHistoryTab extends StatelessWidget {
  const _TransactionHistoryTab({
    required this.transactions,
    required this.isLoggedIn,
  });

  final List<PaymentTransaction> transactions;
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 52),
              const SizedBox(height: 12),
              Text(
                'Login untuk melihat riwayat transaksi.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    final sorted = [...transactions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (sorted.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 52),
              const SizedBox(height: 12),
              Text(
                'Belum ada transaksi.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Topup coin atau langganan premium akan tercatat di sini.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionTitle(
          title: 'Riwayat Transaksi',
          subtitle:
              'Pantau status topup coin dan langganan premium setelah bukti pembayaran dikirim.',
        ),
        const SizedBox(height: 14),
        ...sorted.map((transaction) {
          return _PaymentTransactionCard(transaction: transaction);
        }),
      ],
    );
  }
}

Future<void> _showGuestRequiredDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titlePadding: const EdgeInsets.fromLTRB(24, 18, 14, 0),
        title: Row(
          children: [
            const Expanded(child: Text('Anda belum mendaftar akun')),
            IconButton(
              tooltip: 'Tutup',
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        content: const Text(
          'Topup coin dan langganan premium hanya bisa dilakukan setelah kamu login atau membuat akun PromoHunter.',
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
        actions: [
          OverflowBar(
            spacing: 10,
            overflowSpacing: 10,
            alignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonal(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pushNamed(context, AppRoutes.login);
                },
                child: const Text('Login'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pushNamed(context, AppRoutes.register);
                },
                child: const Text('Daftar'),
              ),
            ],
          ),
        ],
      );
    },
  );
}

Future<_PaymentConfirmation?> _showTransactionDialog(
  BuildContext context, {
  required String title,
  required String itemName,
  required String value,
  required int price,
  required String description,
  required String customerName,
  required String customerEmail,
  required String transactionType,
}) {
  const paymentMethods = <_PaymentMethod>[
    _PaymentMethod(
      id: 'qris',
      name: 'QRIS',
      description: 'Scan QR dari mobile banking atau e-wallet.',
      icon: Icons.qr_code_2_rounded,
      instruction:
          'Lanjutkan ke Snap Midtrans untuk membuka flow QRIS sandbox atau web simulator.',
      paymentCode: 'QRIS-PROMOHUNTER',
      midtransPreferredPaymentMethod: 'qris',
      midtransEnabledPayments: ['gopay'],
      midtransPaymentType: 'qris',
      midtransPayload: {
        'qris': {'acquirer': 'gopay'},
      },
    ),
    _PaymentMethod(
      id: 'ewallet',
      name: 'E-Wallet',
      description: 'DANA, OVO, GoPay, atau ShopeePay.',
      icon: Icons.account_balance_wallet_outlined,
      instruction:
          'Lanjutkan ke Snap Midtrans untuk memilih e-wallet yang tersedia di akun sandbox.',
      paymentCode: 'EW-PH-778899',
      midtransPreferredPaymentMethod: 'gopay',
      midtransEnabledPayments: ['gopay', 'shopeepay', 'dana', 'ovo'],
    ),
    _PaymentMethod(
      id: 'va',
      name: 'Virtual Account',
      description: 'BCA, BNI, BRI, Mandiri, atau bank lain.',
      icon: Icons.account_balance_outlined,
      instruction:
          'Lanjutkan ke Snap Midtrans untuk memilih bank virtual account yang tersedia.',
      paymentCode: '8808 2400 1122 7788',
      midtransPreferredPaymentMethod: 'bank_transfer',
      midtransEnabledPayments: [
        'bca_va',
        'bni_va',
        'bri_va',
        'permata_va',
        'echannel',
      ],
    ),
    _PaymentMethod(
      id: 'transfer',
      name: 'Transfer Bank',
      description:
          'Masuk ke Snap Midtrans untuk opsi transfer/bank yang aktif.',
      icon: Icons.payments_outlined,
      instruction:
          'Lanjutkan ke Snap Midtrans untuk memilih kanal transfer atau pembayaran bank yang aktif.',
      paymentCode: 'BCA 1234567890 a.n. PromoHunter',
      midtransPreferredPaymentMethod: 'bank_transfer',
      midtransEnabledPayments: [
        'bca_va',
        'bni_va',
        'bri_va',
        'permata_va',
        'echannel',
      ],
    ),
  ];
  final invoiceCode =
      'PH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  final midtransService = MidtransInvoiceService();
  Uri? buildPaymentResultUrl(String result) {
    final queryParameters = {
      'order_id': invoiceCode,
      'result': result,
    };
    if (kIsWeb) {
      return Uri.base.replace(
        path: AppRoutes.paymentResult,
        queryParameters: queryParameters,
      );
    }
    return Uri(
      scheme: 'promohunter',
      host: AppRoutes.paymentResult.replaceFirst('/', ''),
      queryParameters: queryParameters,
    );
  }

  Future<bool> openPaymentUrl(Uri uri) async {
    try {
      return await launchUrl(
        uri,
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_blank' : null,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> copyPaymentUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
  }

  return showDialog<_PaymentConfirmation>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      var selectedMethod = paymentMethods.first;
      String? proofFileName;
      String? paymentUrl;
      String? invoiceError;
      var isCreatingInvoice = false;
      return StatefulBuilder(
        builder: (context, setState) {
          final viewport = MediaQuery.sizeOf(dialogContext);
          final isAutomaticMidtrans = MidtransConfig.isConfigured;
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            titlePadding: const EdgeInsets.fromLTRB(24, 18, 14, 0),
            title: Row(
              children: [
                Expanded(child: Text(title)),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 460,
                maxHeight: viewport.height * 0.72,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TransactionRow(label: 'Invoice', value: invoiceCode),
                          const SizedBox(height: 8),
                          _TransactionRow(label: 'Paket', value: itemName),
                          const SizedBox(height: 8),
                          _TransactionRow(label: 'Benefit', value: value),
                          const SizedBox(height: 8),
                          _TransactionRow(
                            label: 'Metode',
                            value: selectedMethod.name,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(description),
                    const SizedBox(height: 16),
                    Text(
                      'Pilih Metode Pembayaran',
                      style: Theme.of(dialogContext).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    ...paymentMethods.map(
                      (method) => _PaymentMethodTile(
                        method: method,
                        isSelected: selectedMethod.id == method.id,
                        onTap: () => setState(() {
                          selectedMethod = method;
                        }),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _PaymentInstructionCard(
                      method: selectedMethod,
                      amount: price,
                      invoiceCode: invoiceCode,
                    ),
                    const SizedBox(height: 14),
                    if (MidtransConfig.isConfigured) ...[
                      _MidtransSandboxCard(
                        isConfigured: MidtransConfig.isConfigured,
                        isLoading: isCreatingInvoice,
                        invoiceReference: null,
                        invoiceUrl: paymentUrl,
                        errorMessage: invoiceError,
                        onCreateInvoice: () async {
                          setState(() {
                            isCreatingInvoice = true;
                            invoiceError = null;
                          });
                          try {
                            final finishCallback =
                                buildPaymentResultUrl('success');
                            final unfinishCallback =
                                buildPaymentResultUrl('pending');
                            final errorCallback =
                                buildPaymentResultUrl('error');
                            final paymentPayload = <String, dynamic>{
                              ...?selectedMethod.midtransPayload,
                              if (finishCallback != null)
                                'callbacks': {
                                  'finish': finishCallback.toString(),
                                  'unfinish': unfinishCallback.toString(),
                                  'error': errorCallback.toString(),
                                },
                            };
                            final result = await midtransService.createInvoice(
                              transactionId: invoiceCode,
                              itemName: itemName,
                              amount: price,
                              customerName: customerName,
                              customerEmail: customerEmail,
                              transactionType: transactionType,
                              preferredPaymentMethod:
                                  selectedMethod.midtransPreferredPaymentMethod,
                              enabledPayments:
                                  selectedMethod.midtransEnabledPayments,
                              paymentType: selectedMethod.midtransPaymentType,
                              paymentPayload: paymentPayload,
                            );
                            final confirmation = _PaymentConfirmation(
                              paymentMethod:
                                  '${selectedMethod.name} via Midtrans Sandbox',
                              proofFileName: result.qrCodeUrl != null
                                  ? 'QRIS Simulator ${result.invoiceId}'
                                  : 'Invoice Midtrans ${result.invoiceId}',
                              paymentReference: result.invoiceId,
                              paymentUrl: result.qrCodeUrl ??
                                  result.simulatorUrl ??
                                  result.invoiceUrl,
                            );
                            final isQris = selectedMethod.id == 'qris';
                            if (isQris && result.qrCodeUrl != null) {
                              await copyPaymentUrl(result.qrCodeUrl!);
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'URL QRIS sudah disalin. Tempel di QRIS Simulator lalu tekan Scan QR.',
                                    ),
                                  ),
                                );
                              }
                              final simulatorUri = Uri.tryParse(
                                result.simulatorUrl ?? result.invoiceUrl,
                              );
                              if (simulatorUri != null) {
                                final opened =
                                    await openPaymentUrl(simulatorUri);
                                if (!opened) {
                                  final qrUri = Uri.tryParse(result.qrCodeUrl!);
                                  if (qrUri != null) {
                                    await openPaymentUrl(qrUri);
                                  }
                                }
                              }
                            } else {
                              final uri = Uri.tryParse(result.invoiceUrl);
                              if (uri != null) {
                                final opened = await openPaymentUrl(uri);
                                if (!opened) {
                                  throw const MidtransInvoiceException(
                                    'Tidak bisa membuka halaman pembayaran. Pastikan browser tersedia di perangkat Android.',
                                  );
                                }
                              }
                            }
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext, confirmation);
                          } catch (error) {
                            setState(() {
                              invoiceError = error.toString();
                            });
                          } finally {
                            setState(() {
                              isCreatingInvoice = false;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Bayar',
                          style: Theme.of(dialogContext).textTheme.titleSmall,
                        ),
                        Text(
                          CurrencyFormatter.format(price),
                          style: Theme.of(dialogContext)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color:
                                    Theme.of(dialogContext).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAutomaticMidtrans
                          ? selectedMethod.id == 'qris'
                              ? kIsWeb
                                  ? 'QRIS sandbox di web membuka QR image dan simulator Midtrans. Setelah simulator menyatakan sukses, saldo atau premium aktif otomatis.'
                                  : 'QRIS sandbox di Android menyalin URL QR lalu membuka QRIS Simulator. Tempel URL tersebut, tekan Scan QR, lalu selesaikan pembayaran sandbox.'
                              : 'Semua metode di sini diproses lewat Snap Midtrans. Buka invoice, selesaikan flow sandbox di halaman Midtrans, lalu saldo atau premium akan aktif tanpa upload bukti.'
                          : 'Metode manual tetap perlu upload bukti pembayaran agar transaksi demo bisa diproses.',
                      style:
                          Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF64748B),
                              ),
                    ),
                    if (!isAutomaticMidtrans) ...[
                      const SizedBox(height: 14),
                      _PaymentProofCard(
                        fileName: proofFileName,
                        onPickProof: () async {
                          final picked = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (picked == null) return;
                          setState(() {
                            proofFileName = picked.name;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
            actions: [
              OverflowBar(
                spacing: 10,
                overflowSpacing: 10,
                alignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonal(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Batal'),
                  ),
                  if (!isAutomaticMidtrans)
                    FilledButton.icon(
                      onPressed: proofFileName == null
                          ? null
                          : () => Navigator.pop(
                                dialogContext,
                                _PaymentConfirmation(
                                  paymentMethod: selectedMethod.name,
                                  proofFileName: proofFileName!,
                                  paymentReference: null,
                                  paymentUrl: paymentUrl,
                                ),
                              ),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Kirim Bukti'),
                    ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}

class _PremiumCountdownCard extends StatelessWidget {
  const _PremiumCountdownCard({required this.experience});

  final DashboardExperienceProvider experience;

  @override
  Widget build(BuildContext context) {
    final expiresAt = experience.premiumExpiresAt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: Color(0xFFB45309),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  experience.premiumCountdownLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF92400E),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  expiresAt == null
                      ? 'Durasi premium belum tersimpan.'
                      : 'Berakhir ${DateFormatter.dateTime(expiresAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF92400E),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethod {
  const _PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.instruction,
    required this.paymentCode,
    this.midtransPreferredPaymentMethod,
    this.midtransEnabledPayments,
    this.midtransPaymentType,
    this.midtransPayload,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String instruction;
  final String paymentCode;
  final String? midtransPreferredPaymentMethod;
  final List<String>? midtransEnabledPayments;
  final String? midtransPaymentType;
  final Map<String, dynamic>? midtransPayload;
}

class _PaymentConfirmation {
  const _PaymentConfirmation({
    required this.paymentMethod,
    required this.proofFileName,
    this.paymentReference,
    this.paymentUrl,
  });

  final String paymentMethod;
  final String proofFileName;
  final String? paymentReference;
  final String? paymentUrl;
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final _PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFFE2E8F0),
            ),
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  method.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentInstructionCard extends StatelessWidget {
  const _PaymentInstructionCard({
    required this.method,
    required this.amount,
    required this.invoiceCode,
  });

  final _PaymentMethod method;
  final int amount;
  final String invoiceCode;

  @override
  Widget build(BuildContext context) {
    final isQris = method.id == 'qris';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(method.icon, color: const Color(0xFF92400E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Instruksi ${method.name}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF92400E),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(method.instruction),
          const SizedBox(height: 12),
          if (isQris) ...[
            Center(
              child: Container(
                width: 128,
                height: 128,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: CustomPaint(
                  painter: _DemoQrPainter(seed: invoiceCode.hashCode),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _TransactionRow(
              label: isQris ? 'Kode QR' : 'Kode', value: method.paymentCode),
          const SizedBox(height: 8),
          _TransactionRow(
              label: 'Nominal', value: CurrencyFormatter.format(amount)),
        ],
      ),
    );
  }
}

class _PaymentProofCard extends StatelessWidget {
  const _PaymentProofCard({
    required this.fileName,
    required this.onPickProof,
  });

  final String? fileName;
  final Future<void> Function() onPickProof;

  @override
  Widget build(BuildContext context) {
    final hasProof = fileName != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasProof ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasProof ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hasProof ? Icons.verified_outlined : Icons.upload_file_outlined,
                color: hasProof
                    ? const Color(0xFF047857)
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasProof
                          ? 'Bukti pembayaran siap dikirim'
                          : 'Upload bukti pembayaran',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasProof
                          ? fileName!
                          : 'Pilih screenshot QRIS, e-wallet, VA, atau transfer bank.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: () async => onPickProof(),
              child: Text(hasProof ? 'Ganti' : 'Upload'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MidtransSandboxCard extends StatelessWidget {
  const _MidtransSandboxCard({
    required this.isConfigured,
    required this.isLoading,
    required this.invoiceReference,
    required this.invoiceUrl,
    required this.errorMessage,
    required this.onCreateInvoice,
  });

  final bool isConfigured;
  final bool isLoading;
  final String? invoiceReference;
  final String? invoiceUrl;
  final String? errorMessage;
  final Future<void> Function() onCreateInvoice;

  @override
  Widget build(BuildContext context) {
    final hasInvoice = invoiceReference != null;
    final color =
        hasInvoice ? const Color(0xFF047857) : const Color(0xFF2563EB);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasInvoice ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasInvoice ? const Color(0xFFA7F3D0) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.payment_rounded, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Midtrans Sandbox',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isConfigured
                          ? 'Buat invoice sandbox lalu lanjutkan pembayaran lewat halaman web Snap Midtrans sesuai metode yang dipilih.'
                          : 'Proxy Midtrans belum dikonfigurasi. Metode manual tetap bisa dipakai.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF475569),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasInvoice) ...[
            const SizedBox(height: 10),
            _TransactionRow(label: 'Ref', value: invoiceReference!),
            if (invoiceUrl != null) ...[
              const SizedBox(height: 8),
              _TransactionRow(label: 'Link', value: invoiceUrl!),
            ],
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFB91C1C),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
          if (isConfigured) ...[
            const SizedBox(height: 10),
            Text(
              'Cara pakai sandbox:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '1. Tekan Buat Invoice Sandbox.\n2. Browser akan membuka halaman Snap Midtrans.\n3. Snap akan langsung masuk ke flow metode yang dipilih atau menampilkan pilihan turunan yang aktif.\n4. Selesaikan flow sandbox di halaman Midtrans. Tidak perlu upload bukti.\n5. Setelah status settlement masuk, saldo atau premium aktif otomatis.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF475569),
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              kIsWeb
                  ? 'Khusus QRIS di web, PromoHunter akan mencoba membuka QR image dan simulator QRIS Midtrans versi sandbox.'
                  : 'Khusus QRIS di Android, URL QR disalin otomatis sebelum QRIS Simulator dibuka. Tempel URL itu ke kolom QR Code Image Url.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF475569),
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(
                      'https://simulator.sandbox.midtrans.com/v2/qris/index',
                    );
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  icon: const Icon(Icons.open_in_browser_rounded),
                  label: const Text('Buka Simulator QRIS'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(
                      'https://docs.midtrans.com/docs/testing-payment-on-sandbox',
                    );
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  icon: const Icon(Icons.help_outline_rounded),
                  label: const Text('Panduan Sandbox'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: !isConfigured || isLoading ? null : onCreateInvoice,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(hasInvoice
                      ? Icons.open_in_new_rounded
                      : Icons.receipt_long_outlined),
              label: Text(
                hasInvoice ? 'Buka/Buat Ulang Invoice' : 'Buat Invoice Sandbox',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTransactionCard extends StatelessWidget {
  const _PaymentTransactionCard({required this.transaction});

  final PaymentTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (transaction.status) {
      PaymentStatus.pending => const Color(0xFFF59E0B),
      PaymentStatus.approved => const Color(0xFF059669),
      PaymentStatus.rejected => const Color(0xFFDC2626),
    };
    final statusIcon = switch (transaction.status) {
      PaymentStatus.pending => Icons.hourglass_top_rounded,
      PaymentStatus.approved => Icons.verified_outlined,
      PaymentStatus.rejected => Icons.cancel_outlined,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.paymentDetail,
          arguments: transaction,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.itemName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${transaction.type.label} - ${transaction.benefitLabel}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF64748B),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusBadge(
                        label: transaction.statusLabel,
                        color: statusColor,
                      ),
                      const SizedBox(height: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _TransactionRow(
                label: 'Total',
                value: CurrencyFormatter.format(transaction.price),
              ),
              const SizedBox(height: 8),
              _TransactionRow(
                  label: 'Metode', value: transaction.paymentMethod),
              if (transaction.paymentReference != null) ...[
                const SizedBox(height: 8),
                _TransactionRow(
                    label: 'Ref', value: transaction.paymentReference!),
              ],
              const SizedBox(height: 8),
              _TransactionRow(
                label: 'Tanggal',
                value: DateFormatter.dateTime(transaction.createdAt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _DemoQrPainter extends CustomPainter {
  const _DemoQrPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF0F172A);
    final cell = size.width / 9;

    void drawBlock(int x, int y, int width, int height) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x * cell, y * cell, width * cell, height * cell),
          Radius.circular(cell * 0.2),
        ),
        paint,
      );
    }

    drawBlock(0, 0, 3, 3);
    drawBlock(6, 0, 3, 3);
    drawBlock(0, 6, 3, 3);

    for (var y = 0; y < 9; y++) {
      for (var x = 0; x < 9; x++) {
        final inFinder =
            (x < 3 && y < 3) || (x > 5 && y < 3) || (x < 3 && y > 5);
        if (inFinder) continue;
        final value = (x * 31 + y * 17 + seed).abs();
        if (value % 3 == 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                x * cell + cell * 0.16,
                y * cell + cell * 0.16,
                cell * 0.68,
                cell * 0.68,
              ),
              Radius.circular(cell * 0.14),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DemoQrPainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.title,
    required this.value,
    required this.price,
    required this.description,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String value;
  final String price;
  final String description;
  final IconData icon;
  final String actionLabel;
  final Future<void> Function()? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.secondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (badge != null) _PackageBadge(label: badge!),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(description),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        value,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(price),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: onTap == null
                        ? null
                        : () async {
                            await onTap!();
                          },
                    child: Text(onTap == null ? 'Sudah Aktif' : actionLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageBadge extends StatelessWidget {
  const _PackageBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0A8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF7C5A00),
            ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle),
      ],
    );
  }
}

class _RedeemedVoucherCard extends StatelessWidget {
  const _RedeemedVoucherCard({required this.voucher});

  final RedeemedVoucher voucher;

  @override
  Widget build(BuildContext context) {
    final statusLabel = voucher.isUsed ? 'Sudah Dipakai' : 'Belum Dipakai';
    final statusColor =
        voucher.isUsed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1);
    final statusTextColor =
        voucher.isUsed ? const Color(0xFF2E7D32) : const Color(0xFF8D6E00);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.confirmation_num_outlined,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(voucher.title)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statusTextColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${voucher.benefitLabel}\n'
          'Kode ${voucher.code}\n'
          'Diklaim ${DateFormatter.dateTime(voucher.redeemedAt)}'
          '${voucher.usedAt != null ? '\nDipakai ${DateFormatter.dateTime(voucher.usedAt!)}' : '\nBelum digunakan'}',
        ),
        isThreeLine: voucher.usedAt == null,
      ),
    );
  }
}
