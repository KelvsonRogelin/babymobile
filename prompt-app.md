# Prompt de Contexto — Babymodile (Telefone de Brinquedo)

> Use este documento como prompt de contexto ao retomar o desenvolvimento do app.
> Todo o projeto, código, comentários e interface estão em **Português do Brasil (PT-BR)**.

---

## 1. Papel esperado

Você é um engenheiro de software sênior especialista em **Flutter/Dart**, UX infantil (3–8 anos) e
arquitetura mobile de baixo custo. Trabalhe em **etapas pequenas, funcionais e testáveis**, sem
inventar dados, sem dependências pagas e sem backend. Preserve o estilo visual já existente.

---

## 2. O que é o app

**Babymodile** é um aplicativo infantil que transforma o celular/tablet num **telefone de brinquedo**.

A criança disca qualquer número no teclado e, ao tocar em **Ligar**, assiste a um **vídeo curto
gravado pela família** — como se a ligação fosse "atendida" por alguém conhecido. Não há internet,
conta, telemetria ou upload: todo o conteúdo fica **no próprio dispositivo**.

- **Público-alvo:** crianças de 3 a 8 anos (uso principal) e pais/responsáveis (administração).
- **Proposta de valor:** brincadeira afetiva e repetível, com operação simples para a criança e
  uma área protegida por senha para os pais gerenciarem os vídeos.
- **Plataforma:** Android (Flutter). Interface retrato, mobile-first.

---

## 3. Stack técnica

| Item | Definição |
|------|-----------|
| Framework | Flutter (Dart SDK `^3.10.4`) |
| Estado | `provider` + `ChangeNotifier` (`AppController`) |
| Persistência | `shared_preferences` (JSON) via `AppStorage` |
| Vídeo | `video_player` (reprodução) + `image_picker` (câmera/galeria) |
| Arquivos | `path_provider` + `path` |
| Senha | `crypto` — SHA-256 com salt aleatório por instalação |
| Container | `MaterialApp` com `switch` sobre `AppView` |

Dependências declaradas em [pubspec.yaml](pubspec.yaml): `crypto`, `image_picker`, `path`,
`path_provider`, `provider`, `shared_preferences`, `video_player`, `cupertino_icons`.

### Build Android (ambiente já validado)
- JDK 21 (`C:\jdk21`), Android SDK em `%LOCALAPPDATA%\Android\sdk`, NDK r28c, CMake 3.22.1.
- Comando: `flutter build apk --release` → gera `build/app/outputs/flutter-apk/app-release.apk`.
- O pacote transitivo `jni` (via `path_provider_android`) exige NDK/CMake para build nativo.

---

## 4. Fluxos de uso

### 4.1 Navegação entre telas
As telas são controladas por `AppController.view` (enum `AppView`), em [main.dart](lib/main.dart):

`booting` → `onboarding` → `kid` → `parentsLogin` → `parentsDashboard`

| View | Tela | Quando aparece |
|------|------|----------------|
| `booting` | `BootScreen` | Enquanto carrega preferências/vídeos |
| `kid` | `KidHomeScreen` | **Sempre** é a tela inicial do app |
| `onboarding` | `OnboardingScreen` | Primeiro acesso: criar a senha de supervisão |
| `parentsLogin` | `ParentsLoginScreen` | Entradas seguintes: pede a senha |
| `parentsDashboard` | `ParentsDashboardScreen` | Gestão de mídias (área dos pais) |

### 4.2 Fluxo da criança (tela principal)
1. O app **abre direto no telefone** (não há onboarding obrigatório na abertura).
2. A criança digita números no teclado (grade de 3 colunas; só dígitos 0–9).
3. Botões **Apagar** (remove o último dígito) e **Ligar** (botão verde, com animação de pulso).
4. Abaixo do teclado existe o botão **Galeria de contatos**: abre uma lista dos contatos já
   gravados em **grade de 3 por linha**, mostrando avatar, nome e número. Tocar em um contato
   **liga imediatamente** para ele.
5. Ao ligar: valida o número (mínimo **3 dígitos**), toca som de chamada, entra na tela
   **"CHAMANDO..."** por cerca de **2,4 segundos** (animação de bolinhas + "Trim... trim...") e
   então reproduz o vídeo.
6. Ao fim do vídeo, ou ao tocar no botão vermelho de **encerrar**, volta automaticamente ao teclado.

### 4.3 Regra de seleção de vídeo
Definida em [video_selection.dart](lib/src/utils/video_selection.dart):
- **Número especial:** se o número discado corresponde ao `linkedPhoneNumber` de um vídeo ativo,
  esse vídeo é exibido (vínculo direto — "esse número conhece um vídeo especial").
- **Sem correspondência:** um vídeo **ativo** é **sorteado aleatoriamente** entre os disponíveis.
- **Galeria vazia/sem ativos:** mensagem amigável, sem frustrar a criança (padrão *no-fail*).

### 4.4 Fluxo dos pais (área protegida)
- **Acesso:** pressionar por **3 segundos** a engrenagem no canto superior do telefone.
  Durante o toque, o visor orienta a ação.
- **Primeiro acesso** (ainda sem senha): abre o cadastro da senha de supervisão — campo **Senha** e
  **Confirmação da senha** no mesmo bloco, com botão **Salvar senha** abaixo. Ao salvar, entra
  direto na gestão de mídias. Há também **Voltar para o telefone**.
- **Entradas seguintes:** a senha é pedida **em toda entrada** (não há sessão persistente).
- **Gestão de mídias:** gravar/enviar vídeo (câmera ou galeria), definir **título**, **número
  especial** (opcional, mínimo 3 dígitos, não pode repetir em outro vídeo), **avatar do contato**,
  **status** (`Ativo`, `Inativo`, `Bloqueado`), assistir **prévia**, **editar** e **excluir**.
- Duração máxima de vídeo: `AppSettings.maxDurationSec` (padrão **30 s**), validada após a medição.

---

## 5. Regras de negócio e dados

- **Validação de número:** normaliza para apenas dígitos; válido com **≥ 3 dígitos**.
  Formatação exibida em grupos de 3 (`123 456`). Centralizado em [dialer.dart](lib/src/utils/dialer.dart).
- **Senha:** armazenada como SHA-256 de `salt::senha` com salt aleatório — nunca em texto puro.
- **Vídeos:** arquivos copiados para o diretório de documentos do app (pasta `videos/`).
  Metadados serializados em JSON no `shared_preferences`.
- **Modelo `VideoEntry`:** id, título, `avatarId`, `linkedPhoneNumber`, status, timestamps,
  caminho do arquivo, mimeType, duração e tamanho.
- **Modelo `AppSettings`:** `quality` (padrão `mid`) e `maxDurationSec` (padrão 30).
- **Avatares de contato:** 10 presets desenhados em código (emoji + gradiente), sem assets externos:
  Papai 👨, Mamãe 👩, Avô 👴, Avó 👵, Tio 🧔, Tia 🙋‍♀️, Primo 🧒, Prima 👧, Amigo 🧑, Amiga 😊.
  Quando não há avatar salvo, o app **sugere** um preset pela palavra no título (ex.: "vovó" → Avó).
  Veja [contact_avatar_art.dart](lib/src/widgets/contact_avatar_art.dart).
- **Efeitos sonoros/hápticos:** clique no teclado, tom de chamada, erro e encerramento, via
  `SystemSound` + `HapticFeedback` (com canal nativo opcional). Veja
  [app_sound_effects.dart](lib/src/services/app_sound_effects.dart).

---

## 6. Estrutura de pastas

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
                  contact_avatar_art
test/             video_selection_test.dart
```

**Widgets base do projeto** (manter o padrão visual):
`ToyPhoneShell` (carcaça do telefone: visor + corpo + ícones), `ToyButton` (botão grande
arredondado), `DeviceLayout` (escala responsiva: `size()`, `sectionRadius`, `roundButtonSize`,
`keypadGap`, `keypadDigitFont`, `isCompactWidth/Height`) e `AppTheme` (cores `pink`, `green`,
`lavender`, `blue`, `orange`, `yellow`, `gold`, `ink`, `shell`).

---

## 7. Diretrizes de design (UX infantil)

- Estética de "brinquedo digital fofinho-tech": cores vivas (rosa, verde, lavanda, azul, laranja,
  amarelo), fundo claro, botões 3D grandes e arredondados.
- Alvos de toque grandes; tipografia legível e generosa nos números.
- Microanimações com propósito (pulso no botão Ligar, bolinhas na espera de chamada).
- Nada de botões decorativos sem ação — **toda affordance precisa funcionar**.
- Feedback sempre **amigável e sem falha** ("no-fail"): erro nunca assusta a criança.
- Textos curtos, simples e em PT-BR.

---

## 8. Estado atual e pendências conhecidas

**Implementado nesta versão:** telefone com teclado, galeria de contatos em 3 colunas com ligação
direta, tela de espera de chamada, sorteio/vínculo de vídeos, cadastro e login de senha,
gestão de mídias (gravar, editar, status, excluir), avatares de contato e sistema de sons/hápticos.

**Pendências em relação ao PRD (transparência):**
- **Compactação de vídeo:** hoje o arquivo é apenas copiado para o app; ainda não há reencode
  respeitando `AppSettings.quality` (ver [prd.md](.trae/documents/prd.md) §5).
- **Confirmação dupla + desfazer** na exclusão de vídeo (§2.3) ainda não foi implementada.
- **Redefinição de senha** exige limpar os dados do app (não há fluxo dedicado).
- **Cobertura de testes** limitada ao sorteio de vídeos.

---

## 9. Formato de trabalho esperado

- Comunique-se e escreva código/comentários em **PT-BR**.
- Faça mudanças incrementais e valide com `flutter analyze` (deve terminar sem issues).
- Não introduza banco de dados, backend ou serviços pagos neste estágio.
- Não baixe dados nem adicione dependências sem necessidade explícita.
- Ao alterar UI, preserve a identidade visual e o padrão dos widgets existentes.
