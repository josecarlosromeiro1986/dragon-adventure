# 🎨 Integração PixelLab.ai & Pipeline Visual — Dragon Adventure

Este documento registra a configuração, arquitetura de sprites e inventário visual gerado via **PixelLab.ai** para o **Dragon Adventure: O Último Herói**.

---

## 1. Conta e Scripts de Integração
* **Plano:** `Tier 1: Pixel Apprentice` (**2.000 gerações**).
* **Endpoint MCP Remoto:** `https://api.pixellab.ai/mcp` (HTTP Streamable, header `Authorization: Bearer <TOKEN>`).
* **Scripts PowerShell:**
  * [`scripts/pixellab.ps1`](../scripts/pixellab.ps1) — Balance, criação de personagens, animações e objetos.
  * [`scripts/generate_batch1_characters.ps1`](../scripts/generate_batch1_characters.ps1), [`scripts/generate_batch2_environment.ps1`](../scripts/generate_batch2_environment.ps1), [`scripts/generate_batch5_animations.ps1`](../scripts/generate_batch5_animations.ps1), [`scripts/generate_batch5_landmarks.ps1`](../scripts/generate_batch5_landmarks.ps1), [`scripts/generate_medieval_ui.ps1`](../scripts/generate_medieval_ui.ps1), [`scripts/download_clean_frames.ps1`](../scripts/download_clean_frames.ps1).

---

## 2. Inventário de Assets Integrados em `res://assets/`

| Categoria | Diretório | Conteúdo Real Gerado |
| :--- | :--- | :--- |
| **Protagonista & Armaduras** | `assets/daniel_ragnar/`, `assets/daniel_armor_{wood,stone,gold,diamond}/` | 4 direções cardeais + animações de caminhada/ataque mantendo a faixa vermelha na testa. |
| **NPCs & Pai** | `assets/aldeao/`, `assets/vendedor/`, `assets/explorador/`, `assets/barao/` | Sprites direcionais de todos os personagens narrativos e mercador. |
| **Monstros Comuns (7)** | `assets/toupeira/`, `assets/zumbi/`, `assets/esqueleto/`, `assets/humano_minerador/`, `assets/robo/`, `assets/fantasma/`, `assets/espectro_slime/` | Sprites base + sequências `anim_walk` por direção (`espectro_slime` em 8 direções base + 4 direções `anim_walk` com 7 frames cada). |
| **Chefes (6)** | `assets/lobisomem/`, `assets/toupeira_serra/`, `assets/robo_toupeira_serra/`, `assets/robo_aranha/`, `assets/dragao/`, `assets/lunario/` | Sprites de chefes em escala ampliada e poses de combate/caminhada. |
| **Itens & Magias** | `assets/items/`, `assets/spells/` | 4 espadas (`sword_{wood,stone,gold,diamond}`), 4 martelos (`hammer_*`), 4 armaduras (`armor_*`), comidas (`maca`, `pao`, `carne_assada`, `banquete_real`), `cash_note.png` e ícones `fireball.png`, `tornado.png`, `water_bomb.png`. |
| **Mapas, Objetos & UI** | `assets/tiles/`, `assets/objects/`, `assets/ui/` | 5 mapas `fenaky_<mundo>.png`, objetos de cenário, 4 painéis `9-slice` (`panel_stone`, `panel_parchment`, `panel_gold`, `panel_slot`), 4 variantes de botões × 4 estados (`normal/hover/pressed/disabled`) e 8 ícones de HUD/cutscenes (`icon_*`). |

---

## 3. Camada de Carregamento e Padronização no Godot (`SpriteFactory.gd` & `MedievalUI.gd`)
1. [`autoload/SpriteFactory.gd`](../autoload/SpriteFactory.gd): Faz cache de texturas base e frames (`anim_walk`, `anim_attack`) e garante *fallback* procedural imediato em pixel art caso algum arquivo ainda não exista em disco.
2. [`scripts/MedievalUI.gd`](../scripts/MedievalUI.gd): Aplica `StyleBoxTexture` 9-slice, `notes_pill_box` padronizado para o contador de notas, tema global de janelas/scrollbars (`build_medieval_theme`) e controle de estados `disabled` dos botões.
