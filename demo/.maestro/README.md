# Maestro flows — archbase_demo

Testes E2E rodando contra o app `archbase_demo` (Android e iOS).

## Instalação do Maestro

```bash
# macOS / Linux
curl -fsSL "https://get.maestro.mobile.dev" | bash

# verificar
maestro --version
```

> No macOS, abra "Settings → Privacy → Accessibility" e habilite o terminal
> que vai rodar `maestro` (necessário em iOS Simulator).

## Pré-requisitos

1. **Build do app instalado** num device/emulador rodando:
   ```bash
   cd demo
   flutter run                # deixa rodando ou
   flutter build apk --debug  # gera o APK e instala manualmente
   flutter build ios --debug  # idem para iOS Simulator
   ```
2. **Device escolhido** (caso tenha mais de um):
   ```bash
   flutter devices
   maestro test --device <id>
   ```

## Executar os flows

```bash
# todos os flows na ordem (config.yaml define a sequência)
cd demo/.maestro
maestro test .

# um único flow
maestro test flows/01_login.yaml

# com tag
maestro test --include-tags smoke .

# em modo "studio" para inspecionar a árvore de elementos visualmente
maestro studio
```

## Flows incluídos

| Arquivo | Cobertura |
|---|---|
| `flows/01_login.yaml` | Validação de campo obrigatório, credenciais inválidas, login bem-sucedido |
| `flows/02_crud.yaml` | Criar, ver, editar, excluir visita (com confirm dialog) |
| `flows/03_offline.yaml` | Liga modo offline simulado, cria visita, valida banner, religa, valida sync |
| `flows/04_settings.yaml` | Toggle tema, alto contraste, logout |

## Ordem de execução

`config.yaml` define `flowsOrder` — o login roda primeiro porque os outros
flows usam `runFlow: when: notVisible` para garantir sessão antes de começar.

## Identificação de widgets

O demo aplica `ValueKey` nos widgets que o Maestro precisa localizar
(ver `lib/keys/test_keys.dart`). No YAML referenciamos com:

```yaml
- tapOn:
    id: "dev_toggle_offline"   # casa com ValueKey('dev_toggle_offline')
```

Para texto livre (rótulos visíveis), usamos `text:` direto:

```yaml
- assertVisible: "Sem conexão"
- tapOn: "Salvar"
```

> **iOS Simulator**: O Flutter expõe `ValueKey` como
> `accessibilityIdentifier`. Em Android, como `tag` na semantics tree.
> O Maestro lida com ambos transparentemente via `id:`.

## Capturar evidências

Cada flow pode tirar screenshots. Adicionar:

```yaml
- takeScreenshot:
    path: ../screenshots/01_login_success
```

Os PNGs ficam em `.maestro/screenshots/`.

## CI (Maestro Cloud)

O repositório já tem o workflow `.github/workflows/maestro-cloud.yml`,
que constrói o APK e roda os 4 flows em devices reais na nuvem.

**Setup (uma vez):**
1. Criar conta em <https://cloud.mobile.dev/> e gerar uma API key.
2. No GitHub: `Settings → Secrets and variables → Actions → New
   repository secret` com nome `MAESTRO_CLOUD_API_KEY`.
3. Pronto — o workflow roda automaticamente em todo push para `main`
   que tocar em `demo/**` ou no workflow. Também pode ser rodado
   manualmente em `Actions → Maestro Cloud → Run workflow`.

Sem o secret, o job termina como "skipped" sem falhar — útil para
forks que não querem (ou não podem) usar o serviço pago.

**Custo:** Maestro Cloud é cobrado por minuto de device. Os 4 flows
rodam em ~5–8 min cada. Veja o pricing atual em
<https://www.mobile.dev/pricing>.

## CI alternativo (self-hosted, sem custo)

Sem cloud, com emulador headless num runner self-hosted:

```yaml
- run: flutter build apk --debug
- run: |
    adb install build/app/outputs/flutter-apk/app-debug.apk
    maestro test demo/.maestro/
```

## Troubleshooting

- **"Element not found"** em widget Flutter: rode `maestro studio` e
  inspecione a árvore. Adicione `ValueKey` no widget se faltar.
- **Animações comendo o `assertVisible`**: aumente `timeout: 10000`.
- **Texto com acento não bate**: use o texto literal (com acento) ou um
  prefixo único e use `text: ".*Sair.*"` (regex).
- **iOS: app não abre**: verifique `appId` em `config.yaml` — precisa casar
  com o bundle id real (`com.archbase.archbaseDemo` se Flutter
  camelizar — confira em `ios/Runner.xcodeproj/project.pbxproj`).
