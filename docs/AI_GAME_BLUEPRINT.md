# 🤖 AI Game Blueprint — Como Construir um RPG 2D Top-Down Semi-Idle para Web (Godot 4 + PixelLab + ElevenLabs)

> **Público-alvo:** Agentes de Inteligência Artificial de Engenharia de Software (LLMs / Coding Agents).  
> **Objetivo:** Fornecer uma especificação arquitetural determinística e um passo a passo reproduzível para criar um novo jogo 2D Top-Down RPG / Semi-Idle no **Godot Engine 4.x (GDScript)** exportado para **WebGL 2.0 (Google Chrome)**, seguindo exatamente os padrões consolidados e as lições aprendidas no projeto **Dragon Adventure: O Último Herói**.

---

## 1. Regras Arquiteturais Fundamentais (Invariantes do Projeto)

Ao iniciar um projeto com esta arquitetura, respeite sempre estas 6 invariantes antes de escrever a primeira linha de gameplay:

1. **Single-Source-of-Truth Estático (`autoload/GameData.gd`):** Todo número de balanceamento (armas, armaduras, preços, consumíveis, magias, monstros, chefes, tabelas de fraqueza e configuração de zonas) vive em dicionários `const` em um único Autoload. UI, IA e projéteis consultam `GameData` — nunca duplique preços, nomes ou danos em scripts de cena.
2. **Fallback Procedural Antes de Assets Pagos (`autoload/SpriteFactory.gd` e `autoload/AudioManager.gd`):** O jogo **precisa rodar e ser jogável do início ao fim mesmo antes** de gerar sprites ou áudios externos. Implemente geradores procedurais (`Image.create` / `ImageTexture`) e síntese simples para que o agente valide toda a lógica sem queimar créditos de API em testes prematuros.
3. **Pausa Global Centralizada (`Main.gd::_sync_modal_pause`):** Nunca tente pausar sistemas individualmente dentro de cada janela. Conecte `visibility_changed` de **todos** os modais, diálogos, cutscenes e tela inicial a uma única função que define `get_tree().paused = has_open_modal()`. A árvore `$UI` e o `AudioManager` rodam com `process_mode = Node.PROCESS_MODE_ALWAYS`.
4. **Proteção Rígida Contra Vazamento de Cliques (`Input Guard`):**
   * Fundos decorativos `ColorRect` dentro do mundo **devem** usar `mouse_filter = Control.MOUSE_FILTER_IGNORE`, ou bloquearão cliques de ataque/movimento.
   * Só dispare ataque por clique esquerdo dentro de `_unhandled_input` (nunca interceptando cliques sobre botões da HUD ou modais) e aplique um `post_modal_guard_timer` (ex.: `0.20s`) ao fechar qualquer modal para que o último clique do botão "Fechar" ou "Avançar" não dispare ataque imediato.
5. **Margens de Câmera Para HUD Sobreposta:** Se a HUD tem barra superior, barra inferior ou painéis laterais direitos (ex.: `HuntAnalyzer` + `MinimapWidget` ocupando ~244 px à direita), **não** trave `camera.limit_*` exatamente em `[0, map_width]`. Estenda `camera.limit_right = int(map_width) + HUD_RIGHT_MARGIN`, `limit_top = -HUD_TOP_MARGIN`, `limit_bottom = int(map_height) + HUD_BOTTOM_MARGIN` para que portais, NPCs e bordas do mapa nunca fiquem inacessíveis ou escondidos atrás da HUD.
6. **Zero Threads Web por Padrão:** Para HTML5/WebGL rodar direto em Chrome sem exigir headers HTTP `Cross-Origin-Opener-Policy` / `Cross-Origin-Embedder-Policy` complexos no servidor estático, exporte com `gl_compatibility` e sem thread support pesado.

---

## 2. Configuração Canônica do Motor (`project.godot`)

```ini
[application]
run/main_scene="res://scenes/Main.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")

[autoload]
GameData="*res://autoload/GameData.gd"
GameState="*res://autoload/GameState.gd"
HuntAnalyzerData="*res://autoload/HuntAnalyzerData.gd"
SpriteFactory="*res://autoload/SpriteFactory.gd"
AudioManager="*res://autoload/AudioManager.gd"

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
textures/canvas_textures/default_texture_filter=0
2d/snap/snap_2d_transforms_to_pixel=true
2d/snap/snap_2d_vertices_to_pixel=true
```

---

## 3. Anatomia dos 5 Autoloads (`autoload/*.gd`)

| Autoload | Responsabilidade Única | Padrão Chave para IAs |
| :--- | :--- | :--- |
| **`GameData.gd`** | Dicionários `const`: `WEAPONS`, `ARMORS`, `RARITIES`, `FOODS`, `SPELLS`, `MONSTERS`, `WORLDS`, plus `get_elemental_multiplier()`. | Cada entrada possui `"id"`, `"name"`, `"tier"`, `"price"`, stats e descrição em português. |
| **`GameState.gd`** | Estado mutável do jogador, cooldowns, inventário, `unlocked_worlds`, `defeated_bosses`, `bestiary_kills`, sinais globais e persistência JSON (`user://savegame.json`). | Auto-save a cada `15s` + save imediato em compras, nível, morte de chefe e troca de zona. Inclua `check_world_unlocks()` e `check_spell_unlocks()` idempotentes para saves legados também desbloquearem recompensas retroativamente. |
| **`HuntAnalyzerData.gd`** | Acumula `session_time`, `total_kills`, `xp_gained`, `gross_cash`, `food_waste_cash` e calcula `XP/h` e lucro líquido. | Só contabiliza `session_time` quando `current_world` for zona de combate (`type == "hunt_zone"`). |
| **`SpriteFactory.gd`** | Cache de texturas (`res://assets/...`) com fallback `ImageTexture` pixel art. | Suporta frames numerados `anim_walk/<dir>/0..8.png`, ícones `assets/items/<id>.png`, `assets/spells/<id>.png` e `assets/ui/<id>.png`. |
| **`AudioManager.gd`** | Mixer de 3 canais independentes (`music_volume`, `sfx_volume`, `voice_volume`) + toggles, crossfade de BGM (`Tween`), ducking automático (`-5 dB`) durante vozes e autoplay unlock no Chrome em `_input`. | Sempre `process_mode = Node.PROCESS_MODE_ALWAYS` e tweens com `set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)` para transições suaves mesmo com jogo pausado. |

---

## 4. Hierarquia da Cena Única (`scenes/Main.tscn` + `scripts/Main.gd`)

Em vez de trocar cenas raiz (`.change_scene_to_file`), mantenha **uma única `Main.tscn`** persistente com:
* `WorldContainer (Node2D)`: recebe o `TibiaTileEngine` + props decorativos + `ColorRect` de fundo (`mouse_filter = IGNORE`, `z_index = -15`).
* `EntitiesContainer (Node2D)`: recebe `Player`, `Monster`, `NPC`, `ZonePortal`, `CashNote`, `SpellProjectile`, `EnemyProjectile`, `BossHazardZone` e `FloatingText`.
* `Camera2D`: segue `player.position` com suavização e `shake_offset`.
* `UI (CanvasLayer, process_mode = ALWAYS)`: contém `HUD` (topo, barra inferior, `HuntAnalyzer`, `MinimapWidget`), todos os modais (`ShopModal`, `InventoryModal`, `HuntsMapModal`, `BestiaryModal`, `SettingsModal`, `VictoryModal`), `DialogueBox`, `CutsceneModal`, `TitleScreen` e `ConfirmResetDialog`.

**Por que cena única funciona melhor para IAs:**
* Elimina erros de transferência de referências entre cenas ao trocar de mapa.
* Trocar de mundo reduz-se a limpar filhos de `WorldContainer`/`EntitiesContainer`, reconstruir `TibiaTileEngine.build_map(world_id)`, reposicionar `player` (no `arrival_points` se veio de portal, ou `default_spawn` se veio de teleporte), tocar `AudioManager.play_bgm(world_id)` e emitir estado para a HUD.

---

## 5. Motor de Mundos Híbrido Top-Down (`scripts/TibiaTileEngine.gd`)

Para combinar beleza visual de cenários ilustrados (16:9) com precisão de grid Top-Down RPG:
1. Defina grade fixa lógica: `cols = 64`, `rows = 36`, `TILE_SIZE = 32` (`2048 × 1152 px`).
2. Renderize o mapa panorâmico `fenaky_<id>.png` no `z_index = -10` com `TEXTURE_FILTER_NEAREST`.
3. Mantenha `walkable_grid[y][x]` espelhada em um `AStarGrid2D` (`diagonal_mode = DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES`, heurística Manhattan) e colisores `StaticBody2D` + `RectangleShape2D`.
4. **Ordem de Escultura das Colisões:**
   * Primeiro marque pontes caminháveis (`_mark_bridge_rect`) em `bridge_cells`.
   * Depois aplique rios e paredes (`_set_solid_cell_rect`), pulando células registradas em `bridge_cells`.
   * Adicione obstáculos circulares (`_add_circle_obstacle`) em construções, torres, estátuas e fogueiras.
5. Defina em cada zona: `default_spawn`, `arrival_points` (para não aparecer exatamente em cima do portal de volta e gerar loop), `portals` (com `required_boss` opcional), e `hunt_spots` (4 polos distribuídos com pool específico de monstros e spawn em *round-robin* longe do jogador).
6. **Geração do Minimapa (`MinimapWidget.gd`):** Redimensione a textura do mapa para `128×72` no carregamento e desenhe em `_draw()` os marcadores relativos (`jogador`, `NPCs`, `monstros`, `chefes`, `portais`) escalando `world_pos / Vector2(map_width, map_height) * size`.

---

## 6. Combate Híbrido, Controles & Loop Semi-Idle

### A. Entrada de Movimento & Ação (`Player.gd`)
* **Movimento Dual:** Aceite `WASD`/Setas (movimento direto cancelando rota automática) **ou** Botão Direito do Mouse (`click-to-walk` calculado via `AStarGrid2D`).
* **Ataque por Cursor + Teclado:** No ataque manual (`Espaço` ou `Clique Esquerdo` no mundo), aponte o vetor para `(get_global_mouse_position() - global_position).normalized()` quando originado do mouse, permitindo acertar inimigos com precisão mesmo sem encostar na direção cardinal.
* **Input Buffering + Dash:** Buffere cliques/teclas de ataque e magia por `0.16s` quando acionados quase ao fim do cooldown; adicione Dash (`Shift`) para esquiva tática contra ataques telegrafados de chefes (`BossHazardZone`).

### B. Máquina de Estados do `Auto-Hunt`
Quando `GameState.auto_hunt_enabled == true`:
1. Verifica se `current_hp < max_hp * 0.50` ➔ chama `GameState.eat_food()` (seleção inteligente de comida por HP faltante).
2. Procura o monstro vivo mais próximo dentro do alcance de patrulha. Se não houver alvo próximo, caminha entre `tile_engine.hunt_spots` em ciclo.
3. Move até o alcance ideal (evita travar em obstáculos calculando A* e alternando vetor de evasão se ficar parado por `_stuck_timer`).
4. Executa ataque básico e conjura magias desbloqueadas (`fireball`, `tornado`, `water_bomb`) conforme mana e cooldown.
5. Interrompe/pausa imediatamente se qualquer modal abrir (`get_tree().paused = true`).

### C. Sistema de Chefes por Zona
* Cada zona de caçada define `kills_to_boss`, `sub_boss` e `boss`.
* `GameState.get_next_world_boss(world_id)` retorna o sub-chefe pendente ou, após vencido, o chefe principal — ou `""` quando ambos já foram derrotados.
* O botão `Desafiar Chefe` na HUD só fica visível enquanto `get_next_world_boss() != ""`, bloqueado até atingir `zone_kills >= kills_to_boss` e dourado/pulsante quando pronto. Quando ambos os chefes da zona caem, o botão **some definitivamente** naquela zona.

---

## 7. Design System de UI Medieval (`scripts/MedievalUI.gd`)

Para evitar interfaces genéricas do Godot ou inconsistência entre janelas construídas via código:
1. Centralize **todo** estilo em `MedievalUI.gd` com cache em `_style_cache`:
   * `setup_modal_chrome(win, variant, pad_x, pad_y)`: configura `Window` sem borda nativa (`borderless = true`, `transparent = true`), aplica `build_medieval_theme()` compartilhado (scrollbars, tooltips, labels padrão `#F5E6C8` com `outline_size = 2`) e insere `MedievalFrame` 9-slice atrás da `Margin`.
   * `panel_box(variant, pad_x, pad_y, tint)`: `StyleBoxTexture` para `stone`, `parchment`, `gold`, `slot`, `bar`.
   * `notes_pill_box(pad_x, pad_y)`: badge padronizado escuro com borda dourada `#B58E43` para moedas/notas na HUD, Loja e Mochila.
   * `style_button(btn, variant, icon_name, font_sz, min_h)`: aplica os 4 estados `normal/hover/pressed/disabled`, texto outline legível e altera `mouse_default_cursor_shape` para `CURSOR_ARROW` quando `btn.disabled == true`.
2. **Regra Crítica de 9-Slice em Texturas Grandes:** Se uma textura `panel_*.png` tem `180×180 px` com moldura de madeira de `18 px`, **nunca** a use em pills estreitas de `24–28 px` de altura com `content_margin < texture_margin` — a borda colapsará o miolo e cortará o texto. Use `StyleBoxFlat` limpo (`notes_pill_box`) para badges pequenos e reserve `panel_parchment` para cartões/diálogos com altura `>= 44 px`.
3. **Validação Econômica na Loja (`ShopModal.gd`):** Botões de compra devem verificar `GameState.cash_notes >= price`, aplicar `disabled = true` + variante visual `"stone"` acinzentada + tooltip `"Saldo insuficiente"` quando não houver saldo, e assinar `GameState.cash_changed` para atualizar em tempo real.

---

## 8. Pipeline Econômico de Geração de Assets & Áudio por IA

### A. Pixel Art (`PixelLab.ai`)
1. **Ordem de geração em lotes controlados (verificando saldo antes/depois):**
   * *Lote 1 (Core Playable):* Protagonista 4 direções + animação `walking` (6 frames via `template` esqueleto), 1 inimigo de teste e ícones principais.
   * *Lote 2 (Personagens & Inimigos):* NPCs, variantes de armadura do protagonista (mantendo traço identitário, ex.: bandana vermelha), demais monstros e chefes em escala ampliada.
   * *Lote 3 (UI & Itens):* Kit 9-slice (`panel_*`, `btn_*` nos 4 estados) e ícones de armas, armaduras, comidas e magias.
   * *Lote 4 (Cenários):* Mapas panorâmicos top-down `fenaky_<id>.png` sincronizados ao grid lógico `64×36`.
2. **Automação:** Mantenha scripts de batch em PowerShell (`scripts/pixellab.ps1`, `download_clean_frames.ps1`) para baixar PNGs já limpos com transparência (`RGBA`) diretamente em `assets/<entidade>/<direção>/`.

### B. Áudio & Dublagens (`ElevenLabs`)
1. **Idioma & Naturalidade:** Use `eleven_multilingual_v2` com texto redigido explicitamente para o sotaque desejado (`pt-BR` brasileiro natural, evitando construções de `pt-PT`).
2. **Elenco de Vozes Distinto:** Selecione `voice_id` e `voice_settings` apropriados à idade/papel:
   * Protagonista criança/jovem: voz juvenil expressiva e natural.
   * Ancião/Pai: voz madura, firme e acolhedora.
   * Chefes: timbres distintos e ameaçadores para cada boss.
3. **Coerência Estrita Fala × Legenda:** A string enviada ao TTS (`elevenlabs.ps1 -Action tts`) deve ser **idêntica** à exibida na UI (`CutsceneModal` / `DialogueBox`).
4. **Música Progressiva por Mapa:**
   * Hub/Vila: tema medieval de suspense/tensão (sem perder o clima de abrigo).
   * Zonas de caçada 1 ➔ 2 ➔ 3: trilhas épicas medievais de intensidade crescente.
   * Epílogo: tema emocional e misterioso.

---

## 9. Protocolo Obrigatório de Build & QA para Agentes de IA

Após **qualquer** edição em scripts `.gd` ou cenas `.tscn`, o agente deve executar este pipeline antes de encerrar a tarefa:

```powershell
# 1. Reimportação limpa de recursos
& $GodotExe --headless --path <ROOT> --import --quit

# 2. Smoke test de inicialização da cena principal (detecta erros GDScript e autoloads quebrados)
& $GodotExe --headless --path <ROOT> --quit-after 3

# 3. Exportação Web Release para HTML5/WebGL
& $GodotExe --headless --path <ROOT> --export-release "Web" "<ROOT>\build\web\index.html"
```

* Critério de aprovação CLI: **código de saída `0` nos 3 comandos** e **zero** `SCRIPT ERROR` / `Parse Error` no log.
* Critério de aprovação Visual/Runtime: subir servidor HTTP local (`scripts/run_web_chrome.ps1 -SkipExport`), abrir `http://localhost:<PORT>/index.html` em navegador real `1280×720`, testar fluxos alterados (cliques, modais, compras, portais, cutscenes), inspecionar o screenshot capturado e exigir **`0` erros no console do navegador**.

---

## 10. Antipatterns & Armadilhas Conhecidas (Evite Repetir Estes Erros)

| Armadilha Observada | Causa Raiz | Solução Definitiva Aplicada |
| :--- | :--- | :--- |
| **Clique esquerdo para de atacar** | `ColorRect` de fundo do mundo criado com `mouse_filter` padrão (`STOP`) ou clique ignorado quando fora da cena. | `bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE` + ataque disparado em `_unhandled_input` direcionado ao cursor + `post_modal_guard_timer`. |
| **Ataque ou movimento vaza atrás de janelas** | Apenas uma janela específica pausava o jogo ou botões não consumiam evento. | `_sync_modal_pause()` centralizado para todos os modais + checagem `if has_open_modal() or get_tree().paused: return`. |
| **Dígitos cortados dentro de badge de pergaminho** | `StyleBoxTexture` de `panel_parchment.png` (180×180, borda ~18 px) usado em pill de 26 px com `content_margin < texture_margin`. | Usar `notes_pill_box()` (`StyleBoxFlat` com borda `#B58E43` e padding folgado) na HUD, Loja e Mochila. |
| **Botão de comprar parece ativo sem saldo** | Criação de botões de loja sem checar `cash_notes >= price`. | `btn.disabled = not can_afford`, variante `"stone"` dimmed, `CURSOR_ARROW` e refresh automático via `cash_changed`. |
| **Portal da vila escondido atrás do Minimapa/Analyzer** | Portal próximo à borda leste + `camera.limit_right == map_width`. | Posicionar portal logo após a saída da ponte **e** estender `camera.limit_right = int(map_width) + 256`. |
| **Botão de Chefe continua ativo após vencer todos os chefes** | Botão verificava apenas `zone_kills` em vez do próximo chefe pendente. | Consultar `GameState.get_next_world_boss()` e ocultar `boss_btn` quando retornar `""`. |
| **Áudio não toca no Chrome ao abrir** | Política de autoplay bloqueia `AudioStreamPlayer.play()` antes de gesto do usuário. | Retomar BGM automaticamente no primeiro evento `InputEventKey` ou `InputEventMouseButton` em `AudioManager._input`. |
| **Texto da cutscene não bate com a dublagem** | Áudio gravado antes de ajustes no roteiro ou com sotaque divergente. | Tratar arquivo MP3 + legenda como par atômico e regenerar ambos juntos quando houver revisão de texto/voz. |
