import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../view_models/auth_view_model.dart';
import '../../widgets/movielog_button.dart';

/// 로그인 화면. login()만 호출하고 화면 이동은 Router(redirect)에 맡긴다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthViewModel _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    // ① 화면이 열려 있는 중에 만료되는 경우
    _auth.addListener(_showSessionExpired);
    // ② 이미 만료된 상태로 화면이 처음 열리는 경우 (첫 frame 뒤 확인)
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSessionExpired());
  }

  /// 만료로 쫓겨났을 때만 한 번 안내한다. 직접 로그아웃·로그인 실패에는 뜨지 않는다.
  void _showSessionExpired() {
    if (!mounted || !_auth.sessionExpired) return;
    _auth.consumeSessionExpired(); // 먼저 꺼서 반복 표시를 막는다
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')));
  }

  @override
  void dispose() {
    _auth.removeListener(_showSessionExpired); // 빠뜨리면 사라진 화면이 계속 호출된다
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    // 비밀번호는 trim하지 않고, 어디에도 저장·출력하지 않는다.
    _auth.login(_emailController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final loading = auth.status == AuthStatus.authenticating;
    final enabled = !loading && !auth.storageCleanupInProgress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
        centerTitle: true,
        automaticallyImplyLeading: false, // 뒤로 갈 보호 화면이 없다
        titleTextStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SvgPicture.asset(
                    'assets/logos/movielog_logo.svg',
                    width: 56,
                    height: 56,
                    semanticsLabel: 'MovieLog 로고',
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'MovieLog에 로그인',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, color: AppColors.labelText),
                ),
                const SizedBox(height: 32),
                const _FieldLabel('이메일'),
                TextFormField(
                  controller: _emailController,
                  enabled: enabled,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'movie@example.com',
                  ),
                  validator: (value) =>
                      (value?.trim().isEmpty ?? true) ? '이메일을 입력해 주세요.' : null,
                ),
                const SizedBox(height: 24),
                const _FieldLabel('비밀번호'),
                TextFormField(
                  controller: _passwordController,
                  enabled: enabled,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (enabled) _submit();
                  },
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    // 로그인 실패(AUTH401_1·COMMON400·네트워크) 문구 → 빨간 테두리 + 아래 문구
                    errorText: auth.message,
                  ),
                  validator: (value) =>
                      (value?.isEmpty ?? true) ? '비밀번호를 입력해 주세요.' : null,
                ),
                const SizedBox(height: 96),
                MovieLogButton(
                  label: '로그인',
                  width: double.infinity,
                  isLoading: loading, // 요청 중: 회색 + 인디케이터 + 비활성
                  onPressed: enabled ? _submit : null,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '계정이 없나요?',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.commentText,
                      ),
                    ),
                    TextButton(
                      onPressed: enabled
                          ? () => context.push('/register')
                          : null,
                      child: const Text('회원가입'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: AppColors.commentText),
      ),
    );
  }
}
