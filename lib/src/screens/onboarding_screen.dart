import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_sound_effects.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../utils/device_layout.dart';
import '../widgets/toy_button.dart';
import '../widgets/toy_phone_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AppController>();
    final layout = DeviceLayout.fromContext(context);
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmController.text.trim();
    final hasMinLength = password.length >= 4;
    final passwordsMatch =
        confirmPassword.isNotEmpty && password == confirmPassword;
    final canSave = hasMinLength && passwordsMatch;

    return Scaffold(
      body: ToyPhoneShell(
        displayLabel: 'PRIMEIRA VEZ POR AQUI',
        displayValue: 'Senha',
        displayMessage: 'Crie a senha dos pais para proteger a Área dos Pais.',
        body: Container(
          decoration: BoxDecoration(
            color: AppTheme.yellow,
            borderRadius: BorderRadius.circular(layout.sectionRadius),
          ),
          padding: EdgeInsets.all(layout.size(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FormCard(
                title: 'Crie a senha dos pais',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Senha',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: layout.size(6)),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      onChanged: (_) => setState(() {
                        _error = null;
                      }),
                      decoration: const InputDecoration(
                        hintText: 'Digite a senha',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: layout.size(6)),
                    Text(
                      password.length >= 6
                          ? 'Perfeito.'
                          : hasMinLength
                          ? 'Boa! Se quiser, use 6 ou mais caracteres.'
                          : 'Escolha uma senha que só os pais saibam.',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: layout.size(10)),
                    const Text(
                      'Confirmação da senha',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: layout.size(6)),
                    TextField(
                      controller: _confirmController,
                      obscureText: true,
                      onChanged: (_) => setState(() {
                        _error = null;
                      }),
                      decoration: const InputDecoration(
                        hintText: 'Digite de novo',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: layout.size(6)),
                    Text(
                      confirmPassword.isEmpty
                          ? 'Repita a senha para confirmar.'
                          : passwordsMatch
                          ? 'As senhas conferem.'
                          : 'As senhas precisam ser iguais.',
                      style: TextStyle(
                        color: confirmPassword.isEmpty || passwordsMatch
                            ? AppTheme.ink
                            : const Color(0xFFB42318),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_error != null) ...[
                      SizedBox(height: layout.size(6)),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE3E3),
                          borderRadius: BorderRadius.circular(layout.size(18)),
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
                    SizedBox(height: layout.size(10)),
                    ToyButton(
                      label: _saving ? 'Salvando...' : 'Salvar senha',
                      color: AppTheme.green,
                      onPressed: canSave && !_saving
                          ? () async {
                              AppSoundEffects.success();
                              setState(() {
                                _saving = true;
                                _error = null;
                              });
                              try {
                                await controller.createPassword(password);
                              } catch (_) {
                                AppSoundEffects.error();
                                setState(() {
                                  _error =
                                      'Não deu certo salvar a senha. Tente novamente.';
                                });
                              } finally {
                                if (mounted) {
                                  setState(() => _saving = false);
                                }
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              SizedBox(height: layout.size(10)),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(layout.size(24)),
                ),
                padding: EdgeInsets.all(layout.size(12)),
                child: const Text(
                  'Dica: na Área dos Pais você grava ou envia vídeos da família e escolhe quais ficam ativos na galeria.',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              SizedBox(height: layout.size(10)),
              ToyButton(
                label: 'Voltar para o telefone',
                color: Colors.white,
                onPressed: () {
                  AppSoundEffects.tap();
                  controller.closeParents();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final layout = DeviceLayout.fromContext(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(layout.size(26)),
      ),
      padding: EdgeInsets.all(layout.size(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: layout.size(10)),
          child,
        ],
      ),
    );
  }
}
