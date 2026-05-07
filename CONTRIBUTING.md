# Contribuindo

## Workflow

1. Fork (ou branch a partir de `main`)
2. `flutter pub get` na raiz e em `demo/`
3. Faça suas alterações
4. Antes do PR, rode local:
   ```bash
   dart format lib test example/lib
   flutter analyze --fatal-infos
   flutter test
   cd demo && flutter analyze --fatal-infos && flutter test
   ```
5. Abra um PR contra `main`

## CI

O workflow [`.github/workflows/ci.yml`](.github/workflows/ci.yml) roda em
todo push para `main` e em PRs:

- `lib`: format check + analyze + 138 tests com coverage
- `demo`: analyze + smoke test
- `build-android` (apenas em push para `main`): gera APK debug

## Convenções de código

- **Sem comentários redundantes**: docstrings só onde o "porquê" não é óbvio
- **Imports**: organize com `dart format` (auto-faz)
- **Nullsafety estrita**: `--fatal-infos` no analyze rejeita até `info`
- **Testes**: cada bug fix vem com um test que falharia sem o fix

## Branch protection (sugerido)

Configure em https://github.com/edsonmartins/archbase-flutter/settings/branches:

- **Branch name pattern**: `main`
- ✅ Require a pull request before merging
  - ✅ Require approvals: 1 (opcional)
  - ✅ Dismiss stale reviews on new commits
- ✅ Require status checks to pass before merging
  - ✅ Require branches to be up to date before merging
  - **Required checks**: `archbase_flutter (lib)`, `archbase_demo (analyze + smoke)`
- ✅ Require conversation resolution before merging
- ✅ Do not allow bypassing the above settings (mesmo para admins)

Após o primeiro CI rodar, os jobs aparecem como opções nos "Required checks".

## Releases

Quando estabilizar a v1:

1. Atualize `CHANGELOG.md`
2. Bump da versão em `pubspec.yaml`
3. Tag: `git tag v1.0.0 && git push --tags`
4. Crie release no GitHub apontando para a tag

## Problemas comuns

- **`flutter analyze --fatal-infos` reclama de info**: rode `dart format` —
  o auto-formatter resolve a maioria.
- **Testes do banner travam localmente**: usa `pump()` em vez de
  `pumpAndSettle()` — animações com timers periódicos podem travar.
- **Demo não compila**: `cd demo && flutter pub get` (o path da lib
  mãe muda quando você abre só o demo no IDE).
