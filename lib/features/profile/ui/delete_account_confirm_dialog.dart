import 'package:flutter/material.dart';

/// deleteAccount 확인과 reauth 비밀번호 입력을 수행하는 다이얼로그.
class DeleteAccountConfirmDialog extends StatefulWidget {
  const DeleteAccountConfirmDialog({super.key});

  @override
  State<DeleteAccountConfirmDialog> createState() =>
      _DeleteAccountConfirmDialogState();
}

class _DeleteAccountConfirmDialogState
    extends State<DeleteAccountConfirmDialog> {
  final TextEditingController _passwordController = TextEditingController();

  bool get _canConfirm => _passwordController.text.isNotEmpty;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete account'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('정말 계정을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              controller: _passwordController,
              autofillHints: const <String>[AutofillHints.password],
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                labelText: 'Current password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canConfirm
              ? () {
                  Navigator.of(context).pop(
                    DeleteAccountDialogResult(
                      currentPassword: _passwordController.text,
                    ),
                  );
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

/// delete dialog가 section에 돌려주는 확인 결과.
class DeleteAccountDialogResult {
  const DeleteAccountDialogResult({required this.currentPassword});

  final String currentPassword;
}
