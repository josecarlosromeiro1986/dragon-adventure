# 🏷️ Guia de Versionamento e Releases — Dragon Adventure: O Último Herói

Este documento define o processo obrigatório de versionamento para que **todas as novas alterações, correções e lançamentos** mantenham histórico limpo, compatibilidade de save e rastreabilidade no **GitHub** e no **GitHub Pages**.

---

## 1. Regra de Ouro (Quando Versionar?)

Sempre que qualquer entrega de código, asset ou balanceamento for concluída para publicação em `main`:

1. **Nunca publique mudança funcional no jogo sem atualizar a versão** em [`project.godot`](../project.godot) e no [`CHANGELOG.md`](../CHANGELOG.md).
2. **Use [`GameData.get_game_version()`](../autoload/GameData.gd)** para ler a versão — jamais crie constantes duplicadas em scripts de UI ou save.

---

## 2. Padrão SemVer (`MAJOR.MINOR.PATCH`)

| Tipo de Incremento | Exemplo (`1.0.0` →) | Quando usar neste projeto |
| :--- | :--- | :--- |
| **`PATCH`** | `1.0.1` | Correções de bugs, ajuste de volume/SFX (ex.: Issue `#1`), correções de colisão, texto, CSS/HUD ou refatorações sem novo conteúdo. |
| **`MINOR`** | `1.1.0` | Novo monstro, novo chefe, novo item/arma/armadura, nova magia, novo NPC, novo sistema ou recurso visível de UI retrocompatível com o save. |
| **`MAJOR`** | `2.0.0` | Mudança estrutural grande, novo ato completo da campanha ou quebra de compatibilidade no formato do save (exigindo incremento de `SAVE_SCHEMA_VERSION`). |

> **Versionamento do Save (`SAVE_SCHEMA_VERSION`):**  
> Em [`autoload/GameState.gd`](../autoload/GameState.gd), `SAVE_SCHEMA_VERSION` controla a estrutura de `user://savegame.json`. Só incremente `SAVE_SCHEMA_VERSION` quando mudar chaves/formatos do save, garantindo migração segura para jogadores antigos em `load_game()`.

---

## 3. Onde a Versão Vive no Projeto

| Arquivo | Papel |
| :--- | :--- |
| [`project.godot`](../project.godot) (`config/version`) | **Fonte única da verdade** da versão do jogo (`application/config/version`). |
| [`autoload/GameData.gd`](../autoload/GameData.gd) (`get_game_version()`) | Helper estático que lê `ProjectSettings.get_setting("application/config/version")`. |
| [`scripts/TitleScreen.gd`](../scripts/TitleScreen.gd) | Exibe `Versão vX.Y.Z • Godot WebGL` na tela inicial. |
| [`scripts/SettingsModal.gd`](../scripts/SettingsModal.gd) | Exibe `vX.Y.Z` no rodapé da janela de configurações. |
| [`autoload/GameState.gd`](../autoload/GameState.gd) | Salva `"save_version"` e `"game_version"` em `user://savegame.json`. |
| [`CHANGELOG.md`](../CHANGELOG.md) | Histórico legível por humanos/IAs organizado por versão e data. |

---

## 4. Checklist Passo a Passo para Lançar uma Nova Versão

Antes de dar como finalizada qualquer tarefa que altere o jogo:

- [ ] **1. Definir o próximo número SemVer (`X.Y.Z`)** com base no escopo (`PATCH`, `MINOR` ou `MAJOR`).
- [ ] **2. Atualizar `config/version="X.Y.Z"`** na seção `[application]` de [`project.godot`](../project.godot).
- [ ] **3. Atualizar [`CHANGELOG.md`](../CHANGELOG.md):** mover os itens concluídos de `[Unreleased]` para uma nova seção `## [X.Y.Z] - AAAA-MM-DD` (referenciando as Issues `#id`).
- [ ] **4. Atualizar a documentação técnica em `docs/`**, caso tenha adicionado ou mudado monstros, itens, magias, áudio ou mapas.
- [ ] **5. Validar localmente no Godot `4.7.2` + WebGL:**
  ```powershell
  godot --headless --path . --import
  godot --headless --path . --quit-after 3
  powershell -ExecutionPolicy Bypass -File .\scripts\run_web_chrome.ps1 -Port 8080
  ```
- [ ] **6. Confirmar na tela do jogo (`TitleScreen` e `SettingsModal`)** que a nova versão `vX.Y.Z` aparece corretamente e sem erros no console.
- [ ] **7. Commitar referenciando a Issue (quando houver):**
  ```powershell
  git commit -m "fix(audio): reduce intro dragon roar volume (Closes #1)"
  ```
- [ ] **8. Criar a tag anotada e enviar `main` + tag para o GitHub:**
  ```powershell
  git tag -a vX.Y.Z -m "Release vX.Y.Z"
  git push origin main
  git push origin vX.Y.Z
  ```
- [ ] **9. Criar a GitHub Release** correspondente à tag `vX.Y.Z` com resumo das notas de lançamento e link direto para jogar no GitHub Pages.
- [ ] **10. Conferir o workflow `Deploy WebGL to GitHub Pages`** no GitHub Actions (`conclusion: success`) e validar o jogo atualizado em [`https://josecarlosromeiro1986.github.io/dragon-adventure/`](https://josecarlosromeiro1986.github.io/dragon-adventure/).
