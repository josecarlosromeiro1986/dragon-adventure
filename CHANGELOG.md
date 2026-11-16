# Changelog

Todas as mudanças notáveis de **Dragon Adventure: O Último Herói** serão documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e o projeto adota **Semantic Versioning (`SemVer`)**: `MAJOR.MINOR.PATCH`.

- **MAJOR (`X.0.0`)**: Mudanças estruturais grandes ou incompatibilidades de campanha/save.
- **MINOR (`1.X.0`)**: Novos monstros, chefes, mapas, magias, sistemas de jogabilidade ou recursos de UI.
- **PATCH (`1.0.X`)**: Correções de bugs, balanceamento, ajustes visuais/áudio e melhorias de código.

---

## [Unreleased]

- Ajuste do volume/atenuação do rugido inicial (`boss_roar`) na cutscene de abertura ([#1](https://github.com/josecarlosromeiro1986/dragon-adventure/issues/1)).

---

## [1.0.0] - 2026-11-16

### Adicionado
- Lançamento público completo no GitHub e publicação WebGL gratuita no GitHub Pages (`https://josecarlosromeiro1986.github.io/dragon-adventure/`).
- **Campanha e Mundos (`5` biomas `64×36`):** Vila Barão Ragnar, Floresta dos Ecos, Cavernas e Minas, Castelo de Lunário e Cabana Inimiga Distante com navegação `AStarGrid2D`.
- **Bestiário Completo (`7` monstros comuns + `6` chefes):** incluindo o **Espectro de Slime** no Castelo com ataques alternados de `slime_orb` e `plasma_bolt`, além de cutscenes dubladas para Prólogo, Chefes e Resgate final.
- **Combate Híbrido & Telemetria:** Ataque manual por clique/cursor, Dash (`Shift`), Auto-Hunt inteligente (`R`), 3 magias elementais (`[1]` Fogo, `[2]` Tornado, `[3]` Água), comida inteligente (`Q`) e **Hunt Analyzer**.
- **Interface Medieval 9-Slice & Áudio `pt-BR`:** Loja, Mochila `[I]`, Bestiário `[B]`, Mapa Mundi, Configurações/Mixer de 3 canais (`Música`, `SFX`, `Vozes`).
- **Versionamento Semântico (`SemVer`):** `config/version="1.0.0"` em `project.godot`, helper `GameData.get_game_version()`, exibição discreta na Tela Inicial e em Configurações, e `save_version`/`game_version` em `user://savegame.json` ([#2](https://github.com/josecarlosromeiro1986/dragon-adventure/issues/2)).
