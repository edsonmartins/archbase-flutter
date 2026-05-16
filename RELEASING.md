# Releasing

Este projeto publica 3 pacotes no pub.dev:

| Pacote | Diretório | Padrão de tag |
|---|---|---|
| `archbase_flutter` | `.` (raiz) | `vX.Y.Z` |
| `archbase_flutter_riverpod` | `packages/archbase_flutter_riverpod` | `archbase_flutter_riverpod-vX.Y.Z` |
| `archbase_flutter_getx` | `packages/archbase_flutter_getx` | `archbase_flutter_getx-vX.Y.Z` |

A publicação é **100% automatizada via GitHub Actions** quando você empurra uma tag — usando OIDC, sem secrets necessários.

## Setup inicial (uma vez por pacote)

Pra liberar o publish via OIDC, configure no admin de cada pacote no pub.dev:

1. Logue em <https://pub.dev/> com a conta dona do pacote
2. Acesse `https://pub.dev/packages/<nome>/admin`
3. Em **"Automated publishing"**, clique **"Enable"** ou **"Configure"**
4. Preencha:
   - **GitHub repository:** `edsonmartins/archbase-flutter`
   - **Tag pattern:**
     - `archbase_flutter` → `v{{version}}`
     - `archbase_flutter_riverpod` → `archbase_flutter_riverpod-v{{version}}`
     - `archbase_flutter_getx` → `archbase_flutter_getx-v{{version}}`
   - **Require successful pull request** → marca se quiser exigir PR (opcional)
5. Salva

Pronto — daí em diante, todo `git push` de uma tag que casa com o padrão dispara o publish automaticamente.

## Fluxo de release (depois do setup)

### archbase_flutter (lib principal)

```bash
# 1. Bumpa version no pubspec.yaml
vim pubspec.yaml   # version: 0.5.4

# 2. Atualiza CHANGELOG.md adicionando a nova seção no topo
vim CHANGELOG.md

# 3. Commit
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: bump 0.5.4"
git push

# 4. Cria e empurra a tag (dispara publish.yml)
git tag -a v0.5.4 -m "v0.5.4"
git push origin v0.5.4
```

O workflow vai:
1. Validar que a tag bate com `pubspec.yaml` (falha se não bater)
2. Rodar `dart pub publish --force` autenticando via OIDC
3. Criar um GitHub Release `v0.5.4` marcado como Latest

### archbase_flutter_riverpod ou _getx

Mesmo processo, mas:

```bash
cd packages/archbase_flutter_riverpod
vim pubspec.yaml          # bumpa version
vim CHANGELOG.md          # adiciona entry
cd ../..

git add packages/archbase_flutter_riverpod
git commit -m "chore(riverpod): bump 0.2.1"
git push

git tag -a archbase_flutter_riverpod-v0.2.1 -m "riverpod 0.2.1"
git push origin archbase_flutter_riverpod-v0.2.1
```

> O workflow remove temporariamente o bloco `dependency_overrides`
> antes de publicar (já que o adapter no monorepo aponta pra
> `path: ../..` em dev).

## Antes de tagear — checklist

- [ ] `flutter analyze` → 0 issues
- [ ] `flutter test` → tudo verde
- [ ] `flutter pub publish --dry-run` → 0 warnings
- [ ] `pubspec.yaml` bumpado
- [ ] `CHANGELOG.md` com entry da versão nova
- [ ] Commit pushado pra `main`

## E se algo der errado?

### Tag empurrada mas pubspec não bumpou

O workflow **falha cedo** com:
```
::error::Tag v0.5.4 não bate com pubspec (0.5.3). Bumpa o pubspec antes de tagear.
```

Pra recuperar:
```bash
git tag -d v0.5.4                    # remove tag local
git push --delete origin v0.5.4      # remove tag remota
# bumpa pubspec, commita, tagea de novo
```

### Publish na pub.dev passou mas GH Release falhou

Recriar manualmente:
```bash
gh release create v0.5.4 --title "archbase_flutter v0.5.4" --notes "..." --latest
```

### Pub.dev rejeitou (credenciais OIDC)

Verifica se "Automated publishing" está ativo no admin do pacote
(<https://pub.dev/packages/archbase_flutter/admin>) e se o tag pattern
casa com a tag empurrada.

## Modo manual (sem o workflow)

Se preferir publicar localmente:

```bash
# main lib
flutter pub publish

# adapter (precisa remover override antes)
cd packages/archbase_flutter_riverpod
# edita pubspec, remove dependency_overrides
flutter pub get
flutter pub publish
# restaura override depois (git checkout pubspec.yaml)
```

E criar o release/tag manualmente:
```bash
git tag -a v0.5.4 -m "..."
git push origin v0.5.4
gh release create v0.5.4 --notes-file CHANGELOG_SECTION.md --latest
```
