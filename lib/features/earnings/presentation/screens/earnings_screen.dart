import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/l10n/app_strings.dart';
import 'package:nextgig/core/settings/settings_cubit.dart';
import 'package:nextgig/core/utils/formatters.dart';
import 'package:nextgig/core/utils/messenger.dart';
import 'package:nextgig/core/widgets/app_button.dart';
import 'package:nextgig/core/widgets/app_text_field.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/earnings/presentation/cubit/earnings_cubit.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({
    super.key,
    this.initialGigTitle = '',
    this.initialGigId = '',
  });

  final String initialGigTitle;
  final String initialGigId;

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  late final TextEditingController _title = TextEditingController(
    text: widget.initialGigTitle,
  );
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<SettingsCubit>().state.language;
    String t(String key) => AppStrings.text(language, key);
    return BlocProvider(
      create: (_) =>
          sl<EarningsCubit>()..watch(context.read<AuthCubit>().state.user!.uid),
      child: Scaffold(
        appBar: AppBar(title: Text(t('earnings'))),
        body: BlocConsumer<EarningsCubit, EarningsState>(
          listener: (context, state) {
            if (state.error != null) showAppMessage(context, state.error!);
          },
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  formatRwf(state.total),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Recorded income only. This does not charge MTN MoMo or Airtel Money.',
                ),
                const SizedBox(height: 16),
                AppTextField(controller: _title, label: 'Gig title'),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _amount,
                  label: 'Amount (RWF)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _reference,
                  label: 'MoMo or Airtel reference',
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: t('record_earnings'),
                  isLoading: _saving,
                  onPressed: () => _save(context),
                ),
                const SizedBox(height: 24),
                for (final earning in state.earnings)
                  ListTile(
                    title: Text(earning.gigTitle),
                    subtitle: Text(
                      earning.mobileMoneyRef.isEmpty
                          ? 'No reference'
                          : earning.mobileMoneyRef,
                    ),
                    trailing: Text(formatRwf(earning.amount)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final amount = int.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0 || _title.text.trim().isEmpty) {
      showAppMessage(context, 'Enter a title and an amount.');
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<EarningsCubit>().add(
        uid: context.read<AuthCubit>().state.user!.uid,
        amount: amount,
        gigTitle: _title.text,
        gigId: widget.initialGigId,
        mobileMoneyRef: _reference.text,
      );
      _amount.clear();
      _reference.clear();
      if (context.mounted) showAppMessage(context, 'Earning saved.');
    } catch (_) {
      // The cubit already reported the error.
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
