# Changelog

Todas as mudanças notáveis de **Dragon Adventure: O Último Herói** serão documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e o projeto adota **Semantic Versioning (`SemVer`)**: `MAJOR.MINOR.PATCH`.

- **MAJOR (`X.0.0`)**: Mudanças estruturais grandes ou incompatibilidades de campanha/save.
- **MINOR (`1.X.0`)**: Novos monstros, chefes, mapas, magias, sistemas de jogabilidade ou recursos de UI.
- **PATCH (`1.0.X`)**: Correções de bugs, balanceamento, ajustes visuais/áudio e melhorias de código.

---

## [Unreleased]

- *(Nenhuma mudança pendente)*

---

## [1.3.0] - 2026-11-17

### Adicionado
- **Sistema de Rank Global / Speedrun por Categoria (`LeaderboardService.gd`, `RankingModal.gd`, `GameState.gd`):**
  - Integração online com **Supabase PostgreSQL + Data API + RLS** (`public.speedrun_ranks` + `private.speedrun_owners` + RPC `submit_speedrun_score`) utilizando apenas a `Publishable Key` pública no cliente WebGL e validação no servidor (`CHECK`, unicidade *case-insensitive* de apelido por jogador via hash SHA-256 de token local, e atualização automática apenas quando o próprio jogador bate seu recorde) ([#9](https://github.com/josecarlosromeiro1986/dragon-adventure/issues/9)).
  - Separação fiel e irreversível por run em duas categorias competitivas: **Sem Auto-Hunt (Manual)** vs **Com Auto-Hunt** (persistida em `used_auto_hunt_in_run` dentro do save da campanha; ativar `Auto: ON` mesmo por 1 segundo classifica a run como Com Auto-Hunt).
  - Congelamento automático do tempo oficial da run ao iniciar o resgate do Barão Ragnar (`GameState.freeze_victory_run()`).
  - Cronômetro live e badge de categoria na `HUD` (`SpeedrunPill` + botão **Rank**), acesso pela `TitleScreen` e envio direto com apelido personalizável e destaque de **Recorde Pessoal / Top Global** na `VictoryModal`.
  - Fallback offline e recordes locais em `user://speedrun_ranks.json` independentes de `reset_save()`.
- **Documentação (`docs/RANKING_SUPABASE.md`, `docs/GDD.md`, `docs/INDEX.md`):** Documentados o schema SQL, políticas RLS, índice composto e fluxo cliente-servidor.

---

## [1.2.1] - 2026-11-17

### Corrigido / Otimizado
- **TouchControls (`TouchControls.gd`):**
  - Captura global de soltura de toque/mouse (`_input`) no Joystick e nos pads de ação para garantir liberação mesmo se o dedo deslizar para fora do controle.
  - Substituído `PRESET_FULL_RECT` por `PRESET_TOP_LEFT` no container raiz de `TouchControls`, eliminando o aviso de sobrescrita de âncoras no Godot.
  - Otimizado `_update_skill_pads()` para chamar `queue_redraw()` apenas quando o texto ou estado visual mudar, e unificada a detecção de modo retrato com `get_viewport().get_visible_rect().size`.
- **AudioManager (`AudioManager.gd`):** Cancelamento seguro de tweens anteriores ao reutilizar players de SFX ou ajustar o volume do canal ([#7](https://github.com/josecarlosromeiro1986/dragon-adventure/issues/7)).
- **Documentação (`docs/GDD.md`):** Removidos atalhos inexistentes (`J/K/L/C`) e sincronizada a tabela de controles Mobile/Touch e `TouchControls.gd`.

---

## [1.2.0] - 2026-11-17

### Adicionado
- **Atalhos Táteis de Magias ao lado de Atacar e Dash (`TouchControls.gd`):**
  - Adicionados 3 pads circulares em arco ergonômico logo acima/à esquerda de **ATACAR** e **DASH** para conjurar **Fogo**, **Vento** e **Água** sem tirar o polegar direito da área de combate ([#5](https://github.com/josecarlosromeiro1986/dragon-adventure/issues/5)).
  - Feedback visual em tempo real nos botões de magia: contagem regressiva durante *cooldown*, escurecimento por mana insuficiente e ícone de cadeado (`Bloq.`) com dica de desbloqueio ao tocar em magias bloqueadas.
  - Botão contextual **Interagir** reposicionado à esquerda do **DASH** para zero sobreposição com o arco de skills.

---

## [1.1.0] - 2026-11-16

### Adicionado
- **Suporte Mobile & Tablet completo (`TouchControls.gd`):**
  - Detecção automática de touchscreen (`DisplayServer` + navegador WebGL via `JavaScriptBridge`) com opção manual em `Configurações & Som` (**Auto / Sempre ON / Sempre OFF**) persistida no save (`touch_controls_mode`).
  - **Joystick Virtual analógico** no canto inferior esquerdo e botões táteis de **Atacar** (segurar para combo contínuo com mira automática no alvo próximo), **Dash** e botão contextual **Interagir** para NPCs e Portais.
  - **Slots de Magia clicáveis/tocáveis** diretamente na `BottomBar` (conjuram magias desbloqueadas ou exibem/alternam a dica de desbloqueio por toque em magias bloqueadas, sem depender de hover de mouse).
  - Suporte a toque direto em **NPCs**, **Portais**, **Minimapa**, **Slots de Equipamento** e aviso discreto de orientação caso o smartphone esteja em modo retrato.
  - Desbloqueio de música (`AudioManager._input`) também em `InputEventScreenTouch` (Android Chrome / iOS Safari) com texturas WebGL (`gl_compatibility`) universais.
  - Redimensionamento responsivo de janelas (`MedievalUI.popup_fit`) para caber confortavelmente em desktop, tablet e smartphone ([#3](https://github.com/josecarlosromeiro1986/dragon-adventure/issues/3)).

---

## [1.0.1] - 2026-11-16

### Corrigido / Ajustado
- Reduzido e suavizado o volume do rugido inicial (`boss_roar`) na cutscene de abertura para não assustar jogadores ao iniciar o jogo, com suporte a tabela de atenuação por SFX (`SFX_DB_OFFSET`) e *fade-in* opcional em `AudioManager.play_sfx()` ([#1](https://github.com/josecarlosromeiro1986/dragon-adventure/issues/1)).
- Equilibrado também o volume de `boss_roar` nas invocações de chefes e no combate para manter o impacto sem estourar o áudio nem cobrir as falas.

---

## [1.0.0] - 2026-11-16

### Adicionado
- Lançamento público completo no GitHub e publicação WebGL gratuita no GitHub Pages (`https://josecarlosromeiro1986.github.io/dragon-adventure/`).
- **Campanha e Mundos (`5` biomas `64×36`):** Vila Barão Ragnar, Floresta dos Ecos, Cavernas e Minas, Castelo de Lunário e Cabana Inimiga Distante com navegação `AStarGrid2D`.
- **Bestiário Completo (`7` monstros comuns + `6` chefes):** incluindo o **Espectro de Slime** no Castelo com ataques alternados de `slime_orb` e `plasma_bolt`, além de cutscenes dubladas para Prólogo, Chefes e Resgate final.
- **Combate Híbrido & Telemetria:** Ataque manual por clique/cursor, Dash (`Shift`), Auto-Hunt inteligente (`R`), 3 magias elementais (`[1]` Fogo, `[2]` Tornado, `[3]` Água), comida inteligente (`Q`) e **Hunt Analyzer**.
- **Interface Medieval 9-Slice & Áudio `pt-BR`:** Loja, Mochila `[I]`, Bestiário `[B]`, Mapa Mundi, Configurações/Mixer de 3 canais (`Música`, `SFX`, `Vozes`).
- **Versionamento Semântico (`SemVer`):** `config/version="1.0.0"` em `project.godot`, helper `GameData.get_game_version()`, exibição discreta na Tela Inicial e em Configurações, e `save_version`/`game_version` em `user://savegame.json` ([#2](https://github.com/josecarlosromeiro1986/dragon-adventure/issues/2)).
