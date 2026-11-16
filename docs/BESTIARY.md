# 👹 Bestiário (Inimigos e Chefes) — Dragon Adventure: O Último Herói

*(Status exatos conforme [`autoload/GameData.gd`](../autoload/GameData.gd) e [`scripts/Monster.gd`](../scripts/Monster.gd).)*

## 1. Monstros Comuns (7 Tipos)
Todos os inimigos comuns possuem barra de HP dinâmica, animações direcionais em pixel art e dropam cédulas de dinheiro (`cash_min`–`cash_max`). O progresso de abates de cada espécie é registrado no **Bestiário Ilustrado (`[B]`)**.

| ID | Nome | Zonas | HP | Dano | Vel. | XP | Notas | Fraqueza (`x2`) |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| `toupeira` | Toupeira | Floresta / Caverna | 40 | 8 | 65 | 15 | 5–15 | 🔥 Bola de Fogo |
| `zumbi` | Zumbi | Floresta | 65 | 12 | 45 | 25 | 10–25 | 🔥 Bola de Fogo |
| `esqueleto` | Esqueleto | Floresta / Castelo | 55 | 14 | 75 | 30 | 15–30 | 🌪️ Tornado |
| `humano_minerador` | Humano Minerador | Caverna | 90 | 18 | 60 | 50 | 25–50 | Ataques físicos / combos |
| `robo` | Robô Patrulheiro | Caverna / Castelo | 115 | 22 | 55 | 75 | 40–75 | 💧 Bomba de Água |
| `fantasma` | Fantasma | Castelo | 115 | 26 | 80 | 120 | 70–125 | 🌪️ Tornado |
| `espectro_slime` | Espectro de Slime | Castelo | 145 | 28 | 72 | 145 | 85–145 | 🔥 Fogo & 🌪️ Tornado |

* **Ataques Duplos do `espectro_slime` (`Monster.gd` + `EnemyProjectile.gd`):** Humanoide simetricamente dividido (metade direita espectral com mão de plasma ciano / metade esquerda de slime roxo viscoso). A cada `1.75s` dentro de `285px`, alterna entre disparar uma **Orbe de Slime** roxa (`slime_orb`, `220 px/s`, `0.92x` do dano) diretamente da **mão de slime** e um **Raio de Plasma** ciano (`plasma_bolt`, `340 px/s`, `1.08x` do dano) diretamente da **mão de plasma**.

---

## 2. Sub-Chefes e Chefes (6 Chefes com Cutscene e Voz Própria)
Cada zona de caçada possui **1 Sub-Chefe** seguido de **1 Chefe Principal**. Após acumular os abates requeridos na zona (`kills_to_boss`), o botão **Desafiar Chefe** na HUD fica ativo e invoca o próximo chefe pendente com uma **cutscene dublada exclusiva** (fala maligna com timbre próprio + resposta de Daniel). Assim que ambos os chefes da zona são derrotados, o botão de invocação dessa zona desaparece automaticamente.

| ID | Nome | Zona | HP | Dano | Vel. | XP | Notas | Fraqueza / Recompensa |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| `lobisomem` | Lobisomem (Sub-Chefe) | Floresta | 300 | 25 | 95 | 200 | 150–250 | 🔥 Fogo · Desbloqueia **Tornado `[2]`** |
| `toupeira_serra` | Toupeira Serra (Chefe) | Floresta | 550 | 35 | 70 | 450 | 350–500 | 🔥 Fogo · Libera **Cavernas** + **Bomba de Água `[3]`** |
| `robo_toupeira_serra` | Robô Toupeira Serra (Sub-Chefe) | Caverna | 800 | 45 | 75 | 700 | 600–900 | 💧 Bomba de Água · Dispara serras giratórias |
| `robo_aranha` | Robô Aranha (Chefe) | Caverna | 1300 | 60 | 65 | 1200 | 1000–1500 | 💧 Bomba de Água · Libera **Castelo de Lunário** |
| `dragao` | O Dragão (Sub-Chefe) | Castelo | 2600 | 80 | 85 | 3200 | 2400–3200 | 💧 Bomba de Água · Jatos de fogo & garras |
| `lunario` | Lunário, o Deus Dragão (Chefe Final) | Castelo | 5200 | 105 | 90 | 6000 | 5000–8000 | 2 fases · Libera a **Cabana Inimiga Distante** |
