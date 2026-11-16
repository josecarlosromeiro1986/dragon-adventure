# 🐉 Dragon Adventure: O Último Herói

> **RPG de Ação e Aventura 2D Top-Down / Semi-Idle em Pixel Art para Navegador Web (WebGL 2.0).**  
> Desenvolvido em **Godot Engine 4.7.2 (GDScript)** a partir da história original concebida por Daniel e seu pai.
>
> 🎮 **Jogar Online (GitHub Pages):** [https://josecarlosromeiro1986.github.io/dragon-adventure/](https://josecarlosromeiro1986.github.io/dragon-adventure/)

---

## 📖 Sobre o Jogo

O **Deus Dragão Lunário** espalhou hordas de monstros que destruíram quase todas as vilas do reino. Apenas a **Vila Barão Ragnar** resistiu — batizada em homenagem ao pai de Daniel, o lendário **Barão Ragnar**, que desapareceu após partir para enfrentar o dragão.

No papel de **Daniel Ragnar**, o menino aventureiro com sua **faixa vermelha na testa**, você deve explorar cinco mundos conectados, caçar monstros em tempo real (no modo **Manual** ou **Auto-Hunt**), coletar **cédulas de dinheiro**, evoluir armas, armaduras e magias elementais, derrotar os **6 chefes** da campanha e resgatar seu pai na **Cabana Inimiga Distante**.

---

## ✨ Principais Recursos

- **Combate Híbrido (Manual + Auto-Hunt):** Jogue com mouse/teclado (`WASD`, clique esquerdo para atacar na direção do cursor, dash com `Shift` e 3 magias elementais `[1]`/`[2]`/`[3]`) ou ative o **Auto-Hunt (`[R]`)** com navegação `AStarGrid2D` e cura inteligente por comidas (`[Q]`).
- **Hunt Analyzer em Tempo Real:** Painel de telemetria inspirado em *Poke Idle League* e *Tibia* exibindo Tempo de Caçada, Abates, `XP/h`, Receita Bruta, Gasto em Comida e Lucro Líquido em notas.
- **5 Mundos Exploráveis (`64×36` tiles / `2048×1152 px`):**
  1. **Vila Barão Ragnar** (Hub seguro com Aldeão, Vendedor/Loja e portais)
  2. **Floresta dos Ecos**
  3. **Cavernas e Minas**
  4. **Castelo de Lunário**
  5. **Cabana Inimiga Distante** (Epílogo do resgate)
- **Bestiário Completo (`7` Monstros Comuns + `6` Chefes):** Inclui o **Espectro de Slime** no Castelo com ataques alternados de orbe de slime e raio de plasma, além de sub-chefes e chefes com áreas telegrafadas (`BossHazardZone`) e cutscenes dubladas.
- **4 Tiers de Progressão Visual & Equipamentos:** Madeira → Pedra → Ouro → Diamante (Espadas rápidas e Martelos pesados de área + Armaduras visíveis no personagem).
- **Áudio e Dublagem em Português (`pt-BR`):** 5 trilhas por bioma com *crossfade* e *ducking*, efeitos sonoros de combate e falas dubladas com mixer de 3 canais (`Música`, `SFX`, `Vozes`).
- **Auto-Save Persistente:** Progresso salvo automaticamente em `user://savegame.json`.

---

## 🎮 Controles Rápidos

| Comando | Ação |
| :--- | :--- |
| `W A S D` / Setas ou Clique no chão | Mover Daniel Ragnar |
| `Clique Esquerdo` / `Espaço` | Atacar (com mira na direção do cursor) |
| `Shift` | Dash rápido com invulnerabilidade breve |
| `1` / `2` / `3` | Bola de Fogo / Tornado / Bomba de Água |
| `Q` | Comer comida automaticamente para curar HP |
| `E` | Interagir com NPCs (Aldeão, Vendedor, Explorador, Barão) |
| `R` | Alternar **Auto-Hunt** ON/OFF |
| `B` / `I` / `M` / `Esc` | Bestiário / Mochila / Mapa Mundi / Configurações |

---

## 🚀 Como Rodar Localmente

### Pré-requisitos
- **Godot Engine 4.7.2** (com **Web Export Templates** instalados para exportar HTML5/WebGL)
- **Google Chrome** (navegador homologado para rodar o build WebGL via servidor HTTP local)

### Executando o jogo no Chrome (Export + Servidor Local)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_web_chrome.ps1 -Port 8080
```
- Se o build em `build/web/` já tiver sido gerado, utilize `-SkipExport` (ou execute [`jogar.bat`](jogar.bat) no Windows).
- Também é possível abrir o projeto diretamente no **Godot 4.7.2** selecionando [`project.godot`](project.godot).

### Validação Headless (Import & Smoke Test)
```powershell
godot --headless --path . --import
godot --headless --path . --quit-after 3
```

---

## 🔑 Scripts de Assets e Variáveis de Ambiente (Opcional)

Os assets finais já estão incluídos em [`assets/`](assets/). Caso deseje executar os scripts utilitários de geração em [`scripts/`](scripts/) (`pixellab.ps1`, `elevenlabs.ps1` e scripts em lote):

1. Copie [`.env.example`](.env.example) como referência.
2. Defina as variáveis de ambiente antes de executar os scripts PowerShell:
   - `PIXELLAB_API_KEY`
   - `ELEVENLABS_API_KEY`

---

## 📁 Estrutura do Projeto

```text
dragon-adventure/
├── autoload/               # Singletons globais (GameData, GameState, HuntAnalyzerData, SpriteFactory, AudioManager)
├── scenes/                 # Cena principal (Main.tscn)
├── scripts/                # Lógica de gameplay, UI medieval, mapas (TibiaTileEngine), utilitários e build Chrome
├── assets/                 # Sprites PixelLab, mapas Fenaky, UI 9-slice, ícones, músicas e dublagens ElevenLabs
├── docs/                   # Documentação modular completa (GDD, Narrativa, Bestiário, Mundos, Blueprint para IAs)
├── .env.example            # Modelo de variáveis de ambiente para geração de assets
├── .gitignore              # Regras de exclusão (.env, .godot/, build/, _archive/)
├── .gitattributes          # Padronização de line endings e binários
├── CONTRIBUTING.md         # Guia de contribuição e validação
├── export_presets.cfg      # Configuração oficial de exportação WebGL (build/web/)
├── jogar.bat               # Atalho Windows para subir o servidor local no Chrome
└── project.godot           # Configuração do projeto Godot Engine 4.7.2
```

---

## 📚 Documentação Completa

Consulte [`docs/INDEX.md`](docs/INDEX.md) para acessar toda a documentação do projeto:

- [**AI_GAME_BLUEPRINT.md**](docs/AI_GAME_BLUEPRINT.md) — Guia arquitetural passo a passo para recriar este modelo de jogo com apoio de IAs
- [**GDD.md**](docs/GDD.md) — Game Design Document completo
- [**NARRATIVE.md**](docs/NARRATIVE.md) — Narrativa por atos, cutscenes e epílogo
- [**CHARACTERS.md**](docs/CHARACTERS.md) — Daniel Ragnar, Barão Ragnar e NPCs
- [**ITEMS_AND_COMBAT.md**](docs/ITEMS_AND_COMBAT.md) — Armas, armaduras, magias, comidas e economia
- [**BESTIARY.md**](docs/BESTIARY.md) — 7 monstros comuns (incluindo Espectro de Slime) e 6 chefes
- [**WORLDS.md**](docs/WORLDS.md) — Os 5 mundos, portais e zonas de caçada
- [**ASSETS_PIXELLAB.md**](docs/ASSETS_PIXELLAB.md) — Pipeline visual e fallbacks procedurais
- [**AUDIO_ELEVENLABS.md**](docs/AUDIO_ELEVENLABS.md) — Pipeline de áudio, SFX e dublagem `pt-BR`
- [**IMPLEMENTATION_PLAN.md**](docs/IMPLEMENTATION_PLAN.md) — Arquitetura detalhada e histórico das fases
- [**DEVELOPMENT_HISTORY.md**](docs/DEVELOPMENT_HISTORY.md) — Prompt inicial fiel e linha do tempo completa do projeto até a publicação
- [**CHANGELOG.md**](CHANGELOG.md) — Registro oficial de versões (`SemVer`) e releases
