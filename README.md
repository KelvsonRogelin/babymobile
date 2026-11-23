# Babymodile — Telefone de Brinquedo

Aplicativo infantil em **Flutter** que transforma o celular/tablet num **telefone de brinquedo**.
A criança disca um número, toca em **Ligar** e assiste a um **vídeo curto gravado pela família** —
como se a ligação fosse "atendida" por alguém conhecido.

Funciona **100% offline**: sem conta, sem internet, sem upload e sem telemetria. Todo o conteúdo
(vídeos e senha) fica **no próprio dispositivo**.

- **Público-alvo:** crianças de 3 a 8 anos (uso principal) e pais/responsáveis (administração).
- **Plataforma:** Android (Flutter), interface retrato, mobile-first.

## Recursos

### Para a criança
- Teclado numérico grande, com som de tecla (DTMF) e vibração.
- Botões **Apagar** (remove o último dígito) e **Ligar** (verde, com animação de pulso).
- **Galeria de contatos** em grade 3×3 — tocar em um contato liga imediatamente.
- Tela de espera **"CHAMANDO..."** com "trim... trim..." antes de o vídeo começar.
- Reprodução do vídeo e retorno automático ao teclado ao terminar ou ao encerrar.
- Nenhuma tela de erro assusta a criança (comportamento *no-fail*).

### Para os pais (área protegida por senha)
- Acesso **segurando a engrenagem por 3 segundos**.
- Cadastro da senha de supervisão no primeiro acesso (SHA-256 + salt aleatório por instalação).
- A senha é pedida **em toda entrada** (não há sessão persistente).
- Gestão de mídias: gravar/enviar vídeo (câmera ou galeria), título, número especial, avatar do
  contato, status (`Ativo` / `Inativo` / `Bloqueado`), prévia, editar e excluir.

## Fluxos

O app **abre direto no telefone**. As telas são controladas por `AppController.view`
(enum `AppView`), em [main.dart](lib/main.dart):

| View | Tela | Quando aparece |
|------|------|----------------|
| `booting` | `BootScreen` | Enquanto carrega preferências e vídeos |
| `kid` | `KidHomeScreen` | **Sempre** a tela inicial do app |
| `onboarding` | `OnboardingScreen` | Primeiro acesso: criar a senha de supervisão |
| `parentsLogin` | `ParentsLoginScreen` | Entradas seguintes: pede a senha |
| `parentsDashboard` | `ParentsDashboardScreen` | Gestão de mídias (área dos pais) |

### Como um vídeo é escolhido
Definido em [video_selection.dart](lib/src/utils/video_selection.dart):

1. **Número especial:** se o número discado corresponde ao `linkedPhoneNumber` de um vídeo ativo,
   esse vídeo é exibido (vínculo direto).
2. **Sem correspondência:** um vídeo **ativo** é sorteado aleatoriamente entre os disponíveis.
3. **Galeria vazia/sem ativos:** mensagem amigável, sem frustrar a criança.

## Stack técnica

| Item | Definição |
|------|-----------|
| Framework | Flutter (Dart SDK `^3.10.4`) |
| Estado | `provider` + `ChangeNotifier` (`AppController`) |
| Persistência | `shared_preferences` (JSON) via `AppStorage` |
| Vídeo | `video_player` (reprodução) + `image_picker` (câmera/galeria) |
| Arquivos | `path_provider` + `path` |
| Senha | `crypto` — SHA-256 com salt aleatório por instalação |
| Sons | Canal nativo Android com `ToneGenerator` (+ `SystemSound`/hápticos como fallback) |

## Estrutura de pastas

```
lib/
  main.dart                         # MaterialApp + switch de AppView
  src/
    models/       app_settings.dart, video_entry.dart
    screens/      boot_screen, onboarding_screen, kid_home_screen,
                  parents_login_screen, parents_dashboard_screen
    services/     app_storage.dart, app_sound_effects.dart
    state/        app_controller.dart        # ChangeNotifier central
    theme/        app_theme.dart             # paleta e tema
    utils/        dialer.dart, video_selection.dart, device_layout.dart
    widgets/      toy_phone_shell, toy_button, video_player_card,
                  contact_avatar_art, baby_mascot
test/             video_selection_test.dart
```

**Widgets base** (mantêm o padrão visual): `ToyPhoneShell` (carcaça: visor + corpo + ícones),
`ToyButton` (botão grande arredondado), `DeviceLayout` (escala responsiva), `AppTheme` (paleta) e
`BabyMascot` (mascote crocodilo).

## Como rodar

```bash
flutter pub get
flutter run
```

## Gerar o APK (release)

```bash
flutter build apk --release
```

Artefato em `build/app/outputs/flutter-apk/app-release.apk`.

## Documentação

- [prompt-app.md](prompt-app.md) — contexto completo do produto, fluxos de uso, regras de negócio
  e diretrizes de design.

## Observações

- Sem backend, sem telemetria e sem serviços pagos.
- Os dados são locais: desinstalar o app remove a senha e os vídeos.
- Redefinir a senha exige limpar os dados do app (não há fluxo dedicado).
- A compactação/reenconding de vídeo respeitando a qualidade ainda não está implementada — o
  arquivo é apenas copiado para o app.
