# 📚 Dragon Adventure: O Último Herói — Documentação Oficial

Bem-vindo à documentação oficial do projeto **Dragon Adventure: O Último Herói**.  
Esta documentação foi estruturada de forma modular em Markdown para servir tanto de guia para desenvolvedores humanos quanto de base de conhecimento precisa para Inteligências Artificiais.

---

## 🗺️ Mapa da Documentação

| Arquivo | Descrição |
| :--- | :--- |
| [**AI_GAME_BLUEPRINT.md**](./AI_GAME_BLUEPRINT.md) | **Guia Arquitetural para IAs (Novo):** Passo a passo completo de como criar outro jogo 2D Top-Down RPG/Semi-Idle seguindo a arquitetura, padrões e lições aprendidas deste projeto. |
| [**GDD.md**](./GDD.md) | **Game Design Document Geral**: Visão geral, gênero, loop de caçadas, HUD, controles e arquitetura no Godot 4.7.2. |
| [**NARRATIVE.md**](./NARRATIVE.md) | **Narrativa e Enredo**: História de Daniel Ragnar, prólogo, cutscenes de chefes e epílogo do resgate do Barão Ragnar. |
| [**CHARACTERS.md**](./CHARACTERS.md) | **Personagens e NPCs**: Perfil de Daniel (menino com faixa vermelha e 4 evoluções de armadura), Barão Ragnar e os 3 NPCs. |
| [**ITEMS_AND_COMBAT.md**](./ITEMS_AND_COMBAT.md) | **Equipamentos, Magias e Economia**: Espadas/martelos (4 tiers), armaduras (4 tiers), 3 magias elementais, loja e comidas inteligentes. |
| [**BESTIARY.md**](./BESTIARY.md) | **Bestiário (Inimigos e Chefes)**: Tabelas exatas de HP, dano, XP, notas e fraquezas dos 7 monstros comuns e 6 chefes. |
| [**WORLDS.md**](./WORLDS.md) | **Mundos e Mapas**: Vila Barão Ragnar, Floresta dos Ecos, Cavernas e Minas, Castelo de Lunário e Cabana Inimiga Distante. |
| [**ASSETS_PIXELLAB.md**](./ASSETS_PIXELLAB.md) | **Integração PixelLab.ai**: Inventário completo de sprites, animações, mapas, UI 9-slice e fallbacks em `SpriteFactory.gd`. |
| [**AUDIO_ELEVENLABS.md**](./AUDIO_ELEVENLABS.md) | **Integração ElevenLabs & Mixer**: 5 BGMs por bioma, 9 SFX, dublagens `pt-BR` e mixer de 3 canais em `AudioManager.gd`. |
| [**IMPLEMENTATION_PLAN.md**](./IMPLEMENTATION_PLAN.md) | **Estrutura & Plano Concluído**: Mapa real de pastas/scripts e registro das 6 fases entregues. |
| [**DEVELOPMENT_HISTORY.md**](./DEVELOPMENT_HISTORY.md) | **Histórico Real da Jornada**: O prompt inicial fiel ao original e a cronologia completa dos 10 marcos até o GitHub. |

---

## 📌 Visão Resumida do Projeto
* **Título:** Dragon Adventure — O Último Herói
* **Motor & Linguagem (Engine):** Godot Engine 4.7.2 (GDScript) com Exportação Web (`gl_compatibility` HTML5 / WebGL 2.0)
* **Navegador Homologado:** Google Chrome
* **Gênero:** RPG de Ação e Aventura 2D / Semi-Idle com Zonas de Caçada (Hunts)
* **Estilo Visual:** Pixel Art Retrô Top-Down 45° (`64×36` tiles de `32 px` / `2048×1152 px`)
* **Protagonista:** Daniel Ragnar (Menino com faixa vermelha na testa)
* **Objetivo:** Explorar os mundos, evoluir equipamentos com notas de dinheiro, derrotar os 6 chefes (culminando no Deus Dragão Lunário) e resgatar o Barão Ragnar.
