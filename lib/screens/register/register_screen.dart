// 회원가입 화면: 입력 형식 검증, 닉네임 중복 확인 상태 표시, 약관 동의

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../view_models/sign_up_view_model.dart';
import '../../data/models/create_member_request.dart';
import '../../view_models/learning_member_session.dart';
import '../../view_models/submit_status.dart';
import '../../widgets/movielog_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // validator: null이면 통과, 문자열이면 오류 문구. 빈 값은 _canSubmit이 막는다.
  String? _validateNickname(String? value) {
    final nickname = value?.trim() ?? '';
    if (nickname.isEmpty) return null;
    if (nickname.length < 2) return '닉네임은 2자 이상이어야 합니다.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    if (!email.contains('@')) return '올바른 이메일 형식이 아닙니다.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return null;
    if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    return null;
  }

  bool get _canSubmit =>
      _nicknameController.text.trim().length >= 2 &&
      _emailController.text.contains('@') &&
      _passwordController.text.length >= 8 &&
      _agreedToTerms;

  // ── 가입하기: 로컬 검증 → 서버 제출 → 성공이면 세션 저장 후 이동 / 실패면 Snackbar ──
  Future<void> _submit() async {
    // ① 로컬 Form 검증 + 키보드 닫기
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    FocusScope.of(context).unfocus();

    // ② 서버 제출 (결과는 ViewModel 필드에 남는다)
    final viewModel = context.read<SignUpViewModel>();
    await viewModel.submit(
      CreateMemberRequest(
        email: _emailController.text,
        password: _passwordController.text,
        nickname: _nicknameController.text,
      ),
    );

    // ③ await 뒤: 화면이 사라졌으면 아무것도 하지 않는다
    if (!mounted) return;

    // ④ 성공: memberId를 앱 세션에 저장 → 안내 → 영화 목록으로
    final memberId = viewModel.createdMemberId;
    if (viewModel.submitStatus == SubmitStatus.success && memberId != null) {
      context.read<LearningMemberSession>().setMemberId(memberId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입 완료 · 학습용 memberId: $memberId')),
      );
      context.go('/movies');
      return;
    }

    // ⑤ 실패(입력칸에 붙지 않는 오류): Snackbar로 한 번만 안내
    final message = viewModel.snackbarMessage;
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // 가입 버튼 조건과 입력창 아이콘을 다시 계산하기 위해 화면을 다시 그린다.
  void _onFieldChanged(String _) => setState(() {});

  String? _checkMessage(CheckStatus status, String target) {
    return switch (status) {
      CheckStatus.checking => '$target 사용 가능 여부를 확인 중입니다.',
      CheckStatus.available => '사용 가능한 $target입니다.',
      _ => null,
    };
  }

  Color _checkMessageColor(CheckStatus status) {
    return status == CheckStatus.checking
        ? AppColors.checkInProgress
        : AppColors.checkAvailable;
  }

  @override
  Widget build(BuildContext context) {
    // 제출 중에는 뒤로가기·스와이프로 화면을 나갈 수 없게 한다 (워크북 9번)
    return Consumer<SignUpViewModel>(
      builder: (context, viewModel, child) => PopScope(
        canPop: viewModel.submitStatus != SubmitStatus.submitting,
        child: child!,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('회원가입'),
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 45, 18, 44),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _RegisterHeader(),
                            const SizedBox(height: 27),
                            Consumer<SignUpViewModel>(
                              builder: (context, viewModel, child) {
                                final status = viewModel.nicknameCheckStatus;
                                return _LabeledTextField(
                                  label: '닉네임',
                                  hintText: '영화광',
                                  controller: _nicknameController,
                                  validator: _validateNickname,
                                  textInputAction: TextInputAction.next,
                                  errorText: viewModel.nicknameErrorText,
                                  isVerified: status == CheckStatus.available,
                                  message: _checkMessage(status, '닉네임'),
                                  messageColor: _checkMessageColor(status),
                                  onChanged: (value) {
                                    viewModel.onNicknameChanged(value);
                                    _onFieldChanged(value);
                                  },
                                  onFieldSubmitted: (_) =>
                                      _emailFocusNode.requestFocus(),
                                  trailing: MovieLogButton(
                                    label: '중복 확인',
                                    width: 102,
                                    fontSize: 13,
                                    isLoading: status == CheckStatus.checking,
                                    onPressed: viewModel.canCheckNickname
                                        ? () => viewModel.checkNickname(
                                            _nicknameController.text,
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 9),
                            Consumer<SignUpViewModel>(
                              builder: (context, viewModel, child) {
                                final status = viewModel.emailCheckStatus;
                                return _LabeledTextField(
                                  label: '이메일',
                                  hintText: 'movie@umc.com',
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  validator: _validateEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  errorText: viewModel.emailErrorText,
                                  isVerified: status == CheckStatus.available,
                                  message: _checkMessage(status, '이메일'),
                                  messageColor: _checkMessageColor(status),
                                  onChanged: (value) {
                                    viewModel.onEmailChanged(value);
                                    _onFieldChanged(value);
                                  },
                                  onFieldSubmitted: (_) =>
                                      _passwordFocusNode.requestFocus(),
                                  trailing: MovieLogButton(
                                    label: '중복 확인',
                                    width: 102,
                                    fontSize: 13,
                                    isLoading: status == CheckStatus.checking,
                                    onPressed: viewModel.canCheckEmail
                                        ? () => viewModel.checkEmail(
                                            _emailController.text,
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 9),
                            Consumer<SignUpViewModel>(
                              builder: (context, viewModel, child) {
                                return _LabeledTextField(
                                  label: '비밀번호',
                                  hintText: '••••••••',
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  validator: _validatePassword,
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  // 서버 400(비밀번호 형식) 문구 — 로컬 validator와 함께 동작
                                  errorText: viewModel.passwordErrorText,
                                  onChanged: (value) {
                                    viewModel.onPasswordChanged();
                                    _onFieldChanged(value);
                                  },
                                  onFieldSubmitted: (_) =>
                                      FocusScope.of(context).unfocus(),
                                );
                              },
                            ),
                            const Spacer(),
                            const SizedBox(height: 24),
                            _TermsCheckbox(
                              value: _agreedToTerms,
                              onChanged: (value) {
                                setState(() => _agreedToTerms = value);
                              },
                            ),
                            const SizedBox(height: 24),
                            Consumer<SignUpViewModel>(
                              builder: (context, viewModel, child) {
                                final isSubmitting =
                                    viewModel.submitStatus ==
                                    SubmitStatus.submitting;
                                return MovieLogButton(
                                  label: '가입하기',
                                  width: double.infinity,
                                  isLoading: isSubmitting,
                                  // 로컬 검증 + 중복 확인 2개 통과 + 제출 중 아님
                                  onPressed:
                                      _canSubmit &&
                                          viewModel.isDuplicateCheckPassed &&
                                          !isSubmitting
                                      ? _submit
                                      : null,
                                );
                              },
                            ),
                            const SizedBox(height: 52),
                            const _LoginPrompt(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          '환영합니다!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.labelText,
          ),
        ),
        SizedBox(height: 3),
        Text(
          '간단한 정보만 입력하고 시작해보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.labelText),
        ),
      ],
    );
  }
}

/// 라벨 + TextFormField + 상태 아이콘 + 오른쪽 위젯(trailing)을 묶은 입력 필드.
class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.validator,
    required this.onChanged,
    required this.onFieldSubmitted,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.errorText,
    this.isVerified,
    this.trailing,
    this.message,
    this.messageColor,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onFieldSubmitted;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final String? errorText;
  final bool? isVerified;
  final Widget? trailing;
  final String? message;
  final Color? messageColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final text = controller.text;
    final hasError = validator(text) != null || errorText != null;
    final isValid = isVerified ?? (text.isNotEmpty && !hasError);
    final icon = hasError
        ? Icon(Icons.error_outline, size: 20, color: colors.error)
        : isValid
        ? Icon(Icons.check_circle, size: 20, color: colors.primary)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.labelText,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                obscureText: obscureText,
                validator: validator,
                onChanged: onChanged,
                onFieldSubmitted: onFieldSubmitted,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.labelText,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  errorText: errorText,
                  fillColor: hasError ? colors.errorContainer : null,
                  suffixIcon: icon == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: icon,
                        ),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 20,
                  ),
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
        if (trailing != null && !hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 1),
            child: SizedBox(
              height: 16,
              child: message == null
                  ? null
                  : Text(
                      message!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: messageColor,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: Transform.scale(
            scale: 26 / 18,
            child: Checkbox(
              value: value,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onChanged: (checked) => onChanged(checked ?? false),
            ),
          ),
        ),
        const SizedBox(width: 7),
        const Text(
          '필수 약관에 동의합니다',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.labelText,
          ),
        ),
      ],
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '이미 계정이 있나요?',
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(width: 8),
        Text(
          '로그인',
          style: textTheme.bodyMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
