# 🎙️ Integração de Áudio ElevenLabs & Mixer — Dragon Adventure

Este documento descreve todo o ecossistema sonoro implementado com **ElevenLabs** e gerenciado por [`autoload/AudioManager.gd`](../autoload/AudioManager.gd) e [`scripts/SettingsModal.gd`](../scripts/SettingsModal.gd).

---

## 1. Arquitetura de Áudio (`AudioManager.gd`)
* **Mixer de 3 Canais Independentes:**
  1. **Música (`music_volume`, `bgm_enabled`):** Toca faixas em loop (`assets/audio/bgm/bgm_<mundo>.mp3`) com *crossfade* suave (`1.1s`) entre zonas e *ducking* automático (`-5.0 dB`) sempre que uma voz está tocando.
  2. **Efeitos Sonoros (`sfx_volume`, `sfx_enabled`):** Pool com 8 `AudioStreamPlayer` simultâneos + gerador de fallback sintético em tempo real caso algum arquivo esteja ausente.
  3. **Vozes & Dublagens (`voice_volume`, `voice_enabled`):** Player principal de diálogos/cutscenes + canal dedicado para gritos de magia (`_spell_voice_player`) para evitar cortes abruptos.
* **Desbloqueio Chrome WebGL Autoplay:** O método `_input` em `AudioManager.gd` inicia automaticamente a BGM na primeira tecla ou clique do usuário caso o navegador bloqueie autoplay inicial.
* **Persistência:** Preferências dos 3 canais salvas em `user://savegame.json`.

---

## 2. Inventário Completo de Áudios Gerados (`assets/audio/`)

### Trilha Sonora por Mapa (`assets/audio/bgm/`)
| Arquivo | Mapa | Direção Musical |
| :--- | :--- | :--- |
| `bgm_vila.mp3` | Vila Barão Ragnar | Suspense medieval sombrio e tenso |
| `bgm_floresta.mp3` | Floresta dos Ecos | Aventura épica medieval progressiva (nível 1) |
| `bgm_caverna.mp3` | Cavernas e Minas | Tema épico tenso/industrial subterrâneo (nível 2) |
| `bgm_castelo.mp3` | Castelo de Lunário | Clímax orquestral épico de fortaleza final (nível 3) |
| `bgm_cabana.mp3` | Cabana Inimiga Distante | Atmosfera misteriosa e emotiva de resgate |

### Efeitos Sonoros (`assets/audio/sfx/`)
`sword_slash.mp3`, `hammer_smash.mp3`, `magic_fireball.mp3`, `magic_tornado.mp3`, `magic_water_bomb.mp3`, `cash_pickup.mp3`, `eat_food.mp3`, `boss_roar.mp3`, `saw_blade.mp3`.

### Dublagens `pt-BR` (`assets/audio/voices/`, modelo `eleven_multilingual_v2`)
Vozes calibradas por faixa etária e alinhadas palavra por palavra ao texto exibido na tela:
* **Daniel Ragnar (menino herói `pt-BR` natural):** `daniel_intro.mp3`, `daniel_boss_challenge.mp3`, `daniel_fireball.mp3`, `daniel_tornado.mp3`, `daniel_water_bomb.mp3`, `daniel_levelup.mp3`, `daniel_victory.mp3`.
* **Barão Ragnar (pai maduro/heroico):** `barao_resgate.mp3`.
* **Aldeão / Ancião da Vila & Vendedor:** `intro_1_ataque.mp3`, `intro_2_barao.mp3`, `aldeao_intro.mp3`, `vendedor_ola.mp3`.
* **Explorador:** `explorador_floresta_1.mp3`, `explorador_floresta_2.mp3`, `explorador_caverna_1.mp3`, `explorador_caverna_2.mp3`, `explorador_castelo.mp3`.
* **Chefes (6 vozes malignas distintas):** `boss_lobisomem.mp3`, `boss_toupeira_serra.mp3`, `boss_robo_toupeira_serra.mp3`, `boss_robo_aranha.mp3`, `boss_dragao.mp3`, `boss_lunario.mp3`.
