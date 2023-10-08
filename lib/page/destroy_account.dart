import 'package:askaide/helper/constant.dart';
import 'package:askaide/helper/helper.dart';
import 'package:askaide/lang/lang.dart';
import 'package:askaide/page/component/background_container.dart';
import 'package:askaide/page/component/column_block.dart';
import 'package:askaide/page/component/loading.dart';
import 'package:askaide/page/component/message_box.dart';
import 'package:askaide/page/component/verify_code_input.dart';
import 'package:askaide/page/dialog.dart';
import 'package:askaide/page/theme/custom_size.dart';
import 'package:askaide/page/theme/custom_theme.dart';
import 'package:askaide/repo/api_server.dart';
import 'package:askaide/repo/settings_repo.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:go_router/go_router.dart';

class DestroyAccountScreen extends StatefulWidget {
  final SettingRepository setting;

  const DestroyAccountScreen({super.key, required this.setting});

  @override
  State<DestroyAccountScreen> createState() => _DestroyAccountScreenState();
}

class _DestroyAccountScreenState extends State<DestroyAccountScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();

  String verifyCodeId = '';

  @override
  void dispose() {
    _passwordController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var customColors = Theme.of(context).extension<CustomColors>()!;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: CustomSize.toolbarHeight,
        title: const Text(
          'Destroy Account',
          style: TextStyle(fontSize: CustomSize.appBarTitleSize),
        ),
        centerTitle: true,
      ),
      backgroundColor: customColors.backgroundContainerColor,
      body: BackgroundContainer(
        setting: widget.setting,
        enabled: false,
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              const MessageBox(
                message:
                    'Please note that after destroying your account:\n1. Your data will be cleared, including all data related to your digital persona, Creation Island history, recharge data, and Wisdom Fruit usage details.\n2. Any unused Wisdom Fruit will be destroyed and cannot be used or refunded.\n3. Account destruction is irreversible, once your account is destroyed, all deleted data cannot be recovered.',
                type: MessageBoxType.warning,
              ),
              const SizedBox(height: 15),
              ColumnBlock(
                children: [
                  VerifyCodeInput(
                    inColumnBlock: true,
                    controller: _verificationCodeController,
                    onVerifyCodeSent: (id) {
                      verifyCodeId = id;
                    },
                    sendVerifyCode: () {
                      return APIServer().sendDestroyAccountSMSCode();
                    },
                    sendCheck: () {
                      return true;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                height: 45,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: onDestroySubmit,
                  child: const Text(
                    'Confirm Account Destruction',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  onDestroySubmit() {
    if (verifyCodeId == '') {
      showErrorMessage(AppLocale.pleaseGetVerifyCodeFirst.getString(context));
      return;
    }

    final verificationCode = _verificationCodeController.text.trim();
    if (verificationCode == '') {
      showErrorMessage(AppLocale.verifyCodeRequired.getString(context));
      return;
    }
    if (verificationCode.length != 6) {
      showErrorMessage(AppLocale.verifyCodeFormatError.getString(context));
      return;
    }

    final cancel = BotToast.showCustomLoading(
      toastBuilder: (cancel) {
        return LoadingIndicator(
          message: AppLocale.processingWait.getString(context),
        );
      },
      allowClick: false,
      duration: const Duration(seconds: 120),
    );

    APIServer()
        .destroyAccount(
      verifyCodeId: verifyCodeId,
      verifyCode: verificationCode,
    )
        .then((value) async {
      await widget.setting.set(settingAPIServerToken, '');
      await widget.setting.set(settingUserInfo, '');

      showSuccessMessage('Account destroyed successfully');

      if (context.mounted) {
        context.go('/login');
      }
    }).catchError((e) {
      showErrorMessage(resolveError(context, e));
    }).whenComplete(() => cancel());
  }
}