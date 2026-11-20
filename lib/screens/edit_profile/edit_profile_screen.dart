import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/edit_profile_view_model.dart';
import '../../widgets/movielog_button.dart';

/// 프로필 수정. 이메일은 읽기 전용, 닉네임만 수정한다.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Route가 member != null일 때만 이 화면을 만들므로 현재 닉네임으로 시작한다.
    final member = context.read<AuthViewModel>().member;
    _controller = TextEditingController(text: member?.nickname ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    // await 뒤 context를 쓰지 않도록 미리 꺼내 둔다.
    final viewModel = context.read<EditProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final success = await viewModel.save(_controller.text);
    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(const SnackBar(content: Text('프로필을 수정했어요.')));
      router.pop(); // 마이페이지에는 이미 새 닉네임이 반영돼 있다
    } else if (viewModel.message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(viewModel.message!)));
    }
    // 401이면 save()가 false + message null → pop하지 않고 Router가 /login으로 보낸다.
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthViewModel, String?>(
      (auth) => auth.member?.email,
    );

    return Consumer<EditProfileViewModel>(
      builder: (context, viewModel, child) {
        final saving = viewModel.status == EditProfileStatus.saving;
        return PopScope(
          canPop: !saving, // 저장 중 뒤로가기 차단
          child: Scaffold(
            appBar: AppBar(
              title: const Text('프로필 수정'),
              centerTitle: true,
              titleTextStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _FieldLabel('이메일 (변경할 수 없습니다)'),
                    TextFormField(
                      initialValue: email,
                      enabled: false, // 이메일은 읽기 전용
                      style: const TextStyle(color: AppColors.commentText),
                      decoration: const InputDecoration(
                        fillColor: AppColors.inputDisabledFill,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const _FieldLabel('닉네임'),
                    TextField(
                      controller: _controller,
                      enabled: !saving,
                      maxLength: 12,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => viewModel.clearNicknameError(),
                      onSubmitted: (_) {
                        if (!saving) _submit();
                      },
                      decoration: InputDecoration(
                        errorText: viewModel.nicknameError, // 409·400·길이 오류
                      ),
                      // Figma: "4 / 12"
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => Text(
                            '$currentLength / $maxLength',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.commentText,
                            ),
                          ),
                    ),
                    const Spacer(),
                    MovieLogButton(
                      label: '저장',
                      width: double.infinity,
                      isLoading: saving,
                      onPressed: saving ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
