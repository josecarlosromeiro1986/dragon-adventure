# 🎮 Game Design Document (GDD) — Dragon Adventure: O Último Herói

## 1. Visão Geral
* **Nome do Jogo:** Dragon Adventure
* **Subtítulo:** O Último Herói
* **Gênero:** RPG de Ação e Aventura 2D / Semi-Idle Auto-Battler com Zonas de Caçada (Hunts)
* **Motor & Linguagem (Engine):** **Godot Engine 4.7.2 (GDScript)**
* **Estilo Artístico:** Pixel Art Retrô em perspectiva Top-Down 45° ortográfica (estilo clássico *Tibia / PokeTibia*, grid lógico 32x32 em mapas `64x36` / `2048x1152 px`)
* **Plataforma-Alvo:** Navegador Web (Exportação HTML5 / WebAssembly / `gl_compatibility` WebGL 2.0)
* **Navegador Homologado:** **Google Chrome**
* **Referência de Gameplay & Interface:** *Poke Idle League* (estrutura de caçadas contínuas, telemetria em tempo real, combate híbrido manual/automático e economia de loot)
* **Público:** Livre / Fãs de jogos clássicos retrô, exploração e RPGs casuais de navegador

---

## 2. Conceito Central (Core Concept)
O jogador controla **Daniel Ragnar**, um menino corajoso com uma **faixa vermelha amarrada na testa**, filho do lendário **Barão Ragnar**. Após o surgimento do **Deus Dragão Lunário**, hordas de monstros destruíram quase todas as civilizações. Apenas a **Vila Barão Ragnar** resistiu. Após a tentativa frustrada do Barão de derrotar o dragão e o seu misterioso sumiço, Daniel assume o papel de ser o **Último Herói**.

Na tela inicial (`TitleScreen`), o jogador acompanha o **Prólogo cinematográfico dublado** e inicia a aventura explorando zonas de caçada (**Floresta dos Ecos**, **Cavernas e Minas** e **Castelo de Lunário**), enfrentando monstros comuns e os **6 chefes** da campanha, recolhendo **cédulas de dinheiro em notas** que caem dos inimigos, gerenciando rendimentos no **Hunt Analyzer**, comprando comidas e equipamentos (**Madeira ➔ Pedra ➔ Ouro ➔ Diamante**) na Loja da Vila, até derrotar o Deus Dragão Lunário e resgatar seu pai na **Cabana Inimiga Distante**.

---

## 3. Perspectiva Visual e Apresentação (Estilo Tibia / Top-Down 45°)
* **Câmera:** Top-Down 2D suave (`Camera2D`) com `position_smoothing_enabled = true` e margens estendidas (`limit_top = -56`, `limit_right = map_width + 256`, `limit_bottom = map_height + 64`) para garantir que painéis da HUD nunca encubram portais ou bordas do mapa.
* **Cenários Vivos:** Mapas ilustrados `2048x1152 px` combinados ao `TibiaTileEngine` (`64x36` tiles, pathfinding `AStarGrid2D`, obstáculos circulares, pontes sobre rios, placas de *Hunt Spots* e tochas/braseiros com partículas).
* **Visual do Herói:** Sprites em 4 direções com animação de caminhada de 6 frames e overlay dinâmico da arma e da armadura equipada (`none`, `wood`, `stone`, `gold`, `diamond`), preservando sempre a faixa vermelha esvoaçante.
* **Feedback Visual de Combate (`FloatingText.gd` + Hitstop + Screen Shake):**
  * **Branco:** Dano físico padrão de Espada ou Martelo.
  * **Dourado (`CRÍTICO!`):** Acertos críticos com *hitstop* e tremor de câmera.
  * **Azul Claro / Ciano (`SUPER EFETIVO! x2`):** Fraqueza elemental explorada.
  * **Verde (`+HP`):** Restauração de vida ao consumir comidas.
  * **Cédulas Verdes (`CashNote.gd`):** Notas lançadas ao chão e atraídas magneticamente para Daniel.

---

## 4. Loop Principal de Jogabilidade (Core Loop & Hunts)
```
┌────────────────────────────────────────────────────────────────────────┐
│                        VILA BARÃO RAGNAR (HUB)                         │
│   • Conversar com o Aldeão (História dublada)                          │
│   • Negociar com o Vendedor / Loja (Comidas, Espadas, Martelos, Armad.)│
│   • Atravessar a ponte leste (Portal visível para a Floresta dos Ecos) │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        ZONA DE CAÇADA ATIVA                            │
│   • Modo Manual (WASD/Mouse + Ataque/Magias) OU Auto-Hunt (Tecla R)    │
│   • Respawn contínuo em Hunt Spots (máx. 10 monstros ativos por zona)  │
│   • Drop de Dinheiro em Notas e Experiência (XP / Nível)               │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   HUNT ANALYZER (PAINEL DE TELEMETRIA)                 │
│   • Tempo de Caçada, Abates totais, XP/h                               │
│   • Receita Bruta (Notas), Gasto em Comida e Lucro Líquido em Notas    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     CONFRONTO DE CHEFES E PROGRESSO                    │
│   • Acumular abates na zona para liberar o botão Desafiar Chefe        │
│   • Cutscene dublada de confronto com Sub-Chefe e depois Chefe da área │
│   • Desbloquear magias e novos biomas até resgatar o Barão Ragnar      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Modos de Combate: Manual, Mobile Touch e Auto-Hunt
### A. Modo Manual (Desktop)
* Movimentação em 8 direções via `WASD` / `Setas` ou clique com o **Botão Direito do Mouse** (*Click-to-Walk* usando `AStarGrid2D`).
* **Dash (`Shift`):** Esquiva rápida com rastro visual e breve janela de recarga (`0.85s`).
* **Ataque (`Espaço` ou `Clique Esquerdo`):** Ataca na direção atual ou na direção exata do cursor do mouse; clicar em janelas, botões da HUD ou fundo durante diálogos/cutscenes nunca dispara ataque.
* **Comida Inteligente (`Q`):** Escolhe automaticamente a comida mais adequada da mochila conforme o HP faltante (`Maçã`, `Pão` ou `Carne`).

### B. Modo Mobile & Tablet (`TouchControls.gd`)
* Ativação automática em dispositivos touchscreen (ou alternância manual `Auto / Sempre ON / Sempre OFF` em **Configurações & Som**).
* **Joystick Virtual (esquerda)** + botões circulares táteis (direita): **`DASH`** à esquerda das skills, arco **`Fogo` → `Vento` → `Água`** ao redor do botão **`ATACAR`** e botão contextual **`Interagir`** ao se aproximar de NPCs ou Portais.
* Toque direto nos slots da barra inferior, Minimapa, NPCs e Portais, além de modais redimensionáveis via `MedievalUI.popup_fit()`.

### C. Modo Auto-Hunt (`R` ou Botão `Auto: ON/OFF`)
* Localiza automaticamente o monstro vivo mais próximo e navega pelos *Hunt Spots* usando `AStarGrid2D` com detecção e evasão de obstáculos.
* Executa ataques básicos e rotaciona magias desbloqueadas respeitando cooldown e mana.
* **Auto-Comer:** Consome comida automaticamente quando o HP cai abaixo de 50%, registrando o gasto no *Hunt Analyzer*.

---

## 6. Interface do Usuário (HUD Medieval Padronizada)
Construída em `MedievalUI.gd` com painéis `9-slice` (`panel_stone`, `panel_parchment`, `panel_gold`, `panel_slot`) e `notes_pill_box` padronizado:
* **Barra Superior (`TopBar`):** Orbes + barras de **HP** e **Mana**, badge de **Notas (`$ X Notas`)**, **Brasão de Nível + Barra de XP**, botões **Auto-Hunt**, **Desafiar Chefe** (oculto após derrotar sub-chefe e chefe da zona), **Mapa**, **Loja** (visível na Vila), **Bestiário [B]**, **Rank** (Speedrun Global), **Mochila [I]**, **Novo Jogo** e **Config / Som**, além do **Cronômetro Speedrun (`Manual` / `Auto-Hunt`)** no canto superior esquerdo.
* **Painel Direito:** **Hunt Analyzer** + **Minimapa ao vivo (`MinimapWidget.gd`)** mostrando jogador, NPCs, monstros, chefes e portais.
* **Barra Inferior (`BottomBar`):** Botão **Comer**, ícones de **Arma/Armadura equipadas** e 3 **Slots Rúnicos de Magias** clicáveis/tocáveis com cooldown visual e popup informando a condição de desbloqueio enquanto bloqueadas.
* **Janelas Modais & Pausa Automática:** Toda janela aberta (`TitleScreen`, `CutsceneModal`, `DialogueBox`, `ShopModal`, `HuntsMapModal`, `BestiaryModal`, `RankingModal`, `InventoryModal`, `SettingsModal`, `VictoryModal`, `ConfirmResetDialog`) pausa a árvore (`get_tree().paused = true`) via `_sync_modal_pause()` e aplica *guard* pós-fechamento no jogador.

---

## 7. Controles Oficiais

| Ação | Teclado & Mouse | Mobile / Tablet (Touch) |
| :--- | :--- | :--- |
| **Mover Daniel** | `W, A, S, D`, `Setas` ou `Clique Direito` no mapa | Joystick Virtual (canto inferior esquerdo) ou toque no Minimapa |
| **Dash / Esquiva** | `Shift` | Botão `DASH` (à esquerda das skills) |
| **Atacar (Espada / Martelo)** | `Espaço` ou `Clique Esquerdo` (mira no cursor) | Segurar/tocar botão `ATACAR` (mira automática no alvo próximo) |
| **Magia 1 — Bola de Fogo** | `1` ou clique no slot | Botão `Fogo` no arco ou slot na barra |
| **Magia 2 — Tornado** | `2` ou clique no slot | Botão `Vento` no arco ou slot na barra |
| **Magia 3 — Bomba de Água** | `3` ou clique no slot | Botão `Água` no arco ou slot na barra |
| **Comer Comida Inteligente** | `Q` ou botão `Comer` | Botão `Comer` na barra inferior |
| **Interagir com NPCs / Portais** | `E` ou clique no NPC/Portal | Botão contextual `Interagir` ou toque direto no NPC/Portal |
| **Alternar Auto-Hunt** | Botão `Auto: ON/OFF` | Toque no botão `Auto: ON/OFF` |
| **Bestiário / Mochila / Fechar** | `B` / `I` / `Esc` | Botões da barra superior |

---

## 8. Arquitetura Técnica no Godot 4.7.2 & Exportação Web
* **Motor:** Godot Engine 4.7.2 (`gl_compatibility`, `viewport_width = 1280`, `viewport_height = 720`, `stretch/mode = "canvas_items"`, `aspect = "expand"`, `default_texture_filter = 0` Nearest, pixel snap 2D habilitado).
* **Autoloads (`project.godot`):**
  1. `GameData` ([`autoload/GameData.gd`](../autoload/GameData.gd)) — Catálogo de armas, armaduras, raridades, comidas, magias, monstros, chefes, mundos e versão oficial (`get_game_version()`).
  2. `GameState` ([`autoload/GameState.gd`](../autoload/GameState.gd)) — Estado do jogador, inventário, detecção touch (`are_touch_controls_active()`), desbloqueios e auto-save em `user://savegame.json`.
  3. `HuntAnalyzerData` ([`autoload/HuntAnalyzerData.gd`](../autoload/HuntAnalyzerData.gd)) — Telemetria de sessão em zonas de caçada.
  4. `SpriteFactory` ([`autoload/SpriteFactory.gd`](../autoload/SpriteFactory.gd)) — Carregamento com cache e *fallback* procedural de texturas/animações.
  5. `AudioManager` ([`autoload/AudioManager.gd`](../autoload/AudioManager.gd)) — Mixer de 3 canais (`Música`, `SFX`, `Vozes`), *crossfade* entre mapas, *ducking* de música durante falas e desbloqueio automático de áudio no primeiro input/toque no navegador.
  6. `LeaderboardService` ([`autoload/LeaderboardService.gd`](../autoload/LeaderboardService.gd)) — Cliente HTTP REST do **Ranking Global (Supabase + RLS)** e persistência local independente em `user://speedrun_ranks.json` (consulte [`RANKING_SUPABASE.md`](./RANKING_SUPABASE.md)).
* **Scripts Principais (`scripts/`):** `Main.gd`, `Player.gd`, `Monster.gd`, `NPC.gd`, `TibiaTileEngine.gd`, `ZonePortal.gd`, `SpellProjectile.gd`, `EnemyProjectile.gd`, `BossHazardZone.gd`, `CashNote.gd`, `FloatingText.gd`, `HUD.gd`, `TouchControls.gd`, `MedievalUI.gd`, `MinimapWidget.gd`, `TitleScreen.gd`, `CutsceneModal.gd`, `DialogueBox.gd`, `ShopModal.gd`, `InventoryModal.gd`, `HuntsMapModal.gd`, `BestiaryModal.gd`, `RankingModal.gd`, `SettingsModal.gd`, `VictoryModal.gd`.
* **Exportação & Execução Local:** `scripts/run_web_chrome.ps1` gera `build/web/index.html` + `build/web/index.pck` e inicia servidor HTTP local para Google Chrome.
