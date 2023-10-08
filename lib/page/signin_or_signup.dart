import 'dart:convert';

import 'package:askaide/helper/constant.dart';
import 'package:askaide/helper/helper.dart';
import 'package:askaide/lang/lang.dart';
import 'package:askaide/page/component/background_container.dart';
import 'package:askaide/page/component/loading.dart';
import 'package:askaide/page/component/password_field.dart';
import 'package:askaide/page/component/verify_code_input.dart';
import 'package:askaide/page/dialog.dart';
import 'package:askaide/page/theme/custom_size.dart';
import 'package:askaide/page/theme/custom_theme.dart';
import 'package:askaide/repo/api_server.dart';
import 'package:askaide/repo/settings_repo.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:go_router/go_router.dart';

class SigninOrSignupScreen extends StatefulWidget {
  final SettingRepository settings;
  final String username;
  final String signInMethod;
  final bool isSignup;

  const SigninOrSignupScreen({
    super.key,
    required this.settings,
    required this.username,
    required this.isSignup,
    required this.signInMethod,
  });

  @override
  State<SigninOrSignupScreen> createState() => _SigninOrSignupScreenState();
}

class _SigninOrSignupScreenState extends State<SigninOrSignupScreen> {
  final TextEditingController _inviteCodeController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String verifyCodeId = '';
  final phoneNumberValidator = RegExp(r"^1[3456789]\d{9}$");
  late String signInMethod;

  @override
  void initState() {
    signInMethod = widget.signInMethod;
    super.initState();
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _verificationCodeController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var customColors = Theme.of(context).extension<CustomColors>()!;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: CustomSize.toolbarHeight,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Verify Account',
          style: TextStyle(fontSize: CustomSize.appBarTitleSize),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      backgroundColor: customColors.backgroundColor,
      body: BackgroundContainer(
        setting: widget.settings,
        enabled: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
                child: widget.isSignup ||
                        signInMethod == 'sms_code' ||
                        signInMethod == 'email_code'
                    ? signInOrSignUpWithSMSOrEmailCode(customColors, context)
                    : signInWithPassword(customColors, context)),
          ),
        ),
      ),
    );
  }

  Widget signInWithPassword(
    CustomColors customColors,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: Text(
            'Please use the password of ${widget.username} to log in.',
            style: TextStyle(
              color: customColors.weakTextColor?.withAlpha(200),
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Password
        Padding(
          padding: const EdgeInsets.only(
              left: 15.0, right: 15.0, top: 15, bottom: 0),
          child: PasswordField(
            controller: _passwordController,
            labelText: AppLocale.password.getString(context),
            hintText: AppLocale.passwordInputTips.getString(context),
          ),
        ),

        const SizedBox(height: 15),
        // Sign In
        Container(
          height: 45,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: customColors.linkColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextButton(
            onPressed: () {
              FocusScope.of(context).requestFocus(FocusNode());

              final password = _passwordController.text.trim();
              if (password == '') {
                showErrorMessage(AppLocale.passwordRequired.getString(context));
                return;
              }

              if (password.length < 8 || password.length > 20) {
                showErrorMessage(
                    AppLocale.passwordFormatError.getString(context));
                return;
              }

              APIServer()
                  .signInWithPassword(widget.username, password)
                  .then((value) async {
                await widget.settings.set(settingAPIServerToken, value.token);
                await widget.settings.set(settingUserInfo, jsonEncode(value));
                if (context.mounted) {
                  context.go(
                      '/chat-chat?show_initial_dialog=${value.isNewUser ? "true" : "false"}&reward=${value.reward}');
                }
              }).catchError((e) {
                showErrorMessage(resolveError(context, e));
              });
            },
            child: Text(
              AppLocale.signIn.getString(context),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
        // Forgot Password
        Container(
          padding: const EdgeInsets.only(left: 15, right: 10),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    signInMethod =
                        phoneNumberValidator.hasMatch(widget.username)
                            ? 'sms_code'
                            : 'email_code';
                  });
                },
                child: Text(
                  'Sign in with verification code',
                  style: TextStyle(
                    color: customColors.weakLinkColor?.withAlpha(120),
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  context
                      .push('/retrieve-password?username=${widget.username}');
                },
                child: Text(
                  AppLocale.forgotPassword.getString(context),
                  style: TextStyle(
                    color: customColors.weakLinkColor?.withAlpha(120),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget signInOrSignUpWithSMSOrEmailCode(
    CustomColors customColors,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: Text(
            'Please send the verification code to ${widget.username} to complete the operation.',
            style: TextStyle(
              color: customColors.weakTextColor,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox