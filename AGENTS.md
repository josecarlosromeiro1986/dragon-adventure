# Regras e Diretrizes do Projeto — Dragon Adventure: O Último Herói

## 🎨 Integração Visual: PixelLab.ai (Plano Tier 1: Pixel Apprentice)
* **Status da Conta:** Plano Ativo (`Tier 1: Pixel Apprentice`).
* **Limite Total:** **2.000 gerações** disponíveis.
* **Regra de Qualidade:** Utilizar os melhores modos do PixelLab (personagens em 4 direções com animações baseadas em esqueleto `template` / `skeleton-v3`, tilesets top-down e ícones de itens em pixel art) mantendo prompts consistentes e registrando o saldo periodicamente (`scripts/pixellab.ps1 -Action balance`).

---

## 🎙️ Integração de Áudio: ElevenLabs (Plano Starter)
* **Status da Conta:** Ativa (Plano Starter).
* **Limite Disponível:** **30.000 créditos/caracteres** disponíveis para o projeto.
* **Regra de Gestão:** Planejar cada efeito sonoro e fala antes de gerar para não desperdiçar a cota.
* **Utilização no Jogo:** Efeitos sonoros procedurais/sintéticos (SFX) via `scripts/elevenlabs.ps1 -Action sfx` e dublagens dos personagens principais (Daniel, Barão Ragnar, Lunário, Aldeão) via `scripts/elevenlabs.ps1 -Action tts`.

---

## 🎮 Diretrizes Centrais do Jogo
* **Engine & Linguagem Oficial:** **Godot Engine 4 (GDScript)** exportado para Web (HTML5 / WebGL Compatibility), homologado para o navegador **Google Chrome**.
* **Protagonista:** Daniel Ragnar é um **menino aventureiro** com uma **faixa/bandana vermelha marcante amarrada na testa** (com as pontas do nó esvoaçando para trás). Não é laço e não é adulto.
* **História:** O Deus Dragão Lunário criou monstros e destruiu vilas. Restou apenas a **Vila Barão Ragnar**, batizada em honra ao pai de Daniel (o Barão Ragnar), que desapareceu após lutar contra o dragão. Daniel é o Último Herói que derrotará os chefes e resgatará seu pai preso em uma cabana inimiga distante.
* **Estilo Visual & Gameplay:** Pixel art 2D top-down 45° (estilo clássico *Tibia / PokeTibia* e referência no *Poke Idle League*), com sistema de caçadas contínuas (Hunts), combate híbrido (Manual e Auto-Hunt), e o painel de telemetria *Hunt Analyzer*.
* **Economia:** Monstros dropam **dinheiro em notas de papel (cédulas)**. Comidas curam vida.
* **Documentação Oficial:** Consulte sempre a pasta `docs/` (`INDEX.md`, `AI_GAME_BLUEPRINT.md`, `GDD.md`, `NARRATIVE.md`, `CHARACTERS.md`, `ITEMS_AND_COMBAT.md`, `BESTIARY.md`, `WORLDS.md`, `ASSETS_PIXELLAB.md`, `AUDIO_ELEVENLABS.md`, `IMPLEMENTATION_PLAN.md`).
