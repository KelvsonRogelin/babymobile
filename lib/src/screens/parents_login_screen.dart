import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_sound_effects.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../utils/device_layout.dart';
import '../widgets/toy_button.dart';
import '../widgets/toy_phone_shell.dart';

class ParentsLoginScreen extends StatefulWidget {
  const ParentsLoginScreen({super.key});

  @override
  State<ParentsLoginScreen> createState() => _ParentsLoginScreenState();
}

class _ParentsLoginScreenState extends State<ParentsLoginScreen> {
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AppController>();
    final layout = DeviceLayout.fromContext(context);

    return Scaffold(
      body: ToyPhoneShell(
        leftIcon: IconButton(
          onPressed: () {
            AppSoundEffects.tap();
            controller.closeParents();
          },
          icon: const Icon(Icons.phone_rounded, color: AppTheme.ink),
        ),
        displayLabel: 'ÁREA DOS PAIS',
        displayValue: 'Senha',
        displayMessage: 'Só os responsáveis conseguem entrar aqui.',
        scrollable: false,
        body: Container(
          decoration: BoxDecoration(
            color: AppTheme.yellow,
            borderRadius: BorderRadius.circular(layout.sectionRadius),
          ),
          padding: EdgeInsets.all(layout.size(16)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Senha',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: layout.size(8)),
              TextField(
                controller: _passwordController,
                obscureText: true,
                onChanged: (_) => setState(() => _error = null),
                decoration: const InputDecoration(
                  hintText: 'Senha',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(22)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: layout.size(12)),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE3E3),
                    borderRadius: BorderRadius.circular(layout.size(20)),
                  ),
                  padding: EdgeInsets.all(layout.size(12)),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              SizedBox(height: layout.size(16)),
              layout.isCompactWidth
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ToyButton(
                          label: 'Voltar',
                          color: Colors.white,
                          onPressed: _loading
                              ? null
                              : () {
                                  controller.closeParents();
                                },
                        ),
                        SizedBox(height: layout.size(12)),
                        ToyButton(
                          label: _loading ? 'Entrando...' : 'Entrar',
                          color: AppTheme.green,
                          onPressed:
                              _passwordController.text.trim().isNotEmpty &&
                                  !_loading
                              ? () async {
                                  setState(() {
                                    _loading = true;
                                    _error = null;
                                  });
                                  final ok = await controller.loginParents(
                                    _passwordController.text.trim(),
                                  );
                                  if (!ok && mounted) {
                                    AppSoundEffects.error();
                                    setState(() {
                                      _error =
                                          'Senha incorreta. Tente de novo.';
                                      _loading = false;
                                    });
                                  } else {
                                    AppSoundEffects.success();
                                  }
                                }
                              : null,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: ToyButton(
                            label: 'Voltar',
                            color: Colors.white,
                            onPressed: _loading
                                ? null
                                : () {
                                    controller.closeParents();
                                  },
                          ),
                        ),
                        SizedBox(width: layout.size(12)),
                        Expanded(
                          child: ToyButton(
                            label: _loading ? 'Entrando...' : 'Entrar',
                            color: AppTheme.green,
                            onPressed:
                                _passwordController.text.trim().isNotEmpty &&
                                    !_loading
                                ? () async {
                                    setState(() {
                                      _loading = true;
                                      _error = null;
                                    });
                                    final ok = await controller.loginParents(
                                      _passwordController.text.trim(),
                                    );
                                    if (!ok && mounted) {
                                      AppSoundEffects.error();
                                      setState(() {
                                        _error =
                                            'Senha incorreta. Tente de novo.';
                                        _loading = false;
                                      });
                                    } else {
                                      AppSoundEffects.success();
                                    }
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: layout.size(12)),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(layout.size(28)),
                ),
                padding: EdgeInsets.all(layout.size(16)),
                child: const Text(
                  'Se esquecer a senha, a redefinição exigirá limpar os dados do app.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
